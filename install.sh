#!/usr/bin/env bash
# Setting for Ameshika — fetch skills from their upstreams into ~/.agents/skills
# Nothing third-party is stored in this repository; everything is pulled here, under its own
# license. Overlays in overlays/ are re-applied after each fetch.
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
  local repo="$1" name="${1##*/}"
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/main" -o "$TMP/$name.tgz"
  tar xzf "$TMP/$name.tgz" -C "$TMP"
  echo "$TMP/$name-main"
}

copy_skill() {  # srcdir destname
  rm -rf "${DEST:?}/$2"
  cp -r "$1" "$DEST/$2"
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
for s in rust-api-design rust-semver rust-module-layout; do
  copy_skill "$SRC/$s" "$s"; say "$s" "ok"
done
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
