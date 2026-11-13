#import "../bookmaster/bookmaster.typ": *

= Glossary <ug-glossary>

#idx("glossary")
This glossary explains the words that this book uses for the things SDSF shows
and does, in alphabetical order. An entry names the chapter that describes the
thing, and a word in italic type refers to another entry. The _SDSF Reference_
describes every command, panel, action character, message and authorization
rule in full\; the glossary says what a word means and where to read on.

#deflist(width: 1.75in,
  [*action character*],
  [One or two characters typed in the NP column of a row on a list panel.
   SDSF carries it out on that row: #cmd("S") shows the output of a job,
   #cmd("H") holds it. It is not a command and is not typed on the command
   line (@ug-start-np). The Reference describes every one in the chapter
   “Action Characters”.],
  [*address space*],
  [What a row of the DA panel shows: a batch job, a started task, a TSO user
   or an idle initiator that runs on the system. The books say “address
   space” where they speak of the system, and “job” where they speak of the
   JES2 job (@ug-running).],
  [*APF-authorized library*],
  [A library whose programs are allowed to run as authorized programs, named
   by an APF entry. #cmd("ISF.LINKLIB") must be one, and must be in the link
   list (@ug-install-apf). Not the same as the authorized state of SDSF,
   which SDSF asks for while it runs.],
  [*APF entry*],
  [The line that names a library, with its volume, in
   #cmd("SYS1.PARMLIB(IEAAPF00)"). See _APF-authorized library_
   (@ug-install-apf).],
  [*ASID*],
  [The number of an address space. The DA panel lists its rows in ASID order.
   The master address space has ASID 1 (@ug-running).],
  [*authorized state*],
  [A second condition besides RAKF. SDSF runs unauthorized and asks the
   system for the authorized state for the moments it needs it: to read the
   log and the outstanding replies, to purge a job, and to give JES2 and
   operator commands. It gets it from its own SVC routine or, where that is
   not installed or refuses the call, through SVC 244. Not to be confused
   with access in RAKF (@ug-access). The Reference describes it in the
   chapter “Authorization”.],
  [*batch job*],
  [A job with TYPE #cmd("JOB"), as against a started task (#cmd("STC")) and a
   TSO user (#cmd("TSU")). See _job_.],
  [*beta*],
  [Version 0.9.0 of SDSF (FMID #cmd("TISF090")). There is no upgrade from it:
   it is removed first, and then 1.2.0 is installed as a first installation
   (@ug-install-beta).],
  [*cancel*],
  [#cmd("C") on a job: the job ends and its output stays. #cmd("CD") cancels
   it and asks for a dump. Compare _purge_.],
  [*class (job)*],
  [The one-character class of a batch job, shown in the #cmd("C") column.
   Classes written directly after #cmd("ST"), #cmd("I"), #cmd("O") or
   #cmd("H") limit the list to the jobs of those classes (@ug-jobs,
   @ug-queues).],
  [*class (RAKF)*],
  [A group of RAKF profiles. SDSF asks about two: JESSPOOL, for the jobs of
   other users, and FACILITY, for the system. See _profile_ and _entity_
   (@ug-access).],
  [*CLPA*],
  [See _IPL with CLPA_.],
  [*column*],
  [A column of a panel and a field of a row are the same thing, seen from the
   panel or from the row. Its name is the heading on the screen:
   #cmd("JOBNAME"), #cmd("JNUM"), #cmd("PRTY"). The Reference describes the
   columns of each panel in the chapter “Panels”. On the Output Data Set
   panel and on the log, “column” also means a character position in a line
   (@ug-search-columns).],
  [*command*],
  [What you type on the command line. An SDSF command is one of SDSF's own
   (#cmd("ST"), #cmd("PREFIX"), #cmd("FIND")). An operator command begins
   with #cmd("/") and a TSO command with #cmd("TSO"). The Reference describes
   them in the chapter “Commands”.],
  [*COMMAND ISSUED*],
  [The message that says SDSF gave a command to JES2 or to the system. It
   does not say that the system took the command; the answer is in the system
   log. See _JES2 command_.],
  [*command line*],
  [The field after #cmd("COMMAND INPUT ===>"), on every panel. It holds up to
   60 characters (@ug-start-cmdline).],
  [*contents*],
  [The table of contents of the help, shown by #cmd("T") in the help. See
   _help_.],
  [*DA panel*],
  [The panel that #cmd("DA") shows: the active address spaces (Display Active
   users) and what each one uses (@ug-running).],
  [*data set (of a job)*],
  [One output data set of a job, a row of the Job Data Set panel. JES2 writes
   three of its own for every job: #cmd("JESMSGLG") (the job log),
   #cmd("JESJCL") and #cmd("JESYSMSG"). With #cmd("INPUT ON") the input of
   the job is listed as well (@ug-jobs).],
  [*destination*],
  [Where the output of a job goes: #cmd("LOCAL"), a remote
   (#cmd("R")#var("n")) or a user destination (#cmd("U")#var("n")). The
   #cmd("DEST") command limits the lists by it. Not the same as the system
   (@ug-log).],
  [*distribution library*],
  [Where SMP keeps an element once the accept job has run:
   #cmd("ISF.AISFLOAD"), #cmd("ISF.AISFPLIB") and #cmd("ISF.AISFCLST").
   Compare _target library_ and _staging library_. The Reference lists them
   in the appendix “Data Sets and Members of the Package”.],
  [*Down key (PF8)*],
  [Scrolls down by the scroll amount. At the end of the system log it reads
   the log again (@ug-start-scroll).],
  [*element*],
  [A member that SMP installs by name: the modules (#cmd("++MOD")) and, as
   macros (#cmd("++MAC")), the panels and the CLIST. SMP's word
   (@ug-install).],
  [*End key (PF3)*],
  [Goes back one step. From the primary option menu it leaves SDSF
   (@ug-start-keys).],
  [*Enter*],
  [Runs what stands on the command line, in the NP column and in the fields
   you typed over. With none of them, a list panel and the log are read
   again. See _read again_ (@ug-start-keys).],
  [*entity*],
  [The name SDSF asks RAKF about. For a job of another user it is
   #var("owner")#cmd(".")#var("jobname")#cmd(".")#var("jobid") in the class
   JESSPOOL, for example #cmd("HERC02.PAYROLL.JOB01234"). For the system it
   is #cmd("SDSF.OPER") in the class FACILITY. RAKF answers from the profile
   that covers the entity (@ug-access).],
  [*FACILITY*],
  [The RAKF class of the operator profile #cmd("SDSF.OPER") and, where SDSF
   uses SVC 244, of the profile #cmd("SVC244").],
  [*field*],
  [See _column_.],
  [*FMID*],
  [The identifier of the SMP SYSMOD of SDSF: #cmd("TISF120") for 1.2.0
   (@ug-install).],
  [*follow a job*],
  [Watch the #cmd("QUEUE") column of the job on the Status panel:
   #cmd("EXECUTION") while it waits and runs, #cmd("PRINT") when it has
   ended. Press Enter with nothing typed to read the list again (@ug-jobs).],
  [*further fields*],
  [Fields that the usual row does not show. #cmd("?") typed alone on the
   command line of the Status and the Input Queue panel switches to them. On
   the DA panel, the Right key (PF11) brings the part of the row on the right
   into view. The Reference describes them in the chapter “Commands”, under
   #cmd("?").],
  [*held job*],
  [A job that waits to execute and does not start: #cmd("HOLD") in the
   #cmd("STAT") column. #cmd("H") on the Status panel holds a job, #cmd("A")
   releases it. Not held output (@ug-queues).],
  [*held output*],
  [The output of a job that has ended and is not printed until it is
   released. The Held Output panel (#cmd("H")) lists it, and #cmd("O")
   releases it. Not a held job (@ug-queues).],
  [*Held Output panel*],
  [The panel that #cmd("H") shows: the jobs with held output (@ug-queues).],
  [*help*],
  [The help panels of SDSF. The Help key (PF1) or #cmd("HELP") shows the help
   of the panel you are on. In the help, #cmd("T") shows the contents and
   #cmd("I") the index. The Reference describes it under #cmd("HELP") in the
   chapter “Commands”.],
  [*Help key (PF1)*],
  [Shows the help of the panel you are on. With something typed on the
   command line, the text is the command and the key is not looked at
   (@ug-start-keys).],
  [*hexadecimal display*],
  [#cmd("SET HEX ON") shows each line of output or of the log also as
   hexadecimal digits, in four rows. SDSF does not keep the setting
   (@ug-search-columns).],
  [*IBM's SDSF V1R2*],
  [The product that SDSF is modeled on, as far as you can see and do things
   with it. “SDSF” alone is always this product. The Reference lists the
   differences in the chapter “Differences from IBM's SDSF V1R2” (@ug-intro).],
  [*idle initiator*],
  [An initiator that runs no job. On the DA panel its #cmd("TYPE") is blank
   and it has no job number, and it is shown only if you ask for it
   (#cmd("DA INIT")). An initiator that runs a job shows as that job
   (@ug-running).],
  [*index*],
  [The index of the help, shown by #cmd("I") in the help. See _help_.],
  [*initiator*],
  [A JES2 initiator starts jobs. The Initiator panel lists them
   (@ug-devices).],
  [*Initiator panel*],
  [The panel that #cmd("INIT") shows: the JES2 initiators. #cmd("S"),
   #cmd("P") and #cmd("Z") start, stop and halt one (@ug-devices).],
  [*input queue*],
  [The jobs that have been read in and wait to execute, or execute. The Input
   Queue panel (#cmd("I")) lists them (@ug-queues).],
  [*IPL with CLPA*],
  [The restart of the system that rebuilds the link pack area from
   #cmd("SYS1.LPALIB"). The SVC routine takes effect only after one, so the
   installation needs one (@ug-install-ipl).],
  [*ISPF profile*],
  [Where SDSF keeps some of your settings from one session to the next: the
   scroll amount, #cmd("PREFIX"), #cmd("DEST"), #cmd("ACTION") and the last
   #cmd("FIND") (@ug-start-profile).],
  [*JES2 command*],
  [The command that an action character or an overtype makes SDSF give to
   JES2. #cmd("C") on batch job 1234 of the Status panel gives
   #cmd("$CJ1234"). The Reference lists them in the chapter “Action
   Characters”, section “The Command Each Action Issues”.],
  [*JNUM*],
  [The JES2 job number, in the #cmd("JNUM") column. Two jobs of the same name
   differ in it. On the DA panel it is the number of the executing job of the
   same name and type, and an address space without a JES2 job has none
   (@ug-jobs, @ug-running).],
  [*job*],
  [A batch job, a started task or a TSO user, where the text need not tell
   them apart. They differ in TYPE: #cmd("JOB"), #cmd("STC") and #cmd("TSU").
   Your own jobs are the jobs that run under your user id (@ug-access).],
  [*Job Data Set panel*],
  [The panel that #cmd("?") on a job shows: the data sets of one job. Its
   title reads #cmd("SDSF JOB DATA SET DISPLAY") (@ug-jobs).],
  [*key (PF key)*],
  [SDSF has no key assignments of its own: a key does what the command it
   carries says. The books name a key by its command first and its default
   position after, as in “the End key (PF3)”. The Reference lists every key
   in the appendix “PF Key Assignments” (@ug-start-keys).],
  [*Left key (PF10)*],
  [Moves the columns of a row, or the text of a line, to the left
   (@ug-start-scroll).],
  [*link list*],
  [The libraries MVS searches for a program when a job gives no STEPLIB
   (#cmd("LNKLST00")). #cmd("ISF.LINKLIB") is put into it (@ug-install-apf).],
  [*list panel*],
  [A panel with a row per job, address space, printer or initiator: Status,
   DA, Input Queue, Output Queue, Held Output, Printer and Initiator. Action
   characters are typed on them (@ug-start-np).],
  [*master address space*],
  [The address space with #cmd("ASID") 1. Its #cmd("JNUM") is the number of
   the executing #cmd("SYSLOG") task, and the action characters on its row
   act on that task (@ug-running).],
  [*master trace table*],
  [The part of the system log that the system keeps in storage. SDSF reads
   the log from it, so the log holds only what the table still has (@ug-log).],
  [*MVS command*],
  [A command for MVS itself, not for JES2. Typing over #cmd("PGN") on the DA
   panel makes SDSF give one, #cmd("E")
   #var("name")#cmd(",PERFORM=")#var("n"). Compare _JES2 command_ and
   _operator command_ (@ug-running).],
  [*NP column*],
  [The first column of a row on a list panel, where action characters are
   typed (@ug-start-np).],
  [*operator command*],
  [An MVS or a JES2 command that you give with #cmd("/") at the start of the
   command line, as from the master console: #cmd("/D A,L"). The answer is in
   the system log, and you need update access to #cmd("SDSF.OPER") (@ug-log).],
  [*operator profile*],
  [The profile #cmd("SDSF.OPER") in the class FACILITY. It guards the side of
   the system: the log, the printers, the initiators, the operator commands
   and the address spaces without a job. The Reference says “the profile
   #cmd("SDSF.OPER")” (@ug-access).],
  [*Output Data Set panel*],
  [The panel that #cmd("S") on a job or on a data set shows: the text of the
   output as it would be printed. You cannot change the output (@ug-jobs).],
  [*output queue*],
  [The jobs that have ended and have output waiting to be printed that is not
   held. The Output Queue panel (#cmd("O")) lists them (@ug-queues).],
  [*outstanding reply*],
  [A message of the system that waits for an answer. The #cmd("ACTION")
   command chooses which outstanding replies SDSF shows after the last line
   of the log. You answer with #cmd("/R") #var("nn")#cmd(",")#var("answer"),
   where #var("nn") is the reply number (@ug-log).],
  [*overtype*],
  [To type a new value over a field of a row and press Enter. SDSF gives the
   command that makes the change. Fields that allow it are overtypeable:
   #cmd("PRTY") and #cmd("DEST") on the Status panel, for example. The
   Reference lists them in the chapter “Action Characters”, section
   “Overtyping Fields”.],
  [*package*],
  [The files of a release that install SDSF, an SMP Release 4 package: three
   TRANSMIT files, three jobs (allocation, installation, accept),
   #cmd("README.md") and #cmd("uninstall.md") (@ug-install).],
  [*panel*],
  [One screen of SDSF. The panels are the primary option menu, the list
   panels, the Job Data Set and Output Data Set panels, and the system log.
   @ug-intro lists them with their commands. The Reference describes each in
   the chapter “Panels”.],
  [*performance group*],
  [The #cmd("PGN") column of the DA panel. Typing a new number over it moves
   the address space to another performance group (@ug-running).],
  [*position*],
  [On the DA panel, the #cmd("POS") column: #cmd("IN") in storage,
   #cmd("OUT") swapped out, #cmd("N/S") not swappable (which counts as in).
   On the Status and Input Queue panels, #cmd("POS") is the place of a
   waiting job in the line of its class (@ug-running, @ug-jobs).],
  [*prefix*],
  [The job name limit that #cmd("PREFIX") sets. It limits the Status, Input
   Queue, Output Queue and Held Output panels, and SDSF keeps it in your ISPF
   profile. The name typed with #cmd("ST") is “the name”, not “the prefix”.
   Not the #cmd("PREFIX") kind of #cmd("FIND") (@ug-jobs).],
  [*preview*],
  [An earlier SDSF that came with TK5 and sits in the libraries of the system
   (#cmd("SYS2.SDSF.LOAD"), #cmd("SYS2.ISP.PLIB"), #cmd("SYS2.CMDPROC")). It
   is removed before 1.2.0 is installed. Not the beta (@ug-install-before).],
  [*primary option menu*],
  [The first panel of SDSF, titled #cmd("SDSF PRIMARY OPTION MENU"). You
   choose a panel by typing its name. #cmd("END") leaves SDSF
   (@ug-start-menu).],
  [*Printer panel*],
  [The panel that #cmd("PR") shows: the JES2 printers (@ug-devices).],
  [*profile (RAKF)*],
  [A rule in a RAKF class. SDSF asks RAKF for an access level to an entity,
   and the profile that covers the entity answers. Not the ISPF profile
   (@ug-access).],
  [*purge*],
  [#cmd("P") on a job: the job ends and its output is deleted. Compare
   _cancel_ (@ug-start-np).],
  [*RAKF*],
  [The security product of MVS 3.8j. SDSF asks it about every job of another
   user and about the system (@ug-access).],
  [*read access*],
  [RAKF's READ to a job or to #cmd("SDSF.OPER"). It lets you see and look; it
   does not let you change anything. Compare _update access_ (@ug-access).],
  [*read again*],
  [Press Enter with nothing typed, and SDSF reads the list or the log again
   and shows the present state. A list does not change by itself, and after
   most action characters the row stays as it was until the next empty Enter
   (@ug-jobs, @ug-start-np).],
  [*release*],
  [#cmd("A") on a held job lets it start. #cmd("O") on held output releases
   it for printing (@ug-queues).],
  [*Repeat-FIND key (PF5)*],
  [Looks again for the last string of #cmd("FIND") (#cmd("RFIND"))
   (@ug-search-find).],
  [*reply number*],
  [The number after the #cmd("@") sign in the line of an outstanding reply,
   the one that #cmd("/R") names (@ug-log).],
  [*Retrieve key (PF12)*],
  [Puts the command you typed before back on the command line. Each further
   press goes one command further back. SDSF keeps the last 10 commands
   (@ug-search-retrieve).],
  [*Right key (PF11)*],
  [Moves the columns of a row, or the text of a line, to the right
   (@ug-start-scroll).],
  [*routing code*],
  [A number from 1 to 16 that the system gives a message. #cmd("ACTION")
   chooses the outstanding replies by it (@ug-log).],
  [*scroll amount*],
  [How far a scroll key moves: #cmd("PAGE"), #cmd("HALF"), #cmd("DATA"),
   #cmd("CSR") or a number of lines. The value stands in the SCROLL field,
   after #cmd("SCROLL ===>"), and SDSF keeps it in your ISPF profile. A word
   typed on the command line before a scroll key is the amount for that one
   scroll (@ug-start-scroll).],
  [*SCROLL field*],
  [See _scroll amount_.],
  [*SDSF*],
  [This product, the spool and system display facility for MVS 3.8j. Compare
   _IBM's SDSF V1R2_ (@ug-intro).],
  [*SDSF.OPER*],
  [See _operator profile_.],
  [*spool class*],
  [The RAKF class JESSPOOL, which guards the jobs of other users. The
   Reference says “the class JESSPOOL” (@ug-access).],
  [*staging library*],
  [The members as received, for SMP to read: #cmd("ISF.ISFLOAD"),
   #cmd("ISF.TISFPLIB") and #cmd("ISF.TISFCLST"). The accept job deletes
   them. Compare _target library_ and _distribution library_ (@ug-install).],
  [*started task*],
  [A job with TYPE #cmd("STC"). See _job_.],
  [*start, stop, halt*],
  [On the Printer and Initiator panels, #cmd("S") starts a printer or an
   initiator, #cmd("P") stops it when its output or its job is done, and
   #cmd("Z") halts it at once. #cmd("S") lets a halted one go on
   (@ug-devices).],
  [*Status panel*],
  [The panel that #cmd("ST") shows: the jobs of all the JES2 queues, in one
   list. It is where you start when you look for a job (@ug-jobs).],
  [*SVC 244*],
  [How SDSF gets the authorized state where its own SVC routine is not
   installed or refuses the call. Then only users with read access to the
   FACILITY profile #cmd("SVC244") have it.],
  [*SVC routine*],
  [#cmd("IGX00011"), the extended SVC routine of SDSF (SVC 109, code 11). SMP
   links it into #cmd("SYS1.LPALIB"). It gives the authorized state to the
   modules of SDSF and to no other program. The Reference describes it in the
   appendix “The SVC Routine” (@ug-install).],
  [*system*],
  [The system whose log the log panel shows, set by #cmd("SYSID"). SDSF reads
   the log of its own system only. Not the destination (@ug-log).],
  [*system log*],
  [What #cmd("LOG") shows: the messages of the system and the commands given
   to it, the oldest first. The title line reads #cmd("SDSF SYSLOG"). You
   need read access to #cmd("SDSF.OPER") (@ug-log).],
  [*target library*],
  [Where SMP installs an element: #cmd("ISF.LINKLIB"), #cmd("ISF.ISFPLIB")
   and #cmd("ISF.ISFCLST"). Compare _distribution library_ and _staging
   library_ (@ug-install).],
  [*title line*],
  [The first line of a panel. Messages appear on it, on the right
   (@ug-start-cmdline).],
  [*TSO command*],
  [A TSO command, a CLIST or a program, given with #cmd("TSO"). It runs in
   your own session, and SDSF asks RAKF nothing for it (@ug-log).],
  [*TSO user*],
  [A TSO session, with TYPE #cmd("TSU"). See _job_.],
  [*tutorial*],
  [The short course that #cmd("TUTOR") starts, in seven parts. The End key
   leaves it (@ug-start-menu).],
  [*update access*],
  [RAKF's UPDATE to a job or to #cmd("SDSF.OPER"). It lets you change what
   the access covers: cancel a job, give an operator command. A user who has
   CONTROL or ALTER has update access in SDSF. Compare _read access_
   (@ug-access).],
  [*Up key (PF7)*],
  [Scrolls up by the scroll amount (@ug-start-scroll).],
  [*Wally ISPF*],
  [The ISPF of MVS 3.8j systems, ISPF 2.2 by Wally Mclaughlin. SDSF runs as a
   dialog under it (@ug-intro).],
  [*wildcard*],
  [In a name on #cmd("ST") or after #cmd("PREFIX"), #cmd("*") stands for any
   number of characters and #cmd("%") for exactly one. Without a wildcard the
   whole name must match (@ug-jobs).],
)
