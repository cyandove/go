// Advanced Go Game Board Controller
// Includes capture detection, scoring, and improved game flow

#include "utils.lsl"

// Game state: 0 = empty, 1 = black, 2 = white
list board_state = [];
integer current_player = BLACK;
integer game_active = TRUE;

// Capture tracking
integer black_captures = 0;
integer white_captures = 0;

// Game history for undo
list move_history = [];

init_board() {
    integer i;
    board_state = [];
    for (i = 0; i < GO_BOARD_SIZE * GO_BOARD_SIZE; ++i) {
        board_state += [0];
    }
    black_captures = 0;
    white_captures = 0;
    move_history = [];
}

has_liberty(integer x, integer y) {
    // Check if a stone at (x,y) has a liberty (empty adjacent space)
    list adjacent = get_adjacent(x, y);
    integer i;
    for (i = 0; i < llGetListLength(adjacent); ++i) {
        vector coord = llList2Vector(adjacent, i);
        integer idx = coord_to_index((integer)coord.x, (integer)coord.y);
        if (llList2Integer(board_state, idx) == EMPTY) {
            return TRUE;
        }
    }
    return FALSE;
}

capture_group(integer x, integer y, integer opponent) {
    // Recursively capture opponent stones in a group with no liberties
    integer idx = coord_to_index(x, y);
    if (idx == -1 || llList2Integer(board_state, idx) != opponent) return 0;

    board_state = llListReplaceList(board_state, [EMPTY], idx, idx);
    integer captured = 1;

    list adjacent = get_adjacent(x, y);
    integer i;
    for (i = 0; i < llGetListLength(adjacent); ++i) {
        vector coord = llList2Vector(adjacent, i);
        if (!has_liberty((integer)coord.x, (integer)coord.y) &&
            llList2Integer(board_state, coord_to_index((integer)coord.x, (integer)coord.y)) == opponent) {
            captured += capture_group((integer)coord.x, (integer)coord.y, opponent);
        }
    }
    return captured;
}

check_and_capture(integer player) {
    // Check all adjacent opponent groups for captures
    integer opponent;
    if (player == BLACK) {
        opponent = WHITE;
    } else {
        opponent = BLACK;
    }
    integer captured = 0;

    list adjacent = [];
    integer i;
    for (i = 0; i < GO_BOARD_SIZE; ++i) {
        integer j;
        for (j = 0; j < GO_BOARD_SIZE; ++j) {
            if (llList2Integer(board_state, coord_to_index(i, j)) == opponent) {
                if (!has_liberty(i, j)) {
                    integer c = capture_group(i, j, opponent);
                    captured += c;
                    if (player == BLACK) {
                        black_captures += c;
                    } else {
                        white_captures += c;
                    }
                }
            }
        }
    }
    return captured;
}

place_stone(integer x, integer y, integer player) {
    integer idx = coord_to_index(x, y);
    if (idx == -1 || llList2Integer(board_state, idx) != EMPTY) {
        return FALSE;
    }

    // Place stone
    board_state = llListReplaceList(board_state, [player], idx, idx);

    // Check for captures
    integer captured = check_and_capture(player);
    if (captured > 0) {
        say_game((string)captured + " stone(s) captured!");
    }

    // Record in history for undo
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
    say_game("Black: " + (string)black_captures + " captured | " +
            "White: " + (string)white_captures + " captured");
    say_game("Current player: " + player_name(current_player));
}

reset_game() {
    init_board();
    current_player = BLACK;
    game_active = TRUE;
    say_game("Game reset. " + player_name(BLACK) + " to play.");
}

undo_last_move() {
    if (llGetListLength(move_history) < 3) {
        say_game("No moves to undo");
        return;
    }

    integer x = llList2Integer(move_history, -3);
    integer y = llList2Integer(move_history, -2);
    integer player = llList2Integer(move_history, -1);

    integer idx = coord_to_index(x, y);
    board_state = llListReplaceList(board_state, [EMPTY], idx, idx);
    move_history = llDeleteSubList(move_history, -3, -1);

    current_player = player;
    say_game("Move undone at " + format_coord(x, y));
}

default {
    state_entry() {
        init_board();
        llSetAlpha(0.3, ALL_SIDES);
        say_game("Advanced Go Board Ready");
        say_game("Commands: touch=place, pass=pass turn, undo=undo, reset=new game, status=show score");
    }

    touch_start(integer num_detected) {
        if (!game_active) {
            say_game("Game is not active");
            return;
        }

        vector touch_pos = llDetectedTouchPos(0);
        vector coords = world_to_coord(touch_pos, llGetPos());

        integer x = (integer)coords.x;
        integer y = (integer)coords.y;

        if (!is_valid_coord(x, y)) {
            say_game("Invalid position");
            return;
        }

        if (place_stone(x, y, current_player)) {
            say_game(player_name(current_player) + " placed at " + format_coord(x, y));
            show_status();
            pass_turn();
        } else {
            say_game("Cannot place stone at " + format_coord(x, y));
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
