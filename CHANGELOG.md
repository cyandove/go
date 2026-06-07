# Changelog

## [1.1.0] - 2026-06-07

### Added
- Touch board before game starts to open setup menu (New Game, Board Size)
- Board Size option opens a text input for any square board size
- Touch any stone during a game to open a reset confirmation dialog
- Menu times out after 30 seconds if no selection is made
- `pass_turn`, `undo_last_move`, and `show_status` now guard against being called with no active game

## [1.0.0] - 2026-06-06

### Added
- 19×19 Go board (configurable via BOARD_SIZE constant — 9, 13, 19 are standard)
- Board prim dimensions auto-calculate cell size and offset; resize the prim and reset the script to adapt
- Board size and cell size stored in prim description for stone use
- Two template stones (`1_stone`, `2_stone`) stored in board inventory; board rezzes copies on placement
- Stones sized automatically to 85% of cell width, 30% tall
- Coordinates packed into `start_param` on rez (bits 0–7: x, 8–15: y, 16–31: cell size in cm)
- Full group-based capture detection using BFS flood-fill
- Suicide rule enforced — move rejected if placed group has no liberty after captures resolve
- Stones remove themselves on capture via channel 1 `delete:x:y` message
- All stones remove themselves on reset via channel 1 `delete_all` message
- Chat commands (channel 0): `pass`, `reset`, `status`, `undo`
- Board transparent at 30% alpha on rez
