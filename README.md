# monaspace.hx

`monaspace.hx` is a Helix Steel plugin that enables [Monaspace](https://monaspace.githubnext.com/) font mixing by applying bold/italic modifiers to highlight groups, so your terminal renders different Monaspace variants for different syntax elements. The modifiers are patched onto your active theme, preserving its colors, and are re-applied automatically when you switch themes with `:theme`.

Inspired by [monaspace.nvim](https://github.com/jackplus-xyz/monaspace.nvim).

<img width="1881" height="2148" alt="Image" src="https://github.com/user-attachments/assets/94f65e1d-6fda-4042-a28b-3a0f06234d6e" />

> [!IMPORTANT]
> Requires a Helix Steel build from **2026-08-22 or later** — specifically one that ships `theme-set-name!` ([mattwparas/helix#130](https://github.com/mattwparas/helix/pull/130)) alongside the `current-theme` / `current-theme-name` APIs. On older builds the patched theme is silently shadowed by the on-disk theme of the same name and the plugin has no visible effect.

## How it works

Terminal emulators render bold, italic, and bold+italic text using separately configured fonts. This plugin sets bold/italic attributes on specific highlight groups:

| Style       | Monaspace Variant | Default scopes                          |
|-------------|-------------------|-----------------------------------------|
| Regular     | Neon              | Standard code                           |
| Bold        | Xenon (slab)      | Comments, headings, documentation       |
| Italic      | Radon (hand)      | Links, URLs, special strings, tags      |
| Bold+Italic | Krypton (mech)    | Diagnostics, errors, warnings           |

The active theme is cloned, patched, and registered as a **derived theme named `<theme>+monaspace`** (e.g. `ayu_mirage+monaspace`), which then becomes the active theme. The rename is required: Helix resolves theme names against the theme directories first and only falls back to dynamically registered themes, so a patched clone registered under the original name would be discarded on the next load.

Your `config.toml` keeps naming the base theme; the derived theme is created at runtime and re-created whenever you run `:theme` or `:config-reload`.

## Requirements

- Helix built with the Steel event system, 2026-08-22 or later. See [`STEEL.md`](https://github.com/mattwparas/helix/blob/steel-event-system/STEEL.md).
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

Two things the family names don't tell you:

- **Ligatures are spread across stylistic sets.** Monaspace files its coding
  ligatures under `ss01`–`ss10` (`!=`/`===`, arrows, `::`, `#[`, …), so the
  defaults alone give you a partial set; texture healing is `calt`. Enable them
  wherever your terminal exposes OpenType features, e.g. in kitty:
  `font_family family="Monaspace Neon" features="+calt +liga +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08 +ss09 +ss10"`.
- **No icons, no CJK.** Monaspace covers neither. For Nerd Font glyphs use the
  patched families (`MonaspiceNe`/`Xe`/`Rn`/`Kr` … `Nerd Font Mono`), and map CJK
  ranges to a fallback font in your terminal config.

## Installation

Install the package with Forge:

```sh
forge pkg install --git https://github.com/Xerxes-2/monaspace.hx.git
```

Then load it from your Helix `init.scm`:

```scheme
(require "monaspace/monaspace.scm")
```

The plugin installs itself when required. It patches your currently active theme on load and re-patches after every `:theme` switch or `:config-reload`.

## Customization

Override the scope lists before requiring the plugin:

```scheme
(set! *monaspace-bold-scopes*
  (append *monaspace-bold-scopes*
    '("keyword" "keyword.control" "keyword.function")))

(require "monaspace/monaspace.scm")
```

## Demo files

`test/demo.rs` and `test/demo.md` exercise the scopes the plugin touches — open
them after installing to check the mapping at a glance.

## Limitations

- Only 4 font slots available (regular, bold, italic, bold+italic) — this is a terminal constraint, not editor-specific
- No control over OpenType features (texture healing, stylistic sets) — those are terminal-level settings
- **Underlines are dropped on patched scopes.** Styles are rebuilt in "replace" mode so each scope lands in exactly one font slot, and Steel exposes no getter for a style's underline or modifiers, so an existing undercurl (common on `diagnostic.*`) cannot be carried over.
- **Theme previews are cut short.** Steel has no theme-change event, so re-patching is driven by the `post-command` hook. Once `:theme <name>` resolves to a real theme, the patched version is applied immediately and aborting the prompt with `Esc` leaves you on that theme instead of restoring the previous one.
- **Adaptive light/dark themes are not tracked.** With `theme = { light = ..., dark = ... }`, Helix swaps themes in response to the terminal's OSC 997 notification without running a command, so the patch is lost until the next `:theme` or `:config-reload`.
- **UI-only scopes the theme never declared may not take effect.** `theme-set-style!` appends new scopes without updating Helix's internal `scope_index`, so UI lookups such as inline diagnostics or jump labels fall back to the parent scope. Tree-sitter highlighting is unaffected.

## Notes

- The plugin reports itself as `monaspace.hx/0.2.0`.
- On load, after each `:theme` switch, and after `:config-reload`, the plugin clones the active theme, applies the modifiers, and registers the result as `<theme>+monaspace`. Themes that already carry the suffix are left alone.
