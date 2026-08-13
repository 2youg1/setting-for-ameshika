---
name: zig
description: Zig 0.16.0 stable language and stdlib patterns, indexed by what changed from training-data-era Zig. Use when writing, reviewing, or debugging Zig, editing build.zig or build.zig.zon, or using comptime. Covers the removals that silently break older code - std.net to std.Io.net, std.time timestamps, std.Thread.Mutex/Condition/sleep, std.crypto.random, ArrayList unmanaged by default, @typeInfo lowercase fields, and the deletion of async/await and usingnamespace. Ships 60 stdlib reference files.
license: MIT
metadata:
  upstream: "github.com/nzrsky/zig-skills"
  vendored: "2026-08-14 (upstream pushed 2026-08-08)"
  pinned-to: "0.16.0"
---

<version-guard importance="highest">

## Target Zig 0.16.0 — not 0.17.0-dev

This configuration targets **Zig 0.16.0 stable** (confirm with `zig version`); Native SDK declares `minimum_zig_version = "0.16.0"`. Upstream wrote this skill against 0.17.0-dev.

**Skip the section titled "Critical: 0.17.0-dev changes (in progress)".** Everything else in this file is verified 0.16.0-valid. Do not apply these 0.17-only deltas:

- `b.args` → `run_cmd.addPassthruArgs()`
- `std.gpu` → `std.spirv`
- `@bitCast` logical-bit (endian-agnostic) semantics
- build configurer/maker split, `zig-pkg/` package directory

Four reference files also carry 0.17 notes — `quality-tooling.md`, `simd-intrinsics.md`, `std-io.md`, `std-testing.md`. Read the version tag before copying from them.

For Native SDK app work, load `native-sdk` first; this skill is the language layer beneath it.

</version-guard>

