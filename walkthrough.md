# Customization, Extended Roles & Modern UI Walkthrough

We have implemented the complete suite of **Customization Features**, **4-6 Player Extended Roles**, **Customizable Scoring**, a **Dedicated Live Scoreboard Screen**, and **Modern Interactive UI Enhancements** across both online multiplayer and offline Pass & Play modes in **DakatBabu**.

---

## 1. Renameable Role System (Built-in Role Presets)
- **`RolePresetModel`** ([role_preset_model.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/data/models/role_preset_model.dart)):
  - Built-in presets:
    - **Classic (Raja-Mantri)**: `Raja`, `Mantri`, `Police`, `Chor`, `Chintaykari`, `Batpar`.
    - **Chor, Police, Dakat, Babu**: `Babu`, `Dewan`, `Police`, `Dakat`, `Chintaykari`, `Batpar`.
  - Stored in `rooms.role_preset` and `rooms.role_labels` (JSONB) so all players connected to the room see uniform customized naming throughout gameplay, lobby, interrogation, results, and scoreboard.
  - Full fallback mechanism to ensure backward compatibility with existing databases and legacy rooms.
- **Create Room UI** ([home_screen.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/presentation/screens/home/home_screen.dart)):
  - Host selects the role preset via animated interactive pills.
  - Expandable **"Customize Role Names & Points"** accordion allowing custom labels per role before launching.

---

## 2. Extended Roles for 4-6 Players (Chintaykari & Batpar)
- **Role Architecture**:
  - `GameRole` extended with `chintaykari` and `batpar` ([app_constants.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/core/constants/app_constants.dart)).
  - Colors, gradients, icons, and container tints added for both civilian roles in [app_colors.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/core/constants/app_colors.dart), [role_art.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/presentation/widgets/role_art.dart), and [extensions.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/core/utils/extensions.dart).
- **Game Logic & Suspect Pool**:
  - **4 Players**: Police interrogates `Mantri` vs `Chor`.
  - **5 Players**: Adds `Chintaykari`. Police interrogates `Mantri` vs `Chor` vs `Chintaykari`. Police must identify the specific `Chor`. `Chintaykari` earns a fixed civilian point value (default 500) regardless of the police guess outcome.
  - **6 Players**: Adds `Batpar` (default 300 pts). Police interrogates `Mantri` vs `Chor` vs `Chintaykari` vs `Batpar`.
  - `submitPoliceGuess` ([game_repository_impl.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/data/repositories/game_repository_impl.dart)) and `PassAndPlayViewModel` ([pass_and_play_viewmodel.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/presentation/viewmodels/pass_and_play_viewmodel.dart)) evaluate accuracy strictly against `chorPlayerId`.
- **Dynamic Capacity**:
  - Host selects `4`, `5`, or `6` players on the Create Room screen and Pass & Play setup screen.
  - Lobby capacity checks and "Start Game" validation dynamically adapt to the chosen player count.

---

## 3. Customizable Scoring System
- Host can optionally adjust the point rewards for each role at room creation:
  - Defaults: Raja (1000), Mantri (800), Police (500), Chor (500), Chintaykari (500), Batpar (300).
  - Stored in `rooms.role_points` (JSONB).
  - Scoring evaluations in `game_repository_impl.dart` read custom values via `room.getPointsForRole(role)`.

---

## 4. Dedicated Scoreboard Screen
- **`ScoreboardScreen`** ([scoreboard_screen.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/presentation/screens/scoreboard/scoreboard_screen.dart)):
  - Live ranking of all players ordered by cumulative score (#1 to #N).
  - **Gold Crown Spotlight**: Prominently highlights the match leader with golden glow, crown badge, and round stats.
  - **Round-by-Round Breakdown Chips**: Displays which role each player held in each past round and points earned (e.g., `R1: 👑 Raja (+1000)`, `R2: 👮 Police (+500)`).
  - **Anytime Access**: Accessible via a dedicated Trophy icon button in the AppBar during active game rounds and results.
  - Routed under `/scoreboard/:roomCode` via [app_routes.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/core/routes/app_routes.dart) and [app_router.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/core/routes/app_router.dart).
  - Backed by clean MVVM `ScoreboardViewModel` ([scoreboard_viewmodel.dart](file:///Users/rafi/Documents/office_projects/dakat-babu/lib/presentation/viewmodels/scoreboard_viewmodel.dart)).

---

## 5. Modern Interactive UI Enhancements
- **Police "Interrogation Case Board"**:
  - Replaces plain grids with a detective cork-board aesthetic: tilted cards (`-3°` to `+3°`), red pushpin markers, evidence photo tape, and dashed connection lines to a central interrogation badge.
- **Haptic Feedback**:
  - `HapticFeedback.lightImpact()` on secret role card flip.
  - `HapticFeedback.mediumImpact()` on suspect selection and accusation confirmation.
- **Tension Timer & Audio**:
  - Pulsing red ambient glow around suspect case board during the police decision phase.
  - Royalty-free, lightweight audio effects synthesized in `assets/sounds/` and triggered via `SoundService`:
    - `ticking.wav`: Subtle heartbeat/clock tick during interrogation.
    - `sting.wav`: Dramatic suspense sound before unmasking.
    - `success.wav`: Triumphant chime when Police catches Chor.
    - `failure.wav`: Failure buzzer when Chor escapes.
- **Celebration Effects**:
  - Integrated `ConfettiWidget` bursting over the screen upon a successful accusation.
- **Swipe-to-Accuse Gesture**:
  - Suspect cards support swipe-up gesture to accuse in addition to tap.

---

## 6. Verification & Test Results

### Automated Test Suite
Ran the entire automated test suite:
```bash
flutter test
```
**Results**:
- `RolePresetModel & Custom Role Labels`: Preset defaults, custom overrides, and JSON serialization (PASSED)
- `Customizable Scoring System`: Default points and custom point configurations (PASSED)
- `5-Player Gameplay (Chintaykari)`: Role assignment, suspect pool (3 suspects), correct accusation (PASSED)
- `6-Player Gameplay (Batpar)`: Role assignment, suspect pool (4 suspects), incorrect accusation (PASSED)
- `Scoreboard Ranking & History`: Leader calculation and per-round role breakdown (PASSED)
- `Pass & Play Mode`: All single-device turn flows, card peeking, and outcomes (PASSED)
- `Live 4-Client Online Round Flow`: Full online Supabase multi-client live simulation (PASSED)
- `Edge Cases & Security`: Host handover, mid-game leaves, timeout, and RLS policies (PASSED)
- **Total: 40 of 40 tests passed (100%)**

### Static Code Analysis
```bash
flutter analyze
```
**Result**: `No issues found! (0 errors, 0 warnings)`
