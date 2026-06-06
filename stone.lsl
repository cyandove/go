// Individual Go Stone Script
// Represents a single stone piece on the Go board

integer player;  // 1 for black, 2 for white
integer board_x;
integer board_y;

set_appearance() {
    if (player == 1) {
        // Black stone
        llSetColor(<0.0, 0.0, 0.0>, ALL_SIDES);
        llSetText("●", <0.0, 0.0, 0.0>, 1.0);
    } else if (player == 2) {
        // White stone
        llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES);
        llSetText("○", <1.0, 1.0, 1.0>, 1.0);
    }
}

default {
    state_entry() {
        // Parse stone type from object name: "1_stone_x_y" or "2_stone_x_y"
        string name = llGetObjectName();
        list parts = llParseString2List(name, ["_"], []);

        if (llGetListLength(parts) >= 4) {
            player = (integer)llList2String(parts, 0);
            board_x = (integer)llList2String(parts, 2);
            board_y = (integer)llList2String(parts, 3);
        }

        set_appearance();

        // Scale stone appropriately (small 0.3m radius sphere)
        llSetScale(<0.3, 0.3, 0.15>);

        // Slight lift above board to avoid z-fighting
        llSetPos(llGetPos() + <0, 0, 0.05>);
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

    on_rez(integer start_param) {
        llResetScript();
    }
}
