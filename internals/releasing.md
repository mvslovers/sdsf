# Releasing

How SDSF is released, as it was done for 1.2.0. There is no 1.3.0: IBM's SDSF V1R2 is the model, so every further release is 1.2.x.

Merging to main, tagging and releasing need the maintainer's approval.

## Before the tag

1. **All PRs for the release are merged**, CI is green on main, and no open PR belongs to the milestone.
2. **SMP:** read the ecosystem's SMP notes (FMID rules, the list of spent ids), then set `[smp]` in `mbt.toml`.
   - `TISF120` is spent by 1.2.0.
   - Until mbt builds PTFs, a patch release needs an explicit FMID and a `delete` of the earlier one. For 1.2.1: `fmid = "TISF121"`, `delete = ["TISF120"]`.
   - Measure the upgrade from the previous release in a throwaway TK5 and MVS/CE before the release: APPLY with the DELETE of the old FMID, ACCEPT, `LIST`, the members of the target libraries, and `IGX00011` still refreshable in `SYS1.LPALIB`.
   - Write the upgrade path into `docs/installation.md`.
3. **CHANGELOG.md:** a section for the version with its date, the toolchain versions, what was added, fixed and changed, and the known limitations with their issue numbers. No consumer project names, no job numbers, no private system names.
4. **The books:**
   - `make -C docs/books` builds both PDFs without warnings;
   - every new command, panel, action character and message of the release is in them;
   - the help panels and `internals/terms.md` agree with them.
   - The edition is in the PDF's name: `ml11-0001-0.pdf` is the draft. Change the edition in `docs/books/Makefile` and the front matter when a book is no longer a draft.
5. **The package:**
   - `mbt package` locally;
   - the zip holds `README.md`, `uninstall.md`, the three XMITs (`-load`, `-isfplib`, `-isfclst`) and the alloc, inst and accept JCL;
   - the README names the version and the FMID.

## The tag

```sh
mbt release 1.2.1            # sets 1.2.1, commits, tags v1.2.1, pushes, then sets 1.2.2-dev
```

`mbt release` commits to main directly. The tag starts `.github/workflows/release.yml`:

1. **`release`:** mbt's `release3.yml`. It builds the toolchain at the pinned versions, runs `mbt package`, and creates the GitHub release with `dist/*`: the dist zip and tar.gz, and the load XMIT.
2. **`books`:** it builds both books from the tag (`SOURCE_DATE_EPOCH=0`, so the PDFs are reproducible) and attaches them with a `SHA256SUMS`. That `SHA256SUMS` lists only the PDFs today (#44): check it and complete it until #44 is fixed.

## After the tag

1. **The release page:** replace the generated notes (`gh release edit vX.Y.Z --notes-file FILE`). The page is for someone who has never heard of this ecosystem:
   - a lead paragraph;
   - "Read this first" (FMID, the IPL with CLPA, the expected return codes, the upgrade path, RAKF);
   - what you get, with a before/now table of fixes for a patch release;
   - requirements;
   - install steps;
   - known limitations with issue numbers;
   - a link to the CHANGELOG at the tag;
   - the trademark line.

   No mention of the comparison system, no job numbers, no private system names.
2. **Check the release:**
   - download every asset;
   - `sha256sum -c SHA256SUMS` passes for all of them;
   - the zip and tar.gz hold the same files with the release's name and no `-dev`;
   - `mbt.toml` and `CHANGELOG.md` at the tag carry the version and date;
   - neither PDF mentions anything the public rules exclude (`internals/README.md`).
3. **Record the spent FMID** in the ecosystem's list of spent ids.
4. **Close the milestone**, and the issues the release finished.
5. Read the Docs builds the online books from main by itself.
