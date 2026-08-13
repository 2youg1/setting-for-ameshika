---
name: native-sdk
description: Native SDK (vercel-labs/native) desktop app development, Zig-core path. Apps are declarative .native markup views plus a Model/Msg/update core, compiled to a single native binary with no WebView, browser, or JS runtime. Use when scaffolding or modifying a Native SDK app, writing .native views, wiring a Zig core, calling a Rust binary from update via the effects channel, configuring app.zon, packaging, or driving the built-in automation server. Reference bodies are local; the native CLI is optional.
license: Apache-2.0
---

# Native SDK — Zig core + Rust workers

Vendored from `vercel-labs/native` (`@native-sdk/cli` 0.9.0, `skill-data/`). Bodies live in `references/` — **no `native skills get` call is needed**. Load only the file the task requires; the full set is ~440 KB.

<stack>

## The chosen path here

This library targets **Zig cores, not TypeScript cores.** Upstream defaults to `src/core.ts`; that path is not used here. Scaffold with:

```bash
native init my_app --template zig-core   # produces src/main.zig, not src/core.ts
```

Three files of truth: `app.zon` (manifest), `src/app.native` (view), `src/main.zig` (core). Markup binds and dispatches but never mutates; all state change happens in one `update`.

**Heavy logic belongs in Rust, not Zig.** The Zig core stays a thin state machine; domain work runs as a Rust binary reached through the effects channel (`fx.spawn`), which streams stdout back as typed Msgs and delivers exit as one more Msg. Have the Rust side emit NDJSON on stdout and keep the process key in the model so `fx.cancel` works. See `references/native-ui.md` §"Effects in Zig cores" (~line 570) — this is the seam that keeps Rust as the project core.

</stack>

<routing>

## Which file to load

| Task | File |
|---|---|
| What is the Native SDK, project layout, `app.zon`, first orientation | `references/core.md` |
| Writing `.native` views, widgets, layout, bindings, messages | `references/native-ui.md` |
| Zig core wiring, effects/subprocess, windows, time, testing | `references/native-ui.md` — Zig sections at ~49, 349, 570, 875, 934, 973, 1215 |
| `zig build` fails on std APIs (0.15-era code) | `references/zig-0.16-idioms.md` |
| Testing a running app, snapshots, screenshots, driving widgets | `references/automation.md` |
| Directory and file conventions | `references/core-project-anatomy.md` |
| Lower-level App/Runtime patterns | `references/core-app-model-runtime.md` |
| Bridge commands, permissions, native capabilities | `references/core-bridge-security.md` |
| Packaging, web engines, debugging | `references/core-packaging-debugging.md` |
| Embedding web content or an existing frontend | `references/core-frontend-assets.md` |

Read `references/core.md` before explaining or changing an app. For view work load `native-ui.md` too. Treat upstream's "use `ts-core`" instructions as pointing to the Zig sections of `native-ui.md` instead.

</routing>

<typescript-path>

## TypeScript files, kept but unused

`references/ts-core.md`, `ts-services.md`, and `ts-service-surface.md` are the upstream TypeScript authoring path (~208 KB). They are retained only to read upstream examples that ship as TypeScript. **Do not propose the TypeScript core path or write `src/core.ts` for this user.** When an upstream recipe appears only in TypeScript, translate its Model/Msg/update shape into the Zig `UiApp` form rather than adopting the TS core.

</typescript-path>

<verify>

## Completion checks

- `native check` validates core and views against the actual `Model`/`Msg` — run it before claiming a view compiles.
- `native dev` hot-reloads while preserving state; `native build` produces the shipping binary.
- Every app embeds an automation server; verify behavior by driving the real window, not by reading source. See `references/automation.md`.
- Pre-1.0: APIs still move. Desktop is mature (macOS deepest); mobile is experimental. Zig 0.16.0 is required — confirm with `zig version`.

</verify>
