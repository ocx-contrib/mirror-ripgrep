# ripgrep/tests/smoke.star — stable across upstream ripgrep releases.
# Asserts the contract (exit code, version shape, the exact result SET of a
# recursive search over a hermetic tree, Unicode-aware regex semantics), never
# help/version prose. See ocx.mirror testing-practices.md.

RG = "rg.exe" if ocx.target_platform.os == ocx.os.Windows else "rg"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE (not the vendor
# banner, not the exact version — the digits are the contract).
r_version = ocx.run(RG, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3a: a real recursive search over a hermetic tree.
#
# ⚠️ rg's exit code alone has no teeth here: a match exits 0 and a binary that
# degenerated into "match every line" would exit 0 too. The assertion that
# bites is the result COUNT — four files exist, exactly two contain "needle",
# and the search must select those two and nothing else.
#
# Output format is pinned explicitly rather than taken from the default: rg
# switches between heading and `path:line:text` form depending on whether
# stdout is a tty, so --no-heading/--with-filename/--line-number is what makes
# the parse deterministic. --no-ignore makes the result independent of any
# .gitignore ABOVE the scratch root (the CI runner's workspace is a git
# checkout), and --no-config of any RIPGREP_CONFIG_PATH on the runner.
ocx.mkdir("tree/sub")
ocx.write_file("tree/a.txt", "needle here\nnothing\n")
ocx.write_file("tree/b.txt", "nothing at all\n")
ocx.write_file("tree/sub/c.md", "another needle line\n")
ocx.write_file("tree/sub/d.md", "no match on this line\n")

r_find = ocx.run(
    RG, "--no-config", "--no-ignore", "--color=never",
    "--no-heading", "--with-filename", "--line-number", "needle", ".",
    cwd = "tree",
)
expect.ok(r_find)

hits = [line for line in r_find.stdout.replace("\r", "").split("\n") if line]
expect.eq(len(hits), 2)
# rg prints paths relative to the search root, so the separator is `/` on unix
# and `\` on Windows — match either rather than branching.
expect.matches(r_find.stdout, r"a\.txt:1:needle here")
expect.matches(r_find.stdout, r"sub[/\\]c\.md:1:another needle line")

# Tier 3b: the inverse selector over the same tree. A pattern present in no
# file must yield an EMPTY result and exit 1 — this is what reds against a
# binary that matches everything, and it is the half `expect.ok` cannot see.
r_none = ocx.run(
    RG, "--no-config", "--no-ignore", "--color=never", "absent-token-xyzzy", ".",
    cwd = "tree",
)
expect.eq(r_none.exit_code, 1)
expect.eq(r_none.stdout, "")

# Tier 3c: --count-matches over one named file returns a bare integer, so the
# count is asserted directly rather than parsed out of match text.
ocx.write_file("counts.txt", "needle\nneedle needle\nplain\n")
r_count = ocx.run(
    RG, "--no-config", "--color=never", "--count-matches", "needle", "counts.txt",
)
expect.ok(r_count)
expect.eq(r_count.stdout.replace("\r", "").strip(), "3")

# Tier 3d: ripgrep's regex engine is Unicode-aware BY DEFAULT — `\w` matches
# `é`. A byte-oriented engine would stop at the `h`, so this asserts the
# embedded Unicode tables actually shipped rather than merely that the binary
# execs. `-o` prints the match itself, so the assertion is on a computed value.
ocx.write_file("unicode.txt", "héllo world\n")
r_word = ocx.run(
    RG, "--no-config", "--color=never", "--no-filename", "--no-line-number",
    "-o", r"^\w+", "unicode.txt",
)
expect.ok(r_word)
expect.eq(r_word.stdout.replace("\r", "").strip(), "héllo")

# No Tier 4: metadata.json declares PATH only (proven by Tier 1 liveness).
