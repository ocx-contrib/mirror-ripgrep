# NOTICE

This repository packages and redistributes upstream software published by the
[ripgrep](https://github.com/BurntSushi/ripgrep) project. The Apache-2.0
license in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It
does **not** cover any upstream-derived asset — the redistributed bytes carry
their own license, recorded below.

The package logo is an original mark authored for this repository — upstream
publishes none — and is used for catalog identification only. No endorsement is
implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `ripgrep` | `ghcr.io/ocx-contrib/ripgrep/ripgrep` | `Unlicense OR MIT` |

---

## `ripgrep`

Upstream: <https://github.com/BurntSushi/ripgrep>
Published to `ghcr.io/ocx-contrib/ripgrep/ripgrep`.

| Component | SPDX | Holder |
|---|---|---|
| ripgrep (`rg`) | **Unlicense OR MIT** | Andrew Gallant ("BurntSushi") |

Dual-licensed — the recipient may take either arm. The upstream `COPYING` file
reads *"This project is dual-licensed under the Unlicense and MIT licenses. You
may use this code under the terms of either license."*; the GitHub license API
surfaces only the `UNLICENSE` file and so reports the SPDX id `Unlicense`.

The Unlicense is a public-domain dedication: the author waives copyright and
related rights worldwide to the extent permitted by law, so redistribution of
the compiled binary is granted unconditionally under that arm — no
notice-retention condition attaches. The MIT arm's copyright and permission
notices are retained regardless: every release archive ships `COPYING`,
`UNLICENSE` and `LICENSE-MIT` beside the executable, and all three are
republished unmodified inside the OCX bundle. The canonical texts are
<https://github.com/BurntSushi/ripgrep/blob/master/UNLICENSE> and
<https://github.com/BurntSushi/ripgrep/blob/master/LICENSE-MIT>.

The published binaries statically link third-party Rust crates under permissive
licenses, enumerated in upstream's `Cargo.lock`.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
