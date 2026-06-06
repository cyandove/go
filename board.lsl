// Go Game Board Controller
// Manages game state, validates moves, and communicates with stones

// Configuration: Change BOARD_SIZE to resize (9, 13, 19 are standard)
integer BOARD_SIZE = 19;

// Calculated automatically from board prim dimensions
float CELL_SIZE;
float BOARD_OFFSET;

// Game state: 0 = empty, 1 = black, 2 = white
list board_state = [];
integer current_player = 1;  // 1 for black, 2 for white
integer game_active = TRUE;

calculate_dimensions() {
    vector board_size = llGetScale();
    float board_x = board_size.x;
    float board_y = board_size.y;
    float min_dim = board_x;
    if (board_y < min_dim) min_dim = board_y;

    CELL_SIZE = min_dim / BOARD_SIZE;
    BOARD_OFFSET = -(min_dim / 2.0) + (CELL_SIZE / 2.0);
}

init_board() {
    integer i;
    board_state = [];
    for (i = 0; i < BOARD_SIZE * BOARD_SIZE; ++i) {
        board_state += [0];
    }
}

integer get_board_index(integer x, integer y) {
    if (x < 0 || x >= BOARD_SIZE || y < 0 || y >= BOARD_SIZE) return -1;
    return y * BOARD_SIZE + x;
}

vector get_cell_position(integer x, integer y) {
    return <BOARD_OFFSET + x * CELL_SIZE,
            BOARD_OFFSET + y * CELL_SIZE,
            0.1>;
}

integer place_stone(integer x, integer y, integer player) {
    integer idx = get_board_index(x, y);
    if (idx == -1 || llList2Integer(board_state, idx) != 0) {
        return FALSE;  // Invalid position or occupied
    }

    board_state = llListReplaceList(board_state, [player], idx, idx);

    vector pos = get_cell_position(x, y);
    string template_name = (string)player + "_stone";

    llRezObject(template_name, llGetPos() + pos, ZERO_VECTOR, ZERO_ROTATION, (x << 16) | y);

    return TRUE;
}

remove_stone(integer x, integer y) {
    integer idx = get_board_index(x, y);
    if (idx != -1 && llList2Integer(board_state, idx) != 0) {
        board_state = llListReplaceList(board_state, [0], idx, idx);
    }
}

integer get_stone_state(integer x, integer y) {
    integer idx = get_board_index(x, y);
    if (idx == -1) return 0;
    return llList2Integer(board_state, idx);
}

pass_turn() {
    if (current_player == 1) {
        current_player = 2;
    } else {
        current_player = 1;
    }
    string stone_color = "White";
    if (current_player == 1) {
        stone_color = "Black";
    }
    llSay(0, "Player " + (string)current_player + "'s turn (Stone: " + stone_color + ")");
}

reset_game() {
    init_board();
    current_player = 1;
    game_active = TRUE;
    llSay(0, "Game reset. Black to play.");
}

default {
    state_entry() {
        calculate_dimensions();
        init_board();
        llListen(0, "", "", "");
        llSay(0, "Go Board Ready (" + (string)BOARD_SIZE + "x" + (string)BOARD_SIZE + ")");
        llSay(0, "Cell size: " + (string)(llRound(CELL_SIZE * 100.0) / 100.0) + "m");
        llSay(0, "Black plays first. Touch the board to place stones.");

        // Make board transparent
        llSetAlpha(0.3, ALL_SIDES);
    }

    touch_start(integer num_detected) {
        if (!game_active) return;

        vector touch_pos = llDetectedTouchPos(0);
        vector local_pos = touch_pos - llGetPos();

        // Convert touch position to board coordinates
        integer x = llRound((local_pos.x - BOARD_OFFSET) / CELL_SIZE);
        integer y = llRound((local_pos.y - BOARD_OFFSET) / CELL_SIZE);

        if (x >= 0 && x < BOARD_SIZE && y >= 0 && y < BOARD_SIZE) {
            if (place_stone(x, y, current_player)) {
                string player_color = "White";
                if (current_player == 1) {
                    player_color = "Black";
                }
                llSay(0, player_color + " plays at (" + (string)x + ", " + (string)y + ")");
                pass_turn();
            } else {
                llSay(0, "Position (" + (string)x + ", " + (string)y + ") is occupied or invalid!");
            }
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (message == "reset") {
            reset_game();
        } else if (message == "pass") {
            pass_turn();
        } else if (message == "status") {
            string current_color = "White";
            if (current_player == 1) {
                current_color = "Black";
            }
            llSay(0, "Current Player: " + current_color);
            integer i;
            integer stones_placed = 0;
            for (i = 0; i < llGetListLength(board_state); ++i) {
                if (llList2Integer(board_state, i) != 0) {
                    stones_placed++;
                }
            }
            llSay(0, "Stones placed: " + (string)stones_placed);
        }
    }

    on_rez(integer start_param) {
        llResetScript();
    }
}
