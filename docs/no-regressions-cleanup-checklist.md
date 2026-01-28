# No-regressions cleanup checklist

Purpose: keep firmware builds stable while you incrementally reduce “spaghetti.” This is the **first** step before any refactor work.

## 0) Define scope and non-goals
- **Do not touch vendor SDK drops** (e.g., `release/src-rt-*` and Broadcom SDK code). Treat them as read-only.  
- **Only touch project glue** (top-level scripts, build wrappers, packaging, and config logic).  
- **Avoid semantic Makefile changes** (no target reordering, variable renames, or logic rewrites).  

## 1) Establish the golden builds (regression oracle)
- Identify **one target per SDK line** to build (e.g., RT-6.x, RT-7.x main, RT-7.14.x).  
- For each target, capture:
  - Build logs
  - Image file hash (e.g., `sha256sum`)
  - Image size
  - `strings` output (or a summarized diff of key strings)
- Store these artifacts in a dedicated folder (e.g., `tools/artifacts/golden-builds/DATE/`).  

## 2) Freeze the working tree before changes
- Clean workspace: `git clean -fdxq`  
- Reset to a known commit: `git reset --hard`  
- Record the commit hash used for the golden builds.  

## 3) Establish a repeatable build entrypoint
- Prefer a wrapper script (e.g., `tools/scripts/build-wrapper.sh`) that accepts target names and normalizes env setup.  
- This wrapper should **only call existing Make targets**—no logic changes.  
- Ensure wrapper output is deterministic and log-friendly.  

## 4) Inventory high-value glue areas
- Identify duplicated logic that’s safe to **extract into includes**:
  - repeated Makefile snippets (flags, target lists, config blocks)
  - duplicated shell blocks in scripts
- Identify conditional “tables” (model configs, flash sizes, feature flags) that can be moved to **data tables** without changing logic.

## 5) Make mechanical, low-risk refactors only
- **Extract code without changing behavior**:
  - move duplicated Makefile blocks into `tools/build/*.mk` and `include` them
  - move repeated shell blocks into `tools/scripts/*.sh`
  - replace `if/elif` model conditionals with a data table lookup
- Add comments for “why this hack exists” rather than changing it.  

## 6) Run diff-based regression checks after each change
- Rebuild the golden targets with the wrapper.
- Compare:
  - image hash
  - image size
  - `strings` output (or small curated string set)
- If any changes occur, stop and investigate before continuing.  

## 7) Keep changes small and reviewable
- One refactor per commit (e.g., “extract target map to include”).  
- Avoid multi-purpose commits.  
- Add a short note in the commit message explaining expected **no behavior change**.  

## 8) Document the safe/unsafe map
- Track: “safe to touch” vs. “do not touch” zones in a single doc.  
- Keep it brief and authoritative so future refactors don’t stray.  

## 9) Tooling tips (safe defaults)
- Formatting: `shfmt -i 2 -ci` **only outside vendor SDK**.  
- Lint: `shellcheck` in warning mode for scripts you own.  
- Avoid mass formatting/renaming unless you can re-validate all golden builds.  

---

### Ready to proceed
Once the checklist is complete, the next safe step is the **model capability table** extraction (highest ROI, minimal behavior risk).
