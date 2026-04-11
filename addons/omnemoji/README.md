# gd-OmnEmoji 🎉

**Universal cross-platform emoji support for Godot 4.x**

Guarantees consistent emoji rendering on Desktop, Mobile, and Web by bundling a compatible emoji font with automatic fallback injection.

[![Live Demo](https://img.shields.io/badge/🎮_Live_Demo-Play_Now-brightgreen)](https://gllm.codeberg.page/gd-OmnEmoji)

> **[🎮 Try the Live Demo](https://gllm.codeberg.page/gd-OmnEmoji)** — Test emoji rendering directly in your browser!

![OmnEmoji project settings](./screenshot/omnemoji_1.png)

## ✨ Features

- **Zero Configuration** — Copy addon, enable plugin, done!
- **Cross-Platform** — Windows, macOS, Linux, Android, iOS, and Web
- **Web Export Ready** — Bundled fonts ensure emoji work without system fonts
- **Auto-Download** — Missing fonts downloaded automatically from multiple mirrors
- **Multiple Providers** — Choose from Noto, OpenMoji, Twemoji, Fluent, or custom fonts
- **Automatic Fallback** — Injects emoji font into project's default theme
- **Export Plugin** — Fonts automatically included in all export builds
- **Consistent Rendering** — Same emoji appearance everywhere

![OmnEmoji web export](./screenshot/onmemoji_web.png)

## 📦 Installation

### Quick Start (2 Steps)

1. Copy the `addons/omnemoji` folder to your project's `addons/` directory
2. Enable the plugin: **Project → Project Settings → Plugins → OmnEmoji ✓**

**That's it!** Default fonts (Noto Color Emoji + Noto Sans) are bundled — no downloads required.

### From Codeberg/GitHub

```bash
# Clone the repository
git clone https://codeberg.org/gllm/gd-OmnEmoji.git

# Copy addon to your project
cp -r gd-OmnEmoji/addons/omnemoji your-project/addons/
```

## 🚀 Usage

Once enabled, emojis work automatically in:

- `Label` and `RichTextLabel` nodes
- `Button`, `LineEdit`, `TextEdit`
- Tooltips and any UI using the default font

### Example

```gdscript
# Just use emoji in your strings - they render correctly everywhere!
$Label.text = "Hello World! 🎉🚀❤️"
$RichTextLabel.text = "[center]Score: 100 ⭐[/center]"
```

## 🧪 Testing

Run the included test scene to verify emoji rendering:

```
test/comprehensive_emoji_test.tscn
```

### Demo Features

The comprehensive test scene includes:
- **Emoji Gallery** — Categories: smileys, gestures, hearts, animals, food, sports, objects, symbols
- **ZWJ Sequences** — Families, professions, pride flags, skin tone variations
- **Interactive Controls** — Buttons, checkboxes, dropdowns with emoji
- **Text Input** — LineEdit and TextEdit with emoji support
- **Rich Text** — BBCode formatting with emoji in RichTextLabel
- **Clipboard Operations** — Copy/paste emoji between applications
- **Selectable Text** — Select and copy emoji text
- **Animation Test** — Emoji cycling animation
- **RTL Support** — Hebrew and Arabic with emoji
- **Font Scaling** — 12px to 64px size tests
- **Edge Cases** — Mixed scripts, keycaps, flags, variation selectors

### Internationalization

The demo supports **12 languages** with auto-detection:
🇺🇸 English, 🇪🇸 Spanish, 🇫🇷 French, 🇩🇪 German, 🇯🇵 Japanese, 🇨🇳 Chinese, 🇷🇺 Russian, 🇧🇷 Portuguese, 🇰🇷 Korean, 🇺🇦 Ukrainian, 🇮🇱 Hebrew, 🇸🇦 Arabic

## 📁 Addon Structure

```
addons/omnemoji/
├── plugin.cfg                     # Addon metadata
├── gd_omnemojis_plugin.gd         # Main plugin (auto font injection)
├── font_providers.gd              # Font provider registry (loads from JSON)
├── font_downloader.gd             # Async font downloader with ZIP support
├── providers/
│   ├── emoji_providers.json       # Emoji font provider definitions
│   └── text_providers.json        # Text font provider definitions
├── exporter/
│   └── OmnEmojiExport.gd          # Export plugin (bundles fonts)
├── resources/
│   ├── OmnTextFont.tres           # Text font with emoji fallback
│   ├── OmnEmojiFont.tres          # Emoji font resource
│   └── OmnEmojiMerged.tres        # Combined font (set as project default)
└── third_party/
    ├── noto-emoji/                # Downloaded: Noto Color Emoji
    ├── openmoji/                  # Downloaded: OpenMoji (optional)
    ├── twemoji/                   # Downloaded: Twemoji (optional)
    └── noto-sans/                 # Text font
```

## 🔧 How It Works

1. **On Plugin Enable**: Loads bundled Noto Color Emoji and Noto Sans fonts
2. **Font Chain**: Creates `OmnTextFont` (text) → `OmnEmojiFont` (fallback)
3. **Project Integration**: Sets merged font as `gui/theme/custom_font`
4. **Export Plugin**: Forces font files to be bundled in all exports

The plugin modifies `project.godot` to set the custom font. Disable the plugin to restore original settings.

## ⚙️ Configuration (Optional)

For most users, the default setup works perfectly. Power users can customize fonts via **Project Settings → OmnEmoji**:

| Setting | Default | Description |
|---------|---------|-------------|
| `omnemoji/enabled` | `true` | Enable/disable emoji injection |
| `omnemoji/auto_download` | `true` | Download missing fonts automatically |
| `omnemoji/emoji_provider` | `Noto Color Emoji` | Emoji font provider (dropdown) |
| `omnemoji/text_provider` | `Noto Sans` | Text font provider (dropdown) |
| `omnemoji/custom_emoji_font` | *(empty)* | Custom emoji font path (when provider = Custom) |
| `omnemoji/custom_text_font` | *(empty)* | Custom text font path (when provider = Custom) |

### 🎨 Available Emoji Providers

| Provider | Size | License | Format | Notes |
|----------|------|---------|--------|-------|
| **Noto Color Emoji** ★ | ~10 MB | SIL OFL 1.1 | CBDT | Recommended, bundled |
| **OpenMoji** | ~52 MB | CC BY-SA 4.0 | CBDT | Open-source, download |
| **Twemoji** | ~1.2 MB | CC BY 4.0 | COLR | Twitter/X style |
| **Fluent Emoji** | ~88 MB | MIT | CBDT | Microsoft 3D style |
| **EmojiOne** | ~25 MB | OFL / CC BY 4.0 | SVG | Adobe's classic set |
| **Custom File** | varies | — | — | Your own TTF/OTF file |
| **System Default** | 0 MB | — | — | Uses OS fonts (no bundling) |

### 🔤 Available Text Providers

| Provider | Size | License | Notes |
|----------|------|---------|-------|
| **Noto Sans** | ~0.6 MB | SIL OFL 1.1 | Excellent Unicode coverage |
| **Roboto** | ~0.2 MB | Apache 2.0 | Android's default font |
| **Inter** | ~0.3 MB | SIL OFL 1.1 | Modern UI font |
| **Open Sans** | ~0.3 MB | SIL OFL 1.1 | Friendly, open |
| **Source Sans 3** | ~0.2 MB | SIL OFL 1.1 | Adobe's professional font |
| **Lato** | ~0.1 MB | SIL OFL 1.1 | Warm, semi-rounded |
| **Ubuntu** | ~0.4 MB | Ubuntu Font License | Canonical's font |
| **Fira Sans** | ~0.2 MB | SIL OFL 1.1 | Mozilla's Firefox OS font |

### Switching Providers

1. Go to **Project → Project Settings → OmnEmoji**
2. Select your preferred **Emoji Provider** from the dropdown
3. If font is missing, it downloads automatically (when auto-download enabled)
4. The plugin rebuilds fonts automatically

### Using a Custom Font

1. Set **Emoji Provider** to "Custom File"
2. Set **Custom Emoji Font** to your TTF/OTF path (e.g., `res://fonts/MyEmoji.ttf`)
3. Same process works for **Text Provider** and **Custom Text Font**

## 📋 Requirements

- **Godot 4.0+** (tested on 4.2+)
- ~10 MB disk space for default Noto fonts (varies by provider)
- Internet connection for auto-download (one-time, optional if fonts bundled)

## 📄 License

- **Addon Code**: MIT License
- **Noto Fonts**: SIL Open Font License 1.1 (OFL)
- **OpenMoji**: CC BY-SA 4.0
- **Twemoji**: CC BY 4.0 / MIT
- **Fluent Emoji**: MIT
- **EmojiOne**: SIL OFL 1.1 / CC BY 4.0

See [THIRD_PARTY.md](addons/omnemoji/THIRD_PARTY.md) for full attribution.

## 🐛 Troubleshooting

### Emoji not appearing?

1. Check the Output panel for `[OmnEmoji]` messages
2. Try disabling and re-enabling the plugin
3. Ensure no other addon is overriding `gui/theme/custom_font`

### Web export shows boxes (tofu)?

The export plugin should bundle fonts automatically. If not:
1. Check that `OmnEmojiExport` appears in export logs
2. Verify font files exist in `addons/omnemoji/third_party/`

### Want to use your own text font?

Configure in **Project Settings → OmnEmoji → Text Provider → Custom File**, then set the path.

### Adding Custom Font Providers

Edit the JSON files in `addons/omnemoji/providers/`:
- `emoji_providers.json` — Emoji font providers
- `text_providers.json` — Text font providers

Example emoji provider entry:

```json
"my_emoji": {
    "name": "My Custom Emoji",
    "description": "Description for UI",
    "filename": "MyEmoji.ttf",
    "subdir": "my-emoji",
    "size_mb": 5.0,
    "license": "MIT",
    "license_url": "https://...",
    "format": "COLR",
    "recommended": false,
    "zip_download": false,
    "mirrors": [
        "https://example.com/MyEmoji.ttf",
        "https://mirror.example.com/MyEmoji.ttf"
    ]
}
```

For ZIP archives, set `"zip_download": true` and add `"zip_filename": "path/inside/archive.ttf"`.

---

Made with ❤️ for the Godot community
