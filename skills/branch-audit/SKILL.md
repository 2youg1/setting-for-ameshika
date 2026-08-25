---
name: branch-audit
description: "Two-pass audit of a branch or PR diff before it merges. Pass one hunts bugs, broken existing behavior, security holes, developer-experience regressions, and feature-gate leaks. Pass two hunts maintainability damage: missed simplifications, files crossing 1000 lines, special-case branching bolted into unrelated flows, and logic landing in the wrong layer. Use for 'review this branch', 'audit this PR', 'deep review', or before shipping a diff you do not fully trust."
---

# Branch audit

Audit a checked-out branch twice, with different eyes each time, then merge the findings into one verdict.

> Adapted from the Thermos plugin (`cursor/plugins`, MIT). The original runs the two rubrics as parallel subagents and synthesizes their reports. pi has no sub-agents, so the passes run sequentially here. Sequential is not merely a downgrade: finish pass one and write its findings down **before** reading the rubric for pass two, because a correctness verdict carried into a maintainability pass suppresses exactly the findings that pass exists to produce.

## Scope

Report only on code this branch **adds or modifies**. Do not report vulnerabilities or smells in untouched existing code, however tempting. The diff is the subject; the rest of the repository is context you read in order to judge the diff.

Gather before starting: the diff against the merge base, and the full current contents of every changed file. Judging a hunk from its diff context alone produces confident wrong findings.

## Pass one — correctness and security

Audit for bugs, changes that break existing behavior, and security vulnerabilities. Be thorough, rigorous, and careful; nothing should slip through.

**Breaking existing functionality.** Codebases have cross-module dependencies where a simple local change interacts subtly with something far away. Trace the side effects of each change through its callers and its data, rather than reading the hunk in isolation.

**Breaking developer experience.** It is easy to break other people's ability to build and run the code locally. Watch for changes to how secrets are read or where they are read from, renamed or newly required environment variables, remapped ports and networking, and new scripts that must be run for existing functionality to keep working. Adding a dependency through the package manager does not count. Adding a *new alternative* way to build does not count. What counts is changing the way developers already build and run.

**Feature-gate leaks.** When the codebase gates features behind flags or internal-only checks, verify that nothing this branch adds escapes its gate. These leaks are subtle; check the gate on every path, not just the obvious one.

**Intended breakage.** If a high-risk finding is the declared point of the branch — removing a flag, retiring a safeguard, deliberately dropping a feature — and the change is well scoped, do not spend the author's time reporting it. Still report it when you believe the author has not seen the full implications, when they appear to be under-weighting the damage, or when the change looks malicious.

**Do not over-report.** Reporting a medium issue as high destroys the trust that makes the next report useful. Trace each issue end to end and reach real confidence before assigning it a priority.

Write pass one's findings down now, then read the next section.

## Pass two — maintainability

Rethink how the change is structured. Behavior stays identical; the question is whether the implementation earns its place.

Be **ambitious**. Do not stop at "this could be a bit cleaner." Look for the restructuring that makes whole branches, helpers, modes, or layers disappear — the move that makes the change feel inevitable in hindsight. When there is a path to deleting complexity rather than rearranging it, push for that path.

**Presumptive blockers.** Each of these needs an explicit justification from the author, not a shrug:

- The diff preserves substantial incidental complexity when a visible restructuring would delete it.
- The diff pushes a file from under 1000 lines to over 1000 lines. Treat this as a strong smell by default and ask whether the code should be decomposed first. Waive it only for a compelling structural reason, and only when the result is still clearly organized.
- The diff adds ad-hoc conditionals, scattered special cases, or one-off branches into flows that are not about this feature. "Weird if statements in random places" is a design problem, not a style nit; the logic belongs behind a dedicated abstraction, state machine, or module.
- The diff solves a local problem by scattering feature checks across shared code.
- The diff adds a wrapper, cast, or optional that makes the contract more indirect rather than clearer. Be skeptical of generic mechanisms that hide a simple data-shape assumption, and of thin abstractions that add indirection without buying clarity.
- The diff duplicates a helper the codebase already has, or puts logic in the wrong layer when a canonical home exists.

**Also flag.** Unnecessary optionality or cast-heavy code where a clearer type boundary could exist; silent fallbacks papering over an unclear invariant; independent work serialized for no reason; related updates that can leave state half-applied when an atomic structure is available.

**Preferred remedies**, roughly in descending order of value: delete a layer of indirection rather than polish it; reframe the state model so the conditionals disappear instead of being centralized; move the ownership boundary so the feature becomes a natural extension of something that already exists; turn a special case into a simpler default with fewer exceptions; split a large file into focused modules; replace a condition chain with a typed model or explicit dispatch; separate orchestration from business logic; reuse the canonical helper.

## Verdict

Merge both passes into one report, deduplicated. Findings first, prioritized in this order:

1. Correctness, security, and broken existing behavior
2. Structural regressions and missed dramatic simplifications
3. Spaghetti and branching growth
4. Boundary, abstraction, and type-contract problems
5. File size and decomposition
6. Legibility

Prefer a small number of high-conviction findings to a long list of cosmetic notes. Do not flood a review with nits while a structural problem sits unaddressed.

Every finding names the failure, cites `file:line`, and states the evidence. A finding you could not trace to confidence is reported as unverified or not at all.

**Approval bar.** Behavior being correct is not sufficient. Approve only when there is no structural regression, no visible missed simplification, no unjustified file-size explosion, no new spaghetti branching, no magical abstraction that makes the code harder to reason about, no architecture-boundary leak, and no avoidable duplication of a canonical helper.

**Tone.** Direct, serious, demanding about quality; never rude. Do not soften a major maintainability problem into a mild suggestion. If the branch makes the codebase messier, say so plainly.

## Last step

Only after both passes are complete, check the PR or MR discussion with `gh` or `glab` for comments from bots or reviewers. Doing this last preserves fresh eyes for the audit itself. Evaluate what others found, incorporate the valid findings you missed, and mark which findings came from the discussion rather than from you.

Never present a finding with unfinished research. "The client has issue X, but this may be handled in the backend" is not a finding when the backend is in this repository and you could have checked.
