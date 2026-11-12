#import "../bookmaster/bookmaster.typ": *

= Installing and Removing SDSF <ug-install>

#idx("installation")#idx("removal")
This chapter is for the system programmer. It takes you through the
installation of SDSF 1.2.0, tells you how to check that SDSF really runs and
not only that the jobs ended, takes you through the removal, and lists what
usually goes wrong. It is the short way. What each data set and member is for,
what SMP records and what the SVC routine checks are described in the _SDSF
Reference_, in Appendix B, "Data Sets and Members of the Package", and in
Appendix C, "The SVC Routine".

SDSF comes as an *SMP Release 4* package, for the SMP that ships with MVS
3.8j (not SMP/E). Its identifier, the FMID, is #cmd("TISF120"). The
installation of the package was run through on TK5 and on MVS/CE. The system
changes, the IPL and the start of SDSF were run on MVS/CE.

The package is the archive of a release of SDSF on GitHub. It holds three
TRANSMIT files (#cmd("sdsf-1.2.0-load.xmit"), #cmd("sdsf-1.2.0-isfplib.xmit")
and #cmd("sdsf-1.2.0-isfclst.xmit")), three jobs
(#cmd("sdsf-1.2.0-alloc.jcl"), #cmd("sdsf-1.2.0-inst.jcl") and
#cmd("sdsf-1.2.0-accept.jcl")), and two guides: #cmd("README.md"), the
installation guide of the release, and #cmd("uninstall.md"), the removal
guide with the jobs. The Reference lists the files in Appendix B.
#idx("package")

== Installing SDSF <ug-install-install>

=== Before You Start <ug-install-before>

*The installation needs an IPL with CLPA.* Besides the data sets of SDSF, it
changes three members of the system: #cmd("SYS1.PARMLIB(IEAAPF00)"),
#cmd("SYS1.PARMLIB(LNKLST00)") and #cmd("SYS1.LPALIB"). It also changes how
ISPF finds its panels and CLISTs, and the profiles of RAKF.

#tab(caption: [Where the parts of SDSF go])[
  #table(columns: (1.9in, 1fr),
    [Part], [What the system needs to know],
    [#cmd("ISF.LINKLIB") (the program #cmd("ISFISP"))], [APF-authorized, with
      its volume, in #cmd("IEAAPF00")\; and in the link list, in
      #cmd("LNKLST00").],
    [#cmd("IGX00011") (the SVC routine)], [SMP links it into
      #cmd("SYS1.LPALIB"). The system finds it at an IPL with CLPA.],
    [#cmd("ISF.ISFPLIB") (the panels)], [In the ISPPLIB concatenation of
      ISPF.],
    [#cmd("ISF.ISFCLST") (the CLIST #cmd("SDSF"))], [In the SYSPROC
      concatenation.],
    [RAKF], [The FACILITY profile #cmd("SDSF.OPER") and the profiles in the
      class JESSPOOL.],
  )
]

SDSF runs its authorized functions through an SVC routine of its own in the
link pack area. Without it, SDSF uses SVC 244, as the previews did, and only
users with READ access to the FACILITY profile #cmd("SVC244") can then use
the log, the printers, the initiators and operator commands.
#idx("SVC routine")#idx("SVC 244")

On a stock TK5 or MVS/CE system, #cmd("SYS1.LPALIB") holds the members
#cmd("IGX00013"), #cmd("IGX00014"), #cmd("IGX00026") and #cmd("IGX00027")
and no #cmd("IGX00011"), so no routine answers to code 11 until SDSF is
installed. Check before you install: if a site has an #cmd("IGX00011") of its
own, SDSF sees code 11 as installed and calls that routine instead.

Two things to settle before you begin.

- *Remove an earlier preview first.* The previews of TK5 put SDSF into
  #cmd("SYS2.SDSF.LOAD"), its panels #cmd("ISFMENU") and #cmd("ISFLIST") into
  #cmd("SYS2.ISP.PLIB") and its CLIST #cmd("SDSF") into #cmd("SYS2.CMDPROC").
  Delete them where they exist. Otherwise the old CLIST and panels are found
  before the new ones.
- *There is no upgrade from the beta 0.9.0.* Remove it first
  (@ug-install-beta), then install 1.2.0 as for a first installation.
#idx("beta")

=== Upload the Files <ug-install-upload>

Upload the three TRANSMIT files *in binary* to sequential data sets with
#cmd("RECFM=FB"), #cmd("LRECL=80") and #cmd("BLKSIZE=3120"), under any names.
Each qualifier can be at most 8 characters long. With the IND\$FILE file
transfer of x3270 or wc3270, choose binary, no CR/LF translation, fixed
records, record length 80 and block size 3120. Note the names: the
installation job asks for them.

#tab(caption: [The files and the names the installation job uses])[
  #table(columns: (2.1in, 1.7in, 1fr),
    [File], [For example], [Name in the installation job],
    [#cmd("sdsf-1.2.0-load.xmit")], [#cmd("HERC01.ISFLOAD.XMIT")],
      [#cmd("CHANGE.ME.ISFLOAD")],
    [#cmd("sdsf-1.2.0-isfplib.xmit")], [#cmd("HERC01.ISFPLIB.XMIT")],
      [#cmd("CHANGE.ME.TISFPLIB")],
    [#cmd("sdsf-1.2.0-isfclst.xmit")], [#cmd("HERC01.ISFCLST.XMIT")],
      [#cmd("CHANGE.ME.TISFCLST")],
  )
]

The jobs are text. Upload them as text, or paste them into an edit session.

=== Allocate the Libraries <ug-install-alloc>

#cmd("sdsf-1.2.0-alloc.jcl") allocates the target and the distribution
libraries. The volumes are the two symbolic parameters on its #cmd("PROC")
statement:

- #cmd("TGTVOL"): the volume of the target libraries. The APF entry
  (@ug-install-apf) names it for #cmd("ISF.LINKLIB").
- #cmd("DLBVOL"): the volume of the distribution libraries.

The defaults are those of MVS/CE (#cmd("MVSRES") and #cmd("SMP000")). On TK5
write #cmd("TGTVOL=TK5RES,DLBVOL=TK5DLB"). Submit the job.

The job allocates only once. If a library is already cataloged, the step
#cmd("CHECK") ends with return code 8 and nothing is allocated.

=== Install <ug-install-inst>

In #cmd("sdsf-1.2.0-inst.jcl") replace each #cmd("CHANGE.ME.*") with the name
you uploaded that file to. Leave the #cmd("VOLUME") lines commented out: the
#cmd("RECEIVE") steps put the staging libraries on a work volume by themselves
(#cmd("PUB000") on a stock MVS/CE). Only if a #cmd("RECEIVE") step fails for
want of space or of a volume, take the comment marks off its #cmd("VOLUME")
line and name one. Submit the job.

*A return code says only that a step ran.* On a first installation the job
looks wrong in three places, and is right:

- #cmd("DELOLD") prints #cmd("IDC0551I ** ENTRY ISF.ISFLOAD NOT DELETED") and
  ends with return code 0.
- #cmd("APPLY") ends with return code 4: SMP links #cmd("IGX00011") into
  #cmd("SYS1.LPALIB") and first tries to include the module that is there,
  which a first installation does not have (#cmd("HMA2391 LINK SUCCESSFUL")
  with #cmd("RETURN CODE=08"), #cmd("IEW0342")).
- #cmd("ASSEM") says #cmd("NO STATEMENTS FLAGGED"). Any other return code
  stops the job before the SYSMOD is received.

The Reference explains each of them in Appendix B, "The Return Codes of a
First Installation". Then check that the work happened:

+ The output of the step #cmd("APPLY") has #cmd("HMA2380 COPY SUCCESSFUL -
  MOD=ISFISP - LMOD=ISFISP - LIBRARY=ISFLINK") and #cmd("HMA2391 LINK
  SUCCESSFUL") for #cmd("IGX00011") into #cmd("LPALIB").
+ #cmd("SYS1.LPALIB") has the member #cmd("IGX00011").
+ #cmd("ISF.LINKLIB") has the member #cmd("ISFISP") and no
  #cmd("IGX00011"). #cmd("ISF.ISFPLIB") has #cmd("ISFLIST"), #cmd("ISFMENU")
  and the help panels (#cmd("ISFHTOC") among them), 82 members in all.
  #cmd("ISF.ISFCLST") has #cmd("SDSF").

Then submit #cmd("sdsf-1.2.0-accept.jcl"). It accepts #cmd("TISF120") into the
distribution libraries and deletes the staging libraries. It ends with return
code 4 for the same reason as #cmd("APPLY"): #cmd("HMA2471 BLDL FAILED IN
LIBRARY AOST4") appears before #cmd("IGX00011") is first put there. Check
that #cmd("ISF.AISFLOAD") has #cmd("ISFISP"), #cmd("SYS1.AOST4") has
#cmd("IGX00011"), #cmd("ISF.AISFPLIB") has the panels and
#cmd("ISF.AISFCLST") has the CLIST.

A #cmd("LIST") shows the result in the SMP inventory:

#code("//LIST     EXEC SMPAPP
//SMPCNTL  DD  *
 LIST CDS SYSMOD(TISF120) .
/*")

It shows #cmd("STATUS = REC APP ACC").

The SVC routine needs nothing more from you at this point. SMP put it into
#cmd("SYS1.LPALIB"), and it takes effect at the IPL with CLPA below.

=== Authorize the Library and Put It in the Link List <ug-install-apf>

#idx("APF")#idx("link list")
#cmd("ISF.LINKLIB") must be APF-authorized and in the link list, so that ISPF
loads SDSF from there as authorized.

*#cmd("SYS1.PARMLIB(IEAAPF00)")*: add a line with the data set name *and the
volume* (the #cmd("TGTVOL") of the allocation job). An entry for the same name
on another volume does not authorize this library. Put a comma after the line
before it. The last line has none. On TK5:

#code(" EXH.ESPLIB TK5002,
 ISF.LINKLIB TK5RES")

*#cmd("SYS1.PARMLIB(LNKLST00)")*: add the library at the end, again with a
comma after the line before it:

#code(" SYS2.DSSLIB,
 ISF.LINKLIB")

On MVS/CE the lines of both members end in a comment. The comma goes directly
after the entry, before the comment. In #cmd("IEAAPF00"):

#code(" SYSC.LINKLIB SYSCPK,         COMPILER/TOOLS VOLUME
 ISF.LINKLIB MVSRES")

and in #cmd("LNKLST00"):

#code("SYS2.CMDLIB,                USER TSO COMMAND LIBRARY
ISF.LINKLIB")

Keep #cmd("ISF.LINKLIB") out of #cmd("ISPLLIB"), and out of a #cmd("STEPLIB")
that is not all APF-authorized. A program from there is not loaded as
authorized, and SDSF then falls back to SVC 244.

=== IPL with CLPA <ug-install-ipl>

#idx("CLPA")#idx("IPL")
#cmd("IEAAPF00"), #cmd("LNKLST00") and the link pack area are read at IPL.
IPL with CLPA:

- On TK5, #cmd("IEASYS00") already says #cmd("CLPA"), so any IPL loads the
  link pack area again.
- On MVS/CE, Hercules answers the prompt #cmd("IEA101A SPECIFY SYSTEM
  PARAMETERS") by itself, so there is no chance to type #cmd("CLPA"). Put
  #cmd("CLPA,") into #cmd("SYS1.PARMLIB(IEASYS00)") (for example after the
  #cmd("BLDLF") line), IPL, and take it out again afterwards. This IPL also
  shows #cmd("IEA357I ERRORS IN IEAPAK00 LIST") for seven IBM modules. That is
  MVS/CE's own and has nothing to do with SDSF.
- Elsewhere, answer #cmd("IEA101A") with #cmd("R 00,CLPA"), or put
  #cmd("CLPA,") into #cmd("IEASYS00") for this one IPL.

=== Put the Panels and the CLIST into ISPF <ug-install-ispf>

#idx("ISPPLIB")#idx("SYSPROC")
Put #cmd("ISF.ISFPLIB") into the ISPPLIB concatenation and
#cmd("ISF.ISFCLST") into SYSPROC. All 82 panels, the help and the tutorial
among them, are in #cmd("ISF.ISFPLIB"). Where you make the change depends on
how the system starts ISPF.

*On TK5*, the CLIST #cmd("SYS1.CMDPROC(ISPLOGON)") builds the concatenations
for every user with the REXX exec #cmd("$CONCAT"). Add two lines after the
others there:

#code("      RX $CONCAT ISPPLIB ISF.ISFPLIB BOT
      RX $CONCAT SYSPROC ISF.ISFCLST BOT")

*On MVS/CE*, ISPF builds ISPPLIB in the CLIST #cmd("SYS1.CMDPROC(ISPF)"). Add
the library to its #cmd("ALLOC"):

#code("ALLOC F(ISPPLIB) DA('SYSGEN.ISPF.PLIB','SYSGEN.ISPF.RFEPLIB', +
               'ISF.ISFPLIB') SHR")

SYSPROC comes from the logon procedure #cmd("SYS1.PROCLIB(IKJACCNT)"). Add a
line after #cmd("SYS2.CMDPROC"):

#code("//SYSPROC  DD  DISP=SHR,DSN=SYS1.CMDPROC
//         DD  DISP=SHR,DSN=SYS2.CMDPROC
//         DD  DISP=SHR,DSN=ISF.ISFCLST")

Do not add the library to the #cmd("ALLOC FILE(SYSPROC)") of
#cmd("SYS1.CMDPROC(TSOLOGON)"). SYSPROC is allocated already, and that
#cmd("ALLOC") fails without a message. #cmd("TSO SDSF") then says
#cmd("COMMAND SDSF NOT FOUND").

The changes take effect at the next logon.

=== Set Up the Authorization <ug-install-auth>

#idx("RAKF")#idx("authorization")
SDSF asks RAKF. There are two kinds of rule, and without them a user sees
only their own jobs and none of the system.

- *Jobs of other users.* Profiles in the class JESSPOOL, the one FTPD uses.
  SDSF asks for the entity
  #var("owner")#cmd(".")#var("jobname")#cmd(".")#var("jobid"), for example
  #cmd("HERC01.PAYROLL.JOB00046"). READ lets a user see the job and browse its
  output. UPDATE lets a user take the actions that change it.
- *The system.* The FACILITY profile #cmd("SDSF.OPER"). READ gives the log, the
  printers and the initiators, and the address spaces without a job on DA.
  UPDATE adds the other actions on printers and initiators and the operator
  commands given with #cmd("/").

On TK5 and on MVS/CE, RAKF reads its profiles from
#cmd("SYS1.SECURE.CNTL(PROFILES)"), kept in sort order. The class goes in
columns 1 to 8, the profile from column 9, the group from column 53 and the
access from column 61. For each profile, the line without a group comes
first:

#code("FACILITYSDSF.OPER                                           NONE
FACILITYSDSF.OPER                                   ADMIN   UPDATE
JESSPOOL*                                                   NONE
JESSPOOL*                                           ADMIN   UPDATE")

With these lines every user sees their own jobs, and the group ADMIN sees and
handles all jobs, the log, the printers and the initiators. Give #cmd("READ")
instead of #cmd("NONE") in a line without a group to let everyone see. Then
#cmd("S RAKFPROF") reloads the profiles.

Chapter 9, "Who May Do What" (@ug-access), has worked examples. The _SDSF
Reference_, chapter "Authorization", describes every check SDSF makes.

=== Start SDSF and Check That It Works <ug-install-check>

#idx("checking the installation")
From any ISPF command line:

#code("TSO SDSF")

SDSF shows its primary option menu, #cmd("SDSF PRIMARY OPTION MENU"). Type
#cmd("ST"), and the Status panel appears, titled #cmd("SDSF STATUS DISPLAY").

That proves the program, the panels and the CLIST. It does not prove the SVC
routine, because a user who may use SVC 244 gets the same result without it.
Check the routine as a user who has UPDATE on #cmd("SDSF.OPER") (a #cmd("/")
command needs UPDATE) and no access to the FACILITY profile #cmd("SVC244").
Ask for the #cmd("LOG"), then give #cmd("/D T"). If the log is shown and the
system answers with #cmd("IEE136I"), SDSF got the authorized state from its
own SVC routine.

Take a user of a group that has no access to #cmd("SVC244"). On a stock
MVS/CE system the group ADMIN has READ on it (#cmd("FACILITYSVC244 ... ADMIN
READ") in the RAKF profiles), so an ADMIN user passes the check without
#cmd("IGX00011"). Give that user's group UPDATE on #cmd("SDSF.OPER"), with a
line of its own, for the check.

If the check fails, see @ug-install-trouble-auth.

== Removing SDSF <ug-install-remove>

#idx("removal")#idx("UCLIN")
The package carries #cmd("uninstall.md"), which has the jobs. This section is
the way through them. The removal deletes the entries in the SMP inventory,
then the data sets and the SVC routine, and then you take back the system
changes of the installation.

SMP refuses #cmd("RESTORE") and #cmd("REJECT") for a function that is
accepted, and the accept job accepts #cmd("TISF120"). The way back is an SMP
#cmd("UCLIN"), which edits the inventory directly.

Submit the jobs under a user with update access to #cmd("SYS1.SMPCDS") and
#cmd("SYS1.SMPACDS"), from TSO with #cmd("SUBMIT"), which puts the user's id
into the job. Through the card reader a job runs without a user, and RAKF
then refuses the SMP data sets with #cmd("ABEND S913").

=== Free the Inventory Entries <ug-install-uclin>

The first job of #cmd("uninstall.md") deletes the entries of #cmd("TISF120")
in both zones: the target zone (#cmd("CDS")) and the distribution zone
(#cmd("ACDS")). Each zone needs its own block. It deletes the SYSMOD, its two
modules and the 83 elements (the 82 panels and the CLIST), not the SYSMOD
alone. SMP records which SYSMOD owns an element by the element's name. If an
element entry is left behind, a later installation of the same element
reports #cmd("NOT SEL") and copies nothing, at return code 0. A load module
has an entry in the target zone only. #cmd("DEL LMOD") under #cmd("UCLIN ACDS")
is refused with #cmd("HMA2762 ILLEGAL UPDATE REQUEST ON SMPACDS LIBRARY") and
ends the job with return code 8.

#code(" UCLIN CDS .
  DEL SYSMOD(TISF120) .
  DEL MOD(ISFISP) .
  DEL MOD(IGX00011) .
  DEL LMOD(ISFISP) .
  DEL LMOD(IGX00011) .
  DEL MAC(SDSF) .
  DEL MAC(ISFMENU) .
  ...
 ENDUCL .")

This is the start of the block for the target zone. The dots stand for the
other #cmd("MAC") statements: #cmd("uninstall.md") has the whole job. Submit
that job as it is. The block for the distribution zone has no #cmd("LMOD")
statements.

Every #cmd("DEL") reports #cmd("HMA2550 UPDATE COMPLETE"), and the
#cmd("UCLIN") step ends with return code 0. It takes a few minutes for its 174
statements. The #cmd("LIST") step of the job is the check: *return code 4,
with every entry reported as not found, means the inventory is clean.*

=== Delete the Data Sets and the SVC Routine <ug-install-delete>

The second job of #cmd("uninstall.md") runs IDCAMS. It deletes the six
libraries #cmd("ISF.LINKLIB"), #cmd("ISF.AISFLOAD"), #cmd("ISF.ISFPLIB"),
#cmd("ISF.AISFPLIB"), #cmd("ISF.ISFCLST") and #cmd("ISF.AISFCLST"), and the
members #cmd("IGX00011") of #cmd("SYS1.LPALIB") and #cmd("SYS1.AOST4"). Each
line reports #cmd("IDC0550I ENTRY ... DELETED") for a data set and
#cmd("IDC0549I MEMBER IGX00011 DELETED") for a member.

Take the lines for SDSF out of the logon CLIST first (next section), or every
logon names data sets that no longer exist.

=== Take Back the System Changes <ug-install-undo>

- Take #cmd("ISF.LINKLIB") out of #cmd("SYS1.PARMLIB(IEAAPF00)") and
  #cmd("SYS1.PARMLIB(LNKLST00)"). An APF entry left behind for a deleted
  library is a risk: a new data set of that name on that volume would be
  authorized.
- Take #cmd("ISF.ISFPLIB") and #cmd("ISF.ISFCLST") out of the ISPPLIB and
  SYSPROC concatenations, where you put them (@ug-install-ispf).
- Take the RAKF rules for SDSF out, if you no longer need them.
- IPL with CLPA. The copy of #cmd("IGX00011") in the running link pack area
  stays until then.

=== Check the Removal <ug-install-removed>

A return code says only that a job ran. Check that:

- the #cmd("LIST") step of the first job ended with return code 4 and reported
  every entry as not found;
- the six libraries are no longer in the catalog;
- #cmd("SYS1.LPALIB") and #cmd("SYS1.AOST4") have no member
  #cmd("IGX00011");
- no logon procedure or CLIST still names a library of SDSF.

=== Removing the Beta 0.9.0 <ug-install-beta>

The beta is not upgraded to 1.2.0. Remove it, then install 1.2.0 as for a
first installation. #cmd("uninstall.md") has its jobs under "Removing the beta
0.9.0".

The SYSMOD #cmd("TISF090") owns only the two modules. Its panels and its CLIST
were not SMP elements: they were received into #cmd("ISF.ISPPLIB") and
#cmd("ISF.CLIST"). Do not name any #cmd("MAC") in its #cmd("UCLIN"). A
#cmd("DEL") of an entry that does not exist gives #cmd("HMA2532"), and that
stops the rest of the step. The #cmd("LIST") step ends with return code 4 when
nothing of #cmd("TISF090") is left.

The job #cmd("isflpa.jcl") of the beta copied #cmd("IGX00011") into
#cmd("SYS1.LPALIB") by hand. The second job deletes it there. If the old copy
stayed, SMP would include it in the link of 1.2.0, and the result would not
be marked refreshable. The IDCAMS job also deletes #cmd("ISF.LINKLIB"),
#cmd("ISF.AISFLOAD"), #cmd("ISF.ISPPLIB") and #cmd("ISF.CLIST").

What stays:

- The lines for #cmd("ISF.LINKLIB") in #cmd("IEAAPF00") and #cmd("LNKLST00").
  1.2.0 uses the same library.
- The logon lines for #cmd("ISF.ISPPLIB") and #cmd("ISF.CLIST") must change to
  #cmd("ISF.ISFPLIB") and #cmd("ISF.ISFCLST") (@ug-install-ispf), since the
  old data sets are gone.

The IPL with CLPA of the installation of 1.2.0 follows anyway.

== Troubleshooting <ug-install-trouble>

#idx("troubleshooting")
Each table gives what you see, why, and what to do. The messages of SDSF are
quoted as the screen shows them. The _SDSF Reference_, chapter "Messages",
lists them all.

=== The Jobs <ug-install-trouble-jobs>

#tab(caption: [Problems with the allocation, installation and accept jobs])[
  #table(columns: (1.9in, 1.8in, 1fr),
    [What you see], [Why], [What to do],
    [The allocation job ends with return code 8 and allocates nothing: the step
      #cmd("CHECK") ended with 8.],
      [A library of SDSF is already in the catalog.],
      [Find out which: an earlier installation, the beta, or an earlier
       attempt. Remove it (@ug-install-remove), then run the job again.],
    [A #cmd("RECEIVE") step of the installation job fails.],
      [For want of space or of a volume for the staging library.],
      [Take the comment marks off its #cmd("VOLUME") line and name a volume.],
    [#cmd("DELOLD") prints #cmd("IDC0551I ** ENTRY ISF.ISFLOAD NOT DELETED")
      and #cmd("HIGHEST CONDITION CODE WAS 8"). The step ends with 0.],
      [The step deletes a staging library left from an earlier run, and there
       is none.],
      [Nothing. It is right on a first installation.],
    [#cmd("APPLY") ends with return code 4, and #cmd("ACCEPT") ends with 4.],
      [#cmd("IGX00011") is not in #cmd("SYS1.LPALIB") and #cmd("SYS1.AOST4")
       yet (#cmd("HMA2391 LINK SUCCESSFUL") with #cmd("RETURN CODE=08") and
       #cmd("IEW0342") in #cmd("APPLY")\; #cmd("HMA2471 BLDL FAILED IN LIBRARY
       AOST4") in #cmd("ACCEPT")).],
      [Nothing on a first installation. Check the work as in
       @ug-install-inst.],
    [The installation job stops after #cmd("ASSEM"), and the SYSMOD is not
      received.],
      [#cmd("ASSEM"), the assembly of #cmd("IGX00011"), ended with a return code
       other than 0.],
      [Read the output of #cmd("ASSEM"). It says #cmd("NO STATEMENTS FLAGGED")
       when it is right.],
    [The accept job ends with return code 8, and the steps #cmd("ACCEPT") and
      #cmd("CLEANUP") did not run.],
      [The step #cmd("GUARD") found that #cmd("TISF120") is not applied, and
       #cmd("NOTAPPL") ended the job.],
      [Look at the output of the step #cmd("APPLY") of the installation job.
       Run the accept job only after the SYSMOD is applied.],
    [A later installation reports #cmd("NOT SEL") and copies nothing, at return
      code 0.],
      [The entry of an element was left in the SMP inventory by an earlier
       removal.],
      [Delete the entries of the elements as well as of the SYSMOD
       (@ug-install-uclin).],
  )
]

=== Starting SDSF <ug-install-trouble-start>

#tab(caption: [Problems starting SDSF])[
  #table(columns: (1.9in, 1.8in, 1fr),
    [What you see], [Why], [What to do],
    [#cmd("TSO SDSF") says #cmd("COMMAND SDSF NOT FOUND").],
      [#cmd("ISF.ISFCLST") is not in the SYSPROC concatenation. One cause is
       an #cmd("ALLOC FILE(SYSPROC)") added to
       #cmd("SYS1.CMDPROC(TSOLOGON)"), which fails without a message.],
      [Add the library as in @ug-install-ispf, and log on again.],
    [#cmd("ISF001E ISFISP RUNS UNDER ISPF: SELECT PGM(ISFISP)"). SDSF ends with
      return code 8.],
      [SDSF was called outside ISPF.],
      [Start it from an ISPF command line with #cmd("TSO SDSF").],
    [SDSF ends at once and shows none of its panels.],
      [SDSF could not show its first panel, #cmd("ISFMENU").],
      [Check that #cmd("ISF.ISFPLIB") is in the ISPPLIB concatenation and has
       #cmd("ISFMENU") and #cmd("ISFLIST"), and that you logged on again after
       the change.],
    [The old panels or the old CLIST of a preview appear.],
      [The libraries of the preview are found before the new ones.],
      [Delete the old libraries (@ug-install-before).],
    [#cmd("HELP NOT AVAILABLE") on the Help key or on #cmd("HELP").],
      [The help panels are not in the ISPPLIB concatenation.],
      [Put #cmd("ISF.ISFPLIB") into ISPPLIB. The 80 panels of the help, the
       tutorial and the index are in it with the two panels that draw SDSF.],
    [#cmd("PANEL NOT FOUND") in the help. The page before stays.],
      [The panel of the topic that you chose is not there.],
      [Check that #cmd("ISF.ISFPLIB") has all 82 members.],
  )
]

=== The Authorized State and the Authorization <ug-install-trouble-auth>

SDSF needs two things for the log, the printers, the initiators and the
operator commands: the access that RAKF gives, and the authorized state. When
either is missing, the same few messages appear. Look at RAKF first.

#tab(caption: [Problems with the authorization])[
  #table(columns: (1.9in, 1.8in, 1fr),
    [What you see], [Why], [What to do],
    [A user sees their own jobs only.],
      [There is no profile in the class JESSPOOL for the jobs of others. RAKF
       before 2.0.0 has no class JESSPOOL at all.],
      [Add the profiles (@ug-install-auth).],
    [#cmd("COMMAND NOT AUTHORIZED") on #cmd("LOG"), #cmd("PR") or #cmd("INIT"),
      or #cmd("NOT AUTHORIZED FOR CMD") on a #cmd("/") command.],
      [The user lacks the access to #cmd("SDSF.OPER"): READ for the first,
       UPDATE for a #cmd("/") command.],
      [Give the access. If the user has it, the authorized state is missing, as
       in the next rows.],
    [#cmd("COMMAND NOT AUTHORIZED") on an action character or a #cmd("/")
      command, #cmd("LOG NOT READABLE") on the log, #cmd("REPLIES NOT
      READABLE") at the end of the log, or #cmd("NOT AUTHORIZED") on #cmd("P")
      on the Status panel, and RAKF writes a refusal of SVC 244 on the console.],
      [SDSF did not get the authorized state from its own SVC routine, and the
       user has no access to #cmd("SVC244").],
      [Find the cause in the next rows.],
    [The same, and #cmd("IGX00011") is not in #cmd("SYS1.LPALIB"), or the
      system was not IPLed with CLPA after it was put there.],
      [No routine answers to code 11.],
      [Check that the member is there. IPL with CLPA (@ug-install-ipl).],
    [The same, and the member is there, and the IPL was with CLPA.],
      [#cmd("ISFISP") is loaded from an unauthorized library in
       #cmd("ISPLLIB"), from a #cmd("STEPLIB") that is not all APF-authorized,
       or from an APF library whose entry in #cmd("IEAAPF00") names another
       volume.],
      [Take #cmd("ISF.LINKLIB") out of #cmd("ISPLLIB") and the
       #cmd("STEPLIB"), and make the APF entry name the volume the library is
       on. ISPF finds SDSF through the link list without either.],
    [The same, and #cmd("ISFISP") is loaded as it should be.],
      [Another module whose name begins with #cmd("ISF") was loaded from an
       unauthorized library, for example a copy in a development library.],
      [Find the module and take its library out of the search.],
    [SDSF works for a user, and the check of @ug-install-check was not made.],
      [A user who may use SVC 244 gets the authorized state without the
       routine. SDSF does not say which of the two ways it used.],
      [Make the check of @ug-install-check with a user who has no access to
       #cmd("SVC244").],
  )
]

The routine and its refusals are described in the _SDSF Reference_,
Appendix C, "The SVC Routine".

=== Removal <ug-install-trouble-remove>

#tab(caption: [Problems with the removal])[
  #table(columns: (1.9in, 1.8in, 1fr),
    [What you see], [Why], [What to do],
    [An SMP job ends with #cmd("ABEND S913").],
      [The job was read in through the card reader. It runs without a user, and
       RAKF refuses the SMP data sets.],
      [Submit it from TSO with #cmd("SUBMIT"), under a user with update access
       to #cmd("SYS1.SMPCDS") and #cmd("SYS1.SMPACDS").],
    [#cmd("HMA2762 ILLEGAL UPDATE REQUEST ON SMPACDS LIBRARY"), return code 8.],
      [A #cmd("DEL LMOD") is under #cmd("UCLIN ACDS"). A load module has an
       entry in the target zone only.],
      [Take the #cmd("DEL LMOD") out of the block for #cmd("ACDS").],
    [#cmd("HMA2532"), and the rest of the #cmd("UCLIN") step does not run.],
      [A #cmd("DEL") named an entry that does not exist. For the beta 0.9.0,
       the panels and the CLIST are no SMP elements.],
      [Do not name any #cmd("MAC") for #cmd("TISF090").],
    [Every logon names data sets that no longer exist.],
      [The logon lines for SDSF were not taken out before the data sets were
       deleted.],
      [Take them out (@ug-install-undo).],
  )
]
