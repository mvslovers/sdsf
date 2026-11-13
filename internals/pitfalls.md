# Pitfalls

What has cost time before. Most of it was measured on TK5 or MVS/CE. `#25` collects the Wally ISPF points for the Wally ISPF project.

## Wally ISPF

- **An attribute at the end of a panel line is not sent.** An input field in the line above a dynamic area runs on into the area. That is why the command row is part of `ISFLIST`'s dynamic area: SDSF fills and reads its fields itself.
- **The data stream of a screen is cut at 3584 bytes.** Beyond that, ISPF sends null bytes, which overwrite the title and cut off the last rows. Each colour change in a dynamic area costs about 10 bytes, so use one attribute per run of overtypeable fields. This is why PRTY and C on I are one input field (#56).
- **Colour in a dynamic area:** a row without its own attribute gets the colour of the last field before the area. White in an area needs an attribute byte, which shifts the text by one column, so the outstanding replies on LOG are bright blue, not white.
- **Two dynamic areas in one panel** gave DISPLAY RC 20.
- **The keys belong to the application.** `VPUT (ZPFnn) PROFILE` under applid ISF changes what a key does in SDSF; the same under ISP does not. `PFK()` in `)INIT` gives only the defaults. `KEYS` works only from ZCMD, and SDSF's command field is ISFCMD, because ISPF would take `HELP` from ZCMD (#68, #69).
- **HELP has no tutorial navigation.** Without `.HELP` on the panel, the Help key ends the DISPLAY with RC 0 like Enter; ZVERB stays blank and only `.PFKEY` tells PF1 from Enter. `isfhelp.c` drives the help panels itself.
- **PA1 ends the whole dialog,** even with a STAX exit of the dialog's own. `CONTROL DISPLAY LOCK` locks the keyboard for as long as it is in effect. This is why `&` (automatic update) was dropped (#23).
- **`SELECT CMD(%name parm)` drops the last character of the parameters.** Leave out the `%`, or put a blank before the `)`.
- **No ZTERMID:** SDSF reads the terminal name itself, in the authorized state.

## Panels

- Keep the 24-line body and the width. A panel that is one column wider breaks the layout on a 24x80 screen.
- `&` and `!` in panel text are taken as a variable or an attribute. Write around them.
- A test that sends Enter does not prove that a key works on a real terminal. The automated tests send keys even when the keyboard is locked.

## SMP

- **A return code says the job ran, not that the work happened.** Check the target libraries and the LIST output.
- **APPLY RC 4 and ACCEPT RC 4 are normal** on a first installation (HMA2391 with IEW0342, HMA2471). `docs/installation.md` names them.
- **`DEL LMOD` belongs under `UCLIN CDS` only.** Under `UCLIN ACDS` it gives HMA2762 and RC 8. That error does not stop the following statements.
- **HMA2532** (DEL of an entry that does not exist) does stop the rest of the UCLIN step.
- **An old `IGX00011` in `SYS1.LPALIB`** is linked into the new one by SMP, and the result is no longer refreshable. A fresh installation must find no `IGX00011` there.
- **FMIDs are spent once.** `TISF120` is spent by 1.2.0. Until mbt builds PTFs, a patch release needs an explicit `fmid` of its own, and must delete the earlier one. 1.2.1, for example, needs `fmid = "TISF121"` and `delete = ["TISF120"]` (see releasing.md). Read the ecosystem's SMP notes (FMID rules, the list of spent ids) before changing `[smp]`.

## JCL and jobs

- **Job cards end in column 71.** mvsMF needs room on the job card, so keep it short.
- **Submit SMP jobs with TSO SUBMIT, not through the reader without a user.** Without a user, the job gets S913 on `SYS1.SMPCDS` under RAKF.
- On TK5, TSO SUBMIT puts `USER=` on the job card. A job without `USER=` has no owner for SDSF.

## MVS/CE

- `IEAAPF00` and `LNKLST00` need a comma before the comment on a continued line.
- CLPA only through `IEASYS00`. Hercules answers the IPL reply itself, so typing `CLPA` there does not work.
- The ISPF libraries: ISPPLIB is set in `SYS1.CMDPROC(ISPF)`, SYSPROC in `SYS1.PROCLIB(IKJACCNT)`. An ALLOC in the TSO logon procedure fails silently.
- RAKF's profiles are in `SYS1.SECURE.CNTL(PROFILES)`, as on TK5. On a stock MVS/CE the group ADMIN has READ on `FACILITY SVC244`, so an ADMIN user passes an authorization check even without the SVC routine. Test with a user outside ADMIN.

## JES2 and the master trace table

- PR and INIT parse the JES2 answer to `$DU,PRTS` and `$DI` from the master trace table. The answer can come late: "NO ANSWER FROM JES2" was seen once right after a submit, and the next Enter was fine.
- JES2 4.1 refuses `$FPRTn,C` (#73).
- The master trace table holds a few hundred lines. That is all the log SDSF can show (#70).
