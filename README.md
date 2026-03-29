# monaspace.hx

`monaspace.hx` is a Helix Steel plugin that enables [Monaspace](https://monaspace.githubnext.com/) font mixing by applying bold/italic modifiers to highlight groups, so your terminal renders different Monaspace variants for different syntax elements.

Inspired by [monaspace.nvim](https://github.com/jackplus-xyz/monaspace.nvim).

## How it works

Terminal emulators render bold, italic, and bold+italic text using separately configured fonts. This plugin sets bold/italic attributes on specific highlight groups:

| Style       | Monaspace Variant | Default scopes                          |
|-------------|-------------------|-----------------------------------------|
| Regular     | Neon              | Standard code                           |
| Bold        | Xenon (slab)      | Comments, headings, documentation       |
| Italic      | Radon (hand)      | Links, URLs, special strings, tags      |
| Bold+Italic | Krypton (mech)    | Diagnostics, errors, warnings           |

## Requirements

- Helix built with the Steel event system. See [`STEEL.md`](https://github.com/mattwparas/helix/blob/steel-event-system/STEEL.md).
- A terminal emulator that supports per-style font configuration (kitty, ghostty, alacritty, wezterm, etc.)

## Terminal setup

Configure your terminal to use different Monaspace variants:

### kitty
```conf
font_family      Monaspace Neon
bold_font        Monaspace Xenon Bold
italic_font      Monaspace Radon Italic
bold_italic_font Monaspace Krypton Bold Italic
```

### ghostty
```conf
font-family = "Monaspace Neon"
font-family-bold = "Monaspace Xenon"
font-family-italic = "Monaspace Radon"
font-family-bold-italic = "Monaspace Krypton"
```

### alacritty
```toml
[font]
normal.family = "Monaspace Neon"
bold.family = "Monaspace Xenon"
italic.family = "Monaspace Radon"
bold_italic.family = "Monaspace Krypton"
```

### wezterm
```lua
config.font = wezterm.font("Monaspace Neon")
config.font_rules = {
  { intensity = "Bold", font = wezterm.font("Monaspace Xenon") },
  { italic = true, font = wezterm.font("Monaspace Radon") },
  { intensity = "Bold", italic = true, font = wezterm.font("Monaspace Krypton") },
}
```

## Installation

Install the package with Forge:

```sh
forge pkg install --git https://github.com/Xerxes-2/monaspace.hx.git
```

Then load it from your Helix `init.scm`:

```scheme
(require "monaspace/monaspace.scm")
```

The plugin installs itself when required. Switch to the monaspace theme with `:theme monaspace`.

## Customization

Override the scope lists before requiring the plugin:

```scheme
(set! *monaspace-bold-scopes*
  (append *monaspace-bold-scopes*
    '("keyword" "keyword.control" "keyword.function")))

(require "monaspace/monaspace.scm")
```

## Limitations

- Only 4 font slots available (regular, bold, italic, bold+italic) — this is a terminal constraint, not editor-specific
- The Steel API doesn't currently expose a way to clone the active theme, so monaspace modifiers are applied to a new empty theme rather than patching the current one
- No control over OpenType features (texture healing, stylistic sets) — those are terminal-level settings

## Notes

- The plugin reports itself as `monaspace.hx/0.1.0`.
- The created theme is named "monaspace" and registered on plugin load.
