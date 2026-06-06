# LSL Go Game

A complete implementation of the ancient board game Go for Second Life, featuring transparent board prims and interactive stone pieces.

## Overview

This system provides two versions:
- **board.lsl** - Basic version with simple move validation
- **board_advanced.lsl** - Enhanced version with automatic capture detection and scoring

## Quick Start

### What You Need
1. A Second Life region where you have building permissions
2. The LSL scripts in this repository
3. Stone object templates (created in-world or provided)

### Installation

1. **Create the Board Prim**
   - Rez a cube prim (~10m × 10m)
   - Resize to be flat (small Z dimension)
   - Name it "Go Board"
   - Drop `board.lsl` or `board_advanced.lsl` into the prim
   - Done! The script sets transparency automatically

2. **Create Stone Templates**
   - Rez a small sphere (represents a Go stone)
   - Add `stone.lsl` script to it
   - Save as object named `1_stone` (for black stones)
   - Duplicate and save as `2_stone` (for white stones)
   - Keep these in your inventory; the board will rez them

3. **Start Playing**
   - Touch the board to place a stone
   - Alternate with your opponent
   - Use local chat commands:
     - `pass` - Skip your turn
     - `reset` - Start a new game
     - `status` - Show current score

## Features

### Basic Version (board.lsl)
- ✓ 19×19 Go board
- ✓ Two-player turn alternation
- ✓ Stone placement validation
- ✓ Prevents placing on occupied intersections
- ✓ Manual game flow control

### Advanced Version (board_advanced.lsl)
- ✓ All basic features
- ✓ Automatic capture detection
- ✓ Capture scoring (stones counted)
- ✓ Undo functionality (`undo` command)
- ✓ Move history tracking
- ✓ Liberty detection (determines group survival)
- ✓ Multi-stone group capture logic

## Game Rules

These scripts enforce basic Go placement rules:
1. Stones can only be placed on empty intersections
2. Players alternate (Black plays first)
3. Advanced version detects when groups have no liberties and captures them automatically

**Note**: The following are managed by players or require expansion:
- Life and death determination (advanced version has liberty detection)
- Ko rule (no immediate recapture)
- Scoring by territory (advanced version counts captured stones only)
- End-of-game procedures

## Files

| File | Purpose |
|------|---------|
| `board.lsl` | Basic board controller - simple, lightweight |
| `board_advanced.lsl` | Advanced board with capture detection and scoring |
| `stone.lsl` | Individual stone script for piece display |
| `utils.lsl` | Shared utilities and constants (used by advanced version) |
| `SETUP.md` | Detailed setup instructions |
| `README.md` | This file |

## Configuration

Edit these constants to customize:

```lsl
integer GO_BOARD_SIZE = 19;      // 19x19, 13x13, 9x9, etc.
float GO_CELL_SIZE = 0.5;        // Size of each intersection (meters)
float GO_BOARD_OFFSET = -4.75;   // Offset to center board
```

Adjust `GO_CELL_SIZE` based on your board prim size:
- For a 10m board: use 0.526 for 19×19
- For an 8m board: use 0.42 for 19×19

## Commands

### Local Chat Commands
```
pass        - Pass your turn to opponent
reset       - Start a new game (clears board)
status      - Display current game status
undo        - Undo last move (advanced version only)
```

### Gameplay
- **Touch** the board at any intersection to place a stone
- **Right-click** a stone to see its position (basic version)
- **Remove** stones by right-clicking (basic version) or they auto-remove when captured (advanced)

## Architecture

### Board Script Flow
1. Initialize empty 19×19 board state
2. Track current player (Black or White)
3. Listen for touch events
4. Validate move and place stone
5. Check for captures (advanced only)
6. Alternate player turns

### Stone Script
- Stores board position (x, y)
- Displays as black (●) or white (○)
- Can be interacted with for feedback
- Removed when captured (advanced version)

### State Representation
Board uses a simple list:
- Index = y * 19 + x (for 19×19 board)
- Value: 0=empty, 1=black, 2=white

## Troubleshooting

### Stones don't appear
- Verify stone object templates exist with exact names: `1_stone`, `2_stone`
- Check region rez permissions
- Ensure objects have storage in inventory

### Touch events not registering
- Check script permissions in object
- Verify prim has "Allow everyone" touch permissions
- Ensure you're touching the board prim, not sky

### Wrong board coordinates
- Adjust `GO_BOARD_OFFSET` and `GO_CELL_SIZE`
- Align board prim to world axes (0° rotation)
- Use `/debug` console to verify prim position

### Advanced version capture issues
- Group capture logic uses flood-fill; verify board state consistency
- Check for infinite loops in `capture_group()` function
- Ensure stone objects are properly cleaned up

## Performance Notes

- **Recommended board size**: 19×19 (full game)
- **Playable variants**: 13×13 (reasonable game), 9×9 (quick game)
- **Script efficiency**: 
  - Basic version: Very lightweight, minimal processing
  - Advanced version: Capture detection is O(n) per move; acceptable for small boards

## Future Enhancements

- [ ] Persistent game saves to notecards
- [ ] HUD menu interface for controls
- [ ] Timed games with countdown
- [ ] Multiplayer spectator mode
- [ ] Territory scoring calculation
- [ ] Ko rule enforcement
- [ ] Handicap stone support
- [ ] Sound effects for moves
- [ ] Statistical tracking (wins, games played)

## License & Attribution

This is a custom LSL implementation for Second Life. Adapt and modify as needed for your use.

## Support

For issues or improvements:
1. Check the troubleshooting section above
2. Review script syntax in LSL editor
3. Enable script debug mode to see detailed error messages
4. Test with a simple 9×9 board first

---

**Created for**: LSL educational and recreational use  
**Tested on**: Second Life (all regions with build permissions)  
**Last Updated**: 2026
