# superpowers (vendored)

Mor's vendored fork of [obra/superpowers](https://github.com/obra/superpowers). Skills, commands, and agents under this plugin are mirrored verbatim from upstream — see [ATTRIBUTION.md](./ATTRIBUTION.md) for credit and licensing.

## Install

```
/plugin add marketplace github:mor-duongmh/claude-plugins
/plugin install superpowers@mor-duongmh
```

This plugin replaces upstream `superpowers@obra` (same plugin name → cannot coexist). If you have upstream installed, `/plugin uninstall superpowers@obra` first.

## Sync upstream

The vendored layer is refreshed by:

```bash
./scripts/sync-superpowers.sh           # use version pinned in .vendor-manifest.json
./scripts/sync-superpowers.sh 5.1.0     # bump to a specific upstream tag
./scripts/sync-superpowers.sh --dry-run 5.1.0
```

The script downloads the upstream tarball, verifies SHA256, wipes and re-copies vendored content, then applies any `overlay/` customizations.

## Customize

Place a file at `overlay/<same-relative-path>/...` to replace the vendored version after sync. See [overlay/README.md](./overlay/README.md).
