# Development

## Build

SDSF builds with mbt 3 (`mbt.toml`, no Makefile). The toolchain versions are pinned there: cc370 1.6.3, libc370 2.29.0, mbt 3.2.

```sh
mbt build            # ISFISP, IGX00011 and the tools
mbt package          # the release artefacts in dist/: SMP package (zip, tar.gz), load XMIT
mbt dist             # only the SMP install package again
make -C docs/books   # the two books (typst, fonts from the bookmaster submodule)
```

`git submodule update --init docs/books/bookmaster` is needed once for the books.

CI (`.github/workflows/`):
- `build.yml`: mbt's `build3.yml`, on every PR and push to main.
- `books.yml`: both books, typst pinned by version and SHA-256. A broken label or reference fails the PR.
- `release.yml`: on a tag `v*` (see releasing.md).

There are no host unit tests. The tests are the TSO tests on an MVS system.

## Targets

MVS systems come from `~/.mbt/targets.toml`; `mbt target list` shows them. Name the target explicitly for anything that writes (`--target NAME`). For work that changes the system (APF, LPA, IPL, RAKF profiles), use a throwaway container:

```sh
eval "$(mvsce-target up)"            # mvs-docker's container tool; --dist tk5 for TK5
mbt target ping env --tso --wait 60
mbt deploy --target env
# ... the development system below, once per container
mbt test --tso --target env
mvsce-target down "$MVSCE_TARGET_NAME"
```

A container is not a long-lived system. Check SMP and installation questions on a fresh TK5 and a fresh MVS/CE, as the release guide was checked.

## The development system

A fresh MVS/CE container does not know SDSF yet: `mbt deploy` only fills `ISF.DEV.LINKLIB`, and without the steps below every TSO test stops at the ISPF menu (no option `S`). Do them once per container, as IBMUSER, in this order:

1. **Panels.** Allocate `ISF.DEV.ISPPLIB` (PDS, RECFM FB, LRECL 80), then `mbt run panels --target env`.
2. **ISPF.** In `SYS1.CMDPROC(ISPF)` put `ISF.DEV.ISPPLIB` first in the `ALLOC` of `ISPPLIB` (continue the line with ` +`; a record is 80 bytes). Copy `ISP@PRIM` from `SYSGEN.ISPF.PLIB` into `ISF.DEV.ISPPLIB` and add a menu line `S` and, in the `)PROC` translation, `S,'PGM(ISFISP) NOCHECK NEWAPPL(ISF)'`. The tests type `S` at the menu.
3. **APF and link list.** Add `ISF.DEV.LINKLIB` with its volume (where the deploy allocated it; `mbt deploy` prints it) to `SYS1.PARMLIB(IEAAPF00)`, and its name alone to `SYS1.PARMLIB(LNKLST00)`: the link list takes data set names only. Commas as in `docs/installation.md` section 5. `ISFISP` and every `ISF*` module must come from an APF library or the LPA, or `IGX00011` refuses. Measured: from the link list ISPF finds `ISFISP` without an ISPLLIB entry, and SDSF runs authorized.
4. **The SVC routine.** Copy `IGX00011` from `ISF.DEV.LINKLIB` to `SYS1.LPALIB` with IEBCOPY (`SELECT MEMBER=IGX00011`). Put `CLPA,` into `SYS1.PARMLIB(IEASYS00)` and restart the container (`docker restart mvsce-NAME`) for the IPL. The published ports change on a restart: run `mvsce-target status NAME` again and `eval` its output.

   Check that the routine is installed with a batch job (`EXEC PGM=ISFSVCT`, STEPLIB `ISF.DEV.LINKLIB`); SYSPRINT says `ISFSVCT ESR11=1 BADR0 RC=4 ON RC=0 TESTAUTH=0 OFF RC=0 TESTAUTH=4`. `ESR11=0` means the routine is not in the LPA (no CLPA yet).
5. **RAKF.** In `SYS1.SECURE.CNTL(PROFILES)` add `FACILITY SDSF.OPER` (NONE; group ADMIN UPDATE) and `JESSPOOL *` (NONE; group ADMIN UPDATE) in sort order, columns as in `docs/installation.md` section 8, then `S RAKFPROF`. Without them IBMUSER has no rights and most tests report `COMMAND NOT AUTHORIZED`.
6. **Is the SVC in use?** IBMUSER is in the group ADMIN, and on a stock MVS/CE ADMIN has READ on `FACILITY SVC244`, so SDSF could authorize itself through SVC 244 and a green run would not show that `IGX00011` works. Set the access of ADMIN to NONE (the line `FACILITYSVC244 ... ADMIN`), `S RAKFPROF`, and run the tests again: they pass only through `IGX00011`. A second TN3270 user outside ADMIN (see below) gives the same proof.

A test that fails can leave its TSO session behind: the next logon says `IKJ56425I`. Cancel it with `C U=IBMUSER` and wait until `D TS,L` shows no user.

`authz.lua` runs only for a user without rights (a TN3270 user other than IBMUSER, one that is not in the group ADMIN). IBMUSER skips it, so a green run as IBMUSER does not exercise the refusal paths.

## Deploy

`mbt deploy` writes the load modules into `ISF.DEV.LINKLIB` (`[deploy]` in `mbt.toml`). `ISF.LINKLIB` belongs to SMP; only the install job writes it.

- `ISFISP` is loaded from the link list, APF-authorized (`ISF.LINKLIB` in production, `ISF.DEV.LINKLIB` on a development system: see above). ISPF itself loads ISPLINK from its own ISPLLIB.
- `mbt run panels [DSN] [PATTERN]` puts the panels of `ispplib/` into `ISF.DEV.ISPPLIB` (or DSN). PATTERN limits them, for example `ispplib/isfh*`.
- `IGX00011` only takes effect from `SYS1.LPALIB` after an IPL with CLPA. A deploy does not install it. Without it, SDSF uses SVC 244 (#74 removes that).

## TSO tests

`test/tso/*.lua` drive SDSF over TN3270 with mbt's TSO test driver: logon, `ISPF`, the menu, typing, PF keys, reading the screen and its colours (`t:color`). Each script is one test; the return code is the contract.

```sh
mbt test --tso --target NAME                # all
mbt test --tso --target NAME --only st      # one
```

`mbt/init.lua` prepares and cleans up:

- **before the TSO tests:** it submits `test/jcl/zswa.jcl` (a job that issues a WTOR and waits) and waits until its reply is outstanding, for `wtor.lua`. It also submits the held job `ZSIN` (`test/jcl/zsin.jcl`) if none is on the input queue, for `i.lua` and the overtype tests.
- **after the TSO tests:** it answers whatever is left of the ZSWA WTOR, so no job stays waiting.
- **`mbt run jown`:** it runs `ISFJOWN` and prints every job with its owner, entity and RAKF's answers. Use it when a job shows or hides unexpectedly.

The test jobs use `CLASS=A,MSGCLASS=H`; the hooks put in the target's job and message class. `test/jcl/README.md` describes each job.

Tests that need a particular user or system:

| Test | Needs |
|---|---|
| `authz.lua` | a TN3270 user without SDSF.OPER and without JESSPOOL profiles (`MBT_TARGET_TN3270_USER=HERC02 ...`); with IBMUSER it skips |
| `colors.lua` | an mbt with `t:color`; otherwise it skips |
| `wtor.lua` | the outstanding ZSWA WTOR from the hook |
| `i.lua`, `overtype.lua` | the held ZSIN |
| `da.lua` | the ZSWA job as a running batch job |

Several actions (purge, cancel, `/` commands, start, stop and halt of printers and initiators) change the system. Run those against a throwaway container, not a shared system.

## Looking at the model

IBM's SDSF V1R2 is the model for panels, columns, messages and behaviour. Where a question of behaviour is open, look at the model and write down what was seen, in your own words, in the issue or the code comment ("as in IBM's SDSF V1R2"). Nothing from it is copied: no panel source, no help text, no screen image, no internals.

## Panels

The panels in `ispplib/` are plain text members. Rules that every panel change must keep:

- the body is 24 lines and keeps the width of the existing panels;
- the attribute characters are `@ } { _ !` as defined in each panel's `)ATTR`;
- no `&` and no `!` in the text: ISPF takes them as variable or attribute;
- the help (`ISFH*`, `ISFK*`), the tutorial (`ISFT*`) and the index (`ISFX*`) must agree with the books and with `internals/terms.md`.

`test/tso/help.lua` walks the help. After a panel change, run it together with the test of the panel concerned.
