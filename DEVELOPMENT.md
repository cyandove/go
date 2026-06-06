# Development Notes for LSL Go Game

## Architecture & Design Decisions

### State Management
- **Simple list-based board**: Each cell is represented by its value in a list
  - 0 = empty
  - 1 = black stone
  - 2 = white stone
- **Linear indexing**: 2D coordinates converted to 1D via `index = y * BOARD_SIZE + x`
- Chosen for LSL compatibility (no structs or complex data types)

### Capture Detection (Advanced Version)
- Uses **flood-fill algorithm** to find connected groups
- **Liberty detection** determines if a group can survive
- **Recursive capture**: When a group has no liberties, all its stones are removed
- Time complexity: O(board_size²) per move in worst case

### Turn Management
- Simple boolean flip: `current_player = (current_player == 1) ? 2 : 1`
- No turn timer implemented (SL events handle timing)

## Known Limitations

### LSL Constraints
1. **No includes** - `#include` syntax is non-standard; use manual code copying
2. **Limited list operations** - No built-in sorting or efficient lookups
3. **Single-script limitations** - Cannot easily communicate between multiple board instances
4. **Memory limits** - Scripts have ~64KB data space
5. **No persistent storage** - Game state lost on script reset

### Game Logic
1. **Ko rule not enforced** - Players must follow Ko rule manually
2. **Scoring limited** - Advanced version only counts captured stones, not territory
3. **No group merging** - Adjacent same-color stones might not be treated as unified groups in basic version
4. **Manual territory counting** - Players must determine final territory manually

### Performance
1. **Large boards slow** - 21×21+ boards may have script timeout issues
2. **Capture detection cost** - Each move in advanced version scans entire board
3. **No caching** - Adjacent cell lookups computed fresh each time

## Potential Improvements

### Immediate Wins
```lsl
// Add endgame scoring
float calculate_territory(integer player) {
    // Count empty regions surrounded by player's stones
    // Use flood-fill from empty cells
}

// Add Ko rule tracking
list ko_state = [];  // Store last few board positions
integer check_ko(list previous_board) {
    // Compare current state to history
}

// Add pass-twice game end
integer consecutive_passes = 0;
```

### Medium-Term Enhancements
- **Notescard storage**: Save/load games
- **HUD menu**: Replace chat commands with GUI
- **Sound effects**: Add beeps for moves
- **Multiple boards**: Create a board manager for multi-game support

### Advanced Features
- **AI opponent**: Simple minimax for 9×9
- **Handicap system**: Place black stones before game starts
- **Timed games**: Integrated timer with countdown
- **Spectator mode**: Read-only observers
- **ELO rating**: Track player statistics

## Testing Checklist

- [ ] Basic placement works on all board positions
- [ ] Turn alternation correct
- [ ] Can pass turns
- [ ] Can reset game
- [ ] Captures work (advanced version)
- [ ] Undo works (advanced version)
- [ ] Stones visible at all board positions
- [ ] Touch coordinates map correctly
- [ ] No script errors on region restart
- [ ] Works with 9×9 and 13×13 boards
- [ ] Multiple players can take turns

## Performance Optimization Ideas

### Current Bottleneck: Capture Detection
```lsl
// Current: O(board_size²) flood-fill per move
// Could optimize with:

// 1. Lazy evaluation - only check adjacent groups
integer opponent = (player == BLACK) ? WHITE : BLACK;
list adjacent = get_adjacent(x, y);
for (each adjacent position) {
    if (stone_color == opponent && !has_liberty(opponent_group)) {
        capture(opponent_group);
    }
}

// 2. Cache adjacent relationships
list adjacent_cache = [];  // Pre-compute per position

// 3. Iterative captures
// Instead of recursion, use a queue for flood-fill
list to_check = [x, y];
while (llGetListLength(to_check) > 0) {
    // Process queue
}
```

### Reducing Memory Usage
```lsl
// Instead of storing full board state:
list board_state = [];  // Current: 361 integers for 19×19

// Could use bitpacking:
// Each integer = 32 bits, each cell = 2 bits (4 values)
// 361 cells / 16 cells per integer = ~23 integers
```

## Code Style Notes

- **Variable naming**: snake_case for functions, lowercase for variables
- **Constants**: ALL_CAPS
- **Comments**: Minimal, only explain WHY not WHAT
- **Indentation**: 4 spaces (LSL convention)
- **No fancy operators**: Avoid complex ternaries; use if/else for clarity

## Extending for Variants

### 13×13 Board
```lsl
integer GO_BOARD_SIZE = 13;
float GO_CELL_SIZE = 0.68;  // Adjust for your board size
float GO_BOARD_OFFSET = -4.26;
```

### 9×9 Board
```lsl
integer GO_BOARD_SIZE = 9;
float GO_CELL_SIZE = 1.02;
float GO_BOARD_OFFSET = -4.08;
```

## Debugging Tips

### Enable verbose output
```lsl
integer DEBUG = 1;
say_game(message) {
    if (DEBUG) {
        llSay(0, "[DEBUG] " + message);
    }
}
```

### Track board state
```lsl
print_board() {
    string output = "";
    integer i;
    for (i = 0; i < GO_BOARD_SIZE * GO_BOARD_SIZE; ++i) {
        output += (string)llList2Integer(board_state, i);
    }
    llSay(0, output);
}
```

### Validate coordinates
```lsl
integer x = /* from calculation */;
if (!is_valid_coord(x, y)) {
    llSay(0, "ERROR: Invalid coordinates " + format_coord(x, y));
    return;
}
```

## References

- **LSL Documentation**: https://wiki.secondlife.com/wiki/LSL
- **Go Rules**: https://www.usgo.org/what-is-go
- **Flood-Fill Algorithm**: Common graph traversal for region detection
