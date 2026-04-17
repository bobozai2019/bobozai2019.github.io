# Game AI Portfolio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the static personal site so it strongly presents bobozai2019 as a game AI programmer and highlights `godot-project-analysis`.

**Architecture:** Keep the site as a static single-page portfolio. `index.html` owns content and structure, `styles.css` owns the dark technical visual system, and `scripts/verify-site.ps1` provides lightweight regression checks for required content.

**Tech Stack:** Static HTML, CSS, PowerShell verification script, Git.

---

### Task 1: Add Verification

**Files:**
- Create: `scripts/verify-site.ps1`

- [x] **Step 1: Write failing verification**

Add checks for the new project URL, game AI positioning, `Godot Project Analysis`, `Layer 0-4`, and dark technical CSS markers.

- [ ] **Step 2: Run verification to confirm it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\scripts\verify-site.ps1`

Expected: FAIL for missing new project and visual markers.

### Task 2: Update Website Content

**Files:**
- Modify: `index.html`

- [ ] **Step 1: Update hero and about sections**

Replace generic AI game wording with game AI programmer positioning focused on Godot tooling, static analysis, architecture recovery, and prototypes.

- [ ] **Step 2: Update project cards**

Add `Godot Project Analysis` as the first project, keep `godot_2d_test_game`, and add a workflow/project pipeline card.

### Task 3: Update Visual System

**Files:**
- Modify: `styles.css`

- [ ] **Step 1: Implement dark technical lab styling**

Replace the plain light style with a dark base, visible section hierarchy, stronger project cards, chips, stats, and hero signal panel.

- [ ] **Step 2: Check responsive behavior**

Ensure the layout collapses cleanly on mobile and no text relies on viewport-scaled font sizes.

### Task 4: Verify and Commit

**Files:**
- Modify: `.gitignore`
- Verify: `scripts/verify-site.ps1`

- [ ] **Step 1: Run verification**

Run: `powershell -ExecutionPolicy Bypass -File .\scripts\verify-site.ps1`

Expected: all checks PASS.

- [ ] **Step 2: Review git diff**

Run: `git diff -- index.html styles.css .gitignore scripts/verify-site.ps1 docs/superpowers/specs/2026-04-18-game-ai-portfolio-design.md docs/superpowers/plans/2026-04-18-game-ai-portfolio.md`

- [ ] **Step 3: Commit**

Run: `git add .gitignore index.html styles.css scripts/verify-site.ps1 docs/superpowers/specs/2026-04-18-game-ai-portfolio-design.md docs/superpowers/plans/2026-04-18-game-ai-portfolio.md && git commit -m "Update game AI portfolio site"`
