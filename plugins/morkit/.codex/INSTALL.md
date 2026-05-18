# Installing morkit for Codex CLI

Enable morkit skills + working agreements trong Codex qua native skill discovery + AGENTS.md.

## Prerequisites

- [Codex CLI](https://developers.openai.com/codex/) ≥ 0.120.0 (`codex --version` để kiểm tra)
- Git

## Installation (quick — recommended)

```bash
git clone https://github.com/mor-duongmh/claude-plugins.git ~/.codex/morkit-source
bash ~/.codex/morkit-source/plugins/morkit/scripts/install-codex.sh
```

`install-codex.sh` symlink skills + AGENTS.md, hỏi (interactive) có bật hooks hay không. Re-runnable an toàn.

Flags: `--yes` (accept defaults, hooks OFF), `--with-hooks` (force enable hooks), `--uninstall` (remove symlinks).

Sau đó verify:
```bash
bash ~/.codex/morkit-source/plugins/morkit/scripts/doctor-codex.sh
```

Restart Codex (quit + relaunch) để discover skills + AGENTS.md.

## Installation (manual — if you prefer)

1. **Clone repo:**
   ```bash
   git clone https://github.com/mor-duongmh/claude-plugins.git ~/.codex/morkit-source
   ```

2. **Symlink skills (bắt buộc):**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/morkit-source/plugins/morkit/skills ~/.agents/skills/morkit
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\morkit" "$env:USERPROFILE\.codex\morkit-source\plugins\morkit\skills"
   ```

3. **Symlink AGENTS.md (khuyến nghị):**
   Để Codex auto-load working agreements + slash-command bridge:
   ```bash
   ln -s ~/.codex/morkit-source/plugins/morkit/AGENTS.md ~/.codex/AGENTS.md
   ```

   Nếu đã có `~/.codex/AGENTS.md`, append nội dung morkit's AGENTS.md vào cuối.

4. **(Optional) Enable hooks:**
   Morkit's `SessionStart` + `PreToolUse` hooks **không auto-load** trong Codex 0.120.0. Để bật thủ công:

   ```bash
   codex features enable codex_hooks
   ```

   Sau đó tạo `~/.codex/hooks.json`:
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "matcher": "startup|resume|clear",
           "hooks": [{
             "type": "command",
             "command": "bash ~/.codex/morkit-source/plugins/morkit/hooks/session-start.sh"
           }]
         }
       ]
     }
   }
   ```

   **Lưu ý**: `PreToolUse` matcher `Skill` của morkit không có equivalent trong Codex (Codex không có Skill tool). Nếu cần checklist gate, đổi matcher sang `apply_patch|Edit|Write` hoặc đợi `plugin_hooks` feature stable.

5. **Restart Codex** (quit + relaunch CLI) để discover skills + AGENTS.md.

## Verify

```bash
bash ~/.codex/morkit-source/plugins/morkit/scripts/doctor-codex.sh
```

`doctor-codex.sh` check: codex CLI version, skill symlink + count ≥ 20, AGENTS.md, hooks state, deep-review prereqs. Exit 0 = healthy, 1 = có FAIL.

Hoặc check thủ công:
```bash
ls -la ~/.agents/skills/morkit
ls -la ~/.codex/AGENTS.md
codex features list | grep codex_hooks
```

Trong Codex CLI:
```
> Liệt kê morkit skills bạn thấy
```
Phải trả về ≥ 25 skills (archive, brainstorming, propose, deep-review, ...).

## Updating

```bash
cd ~/.codex/morkit-source && git pull
```

Skills + AGENTS.md update tức thì qua symlink.

## Uninstalling

```bash
bash ~/.codex/morkit-source/plugins/morkit/scripts/install-codex.sh --uninstall
```

Script chỉ remove các symlink thật sự trỏ vào morkit checkout — file thủ công người dùng tự thêm sẽ được giữ lại. Hooks.json + feature flag cần xoá tay:
```bash
rm ~/.codex/hooks.json          # nếu đã wire hooks
codex features disable codex_hooks
```

Optional: `rm -rf ~/.codex/morkit-source`.

## Deep-review (5-specialist parallel)

Trong Claude Code, `/morkit:deep-review` dispatch parallel subagents qua `Agent` tool. Codex không có subagent native → dùng wrapper bash:

```bash
# Default = git diff HEAD
~/.codex/morkit-source/plugins/morkit/scripts/codex-deep-review.sh

# Other targets
codex-deep-review.sh --diff main     # vs branch
codex-deep-review.sh '#123'          # PR #123 (needs gh)
codex-deep-review.sh --json          # JSON output
codex-deep-review.sh --agents=security-auditor,test-coverage-auditor  # subset
```

**Cách hoạt động**: spawn N `codex exec` processes song song (default: 7 specialists từ `agents/*.md`), mỗi process review cùng một diff trong sandbox read-only, output YAML findings; Python aggregator merge + dedupe + rank → render Markdown.

**Optional alias** để gọi gọn:

```bash
ln -s ~/.codex/morkit-source/plugins/morkit/scripts/codex-deep-review.sh ~/.local/bin/morkit-deep-review
```

Sau đó chỉ cần `morkit-deep-review --diff` từ bất cứ git repo nào.

**Requirements**: `codex ≥ 0.120.0`, `git`, `python3`. `gh` chỉ cần cho PR target.

**Note**: morkit's code-review-graph MCP (Claude Code only) không có equivalent trong Codex. Specialists fall back sang Read/Grep → tốc độ chậm hơn, ít context-aware hơn, nhưng vẫn catch được Security/Convention/Pattern findings cơ bản.

## Differences from Claude Code install

| Aspect | Claude Code | Codex |
|---|---|---|
| Install method | `/plugin install morkit@mor-duongmh` | Clone + symlink (thủ công) |
| Slash commands `/morkit:X` | Native discovery từ `commands/` | Bridge qua AGENTS.md (model đọc `commands/X.md`) |
| Skills auto-invoke | Native via Skill tool | Native via skill discovery |
| Hooks (`SessionStart`, `PreToolUse`) | Auto-loaded từ plugin | Thủ công wire vào `~/.codex/hooks.json` |
| Subagents (deep-review specialists) | Native subagent dispatch | `codex exec` parallel wrapper (`scripts/codex-deep-review.sh`) |
