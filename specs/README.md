# 📚 Daily Savings Tracker — GitHub Standard Specification Kit (Spec-Kit)

Welcome to the official **Specification Kit (Spec-Kit)** for the **Daily Savings Tracker** project (Web & Flutter Mobile App).

This repository follows standard GitHub architectural documentation practices, providing complete technical specifications, database schemas, state management protocols, and mobile app design systems.

---

## 📂 Spec-Kit Table of Contents

| Document Spec | Category | Description |
| :--- | :--- | :--- |
| 📖 [01-architecture-spec.md](./01-architecture-spec.md) | Architecture | High-level system design, data flow, offline-first sync protocol & security models |
| 🗄️ [02-database-schema-spec.md](./02-database-schema-spec.md) | Database | Supabase PostgreSQL tables, RLS security policies, Indexes & Hive local storage schemas |
| 📱 [03-flutter-app-spec.md](./03-flutter-app-spec.md) | Mobile Spec | Complete Flutter 3 (Dart) architecture, Riverpod providers, packages & project structure |
| 🎨 [04-ui-ux-design-spec.md](./04-ui-ux-design-spec.md) | Design System | Dark Glassmorphism tokens, Collapsible Form interactions & Touch-swipe mechanics |

---

## 🚀 Key System Parameters

> [!IMPORTANT]
> - **Default Daily Target Pace:** `150.000 VNĐ / day`
> - **Default Income Categories:** 🚗 `Grab / Chạy xe` (Default active), 💼 `Lương cố định`, 🏪 `Thưởng`, 💰 `Khác`
> - **Target Wishlist Goals:** 🏠 `Xây nhà / Mua nhà` (500M), 🏞️ `Mua đất` (200M), 🛡️ `Quỹ dự phòng khẩn cấp` (10M)
> - **Milestone Badges:** 8 Achievement Tiers (`1M`, `3M`, `5M`, `10M`, `50M`, `100M`, `500M`, `1B`)

---

## 🛠️ Repository & Feature Branching Protocol

> [!NOTE]
> All new features, documentation specs, and code refactorings **MUST** be developed on dedicated feature branches (e.g. `feature/flutter-mobile-app-spec`) before merging into `main`.
