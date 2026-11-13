# Open work

What each open issue needs, written at the handover after 1.2.0 (2026-11-13). The issues themselves are the source of truth. Strike an entry here when its issue closes, or drop the file once it no longer helps.

Legend for "needs":
- **container**: a throwaway TK5 or MVS/CE, because the work changes the system or needs a device or remote;
- **model**: looking at IBM's SDSF V1R2 for its behaviour, written down in our own words;
- **code**: files to change.

## Milestone 1.2.1

| Issue | Needs | Notes |
|---|---|---|
| #74 Remove the SVC 244 fallback | code: `src/isfauth.c` (`isf_autask`, `isf_quiet`); check that every libc370 call that authorizes itself (`cmtt_new`) is reached only in the authorized state; docs in both books, `ispplib/isfhaut2`, `docs/installation.md`, `terms.md`; container without `IGX00011` for the refusal | The largest docs change of 1.2.1. Decide the message for "SVC routine not installed" first. |
| #68 KEYS and RETR | code: a new panel `ISFKEYS`, `src/isfisp.c` (take `KEYS` and abbreviated `RETRIEVE`); VGET and VPUT of `ZPF01` to `ZPF24` in the ISF profile; a test that sets a key and puts it back | Measured: VPUT under ISF changes the key in SDSF. Keep the 3584-byte screen limit in mind with 24 input fields. |
| #46 PR and INIT leave `$DU`/`$DI` in the log | research first: JES2 keeps printers and initiators in its own address space. A way without a command needs code that runs in JES2's address space (an SRB scheduled from the SVC routine) | Weigh the risk of running code in JES2 against a cleaner log. A decision may be "keep it". |
| #48 PR: an active printer | code: `printer_row` in `src/isfpan.c`, which reads `(JOB` with its parenthesis as the job type, so the job is not found; container: `stop 00E` on the Hercules console keeps a printer active with its output | Fault found and described in the issue. REC-CNT and REC-PRT are not in the `$DU` answer. |
| #49 PR: fields with fixed values | code: `src/isfpan.c`; for each field, its source in the `$DU` answer, or blank | Includes CKPTLINE and CKPTPAGE (fixed at 0 and 100). |
| #72 INIT: no job for HALTING or DRAINING | code: `read_init` in `src/isfpan.c` fills the job only for ACTIVE | Small. |
| #51 INIT: colours of the rows | model; `test/tso/colors.lua` | |
| #71 PRINT ODSN with a wrong volume: S213 | code: `print_open` in `src/isfisp.c`; check the data set on the volume before OPEN, or catch the abend; test in `test/tso/print.lua` | The TSO session hangs after the abend and has to be cancelled from the console: test only in a container. |
| #73 Reference: PRINT ODSN format, FC on PR | docs: `ref-cmd.typ` (PRINT), `ref-actions.typ` (B and F) | JES2 4.1 refuses `$FPRTn,C`. |
| #9 `?` on O | code: `src/isfpan.c`, the PF11 pages of O; model for the fourth page; `test/tso/o.lua` | Same pattern as `?` on ST and I. |
| #52 O: rows for output waiting for a printer | model | |
| #53 O: DEVICE, STATUS, PRT-REC empty | an active printer (#48) first | |
| #54 O: one column on the last PF11 page | model; `src/isfpan.c` | |
| #15 PR: overtype SUCS | container: what `,STD` means in `$DU,PRTn` and which `T=` restores it; then an input field like SFCB (`ov_build_pan`) | |
| #16 Un shown as Rn | container with a remote: route one job to `R1` and one to `U1`, read the raw route; then `st_read`, `src/isfpan.c`, `dest_match`; `test/tso/dest.lua` | A real bug: DEST as a filter and as an overtype can hit the wrong route. |
| #70 Master trace table usermod | an answer from the TK5 maintainer (asked in the issue); then docs: `docs/installation.md`, the User's Guide (installation, log chapter), the Reference package appendix, as an optional usermod | Make it reachable for MVS/CE as well. |

## Without a milestone

| Issue | Needs |
|---|---|
| #43 Who May Do What: profile table before an IPL, RAKF commands | docs: `ug-access.typ`, `docs/installation.md` |
| #44 SHA256SUMS lists only the PDFs | `.github/workflows/release.yml`, or mbt writing `SHA256SUMS` in `mbt package` (an mbt change for every project) |
| #25 Wishes for Wally ISPF | report to the Wally ISPF project; points 12 and 13 are handled in #68 and #69 |
| #69 Help names the user's keys | research: VGET of `ZPFnn` before a help panel, against the data-stream limit and the number of panels |

## Research (label `research`)

These need a look at the model or a source on MVS 3.8j before they can be planned. None is promised for a release.

| Issue | Question |
|---|---|
| #55 I: POS of a job that is not held | does the model show the place within the class? |
| #56 I: PRTY and C one field | revisit only if Wally ISPF lifts the 3584-byte limit |
| #57 to #60 H | rows per class, the order of the rows, local time, `S` showing only the held part: model |
| #61 DA: PAGING | a source without cross memory |
| #62 DA: EXCP-CNT | the field that counts |
| #63 DA: TRANS and READY | how to tell them apart on MVS 3.8j |
| #64 DA: CPU in the title on the first display | a value without a previous display |
| #66 DA: PGN of a swapped-out address space | look at one |
| #67 DA: SR names | the swap reason codes of MVS 3.8j |
