# mirror-ripgrep

OCX mirror for [ripgrep](https://github.com/BurntSushi/ripgrep), a line-oriented
recursive regex search tool. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [ripgrep](https://github.com/BurntSushi/ripgrep) | [`ripgrep/mirror.yml`](ripgrep/mirror.yml) | `ghcr.io/ocx-contrib/ripgrep/ripgrep` | [`ocx.sh/ripgrep/ripgrep`](https://index.ocx.sh/ripgrep/ripgrep) | `Unlicense OR MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

`BurntSushi` is a personal handle rather than a vendor, so the tool names
itself: the namespace is `ripgrep`, not the maintainer.

## Layout

```
mirror-base.yml         repo-wide policy the spec inherits via `extends:`
ripgrep/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. The logo is **not** — it sits
beside the spec, because a repo-root `logo.*` sits in no workflow's `paths:`
filter, so replacing it would publish nothing until some unrelated edit
happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. `ripgrep/mirror.yml` does not
restate `platforms:` at all; the measured matrix lives in `mirror-base.yml`.

## Platforms

Six platform entries: both Linux arches, both macOS arches, both Windows
arches. Every one of the six anchored asset patterns was checked against the
full asset list of **every** in-range release (15.0.0, 15.1.0, 15.2.0) and
matches exactly one asset each — a pattern matching zero is *silently skipped*
by the pipeline, not an error, and would ship a missing platform under a green
run.

**The two Linux keys differ, because their linkage does.** `os.features` states
what an artifact requires *of the host*, never how it was built:

| Key | Asset | Measured |
|---|---|---|
| `linux/amd64` | `x86_64-unknown-linux-musl` | static-pie, `INTERP` segment count **0**, zero `DT_NEEDED` → **bare** |
| `linux/arm64+libc.glibc` | `aarch64-unknown-linux-gnu` | `PT_INTERP /lib/ld-linux-aarch64.so.1`, `NEEDED libc.so.6 libgcc_s.so.1`, max symver `GLIBC_2.18` → **`+libc.glibc`** |

Upstream ships **no** `-gnu` build for x86_64 Linux at all, but a musl target
*triple* is not a musl *requirement*: that binary is fully static, so tagging it
`+libc.musl` would be a false requirement hiding the package from every glibc
host it in fact runs on. The `alpine:3.20` container leg is what turns the bare
key's universality claim into evidence. The `+libc.glibc` key gets **no** alpine
leg — the binary genuinely cannot load under musl, and the renderer rejects that
leg at spec load (exit 65).

Two upstream asset-set flips land inside this version range, and both are
handled by *which variant is declared* rather than by a floor bump:

- `aarch64-unknown-linux-musl` is **new in 15.2.0** and absent at 15.0.0 and
  15.1.0. Declaring it would resolve zero assets on two of the three in-range
  releases — silently. The gnu aarch64 asset spans the whole range, so that is
  the one carried.
- `i686-unknown-linux-gnu` shipped at 15.0.0/15.1.0 and was **dropped in
  15.2.0**. Moot either way: i686 has no OCX platform key.

Also published upstream and deliberately not carried: `armv7-*` (three ABI
variants), `s390x-unknown-linux-gnu`, `i686-pc-windows-msvc`,
`x86_64-pc-windows-gnu` (msvc is the one carried), the `.deb` package and every
`.sha256` sidecar. The anchored `^…$` regexes are what keep them out.

## The binaries claim

Every release archive — `.tar.gz` and `.zip` alike — is a single
`ripgrep-<version>-<triple>/` wrapper holding `rg` (`rg.exe` on Windows) at its
**root**, beside `doc/`, `complete/`, `COPYING`, `UNLICENSE`, `LICENSE-MIT` and
`README.md`. One `strip_components: 1` therefore serves every platform, and no
per-platform `asset_type` override is needed.

After the strip the bundle's only PATH entry is a bare `${installPath}` — the
executable *is* the content root. `bin_scan` only looks *below* an
`${installPath}/<dir>` entry, so `auto`/`verify` is rejected at spec load with
exit 65 (*the verification would inspect no file and pass green whatever the
archive contains*). `ripgrep/mirror.yml` therefore sets `bin_scan: "off"` and
`ripgrep/metadata.json` hand-lists `binaries: ["rg"]` — the blessed shape for
this layout, and `rg` is the archive's only mode-0755 entry.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `ripgrep/mirror.yml` | hand | yes — see below |
| `ripgrep/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `ripgrep/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec ripgrep/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; the
redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
