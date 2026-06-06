// Go Stone
// Template: name this object "1_stone" (black) or "2_stone" (white)
// and place it in the board's inventory.

integer player;
integer board_x;
integer board_y;

set_appearance() {
    if (player == 1) {
        llSetColor(<0.0, 0.0, 0.0>, ALL_SIDES);
        llSetText("", ZERO_VECTOR, 0.0);
    } else if (player == 2) {
        llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES);
        llSetText("", ZERO_VECTOR, 0.0);
    }
}

default {
    state_entry() {
        llListen(1, "", "", "");
    }

    on_rez(integer start_param) {
        // start_param == 0 means manually rezzed for setup — leave the template alone
        if (start_param == 0) return;

        board_x = start_param & 0xFF;
        board_y = (start_param >> 8) & 0xFF;
        integer cell_cm = (start_param >> 16) & 0xFFFF;
        float cell_size = cell_cm / 100.0;

        // Parse player from template name: "1_stone" or "2_stone"
        string name = llGetObjectName();
        list parts = llParseString2List(name, ["_"], []);
        if (llGetListLength(parts) >= 1) {
            player = (integer)llList2String(parts, 0);
        }

        // Rename so the board can address this stone by position
        llSetObjectName("stone_" + (string)board_x + "_" + (string)board_y);

        set_appearance();

        // Size stone to fit board cell
        float stone_size = cell_size * 0.85;
        float stone_height = cell_size * 0.3;
        llSetScale(<stone_size, stone_size, stone_height>);

        llSetPos(llGetPos() + <0.0, 0.0, stone_height / 2.0>);

        llListen(1, "", "", "");
    }

    touch_start(integer num_detected) {
        string color = "White";
        if (player == 1) {
            color = "Black";
        }
        llSay(0, color + " stone at " + (string)board_x + "," + (string)board_y);
    }

    listen(integer channel, string name, key id, string message) {
        if (message == "delete_all") {
            llDie();
        } else {
            list parts = llParseString2List(message, [":"], []);
            if (llGetListLength(parts) == 3 && llList2String(parts, 0) == "delete") {
                integer tx = (integer)llList2String(parts, 1);
                integer ty = (integer)llList2String(parts, 2);
                if (tx == board_x && ty == board_y) {
                    llDie();
                }
            }
        }
    }
}
