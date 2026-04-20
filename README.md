# Mor Claude Plugins

> Bộ plugin Claude Code của team Mor — phát triển theo hướng spec-driven với TDD, tích hợp mượt mà với Superpowers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange.svg)](https://docs.anthropic.com/claude/docs/claude-code)

---

## Mục lục

- [Giới thiệu](#giới-thiệu)
- [Danh sách plugin](#danh-sách-plugin)
- [Bắt đầu nhanh](#bắt-đầu-nhanh)
- [Slash commands](#slash-commands)
- [Workflow](#workflow)
- [Bên trong schema `superpowers-driven`](#bên-trong-schema-superpowers-driven)
- [Xử lý sự cố](#xử-lý-sự-cố)
- [Roadmap](#roadmap)
- [License](#license)

---

## Giới thiệu

Marketplace này chứa một plugin duy nhất — **`spec`** — bao gồm:

1. **4 spec skills** — `propose`, `apply`, `explore`, `archive` để quản lý thay đổi theo hướng spec-driven.
2. **Schema `superpowers-driven`** — các artifact sinh ra cắm thẳng vào Superpowers (`writing-plans`, `executing-plans`, `subagent-driven-development`) mà không cần chuyển đổi trung gian.
3. **Slash commands có namespace** dưới `/spec:` để không xung đột với các commands mặc định.
4. **Không cần cài đặt ngoài** — CLI được gọi qua `npx`; dev không phải chạy `npm install -g` trước.
5. **Tự gợi ý cài đặt** — khi mở project có `openspec/` nhưng chưa có schema, plugin sẽ lịch sự hỏi có muốn chạy `/spec:setup` không. Không có file nào bị copy nếu dev chưa xác nhận.

---

## Danh sách plugin

| Plugin | Version | Mục đích |
|--------|---------|----------|
| [`spec`](./plugins/spec) | `0.3.0` | Spec skills + schema `superpowers-driven`. Artifacts sẵn sàng cho TDD và dùng được ngay với Superpowers. |

> **Roadmap:** Plugin thứ hai `mor-superpowers` — fork các Superpowers skills, tùy chỉnh cho coding standards và review rules của Mor — đang nằm trong kế hoạch. Xem [Roadmap](#roadmap).

---

## Bắt đầu nhanh

### Yêu cầu

- [Claude Code](https://docs.anthropic.com/claude/docs/claude-code) đã cài đặt
- Node.js ≥ 18 có trong `PATH` (để `npx` chạy được CLI khi cần)

Không cần `npm install -g` gì cả.

### 1. Thêm marketplace (mỗi máy 1 lần)

Trong Claude Code:

```
/plugin add marketplace github:mor-duongmh/claude-plugins
```

### 2. Cài plugin `spec` (mỗi máy 1 lần)

```
/plugin install spec@mor-duongmh
```

Xong. Khi dev mở một project, plugin sẽ tự nhận diện trạng thái:

- **Project mới (chưa có `openspec/`):** tự chạy `/spec:setup` khi muốn bắt đầu. Skill sẽ hỏi có muốn chạy `openspec init` không, rồi cài schema.
- **Project có `openspec/` nhưng chưa có schema:** plugin tự gợi ý ở đầu session — dev trả lời có/không. Muốn tắt vĩnh viễn thì `touch openspec/.spec-setup-skip`.
- **Project đã setup xong:** im lặng — dùng `/spec:propose` ngay được.

`/spec:setup` **luôn xác nhận path trước khi ghi file** — không bao giờ copy ngầm.

---

## Slash commands

Tất cả commands đều có namespace `/spec:`.

| Command | Tham số | Mục đích |
|---------|---------|----------|
| `/spec:setup` | `[path]` (optional absolute path) | Khởi tạo workflow trong project: chạy `openspec init` nếu cần, cài schema `superpowers-driven`, tùy chọn set làm default |
| `/spec:explore` | — | Chế độ "suy nghĩ": đặt câu hỏi, điều tra, không implement |
| `/spec:propose` | `[description]` (optional) | Tạo change mới gồm proposal + design + tasks TDD-ready |
| `/spec:apply` | `[change-name]` (optional) | Duyệt và thực thi các task còn pending (native runner) |
| `/spec:archive` | `[change-name]` (optional) | Archive change đã xong và sync delta specs |

---

## Workflow

```
┌──────────────────────────────────────────────────────────────┐
│  /spec:explore          (tùy chọn — suy nghĩ trước khi làm)  │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  /spec:propose                                                │
│    Sinh ra:                                                   │
│      • proposal.md   (what & why)                             │
│      • design.md     (how + Tech Stack)                       │
│      • tasks.md      (Superpowers header + TDD steps)         │
└──────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
  ┌──────────────┐   ┌──────────────────┐   ┌────────────────────┐
  │ /spec:apply  │   │ /superpowers:    │   │ /superpowers:      │
  │ (native)     │   │ executing-plans  │   │ subagent-driven-   │
  │              │   │ (TDD discipline) │   │ development        │
  └──────────────┘   └──────────────────┘   │ (parallel agents)  │
                                             └────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  /spec:archive      (sau khi implement + merge xong)          │
└──────────────────────────────────────────────────────────────┘
```

Vì `tasks.md` đã có sẵn Superpowers header (Goal, Architecture, Tech Stack) và các bước TDD với đường dẫn file rõ ràng, dev có thể đưa thẳng cho `/superpowers:executing-plans` **mà không cần viết lại gì**.

---

## Bên trong schema `superpowers-driven`

Fork từ schema mặc định của upstream, tùy chỉnh ở 3 chỗ:

### 1. `design.md` bổ sung mục `## Tech Stack`

Để header của `tasks.md` phía sau có tech stack thật mà tham chiếu, không phải để AI đoán.

### 2. Template `tasks.md` bắt đầu bằng Superpowers header

```markdown
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** <một câu>
**Architecture:** <2-3 câu>
**Tech Stack:** <lấy từ design.md>
```

### 3. Mỗi task group theo cấu trúc TDD

```markdown
## 1. <tên nhóm>

**Files:**
- Create: `path/to/new/file`
- Modify: `path/to/existing/file`
- Test:   `path/to/test/file`

- [ ] 1.1 Viết failing test cho <hành vi>
- [ ] 1.2 Chạy test — xác nhận fail
- [ ] 1.3 Implement <code tối thiểu>
- [ ] 1.4 Chạy tests — xác nhận pass
- [ ] 1.5 Commit
```

Các instructions trong `schema.yaml` ràng buộc quy tắc này để artifact AI sinh ra luôn nhất quán qua mọi change.

---

## Xử lý sự cố

### Prompt tự gợi ý cứ hiện lại ở project tôi không muốn setup

Tạo file trống để tắt:

```bash
touch openspec/.spec-setup-skip
```

### `schema validate superpowers-driven` báo lỗi

Có thể schema bị copy thiếu. Xóa `openspec/schemas/superpowers-driven/` rồi chạy lại `/spec:setup`.

### Commands hiện là `/mor-openspec:*` thay vì `/spec:*`

Đang dùng bản cache cũ của plugin. Update và cài lại:

```
/plugin update spec@mor-duongmh
```

### Xung đột với `/opsx:*`

Không xung đột — `/spec:*` và `/opsx:*` là hai namespace độc lập, song song được. Plugin `spec` wrap cùng skills backend nên dev có thể dùng cái nào cũng được.

### `npx` chạy chậm lần đầu

Lần đầu `/spec:setup` sẽ download `@fission-ai/openspec` vào npm cache cục bộ. Các lần sau chạy tức thì.

---

## Roadmap

- [ ] Plugin `mor-superpowers` — fork Superpowers skills, tùy chỉnh theo coding standards, review rules, commit conventions của Mor.
- [ ] CI validation mỗi lần push (`schema validate superpowers-driven`).
- [ ] Telemetry tùy chọn để theo dõi độ phủ của schema trong các project của Mor.

---

## License

[MIT](LICENSE) © Mor
