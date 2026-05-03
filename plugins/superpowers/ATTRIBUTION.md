# Attribution

This plugin is a **vendored fork** of [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent (jesse@fsck.com), licensed under the MIT License.

## Original work

- **Project:** Superpowers
- **Author:** Jesse Vincent
- **License:** MIT (see [LICENSE](./LICENSE))
- **Upstream:** https://github.com/obra/superpowers
- **Sponsor upstream:** https://github.com/sponsors/obra

## What this fork contains

The contents of `skills/`, `commands/`, and `agents/` are mirrored verbatim from a pinned upstream release (see `.vendor-manifest.json` for the exact version and SHA256). They are NOT modified by Mor.

Mor's customizations, when they exist, live separately in `overlay/` and are layered on top of the vendored content at sync time.

## Why we vendor under the name `superpowers`

Upstream skills contain 34 internal cross-references like `superpowers:executing-plans`. Plugin name must match for these to resolve. Renaming the plugin would require rewriting these references, breaking "vendor as-is" and increasing sync maintenance.

The cost: users cannot install both `superpowers@obra` and `superpowers@mor-duongmh` simultaneously. Mor's vendored fork is a drop-in replacement, not a coexisting alternative.

## Sync policy

`scripts/sync-superpowers.sh` downloads a specific upstream tarball release, verifies its SHA256, and replaces the vendored folders. The script never silently overwrites — it requires user confirmation.
