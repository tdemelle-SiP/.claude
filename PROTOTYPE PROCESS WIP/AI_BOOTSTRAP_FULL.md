# AI Bootstrap – Full Alignment Pack

*Paste this file at the start of every session.*

---

## 0 – Absolute Prohibitions

| Pattern                                               | Why forbidden                                                                             |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Speculative statements**                            | Generates false assumptions that derail tasks. Ask a concise clarifying question instead. |
| **Defensive try/catch that suppresses errors**        | Masks bugs. Always log + re‑throw or surface via `SiP_AJAX_Response::error()`.            |
| **Backward‑compat branches**                          | Adds complexity; we version‑bump instead.                                                 |
| **Globals**                                           | Risk of collision; use `SiPWidget.UI.*` only.                                             |
| **Hidden logging of PII / full JSON blobs**           | Security & performance issue; log counts or IDs only.                                     |
| **Placeholders / TODO comments**                      | Produce finished code; no stubs.                                                          |
| **Words: *if*, *ensure*, *check*, *verify* in prose** | User’s preference for direct language.                                                    |
| **Unescaped output in PHP**                           | XSS risk. Always `esc_html`, `wp_kses_post`, etc.                                         |

---

## 1 – Canonical Code Examples

### 1.1 Allowed Error Surfacing (JS)

```js
try {
    await doThing();
} catch (e) {
    console.error('Widget failed:', e);
    throw e; // propagate
}
```

### 1.2 Forbidden Defensive Block (JS)

```js
try {
    risky();
} catch (e) {
    // silently ignore – BAD
}
```

### 1.3 Correct PHP AJAX Error

```php
SiP_AJAX_Response::error(
    'sip-printify-manager',
    'product_action',
    'generate_mockup',
    'Printify API timeout'
);
```

### 1.4 Namespaced UI Call

```js
SiPWidget.UI.showWidget();
```

---

## 2 – Process Cheat‑Sheet

1. **PLAN** – Goal, Files, Snapshots path.
2. **WORK** – Small steps, tabs indent, async/await, no globals.
3. **REVIEW** – Lint, tests, docs, digest line.

### Review Blockers Checklist

* [ ] No forbidden words in prose.
* [ ] No defensive or legacy branches.
* [ ] All PHP output escaped.
* [ ] UI calls namespaced only.
* [ ] Digest line added.

---

## 3 – Quick Lint Rules (excerpt)

* `no-var`, `prefer-const`, `no-undef`.
* `phpcs --standard=WordPress-Core --severity=1`.
* Tabs indentation; max line length 120.

---

## 4 – Session Startup Prompt (copy‑paste)

> **MODE:** Follow AI\_BOOTSTRAP\_FULL ‑ no speculation, no hidden errors, no globals. Current task: \_\_\_

---

6. For each file or feature mentioned, open its deep guide from CODE_GUIDE_FULL.md and apply those rules.


*End of full alignment pack – ≈1.8 k words.*
