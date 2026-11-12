#import "../bookmaster/bookmaster.typ": *

= Action Characters <ref-actions>

An action character is typed in the NP column of a row of a list panel. It
acts on what the row shows: a job, an address space, a printer or an
initiator. Most action characters make SDSF give a JES2 command to the
system; a few open another panel. A field of a row can also be changed by
typing over it, which makes SDSF give a command as well (see
@ref-actions-overtype).

This chapter lists, for every panel, the action characters it takes, the
command each one issues and the access it needs. The panels themselves are
described in @ref-panels, the profiles and access levels in @ref-auth.
#idx("action characters")#idx("NP column")

== Action Characters per Panel <ref-actions-panels>

#tab(caption: [The action characters of each panel])[
  #table(columns: (1.9in, 1fr),
    [Panel], [Action characters],
    [the Status panel (ST)],
      [#cmd("?") #cmd("S") #cmd("D") #cmd("L") #cmd("C") #cmd("CD") #cmd("P")
       #cmd("A") #cmd("H") #cmd("E") #cmd("O")],
    [the DA panel],
      [#cmd("?") #cmd("S") #cmd("D") #cmd("L") #cmd("C") #cmd("CD") #cmd("P")
       #cmd("A") #cmd("H") #cmd("E")],
    [the Input Queue panel (I)], [#cmd("?") #cmd("S")],
    [the Output Queue panel (O)], [#cmd("?") #cmd("S")],
    [the Held Output panel (H)], [#cmd("?") #cmd("S") #cmd("O")],
    [the Printer panel (PR)],
      [#cmd("D") #cmd("S") #cmd("P") #cmd("Z") #cmd("I") #cmd("E") #cmd("C")
       #cmd("N"), and #cmd("B") and #cmd("F") with an optional count],
    [the Initiator panel (INIT)], [#cmd("D") #cmd("S") #cmd("P") #cmd("Z")],
    [the Job Data Set panel], [#cmd("S")],
    [the SYSLOG panel, the Output Data Set panel], [none],
  )
]
#idx("action characters", "per panel")

=== What the action characters do

#deflist(width: 0.9in,
  [#cmd("?")], [Shows the data sets of the job on the Job Data Set panel.],
  [#cmd("S")], [Shows the output of the job, all its data sets one after the
    other, on the Output Data Set panel. On the Job Data Set panel it shows
    the one data set of the row. On the Printer panel and the Initiator panel
    it starts the printer or the initiator.],
  [#cmd("D")], [Displays the job, the printer or the initiator: JES2 answers
    with its state.],
  [#cmd("L")], [Lists the output of the job: JES2 answers with its data sets.],
  [#cmd("C")], [Cancels the job. Its output stays. On the Printer panel it
    cancels the output the printer is printing.],
  [#cmd("CD")], [Cancels the job and asks for a dump.],
  [#cmd("P")], [On ST, cancels the job and deletes its output. On DA, cancels
    the job and purges its output. On the Printer panel and the Initiator
    panel, stops the printer or the initiator once its work is done.],
  [#cmd("A")], [Releases a held job.],
  [#cmd("H")], [Holds the job. A held job that waits to execute does not start.],
  [#cmd("E")], [Restarts the job: JES2 puts it back on the input queue. On the
    Printer panel it restarts the output the printer is printing from its
    beginning.],
  [#cmd("O")], [Releases the held output of the job for printing.],
  [#cmd("Z")], [Halts the printer or the initiator at once; #cmd("S") lets it
    go on.],
  [#cmd("I")], [Interrupts the output a printer prints; it is printed again
    later.],
  [#cmd("N")], [Prints one more copy of the output a printer prints.],
  [#cmd("B"), #cmd("F")], [Backspace or forward space of a printer by a
    number of pages.],
)

=== Typing action characters

- The NP column of ST, DA, I, O, H and the Job Data Set panel takes two
  characters; on the Printer panel it takes four, as a count can follow
  #cmd("B") and #cmd("F"). Blanks in front of the characters are ignored,
  and lower case is taken as upper case.
- Action characters can be typed in the NP column of several rows at once.
  SDSF carries them out one after the other, from the top row down. The title
  line shows the message of the last one that gave one; it does not say what
  happened to the others. An action character that leads to another panel
  (LOG, DA or another list) drops those of the rows below it.
- On ST, DA, PR and INIT an action character that the panel does not take is
  answered with `INVALID COMMAND`, and it stays in the NP column so that it
  can be corrected. This is also the answer on DA to #cmd("O"), and on the
  Printer panel and the Initiator panel to a row that is not a printer or an
  initiator, or to a count that is not allowed.
- On I, O, H and the Job Data Set panel every action character the panel does
  not take is answered with `ACTION NOT AVAILABLE YET`, and it does not stay
  in the NP column. Those panels take #cmd("?") and #cmd("S") (on the Job Data
  Set panel #cmd("S") only), and H also #cmd("O"). The other action characters
  are for ST, and most of them also for DA.
- `COMMAND ISSUED` on the title line says that SDSF gave the command to the
  system, not that JES2 took it. The answer of JES2 is in the system log; show
  it with LOG, which needs read access to #cmd("SDSF.OPER").
- ST reads its rows again after #cmd("P") only; after the other action
  characters the rows stay as they were, until Enter with nothing typed
  reads them again. DA, I, O and H read their rows again after action
  characters. PR and INIT keep theirs, so that the new state of a printer or
  an initiator shows with the next Enter.
- A row on DA that has no job, such as the master scheduler or an idle
  initiator, takes no action character that acts on a job: `JOB NOT FOUND`. So
  does a job that has left the queues since the list was read.
- On ST, DA, I, O, PR and INIT a field overtyped in the same Enter as an
  action character is dealt with first, and the action characters are not
  carried out. Type them again. On H a new DEST goes with #cmd("O") in the
  same Enter. See @ref-actions-overtype.
#idx("NP column", "typing in")#idx("INVALID COMMAND")#idx("ACTION NOT AVAILABLE YET")

== The Command Each Action Issues <ref-actions-cmds>

#idx("action characters", "commands issued")#idx("JES2 command")

=== Jobs: ST, DA and H

The command is built from the type and the number of the job. In the forms
below, #var("t") is #cmd("J") for a batch job, #cmd("S") for a started task
and #cmd("T") for a TSO user, and #var("n") is the number of the job (the
JNUM column) without leading zeros. On DA the row of an initiator that runs a
batch job counts as a batch job.

#tab(caption: [The JES2 commands of the action characters on jobs])[
  #table(columns: (0.7in, 1.5in, 1fr),
    [Action], [Command], [Panels and remarks],
    [#cmd("D")], [`$Dtn`], [ST, DA.],
    [#cmd("L")], [`$Ltn`], [ST, DA.],
    [#cmd("C")], [`$Ctn`], [ST, DA.],
    [#cmd("CD")], [`$Ctn,D`], [ST, DA. Cancel with a dump.],
    [#cmd("P")], [`$Ctn,P` on DA; on ST no command],
      [On DA, cancel with purge. On ST SDSF does not give a command: it asks
       JES2 itself to cancel the job and purge its output (see below).],
    [#cmd("A")], [`$Atn`], [ST, DA.],
    [#cmd("H")], [`$Htn`], [ST, DA.],
    [#cmd("E")], [`$Etn`], [ST, DA.],
    [#cmd("O")], [`$Otn`], [ST and H. Not on DA: `INVALID COMMAND`.],
  )
]

#cmd("?") and #cmd("S") give no command: they read the data sets of the job.
On H, #cmd("O") with a new DEST typed over the field of the row first gives
`$RALL,J=tn,D=`#var("dest") (see @ref-actions-overtype), then `$Otn`.

#cmd("P") on ST is not a command to JES2, as it is on DA. SDSF makes a request
to JES2 through the subsystem interface: cancel the job and purge its output.
For a job whose output waits on the print queue, the held output is deleted
first; if that leaves no job to cancel, this is not an error. The list is
read again at once, and a purged job is no longer on it. The title line shows
nothing if the request worked. If it did not, it shows one of these:

#deflist(width: 2.4in,
  [`NOT AUTHORIZED`], [SDSF could not enter the authorized state for the
    request (see @ref-actions-access).],
  [`CANNOT CANCEL THIS JOB`], [JES2 would not cancel the job; it does not,
    for example, cancel an active TSO user or started task this way.],
  [`PURGE FAILED RC `#var("n")], [JES2 answered with return code #var("n").],
)
#idx("P action character", "on ST")

=== Printers: PR

The command is built from the number #var("n") of the printer, as it is in the
row (#cmd("PRINTER1") is printer 1).

#tab(caption: [The JES2 commands of the action characters on printers])[
  #table(columns: (1.2in, 1.5in, 1fr),
    [Action], [Command], [Remarks],
    [#cmd("D")], [`$DU,PRTn`], [Display.],
    [#cmd("S")], [`$SPRTn`], [Start.],
    [#cmd("P")], [`$PPRTn`], [Stop when the current output is done.],
    [#cmd("Z")], [`$ZPRTn`], [Halt at once.],
    [#cmd("I")], [`$IPRTn`], [Interrupt the output.],
    [#cmd("E")], [`$EPRTn`], [Restart the output.],
    [#cmd("C")], [`$CPRTn`], [Cancel the output.],
    [#cmd("N")], [`$NPRTn`], [One more copy.],
    [#cmd("B")], [`$BPRTn`], [Backspace.],
    [#cmd("F")], [`$FPRTn`], [Forward space.],
    [#cmd("B")#var("p"), #cmd("F")#var("p")], [`$BPRTn,p`, `$FPRTn,p`],
      [#var("p") pages, up to three digits: #cmd("B5") backs up five pages.],
    [#cmd("B")#var("d"), #cmd("F")#var("d")], [`$BPRTn,d`, `$FPRTn,d`],
      [#var("d") is #cmd("D") or #cmd("C"), as JES2 takes them.],
    [#cmd("B")#var("p")#cmd("C"), #cmd("F")#var("p")#cmd("C")],
      [`$BPRTn,pC`, `$FPRTn,pC`],
      [#var("p") is one or two digits.],
  )
]

Any other text after #cmd("B") or #cmd("F"), and any text after the other
action characters, is not an action: `INVALID COMMAND`. Which of these forms
JES2 takes is for JES2 to say; it answers in the log.

=== Initiators: INIT

The command is built from the number #var("n") of the initiator, as it is in
the ID column.

#tab(caption: [The JES2 commands of the action characters on initiators])[
  #table(columns: (0.7in, 1.5in, 1fr),
    [Action], [Command], [Remarks],
    [#cmd("D")], [`$DIn`], [Display.],
    [#cmd("S")], [`$SIn`], [Start.],
    [#cmd("P")], [`$PIn`], [Stop when its job has ended.],
    [#cmd("Z")], [`$ZIn`], [Halt: no new job until #cmd("S").],
  )
]

=== The Job Data Set panel

#cmd("S") shows the data set of the row on the Output Data Set panel and gives
no command. The Job Data Set panel takes no other action character.

== The Access Each Action Needs <ref-actions-access>

#idx("action characters", "access")#idx("access", "for action characters")
Two things decide whether an action character works: the access RAKF gives
the user, and the authorized state that SDSF needs to give a command. The
first is described in @ref-auth; in short:

- Access to a job is access to the entity
  #var("owner")#cmd(".")#var("jobname")#cmd(".")#var("jobid") in the class
  JESSPOOL. Read access lets the user see the job and use the action
  characters that only show something. Update access is needed to change the
  job. The jobs that run under the user's own user id are always allowed; a job
  without an owner counts as the user's own if its name begins with the user
  id.
- Access to the system is access to the FACILITY profile #cmd("SDSF.OPER"),
  read or update.

#tab(caption: [The access each action character needs])[
  #table(columns: (1.9in, 1.45in, 1fr),
    [Action], [Access], [Without it],
    [#cmd("?"), #cmd("S") on a job],
      [read access to the job],
      [The job is not on the list.],
    [#cmd("D"), #cmd("L") on ST and DA],
      [read access to the job],
      [`NOT AUTHORIZED FOR JOB`],
    [#cmd("C"), #cmd("CD"), #cmd("P"), #cmd("A"), #cmd("H"), #cmd("E") on ST
     and DA; #cmd("O") on ST and H],
      [update access to the job],
      [`NOT AUTHORIZED FOR JOB`],
    [#cmd("D") on PR and INIT], [read access to #cmd("SDSF.OPER")],
      [`NOT AUTHORIZED FOR PRT`, `NOT AUTHORIZED FOR INIT`],
    [All other action characters on PR and INIT],
      [update access to #cmd("SDSF.OPER")],
      [`NOT AUTHORIZED FOR PRT`, `NOT AUTHORIZED FOR INIT`],
  )
]

Notes:

- The rows of the lists are those the user may see. A row on ST, I, O or H
  needs no further access for #cmd("?") and #cmd("S"). On DA an address space
  with a job is shown if the job may be seen; the others (the master
  scheduler, JES2, an idle initiator) are shown with read access to
  #cmd("SDSF.OPER").
- The PR and INIT commands themselves need read access to #cmd("SDSF.OPER")\;
  without it they are answered with `COMMAND NOT AUTHORIZED` and the panel does
  not open.
- On DA the checks run in this order, and the first that applies decides:
  `INVALID COMMAND` for an action character the panel does not take,
  `JOB NOT FOUND` for a row without a job or a job the user may not see, then
  `NOT AUTHORIZED FOR JOB`.
- The authorized state is a second condition, besides the RAKF profiles. SDSF
  enters it by its own SVC if that is installed and SDSF was loaded from an
  APF-authorized library or the LPA (not from ISPLLIB). Otherwise it uses SVC 244 (see
  @apx-svc), and then the user needs read access to the FACILITY profile
  #cmd("SVC244"). If it cannot be entered, an action character that gives a
  command is answered with `COMMAND NOT AUTHORIZED`, and #cmd("P") on ST with
  `NOT AUTHORIZED`.
  #cmd("?") and #cmd("S") do not need it.
#idx("COMMAND NOT AUTHORIZED")#idx("NOT AUTHORIZED FOR JOB")
#idx("NOT AUTHORIZED FOR PRT")#idx("NOT AUTHORIZED FOR INIT")
#idx("authorized state")

== Overtyping Fields <ref-actions-overtype>

#idx("overtyping")#idx("fields", "overtypeable")
Some fields of a row can be overtyped: type a new value over the field and
press Enter. SDSF then gives the command that makes the change. Several fields
on several rows can be overtyped in one Enter. A field counts as changed if it
no longer reads as it was shown; a value equal to the one shown, or a field
left blank, gives no command. A field can be overtyped only where it is on the
screen: a field moved out of sight by the Right key (PF11) cannot be typed
over, and on O and H the DEST field can be overtyped only on the first page of
columns. Lower case is taken as upper case.

#tab(caption: [The overtypeable fields])[
  #table(columns: (0.9in, 0.95in, 1.8in, 1fr),
    [Panel], [Field], [Command], [Value],
    [ST, I], [PRTY], [`$Ttn,P=`#var("value")], [Digits only, three at most.
      JES2 checks the range.],
    [I], [C], [`$Ttn,C=`#var("class")],
      [One class: A to Z or 0 to 9.],
    [ST, I, O, H], [DEST], [`$RALL,J=tn,D=`#var("dest")],
      [#cmd("LOCAL") or #cmd("ANYLOCAL") (the command says #cmd("LOCAL")),
       #cmd("R")#var("n"), #cmd("RM")#var("n") or #cmd("RMT")#var("n") (the
       command says #cmd("R")#var("n")), or #cmd("U")#var("n"). #var("n") has
       up to four digits.],
    [PR], [SFORM], [`$TPRTn,F=`#var("forms")],
      [Up to four characters, A to Z and 0 to 9.],
    [PR], [SCLASS], [`$TPRTn,Q=`#var("classes")],
      [Up to 15 classes, A to Z and 0 to 9.],
    [PR], [SEP], [`$TPRTn,S=Y` or `$TPRTn,S=N`],
      [#cmd("YES"), #cmd("NO"), #cmd("Y") or #cmd("N").],
    [PR], [SFCB], [`$TPRTn,C=`#var("fcb")],
      [Up to four characters, A to Z and 0 to 9.],
    [PR], [SDEST1], [`$TPRTn,R=`#var("dest")], [A destination, as for DEST.],
    [INIT], [CLASSES], [`$TIn,`#var("classes")],
      [Up to eight classes, A to Z and 0 to 9. JES2 keeps five at most.],
    [DA], [PGN], [`E `#var("name")`,PERFORM=`#var("pg")],
      [Digits only, three at most.],
  )
]

On the Input Queue panel PRTY and C stand side by side in one field; type over
either part. In the commands, #var("t") and #var("n") are the type and number
of the job as in the table of job commands, #var("n") in `PRTn` and `TIn` is the
number of the printer or the initiator, and #var("name") is the name of the
address space. The command for PGN on DA is an MVS command, not a JES2
command: it resets the address space of the row to the performance group
#var("pg").

=== How a change is carried out

+ SDSF checks all the fields typed, on all the rows, before it does
  anything. If one value is refused, nothing is done: the values stay as they
  were typed, the cursor goes to the first field in error and the title line
  says why.
+ If all values are good, SDSF checks the access of each change and gives
  one command for each, row by row. The title line shows the message of the
  last one: `COMMAND ISSUED`, or the refusal.

Action characters typed in the same Enter are not carried out, whether the
change is refused or made; type them again (on H see below).

The messages for a value that is refused:

#deflist(width: 2.4in,
  [`FIELD NOT NUMERIC`], [PRTY or PGN is not made of digits, or has more
    than three.],
  [`INVALID CLASS`], [C, SCLASS or CLASSES holds a character that is not
    A to Z or 0 to 9, or too many.],
  [`INVALID SYNTAX`], [SFORM or SFCB is not made of up to four of A to Z
    and 0 to 9, or SEP is not #cmd("YES"), #cmd("NO"), #cmd("Y") or
    #cmd("N").],
  [`INVALID DESTINATION NAME`], [DEST or SDEST1 is none of the destinations
    in the table.],
  [`INVALID COMMAND`], [A field of a row of PR that is not a printer.],
)

=== Access for overtyping

#tab(caption: [The access each overtype needs])[
  #table(columns: (2.2in, 1.4in, 1fr),
    [Overtype], [Access], [Without it],
    [PRTY, C and DEST on ST, I, O and H], [update access to the job],
      [`NOT AUTHORIZED FOR JOB`],
    [Fields of PR], [update access to #cmd("SDSF.OPER")],
      [`NOT AUTHORIZED FOR PRT`],
    [CLASSES on INIT], [update access to #cmd("SDSF.OPER")],
      [`NOT AUTHORIZED FOR INIT`],
    [PGN on DA, address space with a job], [update access to the job],
      [`NOT AUTHORIZED FOR JOB`],
    [PGN on DA, address space without a job],
      [update access to #cmd("SDSF.OPER")], [`NOT AUTHORIZED FOR CMD`],
  )
]

A refusal for want of access comes only after all the values are checked. As
with action characters, a command that SDSF cannot give for want of the
authorized state is answered with `COMMAND NOT AUTHORIZED`.

=== DEST on the Held Output panel

On H a new DEST goes together with #cmd("O") in the NP column of the same row:
SDSF gives the command for the destination and then releases the output
(`$RALL,J=tn,D=`#var("dest") and `$Otn`). A new DEST without #cmd("O") is
refused with `"O" ACTION REQUIRED`; the value stays, so that #cmd("O") can be
added. If a DEST is refused, what was typed in the NP column stays as well. If
all are good, the action characters of that Enter are carried out. On O and on
the other panels a new DEST takes effect alone.

=== Panels without overtypeable fields

The Job Data Set panel, the Output Data Set panel and the SYSLOG panel have no
overtypeable fields.
