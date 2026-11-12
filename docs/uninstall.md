# Removing SDSF

This removes SDSF 1.2.0 (FMID `TISF120`) from an MVS 3.8j system. It
deletes the SMP inventory entries, then the data sets and the SVC routine in
the LPA, and then the system changes the installation made. The last part
removes the beta 0.9.0 (`TISF090`), which has to go before 1.2.0 is
installed.

## Why UCLIN and not RESTORE or REJECT

The accept job accepts `TISF120` into the distribution zone, and SMP refuses
both RESTORE and REJECT for a function that is accepted. `UCLIN` edits the
inventory directly. It is the only way back.

## 1. Free the inventory entries

Submit the jobs of this document under a user with update access to
`SYS1.SMPCDS` and `SYS1.SMPACDS`, from TSO with `SUBMIT`, which puts the
user's id into the job. Through the card reader a job runs without a user,
and RAKF then refuses the SMP data sets (`ABEND S913`).

Delete the entries of the **elements**, not only the SYSMOD. SMP records
which SYSMOD owns an element by its name (`MOD(ISFISP)`, `MAC(ISFMENU)`). If
an element entry is left behind, a later installation of the same element
reports `NOT SEL` and copies nothing, at RC 00.

Each zone needs its own block. `CDS` is the target zone, `ACDS` the
distribution zone. A load module (`LMOD`) has an entry only in the CDS:
`DEL LMOD` under `UCLIN ACDS` is refused with `HMA2762 ILLEGAL UPDATE
REQUEST ON SMPACDS LIBRARY` and ends the job with RC 08.

`TISF120` owns two modules, the CLIST `SDSF` and the 82 panels:

```jcl
//ISFUCL   JOB (SYS),'SDSF UNINSTALL',CLASS=A,MSGCLASS=H,
//             MSGLEVEL=(1,1)
//UCLIN   EXEC SMPAPP
//SMPCNTL  DD  *
 UCLIN CDS .
  DEL SYSMOD(TISF120) .
  DEL MOD(ISFISP) .
  DEL MOD(IGX00011) .
  DEL LMOD(ISFISP) .
  DEL LMOD(IGX00011) .
  DEL MAC(SDSF) .
  DEL MAC(ISFHAUT2) .
  DEL MAC(ISFHAUTH) .
  DEL MAC(ISFHDA) .
  DEL MAC(ISFHDAA) .
  DEL MAC(ISFHDAC) .
  DEL MAC(ISFHDAF) .
  DEL MAC(ISFHDAF2) .
  DEL MAC(ISFHHELP) .
  DEL MAC(ISFHHQ) .
  DEL MAC(ISFHHQC) .
  DEL MAC(ISFHHQF) .
  DEL MAC(ISFHIQ) .
  DEL MAC(ISFHIQA) .
  DEL MAC(ISFHIQC) .
  DEL MAC(ISFHIQF) .
  DEL MAC(ISFHIQO) .
  DEL MAC(ISFHIT) .
  DEL MAC(ISFHJD) .
  DEL MAC(ISFHLG) .
  DEL MAC(ISFHLGM) .
  DEL MAC(ISFHLSM) .
  DEL MAC(ISFHMN) .
  DEL MAC(ISFHMS1) .
  DEL MAC(ISFHMS2) .
  DEL MAC(ISFHMS3) .
  DEL MAC(ISFHMS4) .
  DEL MAC(ISFHMS5) .
  DEL MAC(ISFHMS6) .
  DEL MAC(ISFHOD) .
  DEL MAC(ISFHODM) .
  DEL MAC(ISFHOQ) .
  DEL MAC(ISFHOQC) .
  DEL MAC(ISFHOQF) .
  DEL MAC(ISFHPR) .
  DEL MAC(ISFHPRA) .
  DEL MAC(ISFHPRC) .
  DEL MAC(ISFHPRF) .
  DEL MAC(ISFHST) .
  DEL MAC(ISFHSTA) .
  DEL MAC(ISFHSTC) .
  DEL MAC(ISFHSTF) .
  DEL MAC(ISFHSTF2) .
  DEL MAC(ISFHSTM) .
  DEL MAC(ISFHSTO) .
  DEL MAC(ISFHTOC) .
  DEL MAC(ISFKACT) .
  DEL MAC(ISFKALL) .
  DEL MAC(ISFKDEST) .
  DEL MAC(ISFKFIND) .
  DEL MAC(ISFKFND2) .
  DEL MAC(ISFKPRE) .
  DEL MAC(ISFKPRT) .
  DEL MAC(ISFKPRT2) .
  DEL MAC(ISFKSCR) .
  DEL MAC(ISFKSET) .
  DEL MAC(ISFKSL) .
  DEL MAC(ISFKSYS) .
  DEL MAC(ISFKWHO) .
  DEL MAC(ISFLIST) .
  DEL MAC(ISFMENU) .
  DEL MAC(ISFTACT) .
  DEL MAC(ISFTACT2) .
  DEL MAC(ISFTACT3) .
  DEL MAC(ISFTJOB) .
  DEL MAC(ISFTJOB2) .
  DEL MAC(ISFTJOB3) .
  DEL MAC(ISFTLIM) .
  DEL MAC(ISFTLIM2) .
  DEL MAC(ISFTLIM3) .
  DEL MAC(ISFTNAV) .
  DEL MAC(ISFTOUT) .
  DEL MAC(ISFTOUT2) .
  DEL MAC(ISFTOUT3) .
  DEL MAC(ISFTPAN) .
  DEL MAC(ISFTPAN2) .
  DEL MAC(ISFTSUM) .
  DEL MAC(ISFTUTOR) .
  DEL MAC(ISFXA) .
  DEL MAC(ISFXD) .
  DEL MAC(ISFXJ) .
  DEL MAC(ISFXP) .
  DEL MAC(ISFXR) .
 ENDUCL .
 UCLIN ACDS .
  DEL SYSMOD(TISF120) .
  DEL MOD(ISFISP) .
  DEL MOD(IGX00011) .
  DEL MAC(SDSF) .
  DEL MAC(ISFHAUT2) .
  DEL MAC(ISFHAUTH) .
  DEL MAC(ISFHDA) .
  DEL MAC(ISFHDAA) .
  DEL MAC(ISFHDAC) .
  DEL MAC(ISFHDAF) .
  DEL MAC(ISFHDAF2) .
  DEL MAC(ISFHHELP) .
  DEL MAC(ISFHHQ) .
  DEL MAC(ISFHHQC) .
  DEL MAC(ISFHHQF) .
  DEL MAC(ISFHIQ) .
  DEL MAC(ISFHIQA) .
  DEL MAC(ISFHIQC) .
  DEL MAC(ISFHIQF) .
  DEL MAC(ISFHIQO) .
  DEL MAC(ISFHIT) .
  DEL MAC(ISFHJD) .
  DEL MAC(ISFHLG) .
  DEL MAC(ISFHLGM) .
  DEL MAC(ISFHLSM) .
  DEL MAC(ISFHMN) .
  DEL MAC(ISFHMS1) .
  DEL MAC(ISFHMS2) .
  DEL MAC(ISFHMS3) .
  DEL MAC(ISFHMS4) .
  DEL MAC(ISFHMS5) .
  DEL MAC(ISFHMS6) .
  DEL MAC(ISFHOD) .
  DEL MAC(ISFHODM) .
  DEL MAC(ISFHOQ) .
  DEL MAC(ISFHOQC) .
  DEL MAC(ISFHOQF) .
  DEL MAC(ISFHPR) .
  DEL MAC(ISFHPRA) .
  DEL MAC(ISFHPRC) .
  DEL MAC(ISFHPRF) .
  DEL MAC(ISFHST) .
  DEL MAC(ISFHSTA) .
  DEL MAC(ISFHSTC) .
  DEL MAC(ISFHSTF) .
  DEL MAC(ISFHSTF2) .
  DEL MAC(ISFHSTM) .
  DEL MAC(ISFHSTO) .
  DEL MAC(ISFHTOC) .
  DEL MAC(ISFKACT) .
  DEL MAC(ISFKALL) .
  DEL MAC(ISFKDEST) .
  DEL MAC(ISFKFIND) .
  DEL MAC(ISFKFND2) .
  DEL MAC(ISFKPRE) .
  DEL MAC(ISFKPRT) .
  DEL MAC(ISFKPRT2) .
  DEL MAC(ISFKSCR) .
  DEL MAC(ISFKSET) .
  DEL MAC(ISFKSL) .
  DEL MAC(ISFKSYS) .
  DEL MAC(ISFKWHO) .
  DEL MAC(ISFLIST) .
  DEL MAC(ISFMENU) .
  DEL MAC(ISFTACT) .
  DEL MAC(ISFTACT2) .
  DEL MAC(ISFTACT3) .
  DEL MAC(ISFTJOB) .
  DEL MAC(ISFTJOB2) .
  DEL MAC(ISFTJOB3) .
  DEL MAC(ISFTLIM) .
  DEL MAC(ISFTLIM2) .
  DEL MAC(ISFTLIM3) .
  DEL MAC(ISFTNAV) .
  DEL MAC(ISFTOUT) .
  DEL MAC(ISFTOUT2) .
  DEL MAC(ISFTOUT3) .
  DEL MAC(ISFTPAN) .
  DEL MAC(ISFTPAN2) .
  DEL MAC(ISFTSUM) .
  DEL MAC(ISFTUTOR) .
  DEL MAC(ISFXA) .
  DEL MAC(ISFXD) .
  DEL MAC(ISFXJ) .
  DEL MAC(ISFXP) .
  DEL MAC(ISFXR) .
 ENDUCL .
/*
//LIST    EXEC SMPAPP
//SMPCNTL  DD  *
 LIST CDS  SYSMOD(TISF120) .
 LIST ACDS SYSMOD(TISF120) .
 LIST CDS  MOD(IGX00011,ISFISP) .
 LIST ACDS MOD(IGX00011,ISFISP) .
 LIST CDS  LMOD(IGX00011,ISFISP) .
 LIST CDS  MAC(SDSF,ISFMENU) .
 LIST ACDS MAC(SDSF,ISFMENU) .
/*
//
```

Every `DEL` reports `HMA2550 UPDATE COMPLETE` and the UCLIN step ends with
RC 00. The step takes a few minutes for its 174 statements. The `LIST` step
is the check: **RC 04, with every entry reported as not found, means the
inventory is clean.**

## 2. Delete the data sets and the SVC routine

```jcl
//ISFDEL   JOB (SYS),'SDSF DELETE',CLASS=A,MSGCLASS=H,
//             MSGLEVEL=(1,1)
//DELETE  EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE ISF.LINKLIB NONVSAM SCRATCH PURGE
  DELETE ISF.AISFLOAD NONVSAM SCRATCH PURGE
  DELETE ISF.ISFPLIB NONVSAM SCRATCH PURGE
  DELETE ISF.AISFPLIB NONVSAM SCRATCH PURGE
  DELETE ISF.ISFCLST NONVSAM SCRATCH PURGE
  DELETE ISF.AISFCLST NONVSAM SCRATCH PURGE
  DELETE SYS1.LPALIB(IGX00011) NONVSAM
  DELETE SYS1.AOST4(IGX00011) NONVSAM
/*
//
```

Each line reports `IDC0550I ENTRY ... DELETED` for a data set or
`IDC0549I MEMBER IGX00011 DELETED` for a member. Take the logon CLIST
lines out first (step 3), or every logon names data sets that no longer
exist. The copy of
`IGX00011` in the running LPA stays until the next IPL with CLPA.

## 3. Undo the system changes

- Take `ISF.LINKLIB` out of `SYS1.PARMLIB(IEAAPF00)` and
  `SYS1.PARMLIB(LNKLST00)` (installation section 5). An APF entry left
  behind for a deleted library is a risk: a new data set of that name on
  that volume would be authorized.
- Take the two `$CONCAT` lines for `ISF.ISFPLIB` and `ISF.ISFCLST` out of
  the logon CLIST (installation section 7).
- Take the RAKF rules for SDSF out, if you no longer need them
  (installation section 8).
- IPL with CLPA.

## Removing the beta 0.9.0

The beta is not upgraded to 1.2.0. Remove it, then install 1.2.0 as for a
first installation.

`TISF090` owns only the two modules. Its panels and CLIST were not SMP
elements: they were received into `ISF.ISPPLIB` and `ISF.CLIST`. Do not
name any `MAC` in its UCLIN. A `DEL` of an entry that does not exist gives
`HMA2532`, and that stops the rest of the step.

```jcl
//ISFUCL0  JOB (SYS),'SDSF 0.9.0 UNINSTALL',CLASS=A,MSGCLASS=H,
//             MSGLEVEL=(1,1)
//UCLIN   EXEC SMPAPP
//SMPCNTL  DD  *
 UCLIN CDS .
  DEL SYSMOD(TISF090) .
  DEL MOD(ISFISP) .
  DEL MOD(IGX00011) .
  DEL LMOD(ISFISP) .
  DEL LMOD(IGX00011) .
 ENDUCL .
 UCLIN ACDS .
  DEL SYSMOD(TISF090) .
  DEL MOD(ISFISP) .
  DEL MOD(IGX00011) .
 ENDUCL .
/*
//LIST    EXEC SMPAPP
//SMPCNTL  DD  *
 LIST CDS  SYSMOD(TISF090) .
 LIST ACDS SYSMOD(TISF090) .
 LIST CDS  MOD(IGX00011,ISFISP) .
 LIST ACDS MOD(IGX00011,ISFISP) .
 LIST CDS  LMOD(IGX00011,ISFISP) .
/*
//
//ISFDEL0  JOB (SYS),'SDSF 0.9.0 DELETE',CLASS=A,MSGCLASS=H,
//             MSGLEVEL=(1,1)
//DELETE  EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE ISF.LINKLIB NONVSAM SCRATCH PURGE
  DELETE ISF.AISFLOAD NONVSAM SCRATCH PURGE
  DELETE ISF.ISPPLIB NONVSAM SCRATCH PURGE
  DELETE ISF.CLIST NONVSAM SCRATCH PURGE
  DELETE SYS1.LPALIB(IGX00011) NONVSAM
/*
//
```

The `LIST` step ends with RC 04 when nothing of `TISF090` is left. The
0.9.0 job `isflpa.jcl` copied `IGX00011` into `SYS1.LPALIB` by hand.
Deleting it there lets the installation of 1.2.0 link the module afresh. If
the old copy is left, SMP includes it in the link, and the result is not
marked refreshable.

What stays:

- The lines for `ISF.LINKLIB` in `IEAAPF00` and `LNKLST00` stay; 1.2.0 uses
  the same library.
- The logon CLIST lines for `ISF.ISPPLIB` and `ISF.CLIST` must change to
  `ISF.ISFPLIB` and `ISF.ISFCLST` (installation section 7), since the old
  data sets are gone.

The IPL with CLPA of the 1.2.0 installation follows anyway.
