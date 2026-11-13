## 2026-10-30 - Top-Level AppBar Actions Tooltips
**Learning:** Icon-only buttons in primary AppBar actions (such as settings, navigation toggles, or screen utilities) lack accessible screen reader labels and hover tooltips unless an explicit `tooltip` property is specified on Flutter's `IconButton`.
**Action:** Always provide concise, descriptive `tooltip` labels on all `IconButton` widgets in scaffold app bars and headers across the application.
