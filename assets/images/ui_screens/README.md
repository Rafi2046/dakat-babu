# UI/UX Screen Preview Board — Chor Police Dakat Babu

Portrait mobile game design system (1080×1920 target). Glossy 3D cartoon UI with Bangladeshi character art.

## Presentation boards

| Board | Screens | Path |
|---|---|---|
| Board A | 01–08 Splash → Main Game | `boards/board_01_08.png` |
| Board B | 09–16 Suspect → Badges | `boards/board_09_16.png` |
| Board C | 17–23 Settings → UI Library | `boards/board_17_23.png` |

User-supplied references: `references/`

## Individual portrait screens

| # | Screen | File |
|---|---|---|
| 01 | Splash / Loading | `individual/screen_01_splash_loading.png` |
| 02 | Home / Action | `individual/screen_02_home.png` |
| 03 | Game Mode Selection | `individual/screen_03_mode_selection.png` |
| 04 | Create / Join Room | `individual/screen_04_create_join_room.png` |
| 05 | Waiting Room | `individual/screen_05_waiting_room.png` |
| 06 | Game Intro | `individual/screen_06_game_intro.png` |
| 07 | Role Reveal (Police) | `individual/screen_07_role_reveal_police.png` |
| 08 | Main Game Room | `individual/screen_08_main_game_room.png` |
| 09 | Suspect Selection | `individual/screen_09_suspect_selection.png` |
| 10 | Correct Guess | `individual/screen_10_correct_guess.png` |
| 11 | Wrong Guess | `individual/screen_11_wrong_guess.png` |
| 12 | Round Complete | `individual/screen_12_round_complete.png` |
| 13 | Next Round | `individual/screen_13_next_round.png` |
| 14 | Final Scoreboard | `individual/screen_14_final_scoreboard.png` |
| 15 | Personal Score | `individual/screen_15_personal_score.png` |
| 16 | Badges | `individual/screen_16_badges.png` |
| 17 | Settings | `individual/screen_17_settings.png` |
| 18 | Play with Robot | `individual/screen_18_play_with_robot.png` |
| 19 | Play & Pass | `individual/screen_19_play_and_pass.png` |
| 20 | How to Play | `individual/screen_20_how_to_play.png` |
| 21 | Connection Error | `individual/screen_21_connection_error.png` |
| 22 | Confirmation Modals | `individual/screen_22_confirmation_modals.png` |
| 23 | UI Component Library | Covered on `boards/board_17_23.png` |

Flutter paths: `lib/core/constants/app_images.dart`

## Design tokens (from boards)

- **Police** blue · **Chor** red/orange · **Dakat** green · **Babu** gold/purple
- Large CTAs in thumb zone · Private roles never leak on shared screens
- Soft shadows, rounded cards, glossy 3D buttons

## Follow-ups (optional polish)

- Role reveal variants for Chor / Dakat / Babu
- Bangla-localized twins of Home / Results
- Pixel-perfect Flutter implementation from these mockups
