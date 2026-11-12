# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [1.2.0] - 2026-11-14

The first release of SDSF: a spool and system display facility for MVS 3.8j
under Wally ISPF, modeled after the behaviour of IBM SDSF V1R2. It is
installed with SMP 4 under FMID `TISF120`. It was preceded by a beta, 0.9.0
(`TISF090`), which 1.2.0 does not upgrade: remove the beta first, as
`uninstall.md` describes, then install 1.2.0.

Built with **CC/370 (cc370) 1.6.3**, **LIBC/370 (libc370) 2.29.0** and
**MBT (mbt) 3.2**.

### Requires

- MVS 3.8j with JES2 4.1 and Wally ISPF, as on TK5 and MVS/CE.
- RAKF for the authorization of other users' jobs and of the system.
- An IPL with CLPA after the installation, for the SVC routine in the LPA.

### Added

- **Panels:** Status (`ST`), Display Active (`DA`), Input Queue (`I`),
  Output Queue (`O`), Held Output (`H`), Printers (`PR`), Initiators
  (`INIT`) and the system log (`LOG`), with the outstanding replies at the
  end of the log (`ACTION`). From a job: its data sets (`?`) and its output
  (`S`).
- **Action characters** in the NP column: display, list, cancel, purge,
  hold, release and more on jobs; start, stop, interrupt, restart and
  the other printer and initiator actions. Most go to JES2 as commands.
- **Overtyping** of list fields: priority, class and destination of a job;
  forms, classes, separator, FCB and destination of a printer; the classes
  of an initiator; the performance group of an address space.
- **Commands:** `FIND` with its options and Repeat-FIND, `LOCATE`, `TOP`,
  `BOTTOM`, the scroll commands, `SET HEX`, `COLS`, `PRINT`, `PREFIX`,
  `DEST`, `SYSID`, `INPUT`, `WHO`, `RETRIEVE`, `/` for operator commands
  and `TSO` for TSO commands.
- **Help and tutorial:** the Help key or `HELP` on every panel, with an
  index and a table of contents, and `TUTOR`, a tutorial in seven parts.
- **Authorization through RAKF:** your own jobs always; other users' jobs
  through the class `JESSPOOL`; the system through the FACILITY profile
  `SDSF.OPER`.
- **An SVC routine of its own,** `IGX00011` (SVC 109, code 11) in the LPA,
  for the few functions that need an authorized program. It serves only
  SDSF loaded from an APF-authorized library. Without it, SDSF falls back to
  SVC 244.
- **SMP 4 package:** the load module, the panels and the CLIST as SMP
  elements, `IGX00011` as source assembled and linked into `SYS1.LPALIB` by
  the installation job. `installation.md` and `uninstall.md` come with it.
- **Books** (draft): *SDSF User's Guide* (ML11-0001) and *SDSF Reference*
  (ML11-0002), as PDF with the release.

### Known limitations

- Overtyping SUCS on the Printer panel is not offered yet (#15).
- Special local routes `Un` show as `Rn` (#16).
- `?` on the Output Queue panel has no alternative columns yet (#9).
- `&` (repeat a command every n seconds), `TRACE` and `ABEND` are not
  there yet (#23, #8).

[Unreleased]: https://github.com/mvslovers/sdsf/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/mvslovers/sdsf/releases/tag/v1.2.0
