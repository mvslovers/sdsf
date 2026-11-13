#import "../bookmaster/bookmaster.typ": *

= Data Sets and Members of the Package <apx-package>

#idx("package")
This appendix lists what SDSF 1.2.0 is made of: the files of the package you
download, the data sets the installation makes, the members of each data set
and what each member is for, what SMP records, and the places in the system
that the installation changes. It ends with what removing SDSF takes out.
It does not say how to install. The steps, in the order you take them, are the
subject of the companion volume, the _SDSF User's Guide_.

SDSF comes as an *SMP Release 4* package, for the SMP that ships with MVS
3.8j (not SMP/E). Its identifier is the FMID #cmd("TISF120"). SMP installs
every member: the load module #cmd("ISFISP"), the SVC routine
#cmd("IGX00011"), the 82 panels and the CLIST #cmd("SDSF").
#idx("SMP")

== The Files of the Package <apx-package-files>

#idx("package", "files")
A release of SDSF on GitHub carries the package as one archive, in two forms
(#cmd(".zip") and #cmd(".tar.gz")), and the load module once more on its
own. The archive holds eight files.

#tab(caption: [The files of the package])[
  #table(columns: (2.2in, 1fr),
    [File], [What it is],
    [#cmd("sdsf-1.2.0-load.xmit")], [The load module #cmd("ISFISP"), as a TSO
      TRANSMIT file. #cmd("RECEIVE") unpacks it into the staging library
      #cmd("ISF.ISFLOAD").],
    [#cmd("sdsf-1.2.0-isfplib.xmit")], [The 82 panels (@apx-package-isfplib).
      #cmd("RECEIVE") unpacks them into the staging library
      #cmd("ISF.TISFPLIB").],
    [#cmd("sdsf-1.2.0-isfclst.xmit")], [The CLIST #cmd("SDSF").
      #cmd("RECEIVE") unpacks it into the staging library
      #cmd("ISF.TISFCLST").],
    [#cmd("sdsf-1.2.0-alloc.jcl")], [The allocation job: makes the target and
      the distribution libraries.],
    [#cmd("sdsf-1.2.0-inst.jcl")], [The installation job: the #cmd("RECEIVE")
      of the three TRANSMIT files, the SYSMOD, the source of
      #cmd("IGX00011") and its assembly, and the SMP steps #cmd("RECEIVE"),
      #cmd("APPLY CHECK") and #cmd("APPLY").],
    [#cmd("sdsf-1.2.0-accept.jcl")], [The accept job: #cmd("ACCEPT") of the
      SYSMOD, then removal of the staging libraries.],
    [#cmd("README.md")], [The installation guide of the release (the file
      #cmd("docs/installation.md") of the repository).],
    [#cmd("uninstall.md")], [How to remove SDSF (the file #cmd("docs/uninstall.md") of the
      repository). @apx-package-remove summarizes it.],
  )
] <apx-package-tab-files>

The TRANSMIT files are binary. Upload them to sequential data sets with
#cmd("RECFM=FB"), #cmd("LRECL=80") and #cmd("BLKSIZE=3120"), under any names
(each qualifier at most eight characters), and name those data sets in the
installation job. The jobs are text.

A release also carries the two books, #cmd("ml11-0001-")#var("e")#cmd(".pdf")
and #cmd("ml11-0002-")#var("e")#cmd(".pdf") (#var("e") is the edition), and a
file #cmd("SHA256SUMS") with their checksums. The checksums cover the books,
not the package.

=== The Jobs and Their Steps <apx-package-jobs>

#idx("jobs", "of the package")
#tab(caption: [The jobs of the package and their steps])[
  #table(columns: (1.2in, 1.05in, 1fr),
    [Job], [Step], [What the step does],
    [Allocation], [#cmd("CHECK")], [Looks in the catalog for the six
      libraries of @apx-package-datasets. If any is cataloged, the step ends
      with return code 8 and nothing is allocated.],
    [], [#cmd("ALLOC")], [Allocates the six libraries, on the volumes named by
      the symbolic parameters #cmd("TGTVOL") and #cmd("DLBVOL") of the
      procedure.],
    [Installation], [#cmd("DELOLD")], [Deletes the three staging libraries
      #cmd("ISF.ISFLOAD"), #cmd("ISF.TISFCLST") and #cmd("ISF.TISFPLIB"), so
      that the next steps can make them anew. A library that does not exist is
      no error.],
    [], [#cmd("RECV1")], [#cmd("RECEIVE") of the load TRANSMIT file into
      #cmd("ISF.ISFLOAD").],
    [], [#cmd("RECV2")], [#cmd("RECEIVE") of the CLIST TRANSMIT file into
      #cmd("ISF.TISFCLST").],
    [], [#cmd("RECV3")], [#cmd("RECEIVE") of the panel TRANSMIT file into
      #cmd("ISF.TISFPLIB").],
    [], [#cmd("GENER1")], [Writes the SYSMOD, which is inline in the job, to a
      temporary data set.],
    [], [#cmd("ASSEM")], [Assembles the source of #cmd("IGX00011"), which is
      inline in the job, with the assembler of the system, and appends the
      object deck to the SYSMOD behind its #cmd("++MOD"). Anything but return
      code 0 stops the job before the SYSMOD is received.],
    [], [#cmd("RECV")], [SMP #cmd("RECEIVE") of the SYSMOD #cmd("TISF120").],
    [], [#cmd("APPLYCHK")], [SMP #cmd("APPLY") with #cmd("CHECK"), a dry run.
      #cmd("APPLY") runs only if this step ends with return code 0.],
    [], [#cmd("APPLY")], [SMP #cmd("APPLY"): installs the load module, the
      SVC routine, the panels and the CLIST (@apx-package-smp).],
    [Accept], [#cmd("GUARD")], [SMP #cmd("LIST") of the SYSMOD in the target
      zone: return code 0 if it is applied, 4 if not.],
    [], [#cmd("NOTAPPL")], [Runs only when the SYSMOD is not applied, and ends
      the job with return code 8. #cmd("ACCEPT") and #cmd("CLEANUP") then do
      not run.],
    [], [#cmd("ACCEPT")], [SMP #cmd("ACCEPT"): fills the distribution
      libraries.],
    [], [#cmd("CLEANUP")], [Deletes the three staging libraries, only if
      #cmd("GUARD") ended with return code 0 and #cmd("ACCEPT") with 4 or
      less.],
  )
] <apx-package-tab-jobs>

== The Data Sets <apx-package-datasets>

#idx("data sets", "of the package")
The allocation and installation jobs make nine data sets. Six stay. The three
staging libraries go when the accept job has run. SMP also writes two
libraries of the system. The names are fixed: the jobs and the SMP inventory
use them.

#tab(caption: [The data sets of the package])[
  #table(columns: (1.15in, 0.8in, 1fr, 1.5in),
    [Data set], [DD name], [Holds], [Made by],
    [#cmd("ISF.LINKLIB")], [#cmd("ISFLINK")], [The target library for the load
      module: #cmd("ISFISP"). Load library, #cmd("RECFM=U"),
      #cmd("BLKSIZE=15040").], [The allocation job. SMP writes it at
      #cmd("APPLY").],
    [#cmd("ISF.AISFLOAD")], [#cmd("AISFLOAD")], [Its distribution library: the
      same member, as accepted. Load library, #cmd("RECFM=U"),
      #cmd("BLKSIZE=15040").], [The allocation job. SMP writes it at
      #cmd("ACCEPT").],
    [#cmd("ISF.ISFPLIB")], [#cmd("ISFPLIB")], [The target library for the
      panels: all 82 members (@apx-package-isfplib). Text library,
      #cmd("RECFM=FB"), #cmd("LRECL=80"), #cmd("BLKSIZE=3120").], [The
      allocation job. SMP writes it at #cmd("APPLY").],
    [#cmd("ISF.AISFPLIB")], [#cmd("AISFPLIB")], [Its distribution library: the
      same 82 members. Text library, same format.], [The allocation job. SMP
      writes it at #cmd("ACCEPT").],
    [#cmd("ISF.ISFCLST")], [#cmd("ISFCLST")], [The target library for the
      CLIST: #cmd("SDSF") (@apx-package-clist). Text library, same format as
      the panels.], [The allocation job. SMP writes it at #cmd("APPLY").],
    [#cmd("ISF.AISFCLST")], [#cmd("AISFCLST")], [Its distribution library: the
      same member. Text library, same format.], [The allocation job. SMP
      writes it at #cmd("ACCEPT").],
    [#cmd("ISF.ISFLOAD")], [#cmd("ISFLOAD")], [Staging library: the load
      module as it comes out of the TRANSMIT file. Load library,
      #cmd("RECFM=U"), #cmd("BLKSIZE=15040").], [The installation job
      (#cmd("RECV1")). The accept job deletes it.],
    [#cmd("ISF.TISFPLIB")], [one per member], [Staging library: the 82 panels as they
      come out of the TRANSMIT file. Text library, #cmd("RECFM=FB"),
      #cmd("LRECL=80"), #cmd("BLKSIZE=3120").], [The installation job
      (#cmd("RECV3")). The accept job deletes it.],
    [#cmd("ISF.TISFCLST")], [one per member], [Staging library: the CLIST as it comes out
      of the TRANSMIT file. Text library, same format.], [The installation job
      (#cmd("RECV2")). The accept job deletes it.],
    [#cmd("SYS1.LPALIB")], [#cmd("LPALIB")], [The member #cmd("IGX00011"), the
      SVC routine, in the library of the link pack area (the LPA).], [The
      system. SMP links the member in at #cmd("APPLY").],
    [#cmd("SYS1.AOST4")], [#cmd("AOST4")], [The member #cmd("IGX00011"), kept
      as accepted. This is IBM's distribution library for the LPA.], [The
      system. SMP writes the member at #cmd("ACCEPT").],
  )
] <apx-package-tab-datasets>
#idx("ISF.LINKLIB")#idx("ISF.AISFLOAD")#idx("ISF.ISFLOAD")#idx("ISF.TISFPLIB")#idx("ISF.TISFCLST")#idx("SYS1.LPALIB")#idx("SYS1.AOST4")

SMP reads the load module from the staging library through the DD name
#cmd("ISFLOAD"). It reads each panel and the CLIST through a DD named like the
member, which the installation and accept jobs give it.

The allocation job makes the six libraries with #cmd("DSORG=PO"), a primary of
5 cylinders and a secondary of 2, on the volumes #cmd("TGTVOL") (the three
target libraries) and #cmd("DLBVOL") (the three distribution libraries). The
directory has 20 blocks for the load library and the CLIST library and 37 for
the panel library. The defaults of the volumes are those of MVS/CE
(#cmd("MVSRES") and #cmd("SMP000")); the installation guide gives the values
for TK5.

#note[#cmd("ISF.LINKLIB") must be APF-authorized and in the link list, and
must not be in #cmd("ISPLLIB"), nor in a #cmd("STEPLIB") that is not all
APF-authorized. A program loaded from there is not loaded as authorized, and
SDSF then falls back to SVC 244. The installation guide, in the package,
gives the steps.]

== The Members <apx-package-members>

=== ISF.LINKLIB <apx-package-linklib>

#idx("ISFISP")#idx("IGX00011")
The library has one member.

#tab(caption: [The member of ISF.LINKLIB])[
  #table(columns: (0.95in, 1fr),
    [Member], [What it is],
    [#cmd("ISFISP")], [SDSF itself: the program that shows the panels and does
      the work. The CLIST #cmd("SDSF") starts it under ISPF. It runs
      unauthorized and switches to the authorized state only around the few
      calls that need it, through #cmd("IGX00011").],
  )
]

#cmd("ISF.AISFLOAD") and #cmd("ISF.ISFLOAD") hold the same member.

=== IGX00011 in SYS1.LPALIB and SYS1.AOST4 <apx-package-igx>

#idx("IGX00011")
#cmd("IGX00011") is the SVC routine of SDSF: an extended SVC routine, SVC 109
with code 11. It grants the switch to the authorized state only to a program
whose name begins with #cmd("ISF") and that was loaded from an
APF-authorized library or the LPA. It is written in assembler, reentrant,
serially reusable and refreshable. @apx-svc describes it.

The package does not carry it as a load module but as assembler source, inside
the installation job. The step #cmd("ASSEM") assembles it, and SMP links it
into #cmd("SYS1.LPALIB") and keeps it in #cmd("SYS1.AOST4"), as it does the
SVC routines of the system. It is not in #cmd("ISF.LINKLIB"). It takes effect
at an IPL with CLPA.

=== ISF.ISFCLST <apx-package-clist>

#idx("CLIST")
The library has one member, #cmd("SDSF"). It is what #cmd("TSO SDSF") runs.
Its whole text is:

#code("PROC 0
/* SDSF: START IT UNDER ISPF, WITH TSO SDSF FROM AN ISPF COMMAND LINE */
ISPEXEC SELECT PGM(ISFISP) NOCHECK NEWAPPL(ISF)")

The CLIST starts #cmd("ISFISP") as an ISPF program, in the application
#cmd("ISF"). For #cmd("TSO SDSF") to find the CLIST, #cmd("ISF.ISFCLST") must
be in the #cmd("SYSPROC") concatenation.

=== ISF.ISFPLIB <apx-package-isfplib>

#idx("ISF.ISFPLIB")#idx("ISF.AISFPLIB")#idx("panels", "members of ISF.ISFPLIB")
The library has 82 members, all of them ISPF panels. Two draw the screens of
SDSF. The other 80 are the help, the tutorial and the index. A member name is
the name of its file in the repository, in upper case.

The first letters of a help or tutorial member name tell its kind:

#deflist(width: 1.1in,
  [#cmd("ISFH")], [Help. 45 members: the help of the panels
    (@apx-package-help), the help on help, on the contents and on
    authorization (@apx-package-helpother), and the messages
    (@apx-package-messages).],
  [#cmd("ISFK")], [Help for commands. 13 members (@apx-package-cmdhelp).],
  [#cmd("ISFX")], [The index. 5 members (@apx-package-index).],
  [#cmd("ISFT")], [The tutorial. 17 members (@apx-package-tutorial).],
)

SDSF itself shows the help and the tutorial pages, and follows the keys and
the topic numbers on them. #cmd("ISFHHELP") describes them.

==== The Panels of SDSF <apx-package-screens>

#tab(caption: [The panels that draw SDSF])[
  #table(columns: (0.95in, 1fr),
    [Member], [What it is],
    [#cmd("ISFMENU")], [The primary option menu, #cmd("SDSF PRIMARY OPTION MENU"):
      the eight panels with their commands, #cmd("TUTOR") and #cmd("END"). It
      has the title line, the command line and the SCROLL field.],
    [#cmd("ISFLIST")], [The panel of every other screen: the lists ST, DA, I, O,
      H, PR and INIT, the Job Data Set panel, the Output Data Set panel and the
      system log. It has a title line and one data area that SDSF fills,
      command line and SCROLL field included.],
  )
]

==== The Help of the Panels <apx-package-help>

Each panel of SDSF has a topic of its own in the help: one page that says what
the panel shows and lists the topics below it, and, where the panel has them,
further pages for its command, its action characters, its fields and its
overtypeable fields. The Help key shows the page of the panel you are on.

#tab(caption: [Help for the panels])[
  #table(columns: (0.95in, 1fr),
    [Member], [What it shows],
    [#cmd("ISFHMN")], [The primary option menu.],
    [#cmd("ISFHST")], [The Status panel: what it lists, the order, and its
      topics.],
    [#cmd("ISFHSTC")], [The #cmd("ST") command: limiting the list by class and
      job name.],
    [#cmd("ISFHSTA")], [The action characters of the Status panel.],
    [#cmd("ISFHSTF")], [The fields of the Status panel.],
    [#cmd("ISFHSTF2")], [The further fields of the Status panel, shown with
      #cmd("?").],
    [#cmd("ISFHSTO")], [Overtyping fields on the Status panel (#cmd("PRTY"),
      #cmd("DEST")).],
    [#cmd("ISFHSTM")], [The commands that work on the Status panel.],
    [#cmd("ISFHDA")], [The DA panel: the active address spaces, and its
      topics.],
    [#cmd("ISFHDAC")], [The #cmd("DA") command.],
    [#cmd("ISFHDAA")], [The action characters of the DA panel.],
    [#cmd("ISFHDAF")], [The fields of the DA panel.],
    [#cmd("ISFHDAF2")], [The further fields of the DA panel, to the right of
      #cmd("JOBNAME").],
    [#cmd("ISFHIQ")], [The Input Queue panel, and its topics.],
    [#cmd("ISFHIQC")], [The #cmd("I") command.],
    [#cmd("ISFHIQA")], [The action characters of the Input Queue panel.],
    [#cmd("ISFHIQF")], [The fields of the Input Queue panel.],
    [#cmd("ISFHIQO")], [Overtyping fields on the Input Queue panel.],
    [#cmd("ISFHOQ")], [The Output Queue panel, and its topics.],
    [#cmd("ISFHOQC")], [The #cmd("O") command.],
    [#cmd("ISFHOQF")], [The fields of the Output Queue panel.],
    [#cmd("ISFHHQ")], [The Held Output panel, and its topics.],
    [#cmd("ISFHHQC")], [The #cmd("H") command.],
    [#cmd("ISFHHQF")], [The fields of the Held Output panel.],
    [#cmd("ISFHPR")], [The Printer panel, and its topics.],
    [#cmd("ISFHPRC")], [The #cmd("PR") command.],
    [#cmd("ISFHPRA")], [The action characters of the Printer panel.],
    [#cmd("ISFHPRF")], [The fields of the Printer panel.],
    [#cmd("ISFHIT")], [The Initiator panel: its fields and its action
      characters.],
    [#cmd("ISFHLG")], [The system log panel.],
    [#cmd("ISFHLGM")], [Moving around on the system log.],
    [#cmd("ISFHJD")], [The Job Data Set panel and its fields.],
    [#cmd("ISFHOD")], [The Output Data Set panel.],
    [#cmd("ISFHODM")], [Moving around on the Output Data Set panel.],
    [#cmd("ISFHLSM")], [The commands that work on the list panels.],
  )
]

==== Help for Commands <apx-package-cmdhelp>

#tab(caption: [Help for the commands that work on every panel])[
  #table(columns: (0.95in, 1fr),
    [Member], [What it shows],
    [#cmd("ISFKALL")], [The list of the commands you can give on every panel,
      with the topic of each.],
    [#cmd("ISFKSL")], [The #cmd("/") command (an operator command) and the
      #cmd("TSO") command.],
    [#cmd("ISFKPRE")], [The #cmd("PREFIX") command.],
    [#cmd("ISFKDEST")], [The #cmd("DEST") command.],
    [#cmd("ISFKFIND")], [The #cmd("FIND") command.],
    [#cmd("ISFKFND2")], [#cmd("FIND"), more: examples, and the limit on the
      lines one #cmd("FIND") looks through.],
    [#cmd("ISFKSCR")], [Scrolling: #cmd("UP"), #cmd("DOWN"), #cmd("TOP"),
      #cmd("BOTTOM"), #cmd("LEFT"), #cmd("RIGHT") and the SCROLL field.],
    [#cmd("ISFKPRT")], [The #cmd("PRINT") command.],
    [#cmd("ISFKPRT2")], [#cmd("PRINT"): examples.],
    [#cmd("ISFKACT")], [The #cmd("ACTION") command: which replies show at the
      end of the log.],
    [#cmd("ISFKSYS")], [The #cmd("SYSID") command.],
    [#cmd("ISFKSET")], [The #cmd("INPUT"), #cmd("SET HEX") and
      #cmd("FINDLIM") commands.],
    [#cmd("ISFKWHO")], [The #cmd("WHO") and #cmd("RETRIEVE") commands.],
  )
]

==== Contents, Help on Help and Authorization <apx-package-helpother>

#tab(caption: [Other help panels])[
  #table(columns: (0.95in, 1fr),
    [Member], [What it shows],
    [#cmd("ISFHTOC")], [The table of contents of the help: the topic that each
      number leads to. Typing #cmd("T") on any help page shows it.],
    [#cmd("ISFHHELP")], [Using the help and the tutorial: the keys and the
      topic numbers.],
    [#cmd("ISFHAUTH")], [Who may see and do what: the rules for jobs and for
      the system.],
    [#cmd("ISFHAUT2")], [The same, continued: the authorized state, and the
      messages you get without it.],
  )
]

==== The Messages <apx-package-messages>

The help explains the messages of the title line in alphabetical order. Six
members divide the alphabet.

#tab(caption: [The message pages])[
  #table(columns: (0.95in, 1fr),
    [Member], [Messages],
    [#cmd("ISFHMS1")], [A to C.],
    [#cmd("ISFHMS2")], [C to I.],
    [#cmd("ISFHMS3")], [I to J.],
    [#cmd("ISFHMS4")], [L to N.],
    [#cmd("ISFHMS5")], [N to P.],
    [#cmd("ISFHMS6")], [P to Z.],
  )
]

==== The Index <apx-package-index>

#idx("index", "of the help")
The index lists the subjects of the help in alphabetical order. The number of
a subject leads to its topic. Typing #cmd("I") on a help page shows it.

#tab(caption: [The index pages])[
  #table(columns: (0.95in, 1fr),
    [Member], [Subjects],
    [#cmd("ISFXA")], [A to D.],
    [#cmd("ISFXD")], [D to I.],
    [#cmd("ISFXJ")], [J to O.],
    [#cmd("ISFXP")], [P.],
    [#cmd("ISFXR")], [R to Z.],
  )
]

==== The Tutorial <apx-package-tutorial>

#idx("tutorial")
The tutorial, started with #cmd("TUTOR"), is a short course in seven parts.
Parts 2 to 6 have more than one page.

#tab(caption: [The pages of the tutorial])[
  #table(columns: (0.95in, 0.55in, 1fr),
    [Member], [Part], [What it shows],
    [#cmd("ISFTUTOR")], [], [The start: what the course is, and the list of
      its parts.],
    [#cmd("ISFTNAV")], [1], [Using the tutorial.],
    [#cmd("ISFTPAN")], [2], [The SDSF panels.],
    [#cmd("ISFTPAN2")], [2], [The SDSF panels, a list.],
    [#cmd("ISFTJOB")], [3], [Following a job.],
    [#cmd("ISFTJOB2")], [3], [Following a job, the Status panel.],
    [#cmd("ISFTJOB3")], [3], [Following a job, its data sets.],
    [#cmd("ISFTOUT")], [4], [Looking at output.],
    [#cmd("ISFTOUT2")], [4], [Looking at output, the data set.],
    [#cmd("ISFTOUT3")], [4], [Looking at output, #cmd("FIND") and
      #cmd("PRINT").],
    [#cmd("ISFTACT")], [5], [Acting on jobs.],
    [#cmd("ISFTACT2")], [5], [Acting on jobs, holding a job.],
    [#cmd("ISFTACT3")], [5], [Acting on jobs, a held job.],
    [#cmd("ISFTLIM")], [6], [Showing fewer jobs.],
    [#cmd("ISFTLIM2")], [6], [Showing fewer jobs, classes.],
    [#cmd("ISFTLIM3")], [6], [Showing fewer jobs, class A.],
    [#cmd("ISFTSUM")], [7], [A summary.],
  )
]


== What SMP Records <apx-package-smp>

#idx("FMID")#idx("SYSMOD")
The installation job carries one SYSMOD, a function, and receives it in its
step #cmd("RECV"). Its identifier, the *FMID*, is made of #cmd("T"),
#cmd("ISF") and the version without the dots: #cmd("TISF120") is the FMID of
1.2.0. The header of the installation job
names the FMID.

The SYSMOD:

- names the system level #cmd("Z038") in a #cmd("++VER") statement and no
  requisite;
- has a #cmd("JCLIN") with two steps. The first copies #cmd("ISFISP") with
  #cmd("IEBCOPY") from #cmd("AISFLOAD") to #cmd("ISFLINK"). The second links
  #cmd("IGX00011") from #cmd("AOST4") into #cmd("SYS1.LPALIB") as reentrant,
  serially reusable and refreshable;
- has two modules: #cmd("++MOD(ISFISP)"), read from the staging library
  (#cmd("LKLIB(ISFLOAD)")) and kept in #cmd("AISFLOAD"), and
  #cmd("++MOD(IGX00011)"), kept in #cmd("AOST4"), with the object deck that
  #cmd("ASSEM") made right behind it;
- has 83 macro elements, #cmd("++MAC"): the CLIST #cmd("SDSF") for
  #cmd("ISFCLST") and #cmd("AISFCLST"), and the 82 panels for
  #cmd("ISFPLIB") and #cmd("AISFPLIB"). Each is read from its staging library
  through a #cmd("TXLIB") of its own and is kept in the distribution library
  under its own name.

#tab(caption: [Where SMP keeps the SYSMOD])[
  #table(columns: (1.6in, 1fr),
    [SMP data], [What it holds],
    [The PTS], [The SYSMOD as received.],
    [The target zone (CDS)], [The SYSMOD after #cmd("APPLY"), with its two
      modules, the load modules #cmd("ISFISP") and #cmd("IGX00011") (an
      entry for a load module exists in this zone only), and the 83 macro
      elements.],
    [The distribution zone (ACDS)], [The SYSMOD after #cmd("ACCEPT"), with its
      two modules and the 83 macro elements, as accepted into the
      distribution libraries.],
  )
]

A #cmd("LIST") of the FMID in the target zone shows its status:

#code(" LIST CDS SYSMOD(TISF120) .")

After the accept job it says #cmd("STATUS = REC APP ACC").

=== The Return Codes of a First Installation <apx-package-rc>

#idx("return codes", "of the installation")
A return code says that a job ran, not that the work happened. On a first
installation two steps end with return code 4, and one prints an error
message and still ends with 0. All three are right.

#tab(caption: [What a first installation shows])[
  #block(breakable: false)[#table(columns: (1.0in, 0.8in, 1fr),
    [Step], [Return code], [What the output says, and why],
    [#cmd("DELOLD")], [0], [#cmd("IDC0551I ** ENTRY ISF.ISFLOAD NOT DELETED") and
      #cmd("HIGHEST CONDITION CODE WAS 8"): the step deletes a staging library
      left from an earlier run, and there is none. The step still ends with 0.],
    [#cmd("ASSEM")], [0], [#cmd("NO STATEMENTS FLAGGED").],
    [#cmd("APPLY")], [4], [#cmd("HMA2391 LINK SUCCESSFUL") with
      #cmd("RETURN CODE=08") and #cmd("IEW0342"). SMP links #cmd("IGX00011")
      into #cmd("SYS1.LPALIB") and first tries to include the module that is
      there. A first installation has none.],
    [#cmd("ACCEPT")], [4], [#cmd("HMA2471 BLDL FAILED IN LIBRARY AOST4"), then
      #cmd("HMA2390 LINK SUCCESSFUL"). The same reason: #cmd("IGX00011") is not
      yet in #cmd("SYS1.AOST4").],
  )]
]

To check an installation, list the members of the libraries as this appendix
names them, and read the output of the #cmd("APPLY") step. It has
#cmd("HMA2380 COPY SUCCESSFUL") with #cmd("MOD=ISFISP"),
#cmd("LMOD=ISFISP") and #cmd("LIBRARY=ISFLINK"), and
#cmd("HMA2391 LINK SUCCESSFUL") for #cmd("IGX00011") into #cmd("LPALIB").
#cmd("ISF.LINKLIB") has
#cmd("ISFISP") and no #cmd("IGX00011"), #cmd("ISF.ISFPLIB") has the 82 panels
and #cmd("ISF.ISFCLST") has #cmd("SDSF"). After the accept job,
#cmd("ISF.AISFLOAD") has #cmd("ISFISP"), #cmd("SYS1.AOST4") has
#cmd("IGX00011"), #cmd("ISF.AISFPLIB") has the panels and
#cmd("ISF.AISFCLST") has the CLIST.

== What the Installation Changes in the System <apx-package-system>

#idx("system changes")
SMP writes the data sets of @apx-package-datasets and its own data sets. The
rest of the installation is yours to do, and it changes the system.

#tab(caption: [Changes outside the data sets of the package])[
  #table(columns: (1.9in, 1fr),
    [Where], [What changes],
    [#cmd("SYS1.PARMLIB(IEAAPF00)")], [A line for #cmd("ISF.LINKLIB") with its
      volume, the volume of #cmd("TGTVOL"). An entry of the same name on
      another volume does not authorize this library.],
    [#cmd("SYS1.PARMLIB(LNKLST00)")], [A line for #cmd("ISF.LINKLIB"), so that
      ISPF finds #cmd("ISFISP") in the link list.],
    [the ISPPLIB concatenation], [#cmd("ISF.ISFPLIB") is added. How depends on
      how the system starts ISPF.],
    [the SYSPROC concatenation], [#cmd("ISF.ISFCLST") is added.],
    [the RAKF profiles], [The FACILITY profile #cmd("SDSF.OPER"), and for the
      jobs of other users profiles in the class JESSPOOL. On TK5 and on MVS/CE
      RAKF reads its profiles from #cmd("SYS1.SECURE.CNTL(PROFILES)").
      @ref-auth describes the
      profiles.],
  )
]

The LPA needs no step of yours: SMP has put #cmd("IGX00011") into
#cmd("SYS1.LPALIB"). #cmd("IEAAPF00"), #cmd("LNKLST00") and the LPA are read
at IPL, so the installation needs one IPL with CLPA. The concatenations take
effect at the next logon. The installation guide shows the lines to add, for
TK5 and for MVS/CE.

== Removing SDSF <apx-package-remove>

#idx("removal")#idx("UCLIN")
The package carries #cmd("uninstall.md"), which gives the jobs. This section
says what they take out. There is no #cmd("RESTORE") or #cmd("REJECT") for an
accepted function, so the way back is an SMP #cmd("UCLIN") that deletes the
entries of the inventory.

- *The inventory.* In each zone the entries of the SYSMOD #cmd("TISF120"), of
  its two modules, and of its 83 macro elements. The entries of the two load
  modules exist in the target zone only. An element entry left behind makes a
  later installation of the same element report #cmd("NOT SEL") and copy
  nothing, at return code 0. The #cmd("UCLIN") of the target zone has 88
  statements and that of the distribution zone 86.
- *The data sets.* An IDCAMS job deletes the six libraries of
  @apx-package-datasets and the members #cmd("IGX00011") of
  #cmd("SYS1.LPALIB") and #cmd("SYS1.AOST4"). The copy in the running LPA
  stays until the next IPL with CLPA.
- *The system.* You take #cmd("ISF.LINKLIB") out of #cmd("IEAAPF00") and
  #cmd("LNKLST00"), the two libraries out of the concatenations, and the RAKF
  rules for SDSF out if nobody needs them, and then IPL with CLPA.

Submit the jobs under a user with update access to #cmd("SYS1.SMPCDS") and
#cmd("SYS1.SMPACDS"), from TSO with #cmd("SUBMIT"), which puts the user's id
into the job. Through the card reader a job runs without a user, and RAKF
then refuses the SMP data sets with #cmd("ABEND S913").

A #cmd("LIST") of the removed entries ends with return code 4 when every entry
is reported as not found: that means the inventory is clean.

Measured on MVS/CE, the jobs end as follows. Each #cmd("UCLIN") step ends with
return code 0: the #cmd("UCLIN") for #cmd("TISF120") reports #cmd("HMA2550")
174 times, one for each of its statements. The #cmd("LIST") steps end with
return code 4 and report every entry as not found. The IDCAMS job ends with
return code 0.

== What Is Not in the Package <apx-package-not>

#idx("package", "not included")
The package holds no source of SDSF except the assembler source of
#cmd("IGX00011"). The build of the repository makes four more programs,
#cmd("ISFWAIT"), #cmd("ISFWTOR"), #cmd("ISFSVCT") and #cmd("ISFJOWN"). They
are test and diagnostic tools for the development of SDSF. They are not part
of the SMP package and not in #cmd("ISF.LINKLIB").
