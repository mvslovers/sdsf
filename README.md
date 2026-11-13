# SDSF for MVS 3.8j

A spool and system display facility for **MVS 3.8j** under **ISPF**: browse
the JES2 queues, read job output and the system log, see what runs, and act
on jobs, printers and initiators from one set of panels. It is written in C,
modeled after the behaviour of IBM SDSF V1R2.

> SDSF is an independent implementation. It contains no IBM code. The
> panels, the help and the documentation are written from scratch. IBM, MVS
> and SDSF are trademarks of International Business Machines Corporation.

| | |
|---|---|
| **Runs on** | MVS 3.8j with JES2 and Wally ISPF, such as TK5 and MVS/CE |
| **Security** | RAKF: JESSPOOL for jobs, the FACILITY profile `SDSF.OPER` for the system |
| **Package** | SMP 4, FMID `TISF120` for 1.2.0 |
| **Status** | 1.2.0, released 2026-11-13: [download](https://github.com/mvslovers/sdsf/releases/latest) |

## Panels

| Command | Panel | Shows |
|---|---|---|
| `DA` | Display Active | the address spaces by ASID: job and step names, type, class, position, priorities, real frames, CPU% and SIO, EXCP count, CPU time, swap reason |
| `I` | Input Queue | the jobs waiting to run, by class (`IAB`), `$` for TSO users, `#` for started tasks |
| `O` | Output Queue | the output waiting to print, by class and form |
| `H` | Held Output | the held output, one row per job, by class |
| `ST` | Status | all jobs of the JES2 queues, by name (`*` and `%`), class and prefix |
| `PR` | Printers | the JES2 printers and what they are doing |
| `INIT` | Initiators | the JES2 initiators and their classes |
| `LOG` | System Log | the log, with the outstanding replies at its end (`ACTION`) |

From any list, `?` opens the job's data sets and `S` its output. The output
and the log are shown one line per record, as IBM's SDSF does.

## What you can do

- **Act on jobs, printers and initiators** with action characters in the NP
  column: display, list, cancel, purge, hold, release, route, start,
  stop, interrupt, and more, depending on the panel. Most go to JES2 as
  commands and stay in the system log.
- **Overtype fields** on a list to change them: priority, class and
  destination of a job, the forms, classes and settings of a printer, the
  classes of an initiator, the performance group of an address space.
- **Search** output and the log with `FIND` (`NEXT`, `PREV`, `FIRST`,
  `LAST`, `ALL`, `WORD`, `PREFIX`, `SUFFIX`, `X'..'`, columns) and Repeat-FIND
  on PF5. Move with `LOCATE`, `TOP`, `BOTTOM`, the scroll keys, `LEFT` and
  `RIGHT`; `SET HEX ON`, `COLS`, `NEXT`/`PREV` between the data sets of a
  job.
- **Print** output to a data set or SYSOUT class with `PRINT`.
- **Give commands** from every panel: `/` followed by an operator command,
  `TSO` followed by a TSO command, CLIST or program, `PREFIX`, `DEST`,
  `SYSID`, `WHO`, `RETRIEVE`.
- **Get help**: the Help key or `HELP` shows the help of the panel you are
  on, with an index and a table of contents. `TUTOR` starts a tutorial in
  seven parts, with sample panels to try things on.

## Who may see and do what

SDSF asks RAKF:

- **Your own jobs** are always on the lists, and every action on them is
  allowed.
- **Other users' jobs** need a profile in the class `JESSPOOL`, entity
  `<owner>.<jobname>.<jobid>`. READ shows the job and its output, UPDATE
  allows the actions that change it.
- **The system** needs the FACILITY profile `SDSF.OPER`. READ shows the log,
  the printers, the initiators and the system's address spaces. UPDATE also
  allows actions on printers and initiators, and `/` operator commands.

The functions that need an authorized program (purge, operator commands,
the outstanding replies) go through an SVC routine of SDSF's own,
`IGX00011`, an extended SVC routine (SVC 109, code 11) in the LPA. It serves
only SDSF, loaded from an APF-authorized library. Where it is not
installed, SDSF falls back to SVC 244.

The installation guide gives the RAKF profile lines.

## Install

SDSF is installed with SMP 4 from its release package. The package holds
the load module, the panels, the CLIST, the jobs and two guides:

- [`docs/installation.md`](docs/installation.md): allocation, RECEIVE,
  APPLY and ACCEPT, the system changes (APF, link list, IPL with CLPA), the
  ISPF set-up, RAKF, and a check that it works. It covers TK5 and MVS/CE.
- [`docs/uninstall.md`](docs/uninstall.md): removing SDSF.

## Documentation

Two books come with 1.2.0, as PDF with the
[release](https://github.com/mvslovers/sdsf/releases/latest) and
[online](https://mvslovers.readthedocs.io/projects/sdsf/); the source is in
`docs/books/`:

- **ML11-0001**, *SDSF User's Guide*: how to use the panels, from the first
  logon to the commands of every day.
- **ML11-0002**, *SDSF Reference*: every panel, command, action character
  and message, the authorization rules, and the differences from IBM's
  SDSF V1R2.

## Building

SDSF is built with [mbt](https://github.com/mvslovers/mbt) 3.2 or later,
CC/370 (cc370) and LIBC/370 (libc370):

```
mbt build              build the load modules
mbt deploy             put them into ISF.DEV.LINKLIB on the target system
mbt run panels         put the panels of ispplib/ into ISF.DEV.ISPPLIB
mbt package            build the SMP package into dist/
mbt test --tso         run the interactive tests over TN3270
```

The tests in `test/tso/` drive SDSF over TN3270 on a system with the dialog
installed. `mbt/init.lua` submits the jobs some tests need and answers
their replies afterwards; those jobs are in `test/jcl/`. The test tools
(`ISFWAIT`, `ISFWTOR`, `ISFSVCT`, `ISFJOWN`) are built and deployed but not
shipped.
