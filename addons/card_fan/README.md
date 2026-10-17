# Card Fan for Godot 4

A polished, production-ready card fan UI component for Godot 4.6+.  
Cards arrange in a smooth arc with hover effects, drag-to-reorder, and multiple input methods.

![Godot 4.6+](https://img.shields.io/badge/Godot-4.6+-blue)

## ✨ Features

- **Fan-shaped card layout** — smooth arc arrangement that auto-adjusts based on card count
- **Hover float & neighbor avoidance** — hovered card rises, neighbors spread apart
- **Play cards** — double-click (mouse), swipe-up (touch), or joystick release
- **Drag-to-reorder** — long-press and drag cards to rearrange
- **Virtual joystick** — touch/gamepad joystick for card selection (with cursor dot)
- **Multi-input support** — mouse, touch screen, virtual joystick, and gamepad
- **New card fly-in animation** — cards enter from above with easing
- **Play card fly-out animation** — cards fly upward and fade when played
- **Fully customizable** — all parameters exposed as @export properties
- **Zero dependencies** — pure GDScript, no external plugins needed

## 🎮 Input Methods

| Input | Select | Play Card | Reorder |
|-------|--------|-----------|---------|
| Mouse | Hover | Double-click | Long-press drag |
| Touch | Drag | Swipe up | Long-press drag |
| Virtual Joystick | Move stick | Release on card | — |
| Gamepad | Left stick | Release / A button | — |

## 📦 Installation

### Method 1: Copy to Project

1. Download or clone this repository
2. Copy the `addons/card_fan/` folder into your project's `addons/` directory
3. Open `example/main.tscn` to see the demo

### Method 2: Godot Asset Library

Download from the [Godot Asset Library](https://godotengine.org/asset-library/) (coming soon).

## 🚀 Quick Start

```gdscript
# Add CardSet scene to your node
@onready var card_set = $CardSet

# Enable debug buttons (optional, for testing)
card_set.show_debug_buttons = true

# Connect signals
card_set.card_played.connect(_on_card_played)
card_set.card_clicked.connect(_on_card_clicked)

# Add cards
card_set.add_card("spade", 1)   # Spade A
card_set.add_card("heart", 13)  # Heart K
card_set.add_card("club", 7)    # Club 7

# Add card with custom texture
card_set.add_card_with_texture(my_texture, "diamond", 12)

# Remove cards
card_set.remove_card()            # Remove last card
card_set.remove_specific_card(c)  # Remove specific card

# Clear all
card_set.clear_all_cards()
```

## ⚙️ Export Properties

All parameters are configurable in the Inspector:

### Fan Layout
| Property | Default | Description |
|----------|---------|-------------|
| `fan_card_width` | 80 | Card width in pixels |
| `fan_card_height` | 120 | Card height in pixels |
| `fan_radius` | 600 | Fan arc radius (larger = flatter) |
| `fan_max_angle` | 50° | Max total spread angle |
| `fan_max_angle_step` | 5° | Angle step when few cards |
| `fan_min_angle_step` | 0.5° | Min angle step when many cards |
| `fan_arrange_duration` | 0.3s | Rearrange animation time |
| `fan_enter_duration` | 0.4s | New card enter time |

### Hover
| Property | Default | Description |
|----------|---------|-------------|
| `hover_offset` | 30 | Float-up distance on hover |
| `hover_avoid_angle` | 3° | Neighbor spread angle |
| `hover_duration` | 0.12s | Hover animation time |

### Play Card
| Property | Default | Description |
|----------|---------|-------------|
| `play_double_click_interval` | 0.35s | Max double-click gap |
| `play_swipe_min_distance` | 40px | Min swipe distance |
| `play_fly_duration` | 0.35s | Play animation time |
| `play_fly_distance` | 500px | Play fly distance |

### Drag Reorder
| Property | Default | Description |
|----------|---------|-------------|
| `drag_long_press_duration` | 0.45s | Long press time to start drag |
| `drag_long_press_move_threshold` | 12px | Max movement during long press |
| `drag_gap_factor` | 0.7 | Gap width multiplier during drag |

### Settings
| Property | Default | Description |
|----------|---------|-------------|
| `show_debug_buttons` | false | Show add/remove test buttons |
| `joystick_enabled` | true | Show virtual joystick |
| `debug_logging` | false | Print actions to console |

## 📁 File Structure

```
addons/card_fan/
├── src/
│   ├── card_set.gd          # Fan manager (main component)
│   ├── card_set.tscn        # Fan manager scene
│   ├── card.gd              # Single card component
│   ├── card.tscn            # Card scene (with default texture)
│   ├── joystick.gd          # Virtual joystick
│   ├── joystick.tscn        # Joystick scene
│   ├── joystick_handle.gd   # Joystick knob drawing
│   └── cursor_dot.gd        # Joystick cursor indicator
├── textures/
│   └── default_card.png     # Default card texture (placeholder)
├── example/
│   ├── demo.gd              # Example script
│   ├── demo.tscn            # Example scene
│   └── main.tscn            # Example entry point
└── README.md
```

## 🎨 Custom Card Texture

Replace the default card texture or use your own:

```gdscript
# Method 1: Use add_card_with_texture
card_set.add_card_with_texture(preload("res://my_card.png"), "spade", 1)

# Method 2: Set texture on card instance
var card = card_set.add_card("heart", 13)
card.set_card_texture(preload("res://my_heart_k.png"))
```

## 🃏 Card Suits & Ranks

**Suits:** `spade`, `heart`, `club`, `diamond`, `joker`  
**Ranks:** 1 (A), 2-10, 11 (J), 12 (Q), 13 (K), 14 (Small Joker), 15 (Big Joker)

## 📡 Signals

| Signal | Args | Description |
|--------|------|-------------|
| `card_played` | `card: Control` | Card is played (fly-out starts) |
| `card_clicked` | `card: Control` | Card is single-clicked/tapped |

## 🔧 Advanced: Custom Card Scene

Use your own card scene instead of the built-in one:

```gdscript
# In the Inspector, set card_scene_path to your custom scene
card_set.card_scene_path = "res://my_custom_card.tscn"
```

Your custom card scene must have these methods:
- `set_card_data(suit: String, rank: int, value: int = 0)`
- `get_card_name() -> String`
- `set_hovered(value: bool)`
- `set_original_position(pos: Vector2)`
- `get_card_data() -> Dictionary`
- `card_hovered` signal
- `card_exited` signal
- `card_clicked` signal

## 💝 Support

If you find this addon useful, consider supporting me!

- [爱发电 (Afdian)](https://afdian.net/) — Your support keeps me motivated!

## 📄 License

MIT License — Free for personal and commercial use. Attribution appreciated but not required.
