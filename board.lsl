// Go Game Board Controller
// Manages game state, validates moves, and communicates with stones

integer BOARD_SIZE = 19;
float CELL_SIZE = 0.5;  // Size of each cell in meters
float BOARD_OFFSET = -4.75;  // Offset to center board

// Game state: 0 = empty, 1 = black, 2 = white
list board_state = [];
integer current_player = 1;  // 1 for black, 2 for white
integer game_active = TRUE;

// Stone object info for tracking
list stone_ids = [];

init_board() {
    integer i;
    board_state = [];
    for (i = 0; i < BOARD_SIZE * BOARD_SIZE; ++i) {
        board_state += [0];
    }
}

get_board_index(integer x, integer y) {
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

    // Request stone from sovers to display piece at this position
    vector pos = get_cell_position(x, y);
    string stone_name = (string)player + "_stone_" + (string)x + "_" + (string)y;

    llRezObject(stone_name, llGetPos() + pos, ZERO_VECTOR, ZERO_ROTATION, 0);

    return TRUE;
}

remove_stone(integer x, integer y) {
    integer idx = get_board_index(x, y);
    if (idx != -1 && llList2Integer(board_state, idx) != 0) {
        board_state = llListReplaceList(board_state, [0], idx, idx);
    }
}

get_stone_state(integer x, integer y) {
    integer idx = get_board_index(x, y);
    if (idx == -1) return 0;
    return llList2Integer(board_state, idx);
}

pass_turn() {
    current_player = (current_player == 1) ? 2 : 1;
    llSay(0, "Player " + (string)current_player + "'s turn (Stone: " +
          ((current_player == 1) ? "Black" : "White") + ")");
}

reset_game() {
    init_board();
    current_player = 1;
    game_active = TRUE;
    llSay(0, "Game reset. Black to play.");
}

default {
    state_entry() {
        init_board();
        llSay(0, "Go Board Ready");
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
                llSay(0, (current_player == 1 ? "Black" : "White") +
                      " plays at (" + (string)x + ", " + (string)y + ")");
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
            llSay(0, "Current Player: " + ((current_player == 1) ? "Black" : "White"));
            llSay(0, "Stones placed: " + (string)(llGetListLength(board_state) -
                    llListFindList(board_state, [0])));
        }
    }

    on_rez(integer start_param) {
        llResetScript();
    }
}
