//! Crate-level doc comment — rendered in Xenon (bold → slab serif).
//!
//! This file exercises the scopes the monaspace plugin touches so you can
//! eyeball the font-mixing effect in a single buffer.

// Line comment: also Xenon. Compare its shape against the code below.

/* Block comment: Xenon again. Same story — structural, set-apart text. */

// Helix injects the `comment` grammar into comments, and its tags land on the
// `error`/`warning`/`info`/`hint` scopes — the same slot as diagnostics, so
// they jump out of the surrounding Xenon in Krypton (bold+italic):
//
// TODO: info tag.
// HINT: hint tag.
// HACK: warning tag.
// SAFETY: error tag — every `// SAFETY:` in unsafe code pops automatically.

/// Doc comment on an item. Xenon.
///
/// Helix injects `markdown-rustdoc` here, and injected styles are *merged*
/// with the enclosing one rather than replacing it. So <https://example.com>
/// picks up italic from `markup.link.url` on top of the comment's bold and
/// renders in Krypton, not Radon.
pub fn regular_code_is_neon() {
    let greeting = "Hello, world!"; // regular strings → Neon
    let path = "/usr/local/bin"; // Rust has no `string.special` captures,
    let url = "https://example.com"; // so both of these stay Neon too
    println!("{greeting} {path} {url}");
}

/// Lifetimes are captured as `label`, so every `'a` renders in Radon
/// (italic → handwriting). Generic-heavy signatures show this best.
pub fn longest<'a>(left: &'a str, right: &'a str) -> &'a str {
    if left.len() >= right.len() { left } else { right }
}

/// Loop labels share the `label` capture with lifetimes — Radon as well.
pub fn labeled_loops() {
    'outer: for i in 0..5 {
        'inner: for j in 0..5 {
            if i * j > 6 {
                break 'outer;
            }
            if j == 2 {
                continue 'inner;
            }
        }
    }
}

/// The errors below produce LSP diagnostics in Krypton (bold+italic →
/// mechanical sans). Note that the theme's undercurl is dropped on patched
/// scopes, so the font is the signal.
pub fn diagnostics_demo() {
    let unused_variable = 42; // warning: unused
    let _x: u32 = "not a number"; // error: type mismatch
    undefined_function(); // error: cannot find function
}

fn main() {
    regular_code_is_neon();
    println!("{}", longest("hello", "hi"));
    labeled_loops();
    diagnostics_demo();
}
