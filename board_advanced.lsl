// Go Board v1.1.0
// Standard rules: placement, group capture, suicide prevention

// Configuration: 9, 13, and 19 are standard sizes
integer BOARD_SIZE = 19;

float CELL_SIZE;
float BOARD_OFFSET;

integer BLACK = 1;
integer WHITE = 2;
integer EMPTY = 0;

list board_state = [];
integer current_player = BLACK;
integer game_active = FALSE;
integer black_captures = 0;
integer white_captures = 0;
list move_history = [];
integer consecutive_passes = 0;

key black_player = NULL_KEY;
key white_player = NULL_KEY;

float KOMI = 6.5;
integer black_territory;
integer white_territory;

integer menu_listen;
integer size_listen;
key menu_avatar;

integer MENU_CHANNEL = -9001;
integer SIZE_CHANNEL = -9002;
integer STATUS_REQUEST_CHANNEL = -9004;
integer BOARD_CMD_CHANNEL = -9005;

integer is_registered_player(key id) {
    if (black_player == NULL_KEY && white_player == NULL_KEY) return TRUE;
    return (id == black_player || id == white_player);
}

string player_name(integer p) {
    if (p == BLACK) return "Black";
    if (p == WHITE) return "White";
    return "Unknown";
}

say_game(string msg) {
    llSay(0, "[Go] " + msg);
}

string format_coord(integer x, integer y) {
    return "(" + (string)x + "," + (string)y + ")";
}

calculate_dimensions() {
    vector scale = llGetScale();
    float min_dim = scale.x;
    if (scale.y < min_dim) min_dim = scale.y;
    CELL_SIZE = min_dim / BOARD_SIZE;
    BOARD_OFFSET = -(min_dim / 2.0) + (CELL_SIZE / 2.0);
    llSetObjectDesc((string)BOARD_SIZE + "|" + (string)CELL_SIZE);
}

integer coord_to_index(integer x, integer y) {
    if (x < 0 || x >= BOARD_SIZE || y < 0 || y >= BOARD_SIZE) return -1;
    return y * BOARD_SIZE + x;
}

list get_adjacent(integer x, integer y) {
    list adj = [];
    if (x + 1 < BOARD_SIZE) adj += [x + 1, y];
    if (x - 1 >= 0)         adj += [x - 1, y];
    if (y + 1 < BOARD_SIZE) adj += [x, y + 1];
    if (y - 1 >= 0)         adj += [x, y - 1];
    return adj;
}

init_board() {
    integer i;
    board_state = [];
    for (i = 0; i < BOARD_SIZE * BOARD_SIZE; ++i) {
        board_state += [0];
    }
    black_captures = 0;
    white_captures = 0;
    move_history = [];
    consecutive_passes = 0;
}

list find_group(integer sx, integer sy, integer color) {
    list group = [];
    list frontier = [sx, sy];

    while (llGetListLength(frontier) > 0) {
        integer cx = llList2Integer(frontier, 0);
        integer cy = llList2Integer(frontier, 1);
        frontier = llDeleteSubList(frontier, 0, 1);

        integer idx = coord_to_index(cx, cy);
        if (idx != -1 &&
            llList2Integer(board_state, idx) == color &&
            llListFindList(group, [cx, cy]) == -1) {

            group += [cx, cy];

            list adj = get_adjacent(cx, cy);
            integer i;
            for (i = 0; i < llGetListLength(adj); i += 2) {
                integer nx = llList2Integer(adj, i);
                integer ny = llList2Integer(adj, i + 1);
                if (llListFindList(group, [nx, ny]) == -1) {
                    frontier += [nx, ny];
                }
            }
        }
    }
    return group;
}

integer group_has_liberty(list group) {
    integer i;
    for (i = 0; i < llGetListLength(group); i += 2) {
        integer x = llList2Integer(group, i);
        integer y = llList2Integer(group, i + 1);
        list adj = get_adjacent(x, y);
        integer j;
        for (j = 0; j < llGetListLength(adj); j += 2) {
            integer idx = coord_to_index(llList2Integer(adj, j), llList2Integer(adj, j + 1));
            if (llList2Integer(board_state, idx) == EMPTY) {
                return TRUE;
            }
        }
    }
    return FALSE;
}

list capture_adjacent(integer px, integer py, integer opponent) {
    list captured = [];
    list checked = [];

    list adj = get_adjacent(px, py);
    integer i;
    for (i = 0; i < llGetListLength(adj); i += 2) {
        integer nx = llList2Integer(adj, i);
        integer ny = llList2Integer(adj, i + 1);

        integer idx = coord_to_index(nx, ny);
        if (idx != -1 &&
            llList2Integer(board_state, idx) == opponent &&
            llListFindList(checked, [nx, ny]) == -1) {

            list group = find_group(nx, ny, opponent);
            checked += group;

            if (!group_has_liberty(group)) {
                integer j;
                for (j = 0; j < llGetListLength(group); j += 2) {
                    integer gx = llList2Integer(group, j);
                    integer gy = llList2Integer(group, j + 1);
                    integer gidx = coord_to_index(gx, gy);
                    board_state = llListReplaceList(board_state, [EMPTY], gidx, gidx);
                    captured += [gx, gy];
                }
            }
        }
    }
    return captured;
}

integer pack_start_param(integer x, integer y) {
    integer cell_cm = (integer)(CELL_SIZE * 100.0);
    return (cell_cm << 16) | (y << 8) | x;
}

integer place_stone(integer x, integer y, integer player) {
    integer idx = coord_to_index(x, y);
    if (idx == -1 || llList2Integer(board_state, idx) != EMPTY) {
        return FALSE;
    }

    integer opponent;
    if (player == BLACK) {
        opponent = WHITE;
    } else {
        opponent = BLACK;
    }

    board_state = llListReplaceList(board_state, [player], idx, idx);

    list captured = capture_adjacent(x, y, opponent);

    list own_group = find_group(x, y, player);
    if (!group_has_liberty(own_group)) {
        board_state = llListReplaceList(board_state, [EMPTY], idx, idx);
        integer k;
        for (k = 0; k < llGetListLength(captured); k += 2) {
            integer cx = llList2Integer(captured, k);
            integer cy = llList2Integer(captured, k + 1);
            board_state = llListReplaceList(board_state, [opponent], coord_to_index(cx, cy), coord_to_index(cx, cy));
        }
        return FALSE;
    }

    vector pos = <BOARD_OFFSET + x * CELL_SIZE, BOARD_OFFSET + y * CELL_SIZE, 0.0>;
    llRezObject((string)player + "_stone", llGetPos() + pos, ZERO_VECTOR, ZERO_ROTATION, pack_start_param(x, y));

    integer num_captured = llGetListLength(captured) / 2;
    if (num_captured > 0) {
        if (player == BLACK) {
            black_captures += num_captured;
        } else {
            white_captures += num_captured;
        }
        say_game((string)num_captured + " stone(s) captured!");
        integer i;
        for (i = 0; i < llGetListLength(captured); i += 2) {
            llSay(1, "delete:" + (string)llList2Integer(captured, i) + ":" + (string)llList2Integer(captured, i + 1));
        }
    }

    move_history += [x, y, player];
    consecutive_passes = 0;
    return TRUE;
}

pass_turn() {
    if (current_player == BLACK) {
        current_player = WHITE;
    } else {
        current_player = BLACK;
    }
}

calculate_territory() {
    black_territory = 0;
    white_territory = 0;
    list visited = [];

    integer i;
    for (i = 0; i < BOARD_SIZE * BOARD_SIZE; ++i) {
        if (llList2Integer(board_state, i) == EMPTY &&
            llListFindList(visited, [i]) == -1) {

            list region = [];
            list frontier = [i];
            integer borders = 0;  // bit 0 = black, bit 1 = white

            while (llGetListLength(frontier) > 0) {
                integer cidx = llList2Integer(frontier, 0);
                frontier = llDeleteSubList(frontier, 0, 0);

                if (llList2Integer(board_state, cidx) == EMPTY &&
                    llListFindList(region, [cidx]) == -1) {

                    region += [cidx];

                    integer cx = cidx % BOARD_SIZE;
                    integer cy = cidx / BOARD_SIZE;
                    list adj = get_adjacent(cx, cy);

                    integer j;
                    for (j = 0; j < llGetListLength(adj); j += 2) {
                        integer nidx = coord_to_index(
                            llList2Integer(adj, j),
                            llList2Integer(adj, j + 1));
                        integer nval = llList2Integer(board_state, nidx);
                        if (nval == EMPTY) {
                            if (llListFindList(region, [nidx]) == -1) {
                                frontier += [nidx];
                            }
                        } else if (nval == BLACK) {
                            borders = borders | 1;
                        } else if (nval == WHITE) {
                            borders = borders | 2;
                        }
                    }
                }
            }

            visited += region;
            integer region_size = llGetListLength(region);
            if (borders == 1) {
                black_territory += region_size;
            } else if (borders == 2) {
                white_territory += region_size;
            }
        }
    }
}

announce_score() {
    calculate_territory();

    integer black_score = black_territory + black_captures;
    float white_score = (float)(white_territory + white_captures) + KOMI;

    say_game("Black: " + (string)black_score + " pts  (" +
             (string)black_territory + " territory + " +
             (string)black_captures + " captures)");
    say_game("White: " + (string)white_score + " pts  (" +
             (string)white_territory + " territory + " +
             (string)white_captures + " captures + 6.5 komi)");
    if (white_score > (float)black_score) {
        say_game("White wins by " + (string)(white_score - (float)black_score) + " points!");
    } else {
        say_game("Black wins by " + (string)((float)black_score - white_score) + " points!");
    }
}

end_game() {
    game_active = FALSE;
    say_game("Both players passed. Game over!");
    say_game("Remove any agreed dead stones, then touch a stone and choose Score.");
    announce_score();
    say_game("Touch board to start a new game.");
}

player_pass() {
    if (!game_active) return;
    say_game(player_name(current_player) + " passes.");
    consecutive_passes++;
    if (consecutive_passes >= 2) {
        end_game();
    } else {
        pass_turn();
    }
}

show_status() {
    say_game("Black captures: " + (string)black_captures +
             " | White captures: " + (string)white_captures);
    if (game_active) {
        say_game(player_name(current_player) + " to play");
    } else {
        say_game("No game in progress. Touch board to start.");
    }
}

start_game() {
    init_board();
    current_player = BLACK;
    game_active = TRUE;
    black_player = NULL_KEY;
    white_player = NULL_KEY;
    say_game((string)BOARD_SIZE + "x" + (string)BOARD_SIZE + " game started. Black to play.");
}

reset_game() {
    game_active = FALSE;
    init_board();
    llSay(1, "delete_all");
    say_game("Game reset. Touch board to start.");
}

show_size_input(key avatar) {
    llListenRemove(size_listen);
    size_listen = llListen(SIZE_CHANNEL, "", avatar, "");
    llTextBox(avatar, "Enter board size\n(9, 13, and 19 are standard):", SIZE_CHANNEL);
}

show_setup_menu(key avatar) {
    menu_avatar = avatar;
    llListenRemove(menu_listen);
    menu_listen = llListen(MENU_CHANNEL, "", avatar, "");
    llDialog(avatar,
        "Go Board\nCurrent size: " + (string)BOARD_SIZE + "x" + (string)BOARD_SIZE,
        ["Board Size", "New Game"],
        MENU_CHANNEL);
    llSetTimerEvent(30.0);
}

undo_last_move() {
    if (!game_active) return;
    if (llGetListLength(move_history) < 3) {
        say_game("No moves to undo");
        return;
    }
    integer x = llList2Integer(move_history, -3);
    integer y = llList2Integer(move_history, -2);
    integer player = llList2Integer(move_history, -1);

    board_state = llListReplaceList(board_state, [EMPTY], coord_to_index(x, y), coord_to_index(x, y));
    move_history = llDeleteSubList(move_history, -3, -1);
    current_player = player;

    llSay(1, "delete:" + (string)x + ":" + (string)y);
    say_game("Undone. Note: captures cannot be restored.");
}

default {
    state_entry() {
        calculate_dimensions();
        init_board();
        llListen(0, "", "", "");
        llListen(STATUS_REQUEST_CHANNEL, "", "", "");
        llListen(BOARD_CMD_CHANNEL, "", "", "");
        llSetAlpha(0.3, ALL_SIDES);
        say_game((string)BOARD_SIZE + "x" + (string)BOARD_SIZE + " board ready. Touch to begin.");
    }

    touch_start(integer num_detected) {
        if (!game_active) {
            show_setup_menu(llDetectedKey(0));
            return;
        }

        vector touch_pos = llDetectedTouchPos(0);
        vector local_pos = touch_pos - llGetPos();

        integer x = llRound((local_pos.x - BOARD_OFFSET) / CELL_SIZE);
        integer y = llRound((local_pos.y - BOARD_OFFSET) / CELL_SIZE);

        if (x < 0 || x >= BOARD_SIZE || y < 0 || y >= BOARD_SIZE) return;

        key toucher = llDetectedKey(0);

        if (current_player == BLACK) {
            if (black_player == NULL_KEY) {
                black_player = toucher;
                say_game(llKey2Name(toucher) + " registered as Black.");
            } else if (black_player != toucher) {
                return;
            }
        } else {
            if (white_player == NULL_KEY) {
                white_player = toucher;
                say_game(llKey2Name(toucher) + " registered as White.");
            } else if (white_player != toucher) {
                return;
            }
        }

        if (place_stone(x, y, current_player)) {
            pass_turn();
        } else {
            say_game("Illegal move at " + format_coord(x, y));
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == MENU_CHANNEL) {
            llListenRemove(menu_listen);
            llSetTimerEvent(0.0);
            if (message == "New Game") {
                start_game();
            } else if (message == "Board Size") {
                show_size_input(id);
            }
        } else if (channel == SIZE_CHANNEL) {
            llListenRemove(size_listen);
            integer new_size = (integer)message;
            if (new_size >= 2) {
                BOARD_SIZE = new_size;
                calculate_dimensions();
                say_game("Board size set to " + (string)BOARD_SIZE + "x" + (string)BOARD_SIZE + ".");
            } else {
                say_game("Invalid size — enter a positive whole number.");
            }
            show_setup_menu(menu_avatar);
        } else if (channel == STATUS_REQUEST_CHANNEL) {
            list parts = llParseString2List(message, ["|"], []);
            if (llList2String(parts, 0) == "status" && llGetListLength(parts) >= 2) {
                integer resp_channel = (integer)llList2String(parts, 1);
                string status = player_name(current_player) + " to play\nBlack captures: " +
                    (string)black_captures + "\nWhite captures: " + (string)white_captures;
                llSay(resp_channel, status);
            }
        } else if (channel == BOARD_CMD_CHANNEL) {
            if (message == "score") {
                if (!game_active) {
                    say_game("Calculating score...");
                    announce_score();
                }
            } else if (message == "reset") {
                reset_game();
            } else if (llGetSubString(message, 0, 5) == "remove") {
                list parts = llParseString2List(message, [":"], []);
                if (llGetListLength(parts) == 3) {
                    integer ridx = coord_to_index(
                        (integer)llList2String(parts, 1),
                        (integer)llList2String(parts, 2));
                    if (ridx != -1) {
                        board_state = llListReplaceList(board_state, [EMPTY], ridx, ridx);
                    }
                }
            }
        } else if (channel == 0) {
            if (!is_registered_player(id)) return;
            if (message == "pass") {
                player_pass();
            } else if (message == "reset") {
                reset_game();
            } else if (message == "status") {
                show_status();
            } else if (message == "undo") {
                undo_last_move();
            }
        }
    }

    timer() {
        llListenRemove(menu_listen);
        llListenRemove(size_listen);
        llSetTimerEvent(0.0);
    }

    on_rez(integer start_param) {
        llResetScript();
    }
}
