---
name: playwright-e2e-testing
description: 生成、补充、修复或回归验证 Playwright 端到端测试，并由主 agent 规划测试项、按用例调度 subagent 录制和编写测试。Use when Codex needs to create E2E tests from feature descriptions, acceptance criteria, manual workflows, bug reports, existing PRDs/specs, screenshots, routes/pages, or when asked for e2e test, regression test, playwright test, 端对端测试, 回归测试, E2E 测试.
---

# Playwright E2E Testing

## Core Rule

Create tests that match the current project, not a remembered project. Discover the repository's Playwright setup, routes, scripts, server behavior, and existing test style before choosing paths, ports, filenames, or commands.

## Good Inputs

Use any of these as the source of truth:

- Feature or workflow description: "用户登录后能看到仪表盘"
- Route/page target: "/settings", "admin users page", "checkout page"
- Acceptance criteria: "保存成功后显示 Success toast"
- Manual reproduction steps for a regression or bug
- Existing PRD/spec/task document
- Existing failing Playwright test or trace
- Screenshot plus expected behavior
- Existing component/page code when the user only names a UI area

Do not require a PRD. Use PRDs only when the user provides one, the task is broad enough to need structured requirements, or the project already keeps relevant specs under docs/task/prd folders.

## Project Discovery

Before writing or changing tests:

1. Find Playwright and package setup:
   - Search for `playwright.config.*`, `package.json`, existing `*.spec.ts` or `*.e2e.ts`.
   - Ignore dependency folders such as `node_modules`, `.next`, `dist`, `build`, and coverage output.
2. Inspect the active Playwright config:
   - `testDir`
   - `use.baseURL`
   - `webServer`
   - projects/devices
   - global setup/teardown only if configured
   - trace/screenshot/video settings
3. Inspect package scripts:
   - Prefer an existing e2e/playwright script.
   - If none exists, use the local package manager command from the project root that owns the config, such as `npx playwright test`.
4. Inspect existing tests:
   - Reuse their folder, naming convention, fixtures, helper functions, and selector style.
   - Put new specs beside related specs unless config or project conventions say otherwise.
5. Determine how the app should run:
   - If Playwright config has `webServer`, rely on it.
   - If it does not, start or reuse the project's documented dev/preview server only when needed.
   - Never hard-code a port; read it from config, scripts, docs, env examples, or current running server evidence.

## Workflow

The main agent owns planning and coordination. Subagents own individual test-case execution.

1. Main agent: translate the input into observable user outcomes.
2. Main agent: discover project setup and existing test conventions.
3. Main agent: split outcomes into test cases.
4. Main agent: run a concurrency gate before dispatch.
5. Subagent: for exactly one test case, explore/record, write or update the Playwright test, and run the narrowest relevant command.
6. Subagent: return the required result packet.
7. Main agent: merge outputs, resolve file conflicts, update the failure ledger, and report final status.

Do not pause for user confirmation by default. Ask only when the test scope is ambiguous enough that a reasonable assumption would create the wrong test, when credentials/secrets are required, or when multiple incompatible workflows are equally likely.

## Main Agent Responsibilities

The main agent must:

- Discover Playwright config, package scripts, test directories, app startup behavior, and existing E2E style.
- Identify all testable outcomes and convert them into separate test cases.
- Assign one test case to one subagent.
- Decide serial vs parallel execution before dispatching subagents.
- Provide each subagent only the context needed for its test case, plus shared project conventions.
- Prevent concurrent writes to the same spec, fixture, helper, app file, or failure ledger.
- Aggregate subagent result packets.
- Create or update the failure ledger from subagent-reported entries.
- Run or request a final aggregate command only when it is safe and useful after subagent work.

The main agent should not personally perform recording or write the Playwright spec for an assigned test case unless subagents are unavailable.

## Subagent Dispatch Contract

Use one subagent per test case. The main agent should include:

- Test case id and title
- Source input or acceptance criterion
- Target route/page/workflow
- Expected user-visible outcome
- Relevant project setup discovered by the main agent
- Existing selector/test style to follow
- Assigned output file or explicit instruction to propose one
- Allowed commands to run
- Failure ledger policy: return ledger entries, do not write the ledger directly unless explicitly assigned

Subagents must return this packet:

```markdown
## <test-case-id> - <title>

- Status: pass | failed | blocked
- Spec file: <path or proposed path>
- Test title: <Playwright test title>
- Recorded steps:
  1. <action/assertion>
- Commands run:
  - `<command>` -> <result>
- Files changed:
  - <path>
- Failure ledger entry: none | <markdown entry>
- Notes: <selector assumptions, setup needs, merge risks>
```

## Concurrency Gate

Default to serial dispatch. Parallelize only when the main agent can show the tasks are independent.

Safe to parallelize only if all are true:

- Different test cases write different files, or the main agent preassigns non-overlapping output files.
- No shared fixture/helper/app file edits are needed.
- No shared failure ledger writes occur; subagents only return ledger entries.
- Test data, authentication state, browser storage, database records, and external services are isolated or read-only.
- The dev server, backend, and Playwright config support concurrent sessions for these flows.
- The workflows do not depend on execution order.

Do not parallelize when any conflict is possible:

- Same spec file, helper, fixture, snapshot, generated artifact, or app file
- Shared mutable user/account/project/cart/session/database state
- Tests that create, delete, or rename the same records
- Global setup/teardown that is not concurrency-safe
- One test relies on another test's output
- Unclear server or data isolation

If feature conventions prefer one spec file for multiple related cases, run those subagents serially or have subagents return proposed patches for the main agent to merge.

## Test Planning

Keep planning lightweight unless the task is large. For each test case, identify:

- Target route or entry point
- User steps
- Stable locators to use or discover
- Expected visible state, URL change, network result, or persisted state
- Any setup data, mocks, authentication, or backend dependency

Prefer fewer high-value user journeys over many brittle micro-assertions.

## Selector Strategy

Prefer selectors in this order:

1. `getByRole`, `getByLabel`, `getByText` when accessible names are stable and user-facing
2. `[data-testid]`, `[data-test]`, or project-specific test ids
3. Stable ids
4. Existing project helper locators
5. CSS selectors only when they describe durable structure, not visual styling

Avoid generated class names, nth-child chains, arbitrary sleeps, and assertions that only prove implementation details. Use Playwright auto-waiting assertions instead of `waitForTimeout`.

## Exploration And Recording

Treat "recording" as verified browser exploration, not necessarily `playwright codegen`.

When exploration succeeds:

- Capture the minimal action/assertion sequence needed for the test.
- Replace exploratory selectors with maintainable locators before committing the script.
- Preserve only useful comments, such as setup assumptions or non-obvious waits.

When exploration fails:

1. Retry once if the failure looks like startup, navigation, or timing.
2. Inspect the page state with screenshot, DOM text, locator counts, console errors, network errors, or Playwright trace when available.
3. Classify the failure:
   - Environment: server not running, wrong baseURL, missing browser, missing env var, backend unavailable
   - Selector: element exists but locator is wrong or unstable
   - Timing: asynchronous UI state needs a better assertion or event wait
   - Test data/auth: required state is absent
   - Product bug: app does not satisfy the requested behavior
4. Record the failure in the E2E failure ledger.
5. Fix environment/selector/timing/test-data issues only when the user requested fixes or the issue is clearly in the generated test artifact.
6. If it is a product bug or missing requirement, stop masking it and report the blocker with reproduction steps.

Continue with independent test cases when one case is blocked, unless basic navigation or app startup is broken.

## Failure Ledger

Keep Playwright failures in one project-local ledger.

Default path: `docs/testing/playwright-e2e-failures.md`

If the project already has an obvious E2E issue log, such as `todo/playwright-e2e-issues.md`, `docs/testing/e2e-failures.md`, or a documented quality/bug-history location, use that existing file instead. Do not create multiple failure logs in one project.

Create the ledger when a run, recording, or generated test fails and no suitable file exists. The main agent writes or updates this file after collecting subagent result packets. Append a new entry for each distinct failure:

```markdown
## YYYY-MM-DD - <short scenario name>

- Scope: <test file, route, feature, or workflow>
- Command: `<exact command>`
- Status: failed | blocked
- Classification: environment | selector | timing | test-data-auth | product-bug | unclear
- Evidence: <error summary, trace/screenshot path, console/network clue>
- Reproduction: <minimal steps or Playwright actions>
- Expected: <observable expected result>
- Actual: <observable actual result>
- Next action: <fix test | fix app | provide env/data | needs decision | skipped by request>
```

Update an existing entry instead of duplicating it when the same failure recurs.

## Script Generation

Generate idiomatic Playwright TypeScript:

```typescript
import { test, expect } from '@playwright/test'

test.describe('{feature}', () => {
  test('does the user-visible thing', async ({ page }) => {
    await page.goto('/target')
    await expect(page.getByRole('heading', { name: /target/i })).toBeVisible()
  })
})
```

Rules:

- Use the project's existing config and fixtures.
- Keep each test independent unless the project already uses serial flows intentionally.
- Put setup in fixtures or `beforeEach` only when it removes duplication without sharing mutable test state.
- Use route-relative `page.goto()` when `baseURL` exists.
- Use absolute URLs only when the project convention requires them.
- Use `frameLocator` for iframe content.
- Prefer `toHaveURL`, `toBeVisible`, `toHaveText`, `toContainText`, `toHaveCount`, `toBeEnabled`, and `toBeDisabled` over manual polling.
- Add or reuse test ids only when accessible/user-facing locators are not stable enough, and keep those app changes small.

## Running And Fixing Tests

After generating or changing tests, run the narrowest useful command:

- Specific file: `npx playwright test path/to/spec.ts`
- Specific title: `npx playwright test -g "test title"`
- Existing package script when available, such as `npm run test:e2e -- path/to/spec.ts`

When the generated test fails:

1. Read the Playwright error, screenshot, trace, and relevant app console/network output.
2. Decide whether the failure is in the test or the app.
3. Write or update the E2E failure ledger entry before changing behavior.
4. Fix test issues only when fixing is requested or clearly required for the generated test artifact:
   - wrong route/baseURL
   - weak selector
   - missing setup data
   - incorrect expectation
   - timing handled with sleeps instead of assertions
5. Do not "fix" a real product failure by weakening the assertion.
6. Re-run the same narrow command after each meaningful test-artifact fix.
7. If the same blocker remains, keep the ledger entry current and report it with evidence. Mark or skip tests only when the user requested that policy or the project already has a convention for blocked E2E cases.

## Common Outputs

When done, provide:

- Created or changed test file paths
- Any app/test-id/helper changes made to support stable E2E coverage
- Test command run and result
- Failure ledger path and entries added/updated when anything failed
- Known blockers or product bugs, with reproduction steps
- Any setup command the user must run only if it could not be automated safely

## Anti-Patterns

- Hard-coding ports, test folders, setup files, or mock fixtures that are not present in the current repository
- Creating a PRD for a small test request
- Waiting for user confirmation after every planning phase
- Using `waitForTimeout` for ordinary UI readiness
- Depending on test execution order
- Copying selectors from generated CSS or visual styling classes
- Reporting success without running or at least explaining why the Playwright test could not be run
- Letting failed recordings or test runs disappear without a ledger entry
