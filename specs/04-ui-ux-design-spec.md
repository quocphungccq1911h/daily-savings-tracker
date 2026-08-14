# 🎨 04-UI/UX Design System Specification

## 1. Glassmorphic Color Palette Tokens

The design system enforces a sleek, dark neon glassmorphic palette:

| Token Name | Hex Code / Value | Usage |
| :--- | :--- | :--- |
| `bgApp` | `#0b0f19` | Deep obsidian background |
| `bgCard` | `rgba(15, 23, 42, 0.75)` | Translucent glass container |
| `borderColor` | `rgba(255, 255, 255, 0.08)` | Subtle border separation |
| `emeraldPrimary` | `#10b981` / `#34d399` | Primary action buttons, positive progress |
| `skyBlueAccent` | `#38bdf8` | Secondary badges, chart lines & tab highlights |
| `amberGold` | `#f59e0b` / `#fbbf24` | Streak fire icon, year forecast, milestone badges |
| `purpleCategory` | `#a855f7` | Category "Khác" pill & badge tag |

---

## 2. Typography & Hierarchy System

Powered by Google Fonts (`Inter` or `Plus Jakarta Sans`):

- **Header Title:** `20px`, Bold 800, Color `#ffffff`
- **Section Title:** `14px`, ExtraBold 800, Letter spacing `0.05em`, UpperCase
- **Money Display (Hero):** `28px`, ExtraBold 800, Color `#34d399`
- **Body Text / Notes:** `13px`, Medium 500, Color `#94a3b8`

---

## 3. Collapsible Form Interaction Spec

```text
[Form State: Collapsed]
+---------------------------------------------------------+
| ✍️ Nhập Tiết Kiệm                     [➕ Thêm Khoản Mới ▼] |
+---------------------------------------------------------+

[Form State: Expanded (Animated Cross-Fade)]
+---------------------------------------------------------+
| ✍️ Nhập Tiết Kiệm                              [Thu Gọn ▲] |
| ------------------------------------------------------- |
| Ngày chọn: [ 14/08/2026 📅 ]                             |
| Số tiền:   [ 150000        ] đ                          |
| Quick Chips: [+100k] [+120k] [ +150k ✨ ] [+170k]         |
| Nguồn Thu:   [🚗 Grab] [💼 Lương] [🏪 Thưởng] [💰 Khác]   |
| Ghi chú:   [ Ghi chú thêm...                          ] |
|                                                         |
|                  [  LƯU TIẾT KIỆM  ]                    |
+---------------------------------------------------------+
```

> [!TIP]
> **Auto-Collapse Policy:** Upon successful submission, the form automatically triggers `maxHeight: 0` animation to collapse, preventing thumb touch-collisions while scrolling down the transaction journal.
