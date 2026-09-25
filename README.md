# Setting for Ameshika

A portable coding-agent configuration: one `AGENTS.md` plus a curated skill library, tuned for **Rust as the project core**, **Lean for the properties that must hold**, with **Zig only where Native SDK requires it**.

Works with any agent that reads `AGENTS.md` and `SKILL.md` — Claude Code, Codex, Cursor, Pi, Copilot, Zed, and others.

## Why it is shaped this way

Every line of `AGENTS.md` and every skill *description* is loaded into **every** session, so they compete with each other for attention. This configuration therefore keeps two hard budgets:

| Artifact | Budget | Why |
|---|---|---|
| `AGENTS.md` | **~3.7k tokens, 158 lines** | Always resident, so every line is paid in every session. Policy lives here; procedure lives in a skill body |
| Skill descriptions | **~2.9k tokens total** | Only the description is always-resident; bodies load on demand |

Three rules follow from that:

1. **A skill explains itself.** Its `description` is the only routing: it says when to load the body, and `AGENTS.md` never restates the contents. This assumes the agent lists skill descriptions; one that does not has to be pointed at `~/.agents/skills`.
2. **Bodies are on-demand.** A 440 KB reference set costs nothing until the task needs it, which is why a procedure belongs in a body even when its principles stay resident.
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
-The user is https://github.com/YOUR-GITHUB-USERNAME, and answers to whatever they are called.
+The user is https://github.com/your-actual-handle, and answers to whatever they are called.
```

Point your agent at `~/.agents/`. For Pi, symlink the skills:

```bash
mkdir -p ~/.pi/agent/skills
for d in ~/.agents/skills/*/; do ln -sfn "$d" ~/.pi/agent/skills/"$(basename "$d")"; done
```

## What `AGENTS.md` actually asserts

- **Rust is the default everywhere**; Lean models the properties the code must hold, and Zig appears only as a Native SDK app core, staying a thin state machine whose domain rules live in Rust.
- **One authority each**: the Lean model decides which properties must hold, the Rust code decides how they hold, and a behaviour change updates the model and its proofs first, in the same change.
- **Deep modules with one authority per rule** — many small files composed through one router into one large abstraction, never one large file holding many small abstractions.
- **A named code standard with a conflict rule**: Martin's taste for every line, in Clean Code, Clean Architecture, and SOLID, with `<architecture>` winning where the heuristics collide.
- **Every fact one definition**, ranked by how close the copies are to disagreeing — a second definition is a defect while the copies still agree.
- **Documents first**: pull `AGENTS.md`, `ARCHITECTURE.md`, `glossary.md`, the nearest `SPEC.md`, the ADRs, and the relevant Lean models into context before touching code.

It deliberately says nothing about languages it does not use. Prohibitions spend tokens and raise the salience of the very thing they forbid; silence is cheaper and works better.

## Adapting it

The file is *opinionated on purpose* — that is what makes it useful. Change these first:

| Line | Change it if |
|---|---|
| `The user is https://github.com/…` | always |
| The `<stack>` table | your core language is not Rust, or you do not keep formal models |
| `<verification>` gates | you do not use clippy/rustfmt/`lake build`, or you want a different proof tier |
| The `<authority>` principles | you do not want the one-fact-one-authority rule, or you install a different review skill |

Keep the shape even if you replace the content: context → stack → workflow → writing → coding → formal-models → verification → commands → design → autonomy.

## Licensing

This repository contains **only original configuration**: `AGENTS.md`, the docs, `install.sh`, the files under `overlays/`, and the three skills under `skills/`. Third-party skills are **not** redistributed here — `install.sh` fetches each from its upstream under its own license.

The files under `skills/` are kept here because they cannot be fetched, and all three derive from MIT-licensed `cursor/plugins` originals: `how` and `why` are rewrites of pstack skills, and `authority-review` adapts the Thermos review rubrics and deepens them with this configuration's own one-fact-one-authority lens. Each replaces a parallel-subagent workflow with a sequential one, for agents that have no sub-agents. Every one names its source in its own body.

See [`SKILLS.md`](SKILLS.md) for every origin, license, and pinned version.
