## 2026-10-29 - Password Visibility Toggle Accessibility
**Learning:** Icon-only buttons used for toggling sensitive field visibility (e.g., password field eye icons) lack accessible names for screen readers and helpful text on hover/long-press unless explicitly provided with dynamic `tooltip` attributes.
**Action:** Always provide dynamic `tooltip` strings (e.g. `_obscurePassword ? 'Show password' : 'Hide password'`) on `IconButton` toggle widgets.
