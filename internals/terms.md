# Terms

The words SDSF's help panels, the tutorial and the manuals (ML11-0001
User's Guide, ML11-0002 Reference) use for the same things. The help says
what a thing is; a book may explain more, but it uses these words and must
not contradict the help. Add a term here in the PR that first needs it.

Spelling: names that appear on the screen keep the screen's spelling
(`JOBNAME`, `SDSF STATUS DISPLAY`); commands are upper case (`ST`,
`PREFIX`); keys are named by their command first, the default key after:
"the End key (PF3)".

## The product

| Term | Means | Not |
|---|---|---|
| SDSF | this product, the SDSF clone for MVS 3.8j (repo `sdsf`) | IBM's SDSF, which is "IBM's SDSF V1R2" where it must be named |
| Wally ISPF | the ISPF of MVS 3.8j systems, ISPF 2.2 by Wally Mclaughlin | "ISPF" alone where the difference to IBM's ISPF matters |

## Panels

A **panel** is one screen of SDSF. The panels and the command that shows
each:

| Panel (in prose) | Title on the screen | Command |
|---|---|---|
| the primary option menu | `SDSF PRIMARY OPTION MENU` | (start of SDSF) |
| the Status panel | `SDSF STATUS DISPLAY ...` | `ST` |
| the DA panel (active address spaces) | `SDSF DA ...` | `DA` |
| the Input Queue panel | `SDSF INPUT QUEUE DISPLAY ...` | `I` |
| the Output Queue panel | `SDSF OUTPUT ...` | `O` |
| the Held Output panel | `SDSF HELD OUTPUT DISPLAY ...` | `H` |
| the Printer panel | `SDSF PRINTER DISPLAY` | `PR` |
| the Initiator panel | `SDSF INITIATOR DISPLAY` | `INIT` |
| the system log, the SYSLOG panel | `SDSF SYSLOG ...` | `LOG` |
| the Job Data Set panel | `SDSF JOB DATA SET DISPLAY - ...` | `?` on a job |
| the Output Data Set panel | `SDSF OUTPUT DISPLAY ...` | `S` on a job or a data set |

- **the list panels**: ST, DA, I, O, H, PR and INIT, the panels with a row
  per job, address space, printer or initiator.
- **the command line**: the field after `COMMAND INPUT ===>`.
- **the SCROLL field**: the field after `SCROLL ===>`; its value is the
  **scroll amount** (`PAGE`, `HALF`, `CSR`, `DATA`, a number, `MAX`).
- **the title line**: the first line of a panel; messages appear on it, on
  the right.

## On a list panel

- **job**: a batch job, a started task or a TSO user, when the text does not
  need to tell them apart; otherwise **batch job** (TYPE `JOB`), **started
  task** (`STC`), **TSO user** (`TSU`).
- **the NP column**: the first column of a row, where action characters are
  typed.
- **action character**: a character (or two) typed in the NP column that
  acts on that row: `?`, `S`, `P`, `D`, `L`, `C`, `CD`, `A`, `H`, `E`, `O` on
  ST. Not "line command", not "prefix command".
- **overtype**: type a new value over a field of a row and press Enter;
  such a field is an **overtypeable field** (on ST: `PRTY`, `DEST`).
- **field** (of a row) and **column** (of the panel) are the same thing seen
  from the row or from the panel; the help says "field".
- **the further fields**: what `?` typed alone on the command line of ST and
  I shows in place of the usual fields.
- The columns' names are the headings on the screen (`JOBNAME`, `JNUM`,
  `PRTY`, `QUEUE`, ...). Each panel's help lists and explains them; the
  Status panel's are in `ispplib/isfhstf` and `ispplib/isfhstf2`.

## Commands

- **command**: what is typed on the command line. **SDSF command**: one of
  SDSF's (`ST`, `PREFIX`, `FIND`, ...).
- **operator command**: an MVS or JES2 command given with `/` (`/D A,L`).
- **TSO command**: a TSO command, CLIST or program given with `TSO`.
- **JES2 command**: the command an action character or an overtype makes
  SDSF give to JES2 (`$CJ1234`). The help names it in parentheses.

## Who may see and do what

- **RAKF**: the security product the authorization asks; the help says RAKF,
  not "the security product", since there is no other on MVS 3.8j.
- **read access** / **update access** to a job: RAKF's READ and UPDATE on the
  job's entity in class `JESSPOOL`, `<owner>.<jobname>.<jobid>`.
- **your own jobs**: the jobs that run under your user id; always visible,
  every action allowed.
- **SDSF.OPER**: the FACILITY profile for the system's side (the log,
  printers, initiators, `/` commands). READ and UPDATE as above.
- The messages on the screen are quoted exactly: `NOT AUTHORIZED FOR JOB`,
  `COMMAND NOT AUTHORIZED`.

## Help and tutorial

- **the help**: the help panels, reached with the Help key (PF1) or `HELP`.
- **the tutorial**: the course started with `TUTOR`; its sections are
  **parts**. Not "tutor" in prose.
- **topic**: one subject of a help panel that lists several, chosen by its
  number.
- **the contents**: the help's table of contents (`ISFHTOC`), shown by `T`.
- **the index**: `I`.
- Keys: **Enter**, **the Help key (PF1)**, **the End key (PF3)**, **the Up
  key (PF7)**, **the Down key (PF8)**, **the Left key (PF10)**, **the Right
  key (PF11)**. The defaults of ISPF; a user may have moved them.

Panel names: `ISFH*` help, `ISFK*` help for commands, `ISFX*` index,
`ISFT*` tutorial (`src/isfhelp.c`).

## The package and the installation

- **the package**: the files of a release that install SDSF (the SMP package:
  three TRANSMIT files, the allocation, installation and accept jobs,
  `README.md`, `uninstall.md`). Not "the distribution", which is SMP's word
  for a library.
- **target library**: where SMP installs a member (`ISF.LINKLIB`,
  `ISF.ISFPLIB`, `ISF.ISFCLST`); **distribution library**: where ACCEPT keeps
  it (`ISF.AISFLOAD`, `ISF.AISFPLIB`, `ISF.AISFCLST`); **staging library**:
  the members as received, for SMP to read (`ISF.ISFLOAD`, `ISF.TISFPLIB`,
  `ISF.TISFCLST`), deleted by the accept job.
- **element**: a member that SMP installs by name: the load modules and,
  as macros (`++MAC`), the panels and the CLIST. SMP's word.
- **the SVC routine**: `IGX00011`, SDSF's own extended SVC routine (SVC 109,
  code 11), linked by SMP into `SYS1.LPALIB`. The help says "an SVC routine
  of its own".
- **FMID**: the SYSMOD's identifier (`TISF120` for 1.2.0), the word of SMP.
- **the beta**: version 0.9.0 (`TISF090`). There is no upgrade from it: it is
  removed first, then 1.2.0 is installed as a first installation.
