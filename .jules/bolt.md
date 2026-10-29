# Bolt's Journal

## 2026-02-18 - Pre-compiling RegExp for Live Text Processing
**Learning:** Instantiating `RegExp` instances inside text-processing functions called on every keystroke (`onChanged`) incurs repeated parsing and object allocation overhead.
**Action:** Use static pre-compiled `RegExp` objects for constant patterns in live text-editing utilities.
