// Individual Go Stone Script
// Represents a single stone piece on the Go board

integer player;  // 1 for black, 2 for white
integer board_x;
integer board_y;

set_appearance() {
    if (player == 1) {
        llSetColor(<0.0, 0.0, 0.0>, ALL_SIDES);
        llSetText("●", <0.0, 0.0, 0.0>, 1.0);
    } else if (player == 2) {
        llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES);
        llSetText("○", <1.0, 1.0, 1.0>, 1.0);
    }
}

resize_for_board() {
    key board_key = llGetCreator();
    list board_info = llGetObjectDetails(board_key, [OBJECT_DESC]);
    string desc = llList2String(board_info, 0);

    if (desc != "") {
        list parts = llParseString2List(desc, ["|"], []);
        if (llGetListLength(parts) >= 2) {
            float cell_size = (float)llList2String(parts, 1);
            float stone_size = cell_size * 0.4;
            llSetScale(<stone_size, stone_size, stone_size * 0.5>);
        }
    }
}

default {
    state_entry() {
        // Parse stone type from object name: "1_stone" or "2_stone"
        string name = llGetObjectName();
        list parts = llParseString2List(name, ["_"], []);

        if (llGetListLength(parts) >= 2) {
            player = (integer)llList2String(parts, 0);
        }

        llSetObjectName("stone_" + (string)board_x + "_" + (string)board_y);

        set_appearance();
        resize_for_board();

        llSetPos(llGetPos() + <0, 0, 0.05>);
        llListen(1, "", "", "");
    }

    touch_start(integer num_detected) {
        key toucher = llDetectedKey(0);

        // Right-click to remove stone
        if (llDetectedTouchFace(0) == -1) {
            llSay(0, "Stone at (" + (string)board_x + ", " +
                  (string)board_y + ") removed.");
            llDie();
        } else {
            string player_color = "White";
            if (player == 1) {
                player_color = "Black";
            }
            llSay(0, player_color + " stone at (" +
                  (string)board_x + ", " + (string)board_y + ")");
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == 1) {
            list parts = llParseString2List(message, [":"], []);
            if (llGetListLength(parts) >= 3) {
                if (llList2String(parts, 0) == "delete") {
                    integer x = (integer)llList2String(parts, 1);
                    integer y = (integer)llList2String(parts, 2);
                    if (x == board_x && y == board_y) {
                        llDie();
                    }
                }
            }
        }
    }

    on_rez(integer start_param) {
        board_x = start_param >> 16;
        board_y = start_param & 0xFFFF;
        llResetScript();
    }
}
