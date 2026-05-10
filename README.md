# Mor Claude Plugins

> Bộ plugin Claude Code của Mor giúp bạn lên plan, review, code và check code chuẩn hơn.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 1. Cài đặt (3 dòng)

Yêu cầu: [Claude Code](https://docs.anthropic.com/claude/docs/claude-code) và Node.js ≥ 18.

```
/plugin add marketplace github:mor-duongmh/claude-plugins
/plugin install mor-kit@mor-duongmh
/plugin install superpowers@mor-duongmh
```

Cài xong là dùng được luôn — không cần setup gì thêm trong từng project.

---

## 2. Plugin trong marketplace này

| Plugin | Để làm gì | Khi nào dùng |
|---|---|---|
| **[`mor-kit`](./plugins/mor-kit)** | Tạo proposal/design/tasks và checklist review | Mỗi khi bắt đầu một feature/bug/refactor mới |
| **[`superpowers`](./plugins/superpowers)** | Brainstorm, viết plan, thực thi plan, debug, TDD | Suy nghĩ trước khi code và khi triển khai |
| **[`deep-review`](./plugins/deep-review)** | Code review tự động bằng 5 chuyên gia AI song song (risk, security, pattern, tests, convention) | Sau khi code xong, trước khi merge PR |
| **[`docs-hero`](./plugins/docs-hero)** | Sinh tài liệu BrSE: SRS + API + DB cho dự án ITO Japan offshore | Khi cần generate hoặc update doc |

> `superpowers@mor-duongmh` là bản fork đã chỉnh sửa của [obra/superpowers](https://github.com/obra/superpowers). Đừng cài đồng thời với upstream.

---

## 3. Quy trình điển hình một feature

```
  1. /superpowers:brainstorm     → Suy nghĩ, đặt câu hỏi, không code
                ↓
  2. /mor-kit:propose            → Sinh proposal + design + tasks + checklist
                ↓
  3. 🚦 Mở review-checklist.md, tick từng mục, đặt "Overall Decision: OK"
                ↓
  4. /superpowers:execute-plan   → Chạy plan, code theo TDD
                ↓
  5. /deep-review --diff         → Review code trước PR
                ↓
  6. /mor-kit:archive            → Đóng change sau khi merge
```

Bước 3 là **chốt chặn của con người**. Nếu chưa "OK", plugin sẽ chặn `/superpowers:execute-plan` lại — không cho code khi plan chưa được duyệt.

---

## 4. Tất cả slash command

### `mor-kit` — quản lý change
| Command | Làm gì |
|---|---|
| `/mor-kit:propose [mô tả]` | Sinh đầy đủ proposal + design + tasks + review-checklist |
| `/mor-kit:review [tên]` | Tạo lại review-checklist từ Google Doc canonical |
| `/mor-kit:archive [tên]` | Đóng change sau khi merge |

### `superpowers` — suy nghĩ và thực thi
| Command | Làm gì |
|---|---|
| `/superpowers:brainstorm` | Mode tư duy: hỏi, gợi ý, không code |
| `/superpowers:write-plan` | Viết plan từ ý tưởng |
| `/superpowers:execute-plan` | Thực thi plan từng bước (bị review-gate chặn) |

### `deep-review` — review code
| Command | Làm gì |
|---|---|
| `/deep-review [target]` | Review trên git diff hoặc PR (5 subagent song song) |
| `/deep-review-doctor` | Kiểm tra trạng thái cài đặt |

### `docs-hero` — sinh tài liệu
| Command | Làm gì |
|---|---|
| `/docs-hero:setup` | Bootstrap Python venv (~30-60s, 1 lần) |
| `/docs-hero:init` | Sinh fresh SRS + API + DB từ ProjectModel JSON |
| `/docs-hero:update` | Apply change/plan vào doc, giữ manual edits |
| `/docs-hero:sync` | Scan codebase, đề xuất update API+DB doc |
| `/docs-hero:apply-sync` | Apply đề xuất từ sync (đã được tick) |
| `/docs-hero:doctor` | Kiểm tra tình trạng cài đặt |

---

## 5. Plan review gate (chốt chặn human-in-the-loop)

Sau khi `/mor-kit:propose`, plugin sinh `mor-kit/changes/<tên>/review-checklist.md` từ [Google Doc canonical của Mor](https://docs.google.com/document/d/184wY2N2WOUExmZrClvHCfcRCnSQsJYvav6gc6JwL6xc).

Plugin tự đoán variant phù hợp (BE/FE × Feature/BugFix/Refactor) dựa trên proposal + tasks. Override khi cần:

```
/mor-kit:review --variant FE-BugFix     # BE-Feature, BE-BugFix, BE-Refactor, FE-*
/mor-kit:review --refresh                # Lấy lại từ Google Doc, bỏ qua cache 24h
```

Bạn mở file, tick từng mục, sau đó sửa dòng cuối:

```diff
- Overall Decision: PENDING
+ Overall Decision: OK
```

→ Plugin mới cho phép `/superpowers:execute-plan` chạy.

**Có 2 lớp bảo vệ song song** (defense-in-depth):
1. **PreToolUse hook** — Claude Code chặn tool call ngay từ harness
2. **Skill content** — mỗi skill tự kiểm tra ở Step 0 trước khi làm việc

Nếu một lớp bị bypass, lớp kia vẫn chặn.

---

## 6. Companion tools (Context7 + RTK)

Hai tool nâng chất lượng research và giảm token. Plugin xử lý lịch sự — không cài silent.

| Tool | Vai trò | Cách cài |
|---|---|---|
| **[Context7](https://github.com/upstash/context7)** | Trả docs/API version-specific cho library, agent không cần đoán | **Lazy** — plugin tự `npx -y ctx7` khi cần. MCP optional. |
| **[RTK](https://github.com/rtk-ai/rtk)** | Nén output bash, giảm 60-90% token | **Hỏi 1 lần** session đầu — bạn chọn `Yes`/`Skip`/`Don't ask again`. |

> 🎯 Context7 đã active trong 6 superpowers skill + 3 mor-kit skill — agent sẽ tự gọi Context7 thay vì đoán API.

Cài RTK thủ công:

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
rtk init -g
```

Cài Context7 dạng MCP (full features):

```bash
npx -y ctx7 setup
```

---

## 7. License

[MIT](LICENSE) © Mor.
