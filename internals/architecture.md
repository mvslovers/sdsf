# Architecture

SDSF is one load module, `ISFISP`, that runs as an ISPF dialog under Wally ISPF. The CLIST `SDSF` starts it with `ISPEXEC SELECT PGM(ISFISP) NOCHECK NEWAPPL(ISF)`, so its profile variables and PF keys belong to the application `ISF`. The SVC routine `IGX00011` is a separate module in the LPA. The panels are in `ispplib/`.

## Modules

| Module | Sources | Shipped | What it is |
|---|---|---|---|
| `ISFISP` | `src/isfisp.c`, `isfst.c`, `isfpan.c`, `isfauth.c`, `isfhelp.c` | yes | SDSF itself |
| `IGX00011` | `asm/igx00011.asm` | yes, as source; the install job assembles it and SMP links it into `SYS1.LPALIB` | the SVC routine, SVC 109 code 11 (see authorization.md) |
| `ISFWAIT` | `tools/isfwait.c` | no | test tool: stays in execution for PARM seconds |
| `ISFWTOR` | `tools/isfwtor.c` | no | test tool: issues a WTOR and ends on the reply |
| `ISFSVCT` | `tools/isfsvct.c` | no | test tool for the SVC routine; refused when linked under another name |
| `ISFJOWN` | `tools/isfjown.c` with `isfst.c`, `isfauth.c` | no | diagnostic: every job with its owner, its JESSPOOL entity and RAKF's answers |

`ship = false` in `mbt.toml` keeps the tools out of the SMP package.

## Source files

| File | Lines | Holds |
|---|---|---|
| `src/isf.h` | ~270 | The shared types: `ISFROW` (a job as ST shows it), `ISFPAN` (a list panel's rows), `ISFJDS` (Job Data Set), `ISFOUT` (output and log lines), `ISFDA`, `ISFWTOR`, and the functions between the files |
| `src/isfisp.c` | ~4900 | The dialog. The `DLG` struct holds all state of a session. It covers the main loop of each panel kind (`list_display`, `out_panel2`, the menu), the command line (`cmd_word`, `pan_parse`, `da_parse`, `st_parse`, `setting_cmd`), scrolling, FIND/RFIND/LOCATE/NEXT/PREV, the NP column (`np_typed`, `action_cmd`, `job_command`, `pr_command`, `init_command`), overtyping (`ov_*`), PRINT (`print_*`), PREFIX/DEST, `/` and `TSO`, RETRIEVE, and the profile variables |
| `src/isfst.c` | ~1500 | The data that is not panel layout: the jobs from the JES2 checkpoint (`st_read`), their owners through libc370 (`owners_read`), purge (`st_purge`), the job's data sets and output from the spool (`jds_*`, `out_*`), the system log from the master trace table (`log_load`), the outstanding replies (`wtor_read`), operator commands (`op_command`), the address spaces for DA (`da_read`), WHO |
| `src/isfpan.c` | ~950 | The rows of I, O, H, PR and INIT (`pan_read`). I comes from the ST rows, O and H from the jobs' PDDBs, PR and INIT from the answer to `$DU,PRTS` and `$DI` (`ask_jes2`, `printer_row`, `read_init`) |
| `src/isfauth.c` | ~225 | RAKF checks (`auth_job`, `auth_oper`, `auth_mine`) with a per-list cache, and the authorized state (`isf_autask`, `isf_uatask`, `isf_quiet`) |
| `src/isfhelp.c` | ~290 | The help and tutorial driver. Wally ISPF has no tutorial navigation, so SDSF shows the `ISFH*`, `ISFK*`, `ISFT*` and `ISFX*` panels itself |

## Panels

- `ISFMENU`: the primary option menu.
- `ISFLIST`: every list, the Job Data Set panel, the output and the log. Its body is one dynamic area that SDSF fills row by row, including the command row. The dynamic area also holds the attribute bytes: blue, white, red (overtypeable, active), green (overtypeable, not active), high intensity. See `pitfalls.md` for why the command row lives inside the area.
- `ISFH*` help, `ISFK*` help for commands, `ISFT*` tutorial, `ISFX*` index: plain ISPF panels that `isfhelp.c` displays and navigates.

Each list row is built as one "virtual line" as wide as all columns of the panel. PF11 and PF10 show it from further right or left; the fixed columns stay. The columns, headings and PF11 pages follow IBM's SDSF V1R2.

## Where the data comes from

MVS 3.8j has no cross-memory services. SDSF reads what is in common storage or on the spool, and asks JES2 by command for the rest.

| Panel | Source |
|---|---|
| ST, I | The job queue elements of the JES2 checkpoint. The class of a batch job and the columns of `?` come from its JCT on the spool. The owner comes from libc370 (`USER=` in the converted JCL, the name of a TSO user, `SYSTEM` for a started task). JES2 4.1 leaves JCTUSEID blank. |
| O, H | The job's PDDBs on the spool, summed per job: held or not held SYSOUT |
| Job Data Set, Output | The PDDBs and the spool records of the job's data sets, through libc370 |
| DA | ASVT, ASCB, OUCB and CSCB, all readable in key 8. CPU% and SIO are taken over the interval since the previous display. The terminal of a TSO user comes from its TSB, which needs the authorized state. |
| LOG | The master trace table, read in key 0 (authorized state), so the log holds only what the table still holds |
| Outstanding replies | The OREs and WQEs of the UCM, copied in key 0 into storage got in key 8. The chain is walked without a lock and is bounded by count and plausibility checks. |
| PR, INIT | `$DU,PRTS` and `$DI` issued through SVC 34; the answer is parsed from the master trace table. Every display leaves the command in the log (#46). |
| `/` commands, actions | SVC 34 (`op_command`) for JES2 and MVS commands. Purge goes to JES2 as a request that needs the authorized state. |

## Session state and profile

The `DLG` struct in `isfisp.c` carries everything for one SDSF session: screen size, the current panel, the command line, the scroll amount, FIND's last string, the RETRIEVE stack (10 commands), PREFIX, DEST, the ACTION setting, the open PRINT file. These are kept in the ISPF profile of ISF:

| Variable | What |
|---|---|
| `ISFS` | the scroll amount |
| `ISFFND` | the last FIND string |
| `ISFACT` | the ACTION setting, as four hex digits |
| `ISFPFX` | PREFIX |
| `ISFDST` | DEST |

## Dependencies

- `cc370` 1.6.3, `libc370` 2.29.0, `mbt` 3.2 (pinned in `mbt.toml`).
- libc370 gives the JES2 checkpoint and spool access (`mvs/jes2.h`), the master trace table (`mvs/mtt.h`), RAKF checks (`racf_auth`), the authorization through SVC 244 (`__autask`), dynamic allocation, and the control block mappings (`ibm/mvs/*`, `ibm/jes2/*`).
- At runtime: JES2 4.1, Wally ISPF, RAKF.
