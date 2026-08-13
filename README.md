# Setting for Ameshika

A portable coding-agent configuration: one small `AGENTS.md` plus a curated skill library, tuned for **Rust as the project core** with **Zig only where Native SDK requires it**.

Works with any agent that reads `AGENTS.md` and `SKILL.md` — Claude Code, Codex, Cursor, Pi, Copilot, Zed, and others.

## Why it is shaped this way

Every line of `AGENTS.md` and every skill *description* is loaded into **every** session, so they compete with each other for attention. This configuration therefore keeps two hard budgets:

| Artifact | Budget | Why |
|---|---|---|
| `AGENTS.md` | **~1.4k tokens, 80 lines** | Short instructions are followed more consistently than long ones |
| Skill descriptions | **~6k tokens total** | Only the description is always-resident; bodies load on demand |

Three rules follow from that:

1. **A skill explains itself.** `AGENTS.md` routes to it in one table row and never restates its contents.
2. **Bodies are on-demand.** A 440 KB reference set costs nothing until the task needs it.
3. **Command-only skills are free.** Anything with `disable-model-invocation: true` never enters context, so deleting it saves nothing.

## Quickstart

```bash
git clone https://github.com/OWNER/setting-for-ameshika
cd setting-for-ameshika
./install.sh              # fetches skills from their upstreams into ~/.agents/skills
cp AGENTS.md ~/.agents/AGENTS.md
```

Then **edit one line** in `~/.agents/AGENTS.md`:

```diff
-The user is https://github.com/YOUR-GITHUB-USERNAME.
+The user is https://github.com/your-actual-handle.
```

Point your agent at `~/.agents/`. For Pi, symlink the skills:

```bash
mkdir -p ~/.pi/agent/skills
for d in ~/.agents/skills/*/; do ln -sfn "$d" ~/.pi/agent/skills/"$(basename "$d")"; done
```

## What `AGENTS.md` actually asserts

- **Rust is the default everywhere**; Zig appears only as a Native SDK app core, and stays a thin state machine whose domain rules live in Rust.
- **Invariants live in Rust**, climbing only as far as needed: types → `proptest` → `kani`. No parallel formalism, because a second authority drifts from the first.
- **Deep modules with one authority per rule** — many small files composed through one router into one large abstraction, never one large file holding many small abstractions.
- An explicit **like / dislike** list, so taste is checkable rather than implied.
- **Documents first**: pull `AGENTS.md`, `ARCHITECTURE.md`, adjacent `SPEC.md`, and ADRs into context before touching code.

It deliberately says nothing about languages it does not use. Prohibitions spend tokens and raise the salience of the very thing they forbid; silence is cheaper and works better.

## Adapting it

The file is *opinionated on purpose* — that is what makes it useful. Change these first:

| Line | Change it if |
|---|---|
| `The user is https://github.com/…` | always |
| The `<stack>` table | your core language is not Rust |
| `<verification>` gates | you do not use clippy/rustfmt, or you want a different proof tier |
| The `<routes>` table | you install a different skill set |
| `Leo Strauss` / `坂口安吾` references | *(already removed — describe behavior, not personas)* |

Keep the shape even if you replace the content: stack → workflow → architecture → verification → routes → delivery → ethos.

## Licensing

This repository contains **only original configuration**: `AGENTS.md`, the docs, `install.sh`, and the files under `overlays/`. Third-party skills are **not** redistributed here — `install.sh` fetches each from its upstream under its own license. See [`SKILLS.md`](SKILLS.md) for every origin, license, and pinned version.
