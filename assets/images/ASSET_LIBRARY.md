# Chor Police Dakat Babu — Asset Library

Style bible: premium colorful 3D cartoon CGI, Bangladeshi characters, family-friendly comedy. Character reference: `assets/images/dakat_babu_splash.png`.

## Phase 1 — Done (shipped)

| Category | Assets | Path |
|---|---|---|
| Brand | Splash (existing), Logo, App icon | `brand/`, root splash |
| Characters | Police / Chor / Dakat / Babu standing | `characters/*/standing.png` |
| Role cards | Police, Chor, Dakat, Babu | `role_cards/` |
| Badges | Police, Chor, Dakat, Babu, Winner, Champion | `badges/` |
| Loading | Character group | `loading/` |
| Backgrounds | Dhaka city street | `backgrounds/` |
| Icons | Core 16-icon sheet (needs crop) | `icons/icon_sheet_core.png` |
| Buttons | Play Multiplayer | `buttons/` |
| Money | Pack (notes/stack/bag/coins) | `money/` |

Flutter constants: `lib/core/constants/app_images.dart`

## Remaining backlog (generate next batches)

### Characters — expressions × 4 roles (16 each)
Neutral, Happy, Laughing, Angry, Shocked, Scared, Confused, Suspicious, Excited, Sad, Victorious, Defeated, Surprised, Evil/mischievous, Pointing, Thinking

### Characters — poses × 4 roles
Standing ✅, Running, Pointing, Celebrating, Hiding, Suspicious, Laughing, Shocked, Defeated, Victory, Accusing, Caught, Looking around, Holding money, Holding role card

### Badges remaining
Game Lead, Detective, Master Detective, Lucky Guess, Perfect Round, Survivor, Fast Thinker, Police Hunter, Chor Master, Dakat King, Babu Boss

### UI icons (split sheets then crop)
Navigation, Gameplay, Multiplayer, Social, Stats — full lists from art brief

### Buttons (5 states each)
Play Online, Play With Robot, Play & Pass, Create/Join Room, Start, Ready, Continue, Next Round, Play Again, Home, Retry, Leave, Copy, Share, Choose Suspect — Normal / Pressed / Disabled / Selected / Locked

### Panels / player cards / scoreboard / feedback / decorative / loading chrome
Full lists from art brief

### Backgrounds remaining
Old Dhaka, Village road, Tea stall, Riverside, Market, Residential, Rickshaw street, Night city, Rooftop, Police station, Game arena

## Naming convention

```
characters/{role}/{pose}.png
characters/{role}/expr_{emotion}.png
badges/{slug}.png
role_cards/{role}.png
buttons/{slug}_{state}.png
backgrounds/{slug}.png
icons/{category}/{slug}.png
```

## Production notes

- Prefer transparent PNGs for characters, badges, icons, buttons.
- Keep consistent camera, lighting, and proportions using splash + standing heroes as references.
- Avoid political symbols / real political figures in backgrounds.
- Stylize currency; do not copy real banknote security designs.
- Icon sheets must be cropped into individual icons before production use.
