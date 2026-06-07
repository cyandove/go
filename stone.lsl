// Go Stone v1.1.0
// Template: name "1_stone" (black) or "2_stone" (white), place in board inventory.

integer STONE_MENU_CHANNEL = -9003;

integer player;
integer board_x;
integer board_y;
integer stone_menu_listen;

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
        if (start_param == 0) return;

        board_x = start_param & 0xFF;
        board_y = (start_param >> 8) & 0xFF;
        integer cell_cm = (start_param >> 16) & 0xFFFF;
        float cell_size = cell_cm / 100.0;

        string name = llGetObjectName();
        list parts = llParseString2List(name, ["_"], []);
        if (llGetListLength(parts) >= 1) {
            player = (integer)llList2String(parts, 0);
        }

        llSetObjectName("stone_" + (string)board_x + "_" + (string)board_y);
        set_appearance();

        float stone_size = cell_size * 0.85;
        float stone_height = cell_size * 0.3;
        llSetScale(<stone_size, stone_size, stone_height>);
        llSetPos(llGetPos() + <0.0, 0.0, stone_height / 2.0>);

        llListen(1, "", "", "");
    }

    touch_start(integer num_detected) {
        key toucher = llDetectedKey(0);
        string color = "White";
        if (player == 1) {
            color = "Black";
        }
        llListenRemove(stone_menu_listen);
        stone_menu_listen = llListen(STONE_MENU_CHANNEL, "", toucher, "");
        llDialog(toucher,
            color + " stone at " + (string)board_x + "," + (string)board_y,
            ["Reset Game", "Cancel"],
            STONE_MENU_CHANNEL);
        llSetTimerEvent(30.0);
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == STONE_MENU_CHANNEL) {
            llListenRemove(stone_menu_listen);
            llSetTimerEvent(0.0);
            if (message == "Reset Game") {
                llSay(0, "reset");
            }
        } else if (channel == 1) {
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

    timer() {
        llListenRemove(stone_menu_listen);
        llSetTimerEvent(0.0);
    }
}
