#import "../bookmaster/bookmaster.typ": *

= Introducing SDSF <ug-intro>

This chapter says what SDSF is, who uses it, how it relates to IBM's SDSF
V1R2, and how this book writes down what you see and type.

== What SDSF Is <ug-intro-what>

#idx("SDSF", "what it is")
SDSF is the spool and system display facility for MVS 3.8j. It runs as a
dialog under ISPF, the Wally ISPF of MVS 3.8j systems, and lets you look at
the JES2 spool and at the running system, and act on what you see, from one
set of panels. You start it from ISPF and leave it with the End key (PF3);
@ug-start describes both.

With SDSF you can:

- *Look at jobs.* The Status panel lists the jobs of all the JES2 queues, and
  the Input Queue, Output Queue and Held Output panels list them queue by
  queue. From a job you open its data sets and read its output (@ug-jobs).
- *Look at the running system.* The DA panel lists the address spaces that
  run, and the SYSLOG panel shows the system log (@ug-running).
- *Look at the JES2 devices.* The Printer and Initiator panels show what the
  printers and the initiators are doing (@ug-devices).
- *Act.* An action character typed in the NP column of a row holds, releases,
  cancels or purges a job, or does the matching work for a printer or an
  initiator. A field you overtype changes a job, a printer or an initiator.
  Most of these make SDSF give a JES2 command for you. From every panel you
  can also give an operator command with #cmd("/") and a TSO command with
  #cmd("TSO") (@ug-log).
- *Search.* #cmd("FIND"), #cmd("LOCATE") and the scroll commands move through
  long output and the log (@ug-search).

@ug-intro-panels lists the panels and the command that shows each one.

#tab(caption: [The panels of SDSF and their commands])[
  #table(columns: (0.9in, 1.9in, 1fr),
    [Command], [Panel], [Shows],
    [#cmd("ST")], [Status], [the jobs of all the JES2 queues],
    [#cmd("DA")], [DA], [the active address spaces],
    [#cmd("I")], [Input Queue], [the jobs that wait to run],
    [#cmd("O")], [Output Queue], [the output that waits to print],
    [#cmd("H")], [Held Output], [the output that is held],
    [#cmd("PR")], [Printer], [the JES2 printers],
    [#cmd("INIT")], [Initiator], [the JES2 initiators],
    [#cmd("LOG")], [SYSLOG], [the system log],
  )
] <ug-intro-panels>

SDSF has help and a tutorial of its own. The Help key (PF1) shows the help
of the panel you are on, and #cmd("TUTOR") starts a short course in seven
parts. Both are part of SDSF, so you can use them without this book.

== Who SDSF Is For <ug-intro-who>

#idx("SDSF", "users")
SDSF is for everyone who works with jobs on an MVS 3.8j system, and what you
can do depends on who you are. @ug-access describes this in full; in short:

- *Anyone with a TSO user id* can see their own jobs and their output, and do
  everything to them that a panel offers: find a job, read its output,
  hold, cancel or purge it.
- *Operators* also see the system's side: the log, the printers, the
  initiators and the address spaces without a job. They can give operator
  commands and act on printers and initiators, if the security
  administrator has given them the access (@ug-devices).
- *System programmers and security administrators* install SDSF
  (@ug-install) and set up the RAKF profiles that decide who sees and does
  what.

SDSF asks RAKF, the security product of MVS 3.8j, about every job of
another user and about the system. Your own jobs are always yours.

This book assumes that you know how to log on to TSO, start ISPF and
submit a job. It does not teach JCL or JES2.

== SDSF and IBM's SDSF V1R2 <ug-intro-ibm>

#idx("IBM's SDSF V1R2")
SDSF is an independent implementation, modeled on the behaviour that IBM's
SDSF V1R2 shows to its users. The panels, the help and the manuals are
written for SDSF itself. Where this book must name IBM's product, it says
"IBM's SDSF V1R2"; "SDSF" alone is always this product.

The model covers what you can see and do: the panels, the commands, the
action characters and the messages. Where SDSF differs on purpose, or does not
do what IBM's SDSF V1R2 does, the chapter "Differences from IBM's SDSF V1R2"
in the _SDSF Reference_ lists it. This book does not repeat that list.

The authorization is not modeled on IBM's SDSF V1R2. It is SDSF's own
solution, built on RAKF; the chapter "Authorization" in the _SDSF Reference_
describes it.

IBM, MVS and SDSF are trademarks of International Business Machines
Corporation.

== Conventions in This Book <ug-intro-conv>

#idx("conventions")
This book follows the spelling of the screen and of the _SDSF Reference_.

#deflist(width: 1.35in,
  [Screen names], [A name that appears on the screen is written as the screen
    shows it, in bold type: #cmd("JOBNAME"), #cmd("COMMAND INPUT ===>"),
    #cmd("SDSF STATUS DISPLAY"). The same type shows what you type.],
  [Commands], [A command is written in upper case: #cmd("ST"),
    #cmd("PREFIX"), #cmd("FIND"). You type it on the command line, the field
    after #cmd("COMMAND INPUT ===>").],
  [Values], [A value that you supply stands in italic type: #cmd("PREFIX")
    #var("name") means the command, a blank, and the name you want.],
  [Action characters], [An action character is a character that you type in
    the NP column of a row, the first column of a list panel. It acts on that
    row. It is not a command, and it is not typed on the command line.],
  [Panels], [A panel is named by what it shows: "the Status panel" is the panel
    that #cmd("ST") shows. The title on the screen is quoted only where it
    matters.],
  [Keys], [A key is named by the command it stands for, and its default
    follows in parentheses: "the End key (PF3)", "the Help key (PF1)". The
    defaults are usually those of ISPF. A user may have moved a key; the
    command stays the same, and you can type it instead. The appendix "PF Key
    Assignments" in the _SDSF Reference_ lists the keys and what each one does
    on each panel.],
  [Messages], [A message is quoted exactly as it appears on the screen, in the
    type of a screen name: #cmd("NOT AUTHORIZED FOR JOB"). A message appears
    on the title line, on the right.],
)

A step in a task is written as what you do and what you then see: "Type
#cmd("ST") on the command line and press Enter. The Status panel appears."
The chapters describe the way; for every operand, every field and every
message, follow the pointer to the _SDSF Reference_. A chapter of this book
names the Reference chapter by title, because the two books are separate.
