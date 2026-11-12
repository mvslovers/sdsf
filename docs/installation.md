# Installing SDSF

SDSF is a spool and system display facility for MVS 3.8j under ISPF, after
the panels and behaviour of IBM's SDSF V1R2. It comes as an **SMP
Release 4** package, for the SMP that ships with MVS 3.8j (not SMP/E).

This guide is for **1.2.0**, FMID **`TISF120`**. The SMP installation was
tested on fresh TK5 and MVS/CE systems, and the system changes, the IPL and
the start of SDSF on MVS/CE. Removing SDSF, and the beta 0.9.0 before it, is
described in `uninstall.md`.

## Read this first

- **The installation needs an IPL with CLPA** and changes three members of
  the system: `SYS1.PARMLIB(IEAAPF00)`, `SYS1.PARMLIB(LNKLST00)` and
  `SYS1.LPALIB`. SDSF runs its authorized functions through an SVC routine
  of its own in the LPA, not through SVC 244 (section "How SDSF gets its
  authority").
- **Remove an earlier preview first.** The previews of TK5 put SDSF into
  `SYS2.SDSF.LOAD`, its panels `ISFMENU` and `ISFLIST` into `SYS2.ISP.PLIB`
  and its CLIST `SDSF` into `SYS2.CMDPROC`. Delete them where they exist.
  Otherwise the old CLIST and panels are found before the new ones.
- **There is no upgrade from the beta 0.9.0.** Remove it first, as
  `uninstall.md` describes under "Removing the beta 0.9.0", then install
  1.2.0 as for a first installation.
- **`ISF.LINKLIB` must not be in ISPLLIB**, nor in a STEPLIB that is not
  all APF-authorized. A program from there is not loaded as authorized, and
  SDSF then falls back to SVC 244.

## What is in the package

| File | What it is |
|---|---|
| `sdsf-1.2.0-load.xmit` | the load module `ISFISP` (SDSF) |
| `sdsf-1.2.0-isfplib.xmit` | the panels: `ISFMENU`, `ISFLIST`, and the help and tutorial panels (`ISFH*`, `ISFK*`, `ISFT*`, `ISFX*`), SMP elements (`++MAC`) |
| `sdsf-1.2.0-isfclst.xmit` | the CLIST `SDSF`, an SMP element (`++MAC`) |
| `sdsf-1.2.0-alloc.jcl` | the allocation job |
| `sdsf-1.2.0-inst.jcl` | the installation job: RECEIVE, the source of the SVC routine `IGX00011` and its assembly, APPLY CHECK, APPLY |
| `sdsf-1.2.0-accept.jcl` | the accept job |
| `README.md` | this guide |
| `uninstall.md` | how to remove SDSF, and the beta 0.9.0 before installing 1.2.0 |

The installation makes these data sets:

| Data set | Holds | Made by |
|---|---|---|
| `ISF.LINKLIB` | `ISFISP` (target library, ddname `ISFLINK`) | allocation job, SMP |
| `ISF.AISFLOAD` | the same (distribution library, ddname `AISFLOAD`) | allocation job, SMP |
| `SYS1.LPALIB` | `IGX00011`, linked there by SMP (ddname `LPALIB`) | SMP |
| `SYS1.AOST4` | `IGX00011` (IBM's distribution library for the LPA) | SMP |
| `ISF.ISFPLIB` | `ISFMENU`, `ISFLIST`, the help and tutorial panels (target library, ddname `ISFPLIB`) | allocation job, SMP |
| `ISF.AISFPLIB` | the same (distribution library, ddname `AISFPLIB`) | allocation job, SMP |
| `ISF.ISFCLST` | `SDSF` (target library, ddname `ISFCLST`) | allocation job, SMP |
| `ISF.AISFCLST` | the same (distribution library, ddname `AISFCLST`) | allocation job, SMP |
| `ISF.ISFLOAD`, `ISF.TISFPLIB`, `ISF.TISFCLST` | staging libraries: what the `.xmit` files hold, for SMP to read | installation job; deleted by the accept job |

## 1. Upload

Upload the three `.xmit` files **in binary** to sequential data sets with
`RECFM=FB,LRECL=80,BLKSIZE=3120`, under any names. Each qualifier can be at
most 8 characters long. With the IND$FILE file transfer of x3270 or wc3270,
choose binary, no CR/LF translation, fixed records, record length 80 and
block size 3120. Note the names: the installation job asks for them.

| File | For example | Name in the installation job |
|---|---|---|
| `sdsf-1.2.0-load.xmit` | `HERC01.ISFLOAD.XMIT` | `CHANGE.ME.ISFLOAD` |
| `sdsf-1.2.0-isfplib.xmit` | `HERC01.ISFPLIB.XMIT` | `CHANGE.ME.TISFPLIB` |
| `sdsf-1.2.0-isfclst.xmit` | `HERC01.ISFCLST.XMIT` | `CHANGE.ME.TISFCLST` |

The jobs are text: upload them as text, or paste them into an edit session.

## 2. Allocate

`sdsf-1.2.0-alloc.jcl` allocates the target and distribution libraries of
the table above. The volumes are the two symbolic parameters on its `PROC`
statement:

- `TGTVOL`: the volume of the target libraries. The APF entry in step 5
  names it for `ISF.LINKLIB`.
- `DLBVOL`: the volume of the distribution library.

The defaults are those of MVS/CE (`MVSRES`, `SMP000`). On TK5 write
`TGTVOL=TK5RES,DLBVOL=TK5DLB`. Submit the job.

The job allocates only once: if a library is already cataloged, step
`CHECK` ends with condition code 8 and nothing is allocated.

## 3. Install

In `sdsf-1.2.0-inst.jcl`, replace each `CHANGE.ME.*` with the name you
uploaded that file to (table in step 1). Leave the `VOLUME` lines commented
out: the RECEIVE steps put the staging libraries on a work volume by
themselves (`PUB000` on a stock MVS/CE). Only if a RECEIVE step fails for
want of space or of a volume, take the comment marks off its `VOLUME` line
and name one. Submit the job.

The steps up to `APPLYCHK` end with condition code 0000. On a first run the
output of step `DELOLD` says `IDC0551I ** ENTRY ISF.ISFLOAD NOT DELETED` and
`HIGHEST CONDITION CODE WAS 8`: it deletes a staging library left from an
earlier run, and there is none; the step still ends 0000. `ASSEM`, the
assembly of `IGX00011`, says `NO STATEMENTS FLAGGED`. `APPLY` ends with
0004: SMP links `IGX00011` into `SYS1.LPALIB` and first tries to include the
module that is there, which a first installation does not have (`HMA2391
LINK SUCCESSFUL ... RETURN CODE=08`, `IEW0342`). A return code says only
that a step ran, so check the work:

- the output of step `APPLY` has `HMA2380 COPY SUCCESSFUL - MOD=ISFISP -
  LMOD=ISFISP - LIBRARY=ISFLINK` and `HMA2391 LINK SUCCESSFUL` for
  `IGX00011` into `LPALIB`;
- `SYS1.LPALIB` has the member `IGX00011`;
- `ISF.LINKLIB` has the member `ISFISP` (and no `IGX00011`), `ISF.ISFPLIB` has
  `ISFLIST`, `ISFMENU` and the help panels (`ISFHTOC` among them, 82 in
  all), and `ISF.ISFCLST` has `SDSF`.

Then submit `sdsf-1.2.0-accept.jcl`. It accepts `TISF120` into the
distribution libraries and deletes the staging libraries. It ends with 0004
for the same reason (`HMA2471 BLDL FAILED IN LIBRARY AOST4` before
`IGX00011` is first put there). Check that `ISF.AISFLOAD` has `ISFISP`,
`SYS1.AOST4` has `IGX00011`, `ISF.AISFPLIB` the panels and `ISF.AISFCLST`
the CLIST.

A `LIST` shows the result in the SMP inventory:

```
//LIST     EXEC SMPAPP
//SMPCNTL  DD  *
 LIST CDS SYSMOD(TISF120) .
/*
```

It shows `STATUS = REC APP ACC`.

## 4. The SVC routine in the LPA

Nothing to do: SMP put `IGX00011` into `SYS1.LPALIB` in step 3. It takes
effect at the IPL with CLPA of step 6.

## 5. APF and the link list

`ISF.LINKLIB` must be APF-authorized and in the link list, so that ISPF
loads SDSF from there as authorized.

**`SYS1.PARMLIB(IEAAPF00)`**: add a line with the data set name **and the
volume** (`TGTVOL` of step 2). An entry for the same name on another volume
does not authorize this library. Put a comma after the line before it; the
last line has none. On TK5:

```
 EXH.ESPLIB TK5002,
 ISF.LINKLIB TK5RES
```

**`SYS1.PARMLIB(LNKLST00)`**: add the library at the end, again with a
comma after the line before it:

```
 SYS2.DSSLIB,
 ISF.LINKLIB
```

On MVS/CE the lines of both members end in a comment. The comma goes
directly after the entry, before the comment:

```
 SYSC.LINKLIB SYSCPK,         COMPILER/TOOLS VOLUME
 ISF.LINKLIB MVSRES
```

```
SYS2.CMDLIB,                USER TSO COMMAND LIBRARY
ISF.LINKLIB
```

## 6. IPL with CLPA

Both members and the LPA are read at IPL. IPL with CLPA:

- on TK5, `IEASYS00` already says `CLPA`, so any IPL loads the LPA again;
- on MVS/CE, Hercules answers the prompt `IEA101A SPECIFY SYSTEM
  PARAMETERS` by itself, so there is no chance to type `CLPA`. Put `CLPA,`
  into `SYS1.PARMLIB(IEASYS00)` (for example after the `BLDLF` line), IPL,
  and take it out again afterwards. This IPL also shows `IEA357I ERRORS IN
  IEAPAK00 LIST` for seven IBM modules; that is MVS/CE's own and has nothing
  to do with SDSF;
- elsewhere, answer `IEA101A` with `R 00,CLPA`, or put `CLPA,` into
  `IEASYS00` for this one IPL.

## 7. Panels and CLIST for ISPF

Put `ISF.ISFPLIB` into the ISPPLIB concatenation and `ISF.ISFCLST` into
SYSPROC. Where you do it depends on how the system starts ISPF. On TK5, the
CLIST `SYS1.CMDPROC(ISPLOGON)` builds the concatenations for every user with
the REXX exec `$CONCAT`. Add two lines after the others there:

```
      RX $CONCAT ISPPLIB ISF.ISFPLIB BOT
      RX $CONCAT SYSPROC ISF.ISFCLST BOT
```

On MVS/CE, ISPF builds ISPPLIB in the CLIST `SYS1.CMDPROC(ISPF)`. Add the
library to its `ALLOC`:

```
ALLOC F(ISPPLIB) DA('SYSGEN.ISPF.PLIB','SYSGEN.ISPF.RFEPLIB', +
               'ISF.ISFPLIB') SHR
```

SYSPROC comes from the logon procedure `SYS1.PROCLIB(IKJACCNT)`. Add a line
after `SYS2.CMDPROC`:

```
//SYSPROC  DD  DISP=SHR,DSN=SYS1.CMDPROC
//         DD  DISP=SHR,DSN=SYS2.CMDPROC
//         DD  DISP=SHR,DSN=ISF.ISFCLST
```

Do not add it to the `ALLOC FILE(SYSPROC)` of `SYS1.CMDPROC(TSOLOGON)`:
SYSPROC is allocated already, and that `ALLOC` fails without a message
(`TSO SDSF` then says `COMMAND SDSF NOT FOUND`).

The changes take effect at the next logon.

## 8. Authorization

SDSF asks RAKF. There are two kinds of rule.

**Jobs.** Everyone sees and handles their own jobs.

- A batch job is the user's own when its job card has the user's id in
  `USER=`. TSO `SUBMIT` puts it there on TK5.
- A TSO session is the user's own when its name is the user's id.
- A job without an owner, submitted without `USER=`, counts as the user's
  own when its name begins with the user's id.

Other users' jobs need a profile in the RAKF class `JESSPOOL`, the same one
FTPD uses. SDSF asks for the entity `<owner>.<jobname>.<jobid>`, for example
`HERC01.PAYROLL.JOB00046`.

| Access to the entity | SDSF |
|---|---|
| none, or no profile | the job is not on the lists |
| READ | the job is on the lists, its output can be browsed, and `D` and `L` work |
| UPDATE | every action that changes the job also works (`C`, `P`, `H`, `A`, ...) |

**The system.** The FACILITY profile `SDSF.OPER` controls access to it.

| Access | SDSF |
|---|---|
| none | no LOG, PR, INIT or `/`: SDSF says `COMMAND NOT AUTHORIZED` or `NOT AUTHORIZED FOR CMD`. DA shows only the address spaces of the user's own jobs |
| READ | the LOG with the outstanding replies, PR and INIT, and `D` on printers and initiators. DA also shows the system's address spaces |
| UPDATE | also the other actions on printers and initiators, and `/` operator commands |

On TK5 and MVS/CE, RAKF reads its profiles from `SYS1.SECURE.CNTL(PROFILES)`, kept in
sort order. The class goes in columns 1-8, the profile from column 9, the
group from column 53 and the access from column 61. For each profile, the
line without a group comes first:

```
FACILITYSDSF.OPER                                           NONE
FACILITYSDSF.OPER                                   ADMIN   UPDATE
JESSPOOL*                                                   NONE
JESSPOOL*                                           ADMIN   UPDATE
```

With these lines every user sees their own jobs, and the group ADMIN sees
and handles all jobs, the log, the printers and the initiators. Give `READ`
instead of `NONE` in a line without a group to let everyone see. Then
`S RAKFPROF` reloads the profiles.

## 9. Start and check

From any ISPF command line:

```
TSO SDSF
```

Check the SVC routine as a user who has UPDATE on `SDSF.OPER` (a `/`
command needs UPDATE) but no access to `FACILITY SVC244`. If `LOG` shows the
system log and `/D T` brings back the time (`IEE136I`), SDSF is using its
own SVC routine. Take a user of a group without access to `SVC244`: on a
stock MVS/CE the group ADMIN has READ on it (`FACILITYSVC244 ... ADMIN READ`
in the RAKF profiles), so an ADMIN user would pass the check without
`IGX00011`. Give that user's group UPDATE on `SDSF.OPER` with a line of its
own for the check.

## How SDSF gets its authority

Reading the system log, the outstanding replies and the printers, and
giving operator commands, all need an authorized program. SDSF runs
unauthorized and switches only around those few places, through
`IGX00011`. This is an extended SVC routine: SVC 109 with code 11.

`IGX00011` grants the switch only to a program whose name begins with `ISF`
and that was loaded from an APF-authorized library or the LPA. Every other
`ISF*` module of the task must come from such a library too. Who may see
and do what is decided by SDSF itself, with the RAKF rules above.

If `IGX00011` is not installed, SDSF uses SVC 244 for the same functions,
as the previews did. Then only users with READ on `FACILITY SVC244` can use
them.

## Remove

`uninstall.md` gives the jobs: an SMP `UCLIN` for `TISF120` and its
elements in both zones, the deletion of the data sets and of `IGX00011` in
`SYS1.LPALIB` and `SYS1.AOST4`, and the system changes to take back.
