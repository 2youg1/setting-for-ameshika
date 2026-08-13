# Skill library — origins, licenses, staleness

`install.sh` fetches every skill from its upstream. Nothing third-party is redistributed in this
repository; only `AGENTS.md`, the docs, the script, and `overlays/` are original work here.

## Fetched by `install.sh`

| Skill | Upstream | License | Pinned to | Re-check when |
|---|---|---|---|---|
| `native-sdk` | `vercel-labs/native`, via npm `@native-sdk/cli` | Apache-2.0 | SDK **0.9.0** | upstream is pre-1.0 — check npm before each milestone |
| `zig` | `nzrsky/zig-skills` | MIT | **Zig 0.16.0** | `zig version` changes |
| `rust-c-ffi-safety` | `ytakano/rust_skills` | — | — | annually |
| `rust-coverage-meaningful-tests` | `ytakano/rust_skills` | — | — | annually |
| `rust-hardening` | `ytakano/rust_skills` | — | — | annually |
| `rust-api-design` | `full-stack-skills/rust-skills` | Apache-2.0 | Rust 1.97.1 | `rustc -V` major change |
| `rust-semver` | `full-stack-skills/rust-skills` | Apache-2.0 | Rust 1.97.1 | `rustc -V` major change |
| `rust-module-layout` | `full-stack-skills/rust-skills` | Apache-2.0 | Rust 1.97.1 | `rustc -V` major change |

**A stale skill is worse than no skill** — it makes the agent confidently emit APIs that were
removed. Freshness beats popularity when picking between candidates.

## Overlays applied on top of upstream

Under `overlays/`. Re-apply these after any re-fetch; `install.sh` does it automatically.

- **`zig`** — upstream targets `0.17.0-dev`. The overlay replaces the frontmatter and prepends a
  version guard pinning to **0.16.0**, instructing the agent to skip upstream's
  *"Critical: 0.17.0-dev changes"* section. Four reference files (`quality-tooling.md`,
  `simd-intrinsics.md`, `std-io.md`, `std-testing.md`) also carry 0.17 notes. The upstream
  description is cut from 1429 to 510 characters, since it would otherwise be the largest
  always-resident description in the library.
- **`native-sdk`** — upstream ships a *discovery stub* that requires `npm i -g @native-sdk/cli`
  and `native skills get <name>` at runtime. The overlay replaces it with a local router, and
  `install.sh` extracts the twelve upstream bodies into `references/`, so nothing is fetched at
  use time. The TypeScript authoring path is retained but explicitly disabled: this
  configuration builds Zig cores (`native init --template zig-core`).

## Recommended, not fetched

Set up separately if you want them.

| Set | Origin | Notes |
|---|---|---|
| Rust meta-cognition | `actionbook/rust-skills` | `m0x-*` ownership/borrow/lifetime routing, `domain-*`, `coding-guidelines`, `unsafe-checker`. Large and good; overlaps some entries above |
| Engineering workflow | `mattpocock/skills` | `code-review`, `research`, `diagnosing-bugs`, `writing-for-agents`, plus command-only `to-spec`, `triage`, `wayfinder`, `handoff` |
| Office documents | `anthropics/skills` | `pdf`, `docx`, `xlsx`, `pptx`. ~4 MB; skip unless you produce those formats |

## Evaluated and rejected

Recorded so the evaluation is not repeated.

| Candidate | Why not |
|---|---|
| `full-stack-skills/rust-skills` → `rust-testing` | Description claims `property, fuzz`; body states `Out of Scope: proptest → Not currently covered`. A description that overclaims mis-triggers. Use `rust-coverage-meaningful-tests` |
| `ytakano/rust_skills` → `trace-state-machine-port-conformance` | Triggers only on **C++ → Rust ports**; it would never fire on a greenfield Rust project |
| `zigcc/skills` | Three months stale against a fast-moving language, despite a higher star count |
| `leanprover/skills` | Six of nine skills are for contributing to Lean/Mathlib itself. Lean is deliberately absent from this stack — invariants stay in Rust, since a Lean model has no automated correspondence to Rust code and becomes a second, drifting authority. Use `kani` when a property genuinely needs proof |

## Measuring the budget

```bash
cd ~/.agents/skills && tot=0; n=0
for d in */; do d=${d%/}; [ -f "$d/SKILL.md" ] || continue
  grep -qi '^disable-model-invocation: *true' "$d/SKILL.md" && continue
  c=$(awk '/^---/{x++} x==1' "$d/SKILL.md" | grep -A25 '^description:' \
      | awk '/^[a-z-]+:/ && !/^description:/{exit} {print}' | wc -c)
  tot=$((tot+c+${#d}+95)); n=$((n+1)); done
echo "$n auto-loaded skills ≈ $((tot/4)) tokens"
```

Validate that every skill still parses, and that `AGENTS.md` routes nowhere dead:

```bash
cd ~/.agents/skills
for d in */; do d=${d%/}
  awk '/^---/{n++} n==1 && /^name:/{ok=1} END{exit !ok}' "$d/SKILL.md" || echo "BROKEN $d"
done
for s in $(grep -o '\*[a-z0-9-]*\*' ~/.agents/AGENTS.md | tr -d '*' | sort -u); do
  [ -d "$s" ] || echo "DEAD ROUTE $s"
done
```
