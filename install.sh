#!/usr/bin/env bash
# Setting for Ameshika — fetch skills from their upstreams into ~/.agents/skills
# Nothing third-party is stored in this repository; everything is pulled here, under its own
# license. Overlays in overlays/ and the rewrites in skills/ are re-applied after each fetch.
set -euo pipefail

DEST="${SKILLS_DIR:-$HOME/.agents/skills}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

NATIVE_SDK_VERSION="0.9.0"

for bin in curl tar awk sed; do
  command -v "$bin" >/dev/null || { echo "missing dependency: $bin" >&2; exit 1; }
done
mkdir -p "$DEST"

say() { printf '  %-34s %s\n' "$1" "$2"; }

fetch_tarball() {  # repo -> extracted dir on stdout
  # Each repo extracts under its own slug: actionbook/rust-skills and
  # full-stack-skills/rust-skills share a basename and would otherwise collide.
  local repo="$1" name="${1##*/}" slug="${1//\//-}"
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/main" -o "$TMP/$slug.tgz"
  mkdir -p "$TMP/$slug"
  tar xzf "$TMP/$slug.tgz" -C "$TMP/$slug"
  echo "$TMP/$slug/$name-main"
}

copy_skill() {  # srcdir destname
  rm -rf "${DEST:?}/$2"
  cp -r "$1" "$DEST/$2"
  rm -rf "${DEST:?}/$2/agents"   # Codex-only metadata, unused by the agents this config targets
}

echo "Installing into $DEST"
echo

# ---------------------------------------------------------------- native-sdk
echo "native-sdk  (vercel-labs/native, Apache-2.0, SDK $NATIVE_SDK_VERSION)"
curl -fsSL "https://registry.npmjs.org/@native-sdk/cli/-/cli-$NATIVE_SDK_VERSION.tgz" -o "$TMP/nsdk.tgz"
tar xzf "$TMP/nsdk.tgz" -C "$TMP" package/skill-data
D="$TMP/package/skill-data"
rm -rf "${DEST:?}/native-sdk"; mkdir -p "$DEST/native-sdk/references"
cp "$D/core/SKILL.md"                                          "$DEST/native-sdk/references/core.md"
cp "$D/core/references/project-anatomy.md"                     "$DEST/native-sdk/references/core-project-anatomy.md"
cp "$D/core/references/app-model-runtime.md"                   "$DEST/native-sdk/references/core-app-model-runtime.md"
cp "$D/core/references/bridge-security-native-capabilities.md" "$DEST/native-sdk/references/core-bridge-security.md"
cp "$D/core/references/web-engines-packaging-debugging.md"     "$DEST/native-sdk/references/core-packaging-debugging.md"
cp "$D/core/references/frontend-assets.md"                     "$DEST/native-sdk/references/core-frontend-assets.md"
cp "$D/native-ui/SKILL.md"                                     "$DEST/native-sdk/references/native-ui.md"
cp "$D/zig/SKILL.md"                                           "$DEST/native-sdk/references/zig-0.16-idioms.md"
cp "$D/automation/SKILL.md"                                    "$DEST/native-sdk/references/automation.md"
cp "$D/ts-core/SKILL.md"                                       "$DEST/native-sdk/references/ts-core.md"
cp "$D/ts-services/SKILL.md"                                   "$DEST/native-sdk/references/ts-services.md"
cp "$D/ts-services/references/service-surface.md"              "$DEST/native-sdk/references/ts-service-surface.md"
cp "$HERE/overlays/native-sdk/SKILL.md"                        "$DEST/native-sdk/SKILL.md"
say "native-sdk" "$(ls "$DEST/native-sdk/references" | wc -l) reference files (overlay router applied)"
echo

# ----------------------------------------------------------------------- zig
echo "zig  (nzrsky/zig-skills, MIT, pinned to Zig 0.16.0)"
SRC="$(fetch_tarball nzrsky/zig-skills)/.adal/skills/zig"
copy_skill "$SRC" zig
# Replace upstream frontmatter with the 0.16 overlay header, then keep the upstream body.
awk 'BEGIN{n=0} /^---$/{n++; if(n<=2) next} n>=2' "$SRC/SKILL.md" > "$TMP/zig-body.md"
cat "$HERE/overlays/zig/SKILL.header.md" "$TMP/zig-body.md" > "$DEST/zig/SKILL.md"
sed -i.bak 's|^# Zig Language Reference (v0.17.0-dev)$|# Zig Language Reference (read as 0.16.0 stable; upstream text targets 0.17.0-dev)|' "$DEST/zig/SKILL.md"
rm -f "$DEST/zig/SKILL.md.bak"
say "zig" "$(ls "$DEST/zig/references" | wc -l) reference files (0.16 guard applied)"
echo

# ------------------------------------------------------------------- ytakano
echo "ytakano/rust_skills  (soundness, hardening, meaningful tests)"
SRC="$(fetch_tarball ytakano/rust_skills)/skills"
for s in rust-c-ffi-safety rust-coverage-meaningful-tests rust-hardening; do
  copy_skill "$SRC/$s" "$s"; say "$s" "ok"
done
echo

# ---------------------------------------------------------- full-stack-skills
echo "full-stack-skills/rust-skills  (Apache-2.0, grounded in Rust 1.97.1)"
SRC="$(fetch_tarball full-stack-skills/rust-skills)/skills"
for s in rust-api-design rust-semver rust-module-layout rust-workspace rust-cargo-build rust-documentation; do
  copy_skill "$SRC/$s" "$s"; say "$s" "ok"
done
echo

# ---------------------------------------------------------------- actionbook
# Four of the 38 meta-cognition skills: the two design-layer entries AGENTS.md routes to,
# the anti-pattern catalogue, and the no_std domain constraints.
echo "actionbook/rust-skills  (MIT, meta-cognition layers)"
SRC="$(fetch_tarball actionbook/rust-skills)/skills"
for s in m05-type-driven m13-domain-error m15-anti-pattern domain-embedded; do
  copy_skill "$SRC/$s" "$s"; say "$s" "ok"
done
echo

# --------------------------------------------------------------- pstack
# blast-radius travels nearly verbatim; only the harness-specific steps are rewritten below.
echo "cursor/plugins  (MIT, pstack)"
SRC="$(fetch_tarball cursor/plugins)/pstack/skills"
copy_skill "$SRC/blast-radius" blast-radius; say "blast-radius" "ok"
echo

# ------------------------------------------------------- rewrites in this repo
# how, why and branch-audit are original rewrites of MIT-licensed pstack and Thermos skills,
# reworked for agents without sub-agents. They are not fetchable, so they live here.
echo "rewrites (this repository, MIT-derived — see SKILLS.md for attribution)"
for s in how why branch-audit; do
  rm -rf "${DEST:?}/$s"; cp -r "$HERE/skills/$s" "$DEST/$s"; say "$s" "ok"
done
echo

# ------------------------------------------------------------------- repairs
# Every skill above ships cross-references to siblings this configuration does not install.
# Left alone they send the agent to a skill that is not there, so each one is retargeted to
# the local owner of that concern, or demoted to plain language when nothing here owns it.
echo "repairing cross-references"

# --- full-stack-skills: retarget to the local owner of each concern
for f in $(grep -rlE 'rust-(style-clippy|unsafe-ffi|testing|embedded|performance|dependencies|code-review)' \
           --include='*.md' "$DEST"/rust-{api-design,semver,module-layout,workspace,cargo-build,documentation} 2>/dev/null); do
  sed -i \
    -e 's/rust-style-clippy/rust-hardening/g' \
    -e 's/rust-dependencies/rust-hardening/g' \
    -e 's/rust-unsafe-ffi/rust-c-ffi-safety/g' \
    -e 's/rust-testing/rust-coverage-meaningful-tests/g' \
    -e 's/rust-embedded/domain-embedded/g' \
    -e 's/rust-performance/diagnosing-bugs/g' \
    -e 's/rust-code-review/branch-audit/g' \
    "$f"
done

# --- full-stack-skills: rust-stable and rust-macros have no local owner, so drop the pointer
sed -i \
  -e 's/^1\. Rust ownership, traits, lifetimes — see `rust-stable`$/1. Rust ownership, traits, and lifetimes/' \
  -e 's/^1\. Rust ownership and basic module syntax — see the `rust-stable` skill$/1. Rust ownership and basic module syntax/' \
  -e 's/^1\. Rust ownership and basic module syntax — see `rust-stable`$/1. Rust ownership and basic module syntax/' \
  -e 's/^3\. Rust syntax fundamentals → use `rust-stable`$/3. Rust syntax fundamentals — out of scope here/' \
  "$DEST"/rust-{api-design,module-layout,workspace}/SKILL.md
sed -i \
  -e 's|^The Guidelines are organized into 11 chapters\. This skill owns 8 — the design chapters\. Documentation, Macros, and Necessities live in `rust-documentation`, `rust-macros`, and `rust-cargo-build` respectively\.$|The Guidelines are organized into 11 chapters. This skill owns 8 — the design chapters. Documentation belongs to `rust-documentation` and Necessities to `rust-cargo-build`. The Macros chapter has no separate owner in this configuration; apply C-MACRO and C-MACRO-NAMES straight from the checklist.|' \
  "$DEST/rust-api-design/SKILL.md"
sed -i \
  -e 's|^## 10\. Macros (covered in `rust-macros`)$|## 10. Macros (no separate owner here)|' \
  -e 's|^For C-MACRO, C-MACRO-NAMES — see `rust-macros`\.$|C-MACRO and C-MACRO-NAMES have no dedicated skill in this configuration. Apply them from the upstream chapter: [API Guidelines — Macros](https://rust-lang.github.io/api-guidelines/macros.html).|' \
  "$DEST/rust-api-design/references/api-guidelines-checklist.md"

# --- actionbook: strip Claude-Code-only frontmatter and the shell-injection preamble
for s in m05-type-driven m13-domain-error m15-anti-pattern domain-embedded; do
  sed -i -e '/^user-invocable: false$/d' -e '/^globs: \[/d' "$DEST/$s/SKILL.md"
done
# domain-embedded opens with an "(Auto-Injected)" block that only Claude Code expands, and its
# singleton pattern panics, which this configuration bans outside tests.
python3 - "$DEST/domain-embedded/SKILL.md" "$HERE/overlays/actionbook/domain-embedded.header.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text(encoding="utf-8")
head = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8").rstrip() + "\n"

# Keep the frontmatter, drop everything up to the first real section, splice the overlay in.
parts = t.split("---\n", 2)
if len(parts) < 3:
    sys.exit("domain-embedded: frontmatter not found")
frontmatter = "---\n" + parts[1] + "---\n\n"
marker = "## Domain Constraints"
if marker not in parts[2]:
    sys.exit("domain-embedded: '%s' not found" % marker)
t = frontmatter + head + "\n---\n\n" + parts[2][parts[2].index(marker):]

t = t.replace(
    "    let dp = pac::Peripherals::take().unwrap();",
    "    // take() yields Some exactly once. There is no caller to return an error to\n"
    "    // from `-> !`, so the second entry halts deliberately instead of panicking.\n"
    "    let Some(dp) = pac::Peripherals::take() else {\n"
    "        loop {\n"
    "            cortex_m::asm::wfi();\n"
    "        }\n"
    "    };")
t = t.replace("| Hardware ownership | Singleton | take().unwrap() |",
              "| Hardware ownership | Singleton | `let Some(dp) = Peripherals::take() else { halt }` |")
p.write_text(t, encoding="utf-8")
PY

# --- actionbook: demote references to the 34 sibling skills this configuration omits
for f in $(find "$DEST"/{m05-type-driven,m13-domain-error,m15-anti-pattern,domain-embedded} -name '*.md'); do
  sed -i \
    -e 's/m01-ownership/ownership/g'            -e 's/m02-resource/resource ownership/g' \
    -e 's/m03-mutability/interior mutability/g' -e 's/m04-zero-cost/zero-cost abstraction/g' \
    -e 's/m06-error-handling/error handling/g'  -e 's/m07-concurrency/concurrency/g' \
    -e 's/m09-domain/domain modeling/g'         -e 's/m10-performance/performance/g' \
    -e 's/m11-ecosystem/crate selection/g'      -e 's/m12-lifecycle/lifecycle and RAII/g' \
    -e 's/m14-mental-model/mental model/g'      -e 's/unsafe-checker/unsafe review/g' \
    -e 's/domain-\*/domain constraints/g' "$f"
done
# --- actionbook: record why these four look different from upstream
for s in m05-type-driven m13-domain-error m15-anti-pattern; do
  python3 - "$DEST/$s/SKILL.md" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text(encoding="utf-8")
note = ("> From actionbook/rust-skills (MIT), cut out of its 38-skill router. Cross-references to "
        "sibling skills are now concept names; the table at the end points at the skills this "
        "configuration installs.\n")
if "actionbook/rust-skills (MIT)" not in t:
    t = re.sub(r"(^> \*\*Layer \d[^\n]*\n)", r"\1\n" + note, t, count=1, flags=re.M)
p.write_text(t, encoding="utf-8")
PY
done

# --- actionbook: the "Related Skills" footer routes into the omitted set; replace it wholesale
for s in m05-type-driven m13-domain-error m15-anti-pattern domain-embedded; do
  awk '/^## Related Skills/{exit} {print}' "$DEST/$s/SKILL.md" > "$TMP/$s.body"
  cat "$TMP/$s.body" "$HERE/overlays/actionbook/$s.related.md" > "$DEST/$s/SKILL.md"
done
# --- actionbook: m15 recommends expect() as the cure for unwrap(); both are banned here
python3 - "$DEST/m15-anti-pattern/SKILL.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text(encoding="utf-8")
t = t.replace(
    "| `.unwrap()` in production | Runtime panics | `?`, `expect`, or handling |",
    "| `.unwrap()` or `.expect()` outside tests | Runtime panics | `?`, a typed error, or local recovery |")
t = t.replace("- [ ] No `.unwrap()` in library code",
              "- [ ] No `.unwrap()` or `.expect()` in non-test code")
p.write_text(t, encoding="utf-8")
PY

# --- pstack: blast-radius points at skills that ship elsewhere, and at parallel sub-agents
python3 - "$DEST/blast-radius/SKILL.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text(encoding="utf-8")
t = t.replace("disable-model-invocation: true\n", "")
t = t.replace("Blast radius tells you what it breaks somewhere else.",
    "Blast radius tells you what it breaks somewhere else. For a full pre-merge audit of the diff "
    "itself rather than its reach, use `branch-audit`.\n\n"
    "> Adapted from pstack (`cursor/plugins`, MIT), with the parallel-model step rewritten for "
    "agents that have no sub-agents.", 1)
t = t.replace(
    "6. For a big or wide change, run it as an `arena`. Ask several models the same question and "
    "merge the answers. Different models catch different real bugs.",
    "6. For a big or wide change, take the question again from a different starting point. The "
    "original skill sent it to several models in parallel and merged the answers, because "
    "different models catch different real bugs. One agent cannot reproduce that, so approximate "
    "it: re-enter from the opposite end of the data flow (from the consumer backward instead of "
    "the change forward), and refuse to carry the first pass's verdict in. When the change is "
    "expensive to get wrong, say plainly that a second model should be asked the same question "
    "separately.")
t = t.replace("Write it through `unslop`,", "Write it through `apostle-antislop`,")
p.write_text(t, encoding="utf-8")
PY
say "cross-references" "retargeted to local owners"
echo

# -------------------------------------------------------------------- verify
fail=0
for d in "$DEST"/*/; do
  d="${d%/}"
  [ -f "$d/SKILL.md" ] || { echo "BROKEN (no SKILL.md): ${d##*/}" >&2; fail=1; continue; }
  awk '/^---/{n++} n==1 && /^name:/{ok=1} END{exit !ok}' "$d/SKILL.md" \
    || { echo "BROKEN (frontmatter): ${d##*/}" >&2; fail=1; }
done
[ "$fail" -eq 0 ] && echo "All skills parse."

# A backtick-quoted skill name that resolves to no installed directory is either a dead route or
# a deliberate pointer into one of the sets SKILLS.md lists as recommended-but-not-fetched.
# `rust-version` is excluded because it is the Cargo.toml MSRV field, not a skill.
OPTIONAL="apostle-antislop apostle-artifacts-loops apostle-sdd apostle-translation domain-modeling codebase-design diagnosing-bugs research writing-for-agents skill-creator"
NOT_A_SKILL="rust-version"
dead=""; optional_missing=""
while read -r s; do
  [ -n "$s" ] || continue
  [ -d "$DEST/$s" ] && continue
  case " $NOT_A_SKILL " in *" $s "*) continue ;; esac
  case " $OPTIONAL " in
    *" $s "*) optional_missing="$optional_missing $s" ;;
    *)        dead="$dead $s" ;;
  esac
done <<EOF
$(grep -rhoE '`(rust|apostle|domain|m[0-9]{2}|branch|blast)-[a-z0-9-]+`|`(how|why)`' \
    --include='*.md' "$DEST" 2>/dev/null | tr -d '`' | sort -u)
EOF
[ -n "$optional_missing" ] && echo "Referenced but not fetched (see SKILLS.md, \"Recommended, not fetched\"):$optional_missing"
if [ -n "$dead" ]; then echo "DEAD CROSS-REFERENCES:$dead" >&2; fail=1; fi

tot=0; n=0
for d in "$DEST"/*/; do
  d="${d%/}"; [ -f "$d/SKILL.md" ] || continue
  grep -qi '^disable-model-invocation: *true' "$d/SKILL.md" && continue
  c=$(awk '/^---/{x++} x==1' "$d/SKILL.md" | grep -A25 '^description:' \
      | awk '/^[a-z-]+:/ && !/^description:/{exit} {print}' | wc -c)
  tot=$((tot+c+${#d}+95)); n=$((n+1))
done
echo "$n auto-loaded skills ≈ $((tot/4)) tokens of always-resident context."
echo
echo "Next: cp AGENTS.md ~/.agents/AGENTS.md  then edit the 'The user is https://github.com/…' line."
exit "$fail"
