// Go Board
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
integer game_active = TRUE;
integer black_captures = 0;
integer white_captures = 0;
list move_history = [];

calculate_dimensions() {
    vector scale = llGetScale();
    float min_dim = scale.x;
    if (scale.y < min_dim) min_dim = scale.y;
    CELL_SIZE = min_dim / BOARD_SIZE;
    BOARD_OFFSET = -(min_dim / 2.0) + (CELL_SIZE / 2.0);
    llSetObjectDesc((string)BOARD_SIZE + "|" + (string)CELL_SIZE);
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
}

integer coord_to_index(integer x, integer y) {
    if (x < 0 || x >= BOARD_SIZE || y < 0 || y >= BOARD_SIZE) return -1;
    return y * BOARD_SIZE + x;
}

// Returns flat list [x0,y0, x1,y1, ...]
list get_adjacent(integer x, integer y) {
    list adj = [];
    if (x + 1 < BOARD_SIZE) adj += [x + 1, y];
    if (x - 1 >= 0)         adj += [x - 1, y];
    if (y + 1 < BOARD_SIZE) adj += [x, y + 1];
    if (y - 1 >= 0)         adj += [x, y - 1];
    return adj;
}

// BFS flood-fill to find all connected stones of the same color
// Returns flat list [x0,y0, x1,y1, ...]
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

// True if any stone in the group has at least one empty adjacent cell
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

// Check opponent groups adjacent to the placed stone; remove any with no liberties.
// Returns flat list of captured positions [x0,y0, x1,y1, ...]
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

// start_param packing: bits 0-7 = x, bits 8-15 = y, bits 16-31 = cell_size in cm
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

    // Suicide rule: if the placed group still has no liberty, the move is illegal
    // (unless it just captured — in which case it may now have liberties)
    list own_group = find_group(x, y, player);
    if (!group_has_liberty(own_group)) {
        // Illegal move — undo placement
        board_state = llListReplaceList(board_state, [EMPTY], idx, idx);
        // Restore any erroneously "captured" stones (shouldn't occur, but be safe)
        integer k;
        for (k = 0; k < llGetListLength(captured); k += 2) {
            integer cx = llList2Integer(captured, k);
            integer cy = llList2Integer(captured, k + 1);
            board_state = llListReplaceList(board_state, [opponent], coord_to_index(cx, cy), coord_to_index(cx, cy));
        }
        return FALSE;
    }

    // Rez stone prim from board inventory
    vector pos = <BOARD_OFFSET + x * CELL_SIZE, BOARD_OFFSET + y * CELL_SIZE, 0.1>;
    llRezObject((string)player + "_stone", llGetPos() + pos, ZERO_VECTOR, ZERO_ROTATION, pack_start_param(x, y));

    // Handle captures
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
    return TRUE;
}

pass_turn() {
    if (current_player == BLACK) {
        current_player = WHITE;
    } else {
        current_player = BLACK;
    }
    say_game(player_name(current_player) + " to play");
}

show_status() {
    say_game("Black captures: " + (string)black_captures +
             " | White captures: " + (string)white_captures);
    say_game(player_name(current_player) + " to play");
}

reset_game() {
    init_board();
    current_player = BLACK;
    game_active = TRUE;
    llSay(1, "delete_all");
    say_game("New game. Black to play.");
}

undo_last_move() {
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
    say_game("Move undone. Note: captures cannot be restored.");
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

default {
    state_entry() {
        calculate_dimensions();
        init_board();
        llListen(0, "", "", "");
        llSetAlpha(0.3, ALL_SIDES);
        say_game((string)BOARD_SIZE + "x" + (string)BOARD_SIZE + " board ready. Black to play.");
        say_game("Commands: pass, reset, status, undo");
    }

    touch_start(integer num_detected) {
        if (!game_active) return;

        vector touch_pos = llDetectedTouchPos(0);
        vector local_pos = touch_pos - llGetPos();

        integer x = llRound((local_pos.x - BOARD_OFFSET) / CELL_SIZE);
        integer y = llRound((local_pos.y - BOARD_OFFSET) / CELL_SIZE);

        if (x < 0 || x >= BOARD_SIZE || y < 0 || y >= BOARD_SIZE) return;

        if (place_stone(x, y, current_player)) {
            say_game(player_name(current_player) + " plays at " + format_coord(x, y));
            show_status();
            pass_turn();
        } else {
            say_game("Illegal move at " + format_coord(x, y));
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (message == "pass") {
            pass_turn();
        } else if (message == "reset") {
            reset_game();
        } else if (message == "status") {
            show_status();
        } else if (message == "undo") {
            undo_last_move();
        }
    }

    on_rez(integer start_param) {
        llResetScript();
    }
}
