# Embedded Domain

> **Layer 3: Domain Constraints**

> From actionbook/rust-skills (MIT), cut out of its 38-skill router. Cross-references to sibling skills are now concept names, and the panicking singleton pattern has been replaced to match this configuration's ban on `unwrap` in non-test code.

Read the target configuration before advising, because every constraint below depends on it:

```bash
cat .cargo/config.toml 2>/dev/null || echo "no .cargo/config.toml"
```
