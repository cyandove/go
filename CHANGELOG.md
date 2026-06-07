# Changelog

## [1.1.1] - 2026-06-07

### Fixed
- Instructions corrected to match implementation: removed unimplemented handicap stones
  reference, fixed `status` command description, clarified stone menu availability and
  Score button behaviour

## [1.1.0] - 2026-06-07

### Added
- Touch board when no game is active to open setup menu (New Game, Board Size)
- Board Size option opens a text input accepting any positive integer for a square board
- Touch any stone to open a stone menu showing live game status (current player, capture counts)
- Stone menu options: Score, Remove Stone, Reset Game, Cancel
- Menus time out after 30 seconds
- Consecutive pass detection: two passes in a row ends the game
- Automatic territory counting at end of game using BFS flood-fill (Japanese rules)
- Komi (6.5 points) automatically added to White's final score; winner announced with margin
- Remove Stone option on stone menu for dead stone cleanup without resetting the game
- Score button on stone menu to recalculate and announce scores after dead stone removal
- Player registration: first person to place a stone for a color is locked in for that color
- Solo play supported — one player can register for both colors
- Chat commands gated to registered players; stone menu and board touch open to anyone
- `Go - How to Play` notecard with full rules, controls, scoring, and beginner tips

### Changed
- Removed "Black/White to play" chat announcements after each move
- Removed stone placement chat messages; only captures, errors, and registration are announced
- Stone menu fetches live game state from the board via private channel before showing
- Stone menu commands use a private channel (not public chat) to avoid chat spam
- Stone menu dialog uses a random per-interaction channel to prevent cross-stone collisions
- `pass` chat command routes through `player_pass` for consecutive-pass detection
- `pass_turn`, `undo_last_move`, and `show_status` guard against being called with no active game
- Stone Z position corrected — no longer hovers above the board surface

## [1.0.0] - 2026-06-06

### Added
- 19×19 Go board (configurable via BOARD_SIZE constant — 9, 13, 19 are standard)
- Board prim dimensions auto-calculate cell size and offset; resize the prim and reset the script to adapt
- Two template stones (`1_stone`, `2_stone`) stored in board inventory; board rezzes copies on placement
- Stones sized automatically to 85% of cell width, 30% tall
- Coordinates and cell size packed into `start_param` on rez (bits 0–7: x, 8–15: y, 16–31: cell size in cm)
- Full group-based capture detection using BFS flood-fill
- Suicide rule enforced — move rejected if placed group has no liberty after captures resolve
- Stones remove themselves on capture via channel 1 `delete:x:y` message
- All stones remove themselves on reset via channel 1 `delete_all` message
- Chat commands (channel 0): `pass`, `reset`, `status`, `undo`
- Board transparent at 30% alpha on rez
