# Task: {{slug}}

## 🎯 PLAN

* **Goal:** *one sentence*
* **Files Touched:**
* **Snapshot Folder:** `/snapshots/{{slug}}/`

## 🔨 WORK

```bash
# use during dev
npm run snapshot            # dump runtime data
npm test                    # run unit tests
```

## ✅ REVIEW CHECKLIST

* [ ] Lint passes (`npm run lint`)
* [ ] Unit tests green (`npm test`)
* [ ] Updated docs / comments
* [ ] Added `STATE_DIGEST` line below

### 📜 DIGEST LINE

Paste here before merge:

```json
{"id":"{{slug}}","summary":"…","choices":"UI=v2","sha":"abc123"}
```
