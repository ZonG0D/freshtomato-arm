# No-Regressions Cleanup Checklist (FreshTomato-ARM)

**Purpose**
Keep firmware builds stable while incrementally reducing “spaghetti.”
This checklist must be completed **before** any refactor work begins.

---

## 0) Define scope and non-goals (hard rules)

**Do not touch (read-only):**

* Vendor SDK drops:
  * `release/src-rt-*`
  * Broadcom SDK code
  * Toolchain internals
* Generated files and binary blobs

**Allowed scope:**

* Top-level scripts
* Build wrappers
* Packaging logic
* Project-owned config logic
* Documentation

**Explicit non-goals:**

* No semantic Makefile changes
  (no target reordering, variable renames, or logic rewrites)
* No build system “modernization”
* No dead-code deletion inside SDK trees

---

## 1) Establish golden builds (regression oracle)

Select **one representative target per SDK line**:

* RT-6.x
* RT-7.x main
* RT-7.14.x

For each target, capture and store:

* Full build log
* Image hash (`sha256sum`)
* Image size
* `strings` output
  (or a curated subset of known-stable strings)

**Storage layout (example):**

```
tools/artifacts/golden-builds/
└── 2026-01-XX/
    ├── sdk6-n18u/
    ├── sdk7-ac3200/
    └── sdk714-ac5300/
```

These artifacts are the **single source of truth** for regressions.

---

## 2) Freeze the working tree

Before *any* changes:

```bash
git clean -fdxq
git reset --hard
```

* Record the exact commit hash used for golden builds
* Do not rebase or amend this commit during cleanup work

---

## 3) Establish a repeatable build entrypoint

Create a **wrapper script** (example: `tools/scripts/build-wrapper.sh`) that:

* Accepts target names as arguments
* Normalizes environment variables
* Invokes existing `make` targets verbatim
* Produces deterministic, log-friendly output

**Constraints:**

* No new logic
* No conditional behavior changes
* Wrapper must be a thin layer only

All future builds (including regression checks) must go through this wrapper.

---

## 4) Inventory high-value glue areas

Identify **safe, high-ROI extraction candidates**:

### A) Duplicated Makefile logic

* Repeated flag blocks
* Target lists
* Common config snippets

### B) Duplicated shell logic

* Environment setup blocks
* Repeated pre/post build steps

### C) Conditional tables

* Router model → flash size
* Feature flags
* SMP / non-SMP mappings

These are candidates for **mechanical extraction only**.

---

## 5) Perform mechanical, low-risk refactors only

Allowed refactors:

* Extract duplicated Makefile blocks into `tools/build/*.mk`
* Extract repeated shell logic into `tools/scripts/*.sh`
* Replace `if/elif` model conditionals with data table lookups
* Add comments explaining *why* hacks exist

**Not allowed:**

* Logic simplification
* Behavior changes
* Variable renaming
* Reordering Makefile targets

If a refactor *feels* clever, it is out of scope.

---

## 6) Run diff-based regression checks after every change

After **each** refactor commit:

1. Rebuild all golden targets using the wrapper
2. Compare against golden artifacts:

   * Image hash
   * Image size
   * `strings` output (or curated subset)

**If any difference is detected:**

* Stop immediately
* Investigate
* Revert or fix before proceeding

No cumulative drift is allowed.

---

## 7) Keep changes small and reviewable

* One refactor per commit
* One concern per commit
* No “drive-by” cleanups

**Commit message must include:**

* What was extracted
* Explicit statement: *“No behavior change expected”*

---

## 8) Document the safe / unsafe map

Maintain a short, authoritative document that lists:

* Safe-to-touch zones
* Read-only zones
* Rationale for each

This prevents future refactors from crossing dangerous boundaries.

---

## 9) Tooling rules (safe defaults)

* Formatting:

  * `shfmt -i 2 -ci` **only** outside vendor SDK
* Linting:

  * `shellcheck` in warning-only mode for owned scripts
* Avoid:

  * Mass formatting
  * Renames
  * Automated “cleanup” tools

If a tool requires re-validating all golden builds, it is not safe by default.

---

## Ready to proceed

Once this checklist is complete and enforced, the **next safe step** is:

➡️ **Model capability table extraction**
(highest ROI, minimal behavior risk, easy to regression-check)
