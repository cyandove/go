// Go Game Utilities & Constants
// Shared functions and configuration

// Board configuration
integer GO_BOARD_SIZE = 19;
float GO_CELL_SIZE = 0.5;
float GO_BOARD_OFFSET = -4.75;

// Player constants
integer BLACK = 1;
integer WHITE = 2;
integer EMPTY = 0;

// Returns player name
string player_name(integer player) {
    if (player == BLACK) return "Black";
    if (player == WHITE) return "White";
    return "Unknown";
}

// Returns player color
vector player_color(integer player) {
    if (player == BLACK) return <0.0, 0.0, 0.0>;
    if (player == WHITE) return <1.0, 1.0, 1.0>;
    return <0.5, 0.5, 0.5>;
}

// Convert board coordinates to world position
vector coord_to_world(integer x, integer y) {
    return <GO_BOARD_OFFSET + x * GO_CELL_SIZE,
            GO_BOARD_OFFSET + y * GO_CELL_SIZE,
            0.1>;
}

// Convert world position to board coordinates
vector world_to_coord(vector world_pos, vector board_pos) {
    vector local_pos = world_pos - board_pos;
    integer x = llRound((local_pos.x - GO_BOARD_OFFSET) / GO_CELL_SIZE);
    integer y = llRound((local_pos.y - GO_BOARD_OFFSET) / GO_CELL_SIZE);
    return <x, y, 0>;
}

// Check if coordinates are valid
integer is_valid_coord(integer x, integer y) {
    return (x >= 0 && x < GO_BOARD_SIZE && y >= 0 && y < GO_BOARD_SIZE);
}

// Convert 2D board coordinates to linear index
integer coord_to_index(integer x, integer y) {
    if (!is_valid_coord(x, y)) return -1;
    return y * GO_BOARD_SIZE + x;
}

// Convert linear index to 2D coordinates
vector index_to_coord(integer idx) {
    if (idx < 0 || idx >= GO_BOARD_SIZE * GO_BOARD_SIZE) return <-1, -1, 0>;
    return <idx % GO_BOARD_SIZE, idx / GO_BOARD_SIZE, 0>;
}

// Get adjacent positions (4-directional)
list get_adjacent(integer x, integer y) {
    list adjacent = [];
    if (is_valid_coord(x + 1, y)) adjacent += [<x + 1, y, 0>];
    if (is_valid_coord(x - 1, y)) adjacent += [<x - 1, y, 0>];
    if (is_valid_coord(x, y + 1)) adjacent += [<x, y + 1, 0>];
    if (is_valid_coord(x, y - 1)) adjacent += [<x, y - 1, 0>];
    return adjacent;
}

// Display a message with game prefix
say_game(string msg) {
    llSay(0, "[Go] " + msg);
}

// Format board position as string
string format_coord(integer x, integer y) {
    return "(" + (string)x + "," + (string)y + ")";
}
