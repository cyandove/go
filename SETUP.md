# LSL Go Game Setup Guide

A two-player Go game implementation for Second Life using transparent prims and interactive stones.

## Components

### board.lsl
The main board controller script. Manages:
- 19×19 board state
- Player turns (Black and White)
- Move validation
- Stone placement
- Game flow

### stone.lsl
Individual stone piece script. Each stone:
- Displays as black (●) or white (○)
- Shows board coordinates on touch
- Can be removed by right-clicking

## Installation in Second Life

### Step 1: Create the Board Prim
1. Rez a cube prim (start with 10m × 10m)
2. Name it "Go Board"
3. Set it to transparent (alpha 0.3) - the script will handle this
4. Resize it to be flat (make Z-dimension small, ~0.2m)
5. Drop the **board.lsl** script into it
6. The script will automatically calculate cell sizes based on the prim's dimensions
7. **Alternatively**: Add a visible Go board texture to the prim for a better visual

**Resizing tip**: You can resize the board prim at any time, and the cell sizes will automatically adjust. Just reset the script to recalculate.

### Step 2: Prepare Stone Objects
Create two stone object templates in your inventory:
- Name: `1_stone` (Black stones)
- Name: `2_stone` (White stones)

For each template:
1. Rez a small sphere or cube
2. Add the **stone.lsl** script
3. Save as an object in inventory
4. You can customize appearance (color, texture, size)

**Note:** The board.lsl script will rez stones dynamically with the naming convention:
- `1_stone_X_Y` for black stones
- `2_stone_X_Y` for white stones

Make sure these templates exist in the same region/inventory where the board operates.

### Step 3: Start Playing
1. Touch the transparent board at any intersection
2. A stone will appear at that intersection
3. Players alternate turns automatically
4. Say "pass" in local chat to pass your turn
5. Right-click a stone to remove it (for corrections)
6. Say "reset" to start a new game
7. Say "status" to see the current game state

## Game Rules

This implementation handles:
- Basic stone placement
- Turn alternation
- Occupancy validation (stones cannot be placed on occupied intersections)

**Not implemented** (you play by traditional Go rules):
- Capture detection
- Scoring
- Life/death determination
- Ko rule

Players should follow standard Go rules and manage captures manually, or expand the scripts to automate these features.

## Configuration

### Board Size
Edit `BOARD_SIZE` in the script to change the board dimensions:
```lsl
integer BOARD_SIZE = 19;  // Standard options: 9, 13, or 19
```

Common board sizes:
- **19×19** - Full professional Go game (361 stones per player)
- **13×13** - Medium game, plays faster
- **9×9** - Quick game, good for beginners

Reset the script after changing the board size.

### Prim Dimensions
The script automatically calculates cell size from your board prim's dimensions:
- **Larger prim** → larger cells (easier for clicking)
- **Smaller prim** → smaller cells (more compact layout)

You can resize the prim at any time, then reset the script to adapt.

## Limitations & Future Enhancements

Current limitations:
- No capture detection
- No automatic scoring
- No undo system (except manual removal)
- Board texture/visuals must be added manually

Possible enhancements:
- Add automatic capture detection (flood-fill algorithm)
- Implement scoring calculation
- Add a timer for timed games
- Add HUD menu for controls
- Multi-region support
- Persistent game save

## Commands (via local chat)

- `reset` - Start a new game
- `pass` - Pass your turn
- `status` - Show current player and stone count

## Troubleshooting

**Stones not appearing:**
- Check that stone object templates exist in inventory
- Verify naming convention matches (e.g., `1_stone`, `2_stone`)
- Check if you have object rez permissions in that region

**Board coordinates wrong:**
- Adjust `BOARD_OFFSET` and `CELL_SIZE` constants
- Ensure the board prim is aligned to the world grid

**Script errors:**
- Check LSL script syntax in the editor
- Verify all objects are in the same region
- Review Second Life console for error messages
