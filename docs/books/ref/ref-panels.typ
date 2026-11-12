#import "../bookmaster/bookmaster.typ": *

= Panels <ref-panels>

#idx("panel")
This chapter describes each panel of SDSF: what it is for, the fields on
it in the order they stand on the screen, the order of its rows, its
action characters and overtypeable fields, its keys and the profile
variables it uses. Names that appear on the screen are written as the
screen shows them, in the type of #cmd("JOBNAME"). The action characters are
listed again, with the command each one issues and the access it needs, in
@ref-actions; the commands are in @ref-cmd, and the messages in
@ref-messages.

The panels are the primary option menu, the seven list panels (ST, DA, I,
O, H, PR and INIT), the system log, and the two panels below a job: the Job
Data Set panel and the Output Data Set panel. The text says "the Status
panel" for the panel the command #cmd("ST") shows, and likewise for the
others.

== What the Panels Have in Common <ref-panels-common>

#idx("title line")
#idx("command line")
#idx("SCROLL field")
Every panel has a title line, a command line after #cmd("COMMAND INPUT ===>")
and, on the right of it, the SCROLL field after #cmd("SCROLL ===>"). A message
appears on the title line, on the right. A list panel then has a heading
line and one row per job, address space, printer or initiator.

#idx("NP column")
The first column of a row on a list panel is #cmd("NP"). An action character
typed there acts on that row (@ref-actions). A field that may be overtyped is
shown as an input field; the section of each panel says which. An action
character typed in the same Enter as a change to such a field is not carried
out, whether the change is refused or made; type it again. The Held Output
panel is the exception: there #cmd("O") and a new #cmd("DEST") go together in
one Enter (@ref-panels-h).

#idx("further fields")
A row can be wider than the screen. The first columns, #cmd("NP") and the name
of the job (on the Printer panel, of the printer), stay in place; the Right
key (PF11) and the Left key (PF10) move the others. The first move of the
Right key shows what comes after the columns on the screen, and each further
move shows the next part, with the last column of the one before repeated at
the left. On the Status and Input Queue panels the further fields appear
only after #cmd("?") has been typed alone on the command line
(@ref-panels-st). The width of a whole row is this:

#tab(caption: [The width of a row, in columns])[
  #table(columns: (2.2in, 1fr),
    [Panel], [Width of the row],
    [Status], [80; with #cmd("?"), 174],
    [DA], [113 or 114, by the order of the columns],
    [Input Queue], [80; with #cmd("?"), 168],
    [Held Output], [230],
    [Output Queue], [157],
    [Printer], [341],
    [Initiator], [80],
    [Job Data Set], [163],
  )
] <ref-panels-widths>

#idx("scroll amount")
#idx("PF keys")
The panels use the keys of ISPF, so a user's own key assignment applies. The
list below names each key by the command it stands for and gives the default
(@apx-pfkeys).

#deflist(width: 1.6in,
  [the Help key (PF1)], [the help of the panel.],
  [the End key (PF3)], [leaves the panel: from the primary option menu it
    leaves SDSF, from a list panel it goes back to the primary option menu,
    and from the Job Data Set and the Output Data Set panel it goes back to
    the panel before.],
  [the Up key (PF7), the Down key (PF8)], [scroll the rows up and down.],
  [the Left key (PF10), the Right key (PF11)], [move the columns that are
    not fixed.],
  [PF5], [#cmd("RFIND"): look again for the last string of #cmd("FIND").],
)

A word typed on the command line before the Up, Down, Left or Right key
is the scroll amount for that one move: #cmd("M") or #cmd("MAX") for as far
as it goes, #cmd("P") or #cmd("PAGE") for a page, #cmd("H") or #cmd("HALF") for
half a page, #cmd("D") or #cmd("DATA") for a page less a line, #cmd("C") or
#cmd("CSR") for the line of the cursor, or a number. Anything else gives the
message #cmd("INVALID SCROLL AMOUNT"). The SCROLL field holds the amount for
the keys typed with nothing before them: #cmd("PAGE"), #cmd("HALF"),
#cmd("DATA"), #cmd("CSR"), or a number of one to four digits. #cmd("MAX") in
the SCROLL field raises no message and scrolls nothing; the last amount comes
back in the field. The amount counts for the Left and Right keys on the Job
Data Set panel, the Output Data Set panel and the system log. On the list
panels it has no effect on them.

#idx("colour")
Where a panel marks rows by colour, an executing job, an active printer or
initiator, and an address space in storage are white, and the others are
blue. Enter with nothing on the command line and no action character reads
the list again.

#idx("profile variable")
#idx("ISPF profile")
SDSF keeps five settings in the ISPF profile of the user, so that the next
session starts with them. It reads them when it starts and writes one when it
changes.

#tab(caption: [The profile variables])[
  #table(columns: (0.9in, 3in, 1fr),
    [Variable], [Holds], [Set by],
    [#cmd("ISFS")], [the scroll amount, four characters; #cmd("PAGE") at
      first], [the SCROLL field],
    [#cmd("ISFACT")], [the routing codes of #cmd("ACTION"), four hexadecimal
      digits; #cmd("OFF") at first], [#cmd("ACTION")],
    [#cmd("ISFFND")], [the last string of #cmd("FIND"), with its direction
      and length], [#cmd("FIND") on the log and on output],
    [#cmd("ISFPFX")], [the name of #cmd("PREFIX") and its two wildcard
      characters; at first #cmd("*") and #cmd("%")], [#cmd("PREFIX")],
    [#cmd("ISFDST")], [the destinations of #cmd("DEST"), four at most],
      [#cmd("DEST")],
  )
] <ref-panels-profile>

Everything else lasts only until SDSF ends: the classes and the name of
#cmd("ST"), the types and positions of #cmd("DA"), the classes of #cmd("I"),
#cmd("H") and #cmd("O"), the forms of #cmd("O"), #cmd("SYSID"),
#cmd("INPUT"), #cmd("SET HEX"), the state of #cmd("?"), and the limit of
#cmd("FIND"), which is 5000 lines. The scale line of #cmd("COLS") lasts only
while the output or log display it was shown on stays open.

The text of each panel names the variables that govern what the panel shows or
that its own commands write. #cmd("ISFS") holds for every panel, since the
SCROLL field is on every panel, and is not repeated. #cmd("ISFACT") is named
where it decides what the panel shows, which is the replies on the system log.
Where a panel names none, it has none of its own.

== The Primary Option Menu <ref-panels-menu>

#idx("primary option menu")
#idx("SDSF PRIMARY OPTION MENU")
The primary option menu, titled #cmd("SDSF PRIMARY OPTION MENU"), is where
SDSF starts. It shows the options in this order, each with a line saying
what it does:

#deflist(width: 1.0in,
  [#cmd("LOG")], [display the system log.],
  [#cmd("DA")], [display the active address spaces.],
  [#cmd("I")], [display the input queue.],
  [#cmd("O")], [display the output queue.],
  [#cmd("H")], [display the held output.],
  [#cmd("ST")], [display the status of jobs.],
  [#cmd("PR")], [display the printers.],
  [#cmd("INIT")], [display the initiators.],
  [#cmd("TUTOR")], [a short course on SDSF (under ISPF only).],
  [#cmd("END")], [exit SDSF.],
)

Below them the menu says that the Help key gives more information, and
carries the line of the product. There are no fields besides the command line
and the SCROLL field, and the menu does not scroll.

The menu takes every command that shows a panel (@ref-cmd): #cmd("ST"),
#cmd("DA"), #cmd("I"), #cmd("O"), #cmd("H"), #cmd("PR"), #cmd("INIT") and
#cmd("LOG"), also with their parameters, and #cmd("/"), #cmd("TSO"),
#cmd("PREFIX"), #cmd("DEST"), #cmd("ACTION"), #cmd("SYSID") and the settings.
A word it does not know gives #cmd("INVALID COMMAND") and stays on the command
line. So do the commands that work on rows or lines, such as #cmd("FIND"),
#cmd("LOCATE"), #cmd("TOP") and the scroll commands. #cmd("LOG") without read
access to #cmd("SDSF.OPER") gives #cmd("COMMAND NOT AUTHORIZED").
#cmd("LOG") with a parameter gives #cmd("NOT AVAILABLE YET"). A scroll amount
that is none of the values above gives #cmd("INVALID SCROLL AMOUNT").

*Keys.* The End key (PF3) leaves SDSF. The Help key (PF1) shows the help of the
menu, from which the contents of the help can be reached.

*Profile variables.* #cmd("ISFS"); and #cmd("ISFACT"), #cmd("ISFPFX") and
#cmd("ISFDST") through the commands that set them.

== ST: Status <ref-panels-st>

#idx("Status panel")
#idx("ST command")
#idx("SDSF STATUS DISPLAY")
The Status panel lists the jobs JES2 holds: batch jobs, started tasks and
TSO users, waiting to execute, executing, or waiting for their output to be
printed. It is the panel from which a job is cancelled, held, released or
purged, and from which its data sets are reached. The title line reads
#cmd("SDSF STATUS DISPLAY ALL CLASSES"), or
#cmd("SDSF STATUS DISPLAY CLASS") and the classes asked for.

*Columns.* The columns are, from the left:

#deflist(width: 1.2in,
  [#cmd("NP")], [where an action character is typed.],
  [#cmd("JOBNAME")], [the name of the job, started task or TSO user.],
  [#cmd("TYPE")], [#cmd("JOB") for a batch job, #cmd("STC") for a started
    task, #cmd("TSU") for a TSO user.],
  [#cmd("JNUM")], [the JES2 job number.],
  [#cmd("PRTY")], [the JES2 priority, 0 to 15. May be overtyped.],
  [#cmd("QUEUE")], [the queue the job is on: #cmd("INPUT"),
    #cmd("EXECUTION"), #cmd("PRINT"), #cmd("XMIT"), #cmd("SETUP") or
    #cmd("RECEIVE"). #cmd("UNKNOWN") stands for a queue SDSF does not
    know.],
  [#cmd("C")], [the job class of a batch job.],
  [#cmd("POS")], [the place of a waiting job among the jobs of its class
    that are not held.],
  [#cmd("HDN")], [the number of the job's held output data sets; blank
    when there is none.],
  [#cmd("DEST")], [where the output goes: #cmd("LOCAL"), or #cmd("R")#var("n")
    for remote #var("n"). May be overtyped.],
  [#cmd("SAFF")], [the system the job is bound to, if it is bound to one.],
  [#cmd("ASYS")], [the system the job is active on.],
  [#cmd("STAT")], [#cmd("HOLD") if the job is held.],
)

*The further fields.* #cmd("?") typed alone on the command line adds these
fields after the ones above, in a longer row, and a second #cmd("?") takes them
away again. The first screen after #cmd("?") still shows the columns above; the
Right key (PF11) brings the further fields into view, and the Left key (PF10)
goes back, with #cmd("NP") and #cmd("JOBNAME") staying. Without #cmd("?") the
keys move nothing, and on the Status panel they read the list again, as Enter
does. In their order the further fields are:

#deflist(width: 1.8in,
  [#cmd("RNUM")], [the remote the job came from; blank for local jobs.],
  [#cmd("PROGRAMMER-NAME")], [the programmer name of the JOB statement.],
  [#cmd("ACCT")], [the account number.],
  [#cmd("NOTIFY")], [the user told when the job ends.],
  [#cmd("ISYS")], [the system that read the job in.],
  [#cmd("RD-TIME"), #cmd("RD-DATE")], [when the job was read in.],
  [#cmd("ESYS")], [the system that executes, or executed, the job.],
  [#cmd("ST-TIME"), #cmd("ST-DATE")], [when the job started to execute.],
  [#cmd("CARDS")], [the number of input cards.],
  [#cmd("MC")], [the message class (#cmd("MSGCLASS")).],
  [#cmd("TOT-LINES")], [the number of output lines of the job.],
)

Times are #cmd("hh:mm:ss"), dates #cmd("yy.ddd"): the year and the day of the
year.

*Order of the rows.* The jobs waiting to execute come first, by class, then by
priority, highest first, then by job number. After them come the executing
batch jobs, again by class, priority and job number; then the executing TSO
users and the executing started tasks, each by priority and job number. The
jobs on the print queue come last. Where the jobs on the #cmd("INPUT"),
#cmd("XMIT"), #cmd("SETUP") and #cmd("RECEIVE") queues come is not defined. A
job that is waiting to execute shows #cmd("EXECUTION") in #cmd("QUEUE"), not
#cmd("INPUT"). Executing jobs are white, the others blue.

*Limiting the list.* #cmd("ST") with up to six classes written directly after
it, and a name that may hold #cmd("*") and #cmd("%"), shows only the jobs of
those classes and that name. TSO users, started tasks and the print queue have
no class and drop out when classes are given. #cmd("PREFIX") and #cmd("DEST")
limit the list too, and a job must match every limit in force. A job the user
has no read access to is not listed (@ref-auth).

*Action characters.* #cmd("?") shows the data sets of the job on the Job Data
Set panel (@ref-panels-jds), #cmd("S") shows the job's output on the Output Data
Set panel (@ref-panels-ods), #cmd("P") purges the job, and #cmd("D"),
#cmd("L"), #cmd("C"), #cmd("CD"), #cmd("A"), #cmd("H"), #cmd("E") and #cmd("O")
give the matching JES2 command (@ref-actions). Any other character gives
#cmd("INVALID COMMAND") and stays in #cmd("NP").

*Overtyping.* #cmd("PRTY") sets the priority and #cmd("DEST") the destination
of the job in that row. A priority that is not a number gives
#cmd("FIELD NOT NUMERIC"), and a destination SDSF does not know gives
#cmd("INVALID DESTINATION NAME"). A destination is #cmd("LOCAL"),
#cmd("ANYLOCAL"), #cmd("R")#var("n"), #cmd("RM")#var("n"), #cmd("RMT")#var("n")
or #cmd("U")#var("n"). SDSF checks every value typed before it gives any
command: if one is refused, none is given, the values stay on the screen and
the cursor goes to the one that is wrong.

*Other messages.* #cmd("NOT ENOUGH STORAGE") if the list does not fit in
storage, and #cmd("JES2 NOT READABLE"). Coming back to this panel with
#cmd("ST") from the output display of a job, the message is
#cmd("DATA SET DISPLAYED").

*Keys.* As in @ref-panels-common. The Left and Right keys act only after
#cmd("?").

*Profile variables.* #cmd("ISFPFX") and #cmd("ISFDST"). The
classes and the name of #cmd("ST") are not in the profile and last until SDSF
ends.

== Job Data Set <ref-panels-jds>

#idx("Job Data Set panel")
#idx("SDSF JOB DATA SET DISPLAY")
The Job Data Set panel lists the output data sets of one job. It is reached by
typing #cmd("?") in #cmd("NP") of a row on the Status, DA, Input Queue, Output
Queue or Held Output panel. The title line reads
#cmd("SDSF JOB DATA SET DISPLAY -") and then the type, the name and the JES2
job number of the job: #cmd("JOB"), the name, and a number such as #cmd("J1234")
in parentheses.

*Rows.* There is one row per output data set of the job, in the order the job
has them. #cmd("INPUT ON") adds the input of the job: its JCL as JES2 converted
it and its instream data.

*Columns.* #cmd("NP") and #cmd("DDNAME") stay in place; the Right key (PF11) and
the Left key (PF10) move the others. In their order they are:

#deflist(width: 1.8in,
  [#cmd("NP")], [where an action character is typed.],
  [#cmd("DDNAME")], [the DD name of the data set; #cmd("JESMSGLG"),
    #cmd("JESJCL") and #cmd("JESYSMSG") are JES2's.],
  [#cmd("STEP-NAME"), #cmd("PROC-STEP")], [the step that wrote it, and its
    procedure step; #cmd("JES2") for the data sets of JES2.],
  [#cmd("DSID")], [the number of the data set within the job.],
  [#cmd("C")], [its output class.],
  [#cmd("REC-CNT")], [its records.],
  [#cmd("CC")], [the copies to print, shown when there is more than none.],
  [#cmd("PRMODE")], [the process mode; always #cmd("LINE").],
  [#cmd("BURST")], [#cmd("YES") or #cmd("NO").],
  [#cmd("CREATE-DATE-TIME")], [the date of the job as #cmd("yy.ddd"): the day
    it started, or if it has not started, the day it was read in.],
  [#cmd("FORMS"), #cmd("FCB"), #cmd("UCS"), #cmd("FLASH")], [how it is
    printed; #cmd("****") if none was named.],
)

The panel has more headings than these: #cmd("PAGE-CNT"), #cmd("BYTE-CNT"),
#cmd("RMT"), #cmd("NODE"), #cmd("O-GRP-N"), #cmd("DEST-NAME") and
#cmd("WTR-NAME"). SDSF does not fill them yet, and they stay blank.

*Action characters.* #cmd("S") shows the data set on the Output Data Set panel
(@ref-panels-ods). Any other gives #cmd("ACTION NOT AVAILABLE YET").
#cmd("OUTPUT NOT READABLE") says the output could not be read.

*Keys.* The End key (PF3) goes back to the panel the job was chosen on. The
Left and Right keys move the fields right of #cmd("DDNAME"). The commands that
switch panels (#cmd("ST"), #cmd("DA"), #cmd("I"), #cmd("O"), #cmd("H"),
#cmd("PR"), #cmd("INIT"), #cmd("LOG")) work here.

*Profile variables.* None of its own.

== Output Data Set <ref-panels-ods>

#idx("Output Data Set panel")
#idx("SDSF OUTPUT DISPLAY")
The Output Data Set panel shows the text of a job's output. It is reached by
#cmd("S") in #cmd("NP") of a job on the Status, DA, Input Queue, Output Queue
or Held Output panel, which shows all the output data sets of the job one
after the other, or by #cmd("S") on a data set of the Job Data Set panel,
which shows that data set only. The output cannot be changed: what is typed
over it is not kept.

The title line shows the job, the data set at the top (#cmd("DSID") and its
number), #cmd("LINE") and the number of the line at the top within that data
set, and #cmd("COLUMNS") with the first and last column shown. The columns
start at 02, since column 1 holds the carriage control and is never shown.

*Rows.* One record is one line; carriage control does not add lines. The lines
#cmd("TOP OF DATA") and #cmd("BOTTOM OF DATA") stand once, at the start and the
end of the whole display. If the output is bigger than the storage SDSF has,
the panel shows what fits and says #cmd("NOT ENOUGH STORAGE").

*Commands.* Besides the scroll commands there are #cmd("FIND"),
#cmd("NEXT") and #cmd("PREV") to move by data set, #cmd("LOCATE"),
#cmd("TOP") and #cmd("BOTTOM"), #cmd("COLS") for a scale line and
#cmd("RESET") to take it away, #cmd("SET HEX ON") and #cmd("SET HEX OFF") for
each line also in hexadecimal, and #cmd("PRINT") (@ref-cmd).

*Keys.* The End key (PF3) goes back to the panel before. The command
#cmd("ST") goes to a new Status panel. The Left and Right keys move the
columns, up to column 255; the Up and Down keys scroll the lines.

*Profile variables.* #cmd("ISFFND").

== DA: Active Address Spaces <ref-panels-da>

#idx("DA panel")
#idx("DA command")
#idx("SDSF DA")
The DA panel lists the address spaces that are active on the system:
batch jobs, started tasks, TSO users and, if asked for, idle initiators. It
shows what each one uses: the processor, I/O and real storage. The title line
reads #cmd("SDSF DA"), the system id, #cmd("PAGING 0.00"), #cmd("SIO") and
#cmd("CPU"). #cmd("SIO") and #cmd("CPU") add up the rates only of the address
spaces that were also in the previous measurement, so both are 0 the first
time the panel is shown. The sum includes address spaces that the panel does
not show, so it can be larger than the sum of the rows on the screen. #cmd("PAGING") is always 0.00.

*Columns.* In the order they have when the panel is first shown:

#deflist(width: 1.2in,
  [#cmd("NP")], [where an action character is typed.],
  [#cmd("JOBNAME")], [the name of the job, started task, TSO user or
    initiator. It stays in place when the columns move.],
  [#cmd("STEPNAME")], [the step running, for a batch job\; the procedure of a
    started task\; the logon procedure of a TSO user.],
  [#cmd("PROCSTEP")], [the step of the procedure\; for a TSO user, the
    terminal.],
  [#cmd("TYPE")], [#cmd("JOB"), #cmd("STC") or #cmd("TSU")\; blank for an idle
    initiator.],
  [#cmd("JNUM")], [the JES2 job number, if the address space has one.],
  [#cmd("C")], [the job class.],
  [#cmd("POS")], [#cmd("IN") in storage, #cmd("OUT") swapped out, #cmd("N/S")
    not swappable.],
  [#cmd("DP")], [the dispatching priority, in hexadecimal.],
  [#cmd("PGN")], [the performance group. May be overtyped.],
  [#cmd("REAL")], [the frames of real storage the address space holds.],
  [#cmd("PAGING")], [always 0.00.],
  [#cmd("SIO")], [the I/O (EXCPs) per second since the panel was last shown.],
  [#cmd("CPU%")], [the share of the processor since the panel was last
    shown.],
  [#cmd("ASID")], [the address space id.],
  [#cmd("EXCP-CNT")], [the I/O (EXCPs) of the address space so far.],
  [#cmd("CPU-TIME")], [the processor time of the current step, in seconds.],
  [#cmd("SR")], [why it was swapped out: #cmd("TI") and #cmd("TO"), terminal
    input or output wait\; #cmd("LW"), long wait\; #cmd("XS"), auxiliary
    storage shortage\; #cmd("RS"), real storage shortage\; #cmd("DW"),
    detected wait\; #cmd("RQ"), requested\; #cmd("NQ"), enqueue exchange\;
    #cmd("EX"), exchange\; #cmd("US"), unilateral.],
  [#cmd("DMN")], [the domain.],
)

#cmd("SIO") and #cmd("CPU%") are taken over the time between two displays: the
first display shows 0.00, and Enter shows the next interval.

#cmd("?") typed alone on the command line puts the columns after #cmd("JOBNAME")
in another order, and a second #cmd("?") returns to the first. The other
order is #cmd("NP"), #cmd("JOBNAME"), #cmd("STEPNAME"), #cmd("PROCSTEP"),
#cmd("TYPE"), #cmd("JNUM"), #cmd("C"), #cmd("ASID"), #cmd("EXCP-CNT"),
#cmd("CPU-TIME"), #cmd("REAL"), #cmd("PAGING"), #cmd("SIO"), #cmd("CPU%"),
#cmd("DP"), #cmd("POS"), #cmd("SR"), #cmd("PGN") and #cmd("DMN"). The Right key
moves the columns after #cmd("JOBNAME") once, as far as the end of the row, and
the Left key goes back to the start, in either order. If the screen is as wide
as the row, nothing moves. The amount does not count here.

*Order of the rows.* By address space id. A row is white, or blue while the
address space is swapped out.

*Limiting the list.* #cmd("DA") with up to four words chooses what is shown:

#deflist(width: 1.8in,
  [#cmd("JOB"), #cmd("TSU"), #cmd("STC"), #cmd("INIT")], [the types: batch
    jobs, TSO users, started tasks, idle initiators.],
  [#cmd("IN"), #cmd("OUT"), #cmd("TRANS"), #cmd("READY")], [the positions.
    #cmd("TRANS") and #cmd("READY") are accepted but select nothing, since
    SDSF sees only #cmd("IN") and #cmd("OUT")\; an address space that is not
    swappable counts as #cmd("IN").],
  [#cmd("O")#var("type"), #cmd("O")#var("position")], [only that type or
    position, for example #cmd("OJOB") or #cmd("OOUT"). Only one such word.],
  [#cmd("NO")#var("type"), #cmd("NO")#var("position")], [all but that type or
    position, for example #cmd("NOTSU").],
  [#cmd("ALL"), #cmd("ALLT"), #cmd("ALLP")], [each only by itself.],
)

Without parameters the panel shows batch jobs, TSO users and started tasks at
every position. A word that is none of these gives #cmd("PARM INVALID"), and
more than four give #cmd("TOO MANY PARMS"). An initiator that is running a
job shows as that job. The panel has no limit by name, and #cmd("PREFIX") and
#cmd("DEST") do not limit it.

*Who sees what.* A row that has a JES2 job is shown when the user may read the
job (@ref-auth). The rows that have none, such as JES2 and idle initiators,
need read access to #cmd("SDSF.OPER").

*Action characters.* #cmd("?"), #cmd("S"), #cmd("D"), #cmd("L"), #cmd("C"),
#cmd("CD"), #cmd("P"), #cmd("A"), #cmd("H") and #cmd("E") act on the JES2 job
of the row (@ref-actions). #cmd("O") is not taken here and gives
#cmd("INVALID COMMAND"). A row without a JES2 job gives #cmd("JOB NOT FOUND").
The list is read again after an action. SDSF takes the job number from JES2:
it is that of the executing job of the same name and type. The master address
space (ASID 1) shows the number of the executing #cmd("SYSLOG") task, and the
action characters on its row act on that task.

*Overtyping.* #cmd("PGN") moves the address space to another performance
group: SDSF gives the operator command #cmd("E") #var("name")#cmd(",PERFORM=")#var("n").
It needs update access to the job, or to #cmd("SDSF.OPER") for an address
space without a job.

*Profile variables.* None of its own.

== I: Input Queue <ref-panels-i>

#idx("Input Queue panel")
#idx("I command")
#idx("SDSF INPUT QUEUE DISPLAY")
The Input Queue panel lists the jobs that have been read in and are waiting
to execute or executing, in the order of the Status panel. The title line
reads #cmd("SDSF INPUT QUEUE DISPLAY ALL CLASSES") or
#cmd("SDSF INPUT QUEUE DISPLAY CLASS") and the classes asked for.

*Columns.*

#deflist(width: 1.2in,
  [#cmd("NP")], [where an action character is typed.],
  [#cmd("JOBNAME")], [the name of the job, started task or TSO user.],
  [#cmd("TYPE")], [#cmd("JOB"), #cmd("STC") or #cmd("TSU").],
  [#cmd("JNUM")], [the JES2 job number.],
  [#cmd("PRTY")], [the JES2 priority, 0 to 15. May be overtyped.],
  [#cmd("C")], [the job class\; #cmd("$") for a TSO user, #cmd("#") for a
    started task. May be overtyped.],
  [#cmd("POS")], [the place of a waiting job among the jobs of its class
    that are not held.],
  [#cmd("DEST")], [where the output goes: #cmd("LOCAL"), or #cmd("R")#var("n").
    May be overtyped.],
  [#cmd("RMT")], [not filled yet.],
  [#cmd("NODE")], [the JES2 node, #cmd("1").],
  [#cmd("SAFF")], [the system the job is bound to, if it is bound to one.],
  [#cmd("ASYS")], [the system the job is active on.],
  [#cmd("STAT")], [#cmd("HOLD") if the job is held.],
)

#cmd("?") typed alone on the command line adds the further fields of the
Status panel (@ref-panels-st) after the columns of this panel, in a longer row
of 168 columns. The Right key brings them into view and the Left key goes back,
and a second #cmd("?") takes them away again. Without #cmd("?") the Left and
Right keys do nothing on this panel.

*Order of the rows.* As on the Status panel, which this panel draws on; the
jobs on the print queue are not listed. Executing jobs are white, the others
blue.

*Limiting the list.* #cmd("I") with up to seven classes written directly after
it, and
#cmd("H") or #cmd("NH") after them, as in #cmd("IA H"). Without classes only
batch jobs are shown\; in the classes, #cmd("$") adds the TSO users and
#cmd("#") the started tasks. #cmd("H") shows only held jobs, #cmd("NH") only
the jobs that are not held. #cmd("PREFIX") and #cmd("DEST") limit the list
too. A word that is none of these gives #cmd("PARM INVALID").

*Action characters.* #cmd("?") and #cmd("S") work as on the Status panel. The
others give #cmd("ACTION NOT AVAILABLE YET").

*Overtyping.* #cmd("PRTY"), #cmd("C") and #cmd("DEST") change the priority, the
class and the destination of the job (@ref-actions). The messages are
#cmd("FIELD NOT NUMERIC"), #cmd("INVALID CLASS") and
#cmd("INVALID DESTINATION NAME").

*Profile variables.* #cmd("ISFPFX") and #cmd("ISFDST").

== H: Held Output <ref-panels-h>

#idx("Held Output panel")
#idx("H command")
#idx("SDSF HELD OUTPUT DISPLAY")
The Held Output panel lists the jobs that have held output: output that is not
printed until it is released. It is where the output of jobs whose
#cmd("MSGCLASS") is a held class can be looked at. The title line reads
#cmd("SDSF HELD OUTPUT DISPLAY"), then #cmd("ALL CLASSES") or #cmd("CLASS")
and the classes, then the lines of all the rows and #cmd("LINES").

A row stands for one job. #cmd("C"), #cmd("FORM"), #cmd("FCB"), #cmd("UCS"),
#cmd("FLASH") and #cmd("BURST") are those of the job's first held data set.

*Columns.* #cmd("NP") and #cmd("JOBNAME") stay in place; the Right and Left
keys move the others. In their order:

#deflist(width: 1.8in,
  [#cmd("NP")], [where an action character is typed.],
  [#cmd("JOBNAME")], [the name of the job.],
  [#cmd("TYPE")], [#cmd("JOB"), #cmd("STC") or #cmd("TSU").],
  [#cmd("JNUM")], [the JES2 job number.],
  [#cmd("DN")], [the job's held data sets.],
  [#cmd("CRDATE")], [the date the job was read in (#cmd("yy.ddd")).],
  [#cmd("C")], [the output class of the first held data set.],
  [#cmd("FORM"), #cmd("FCB")], [its forms and FCB image\; #cmd("****") if none
    were named.],
  [#cmd("DEST")], [where the output goes. May be overtyped.],
  [#cmd("RMT")], [not filled yet.],
  [#cmd("NODE")], [the JES2 node, #cmd("1").],
  [#cmd("TOT-REC")], [the records of all the held data sets.],
  [#cmd("RNUM")], [not filled yet.],
  [#cmd("PROGRAMMER-NAME"), #cmd("ACCT"), #cmd("NOTIFY")], [from the JOB
    statement.],
  [#cmd("ISYS"), #cmd("RD-TIME"), #cmd("RD-DATE")], [where and when the job was
    read in.],
  [#cmd("ESYS"), #cmd("ST-TIME"), #cmd("ST-DATE")], [where and when it
    started.],
  [#cmd("END-TIME"), #cmd("END-DATE")], [when it ended.],
  [#cmd("CARDS")], [the cards read in.],
  [#cmd("PR")], [its priority.],
  [#cmd("STATUS")], [not filled yet.],
  [#cmd("UCS")], [as on the Output Queue panel.],
  [#cmd("JC")], [its job class.],
  [#cmd("BURST"), #cmd("PRMODE")], [as on the Output Queue panel.],
  [#cmd("WTR")], [not filled yet.],
  [#cmd("MC")], [its #cmd("MSGCLASS").],
  [#cmd("FLASH")], [as on the Output Queue panel.],
)

*Order of the rows.* The oldest comes first, by the time the job ended.

*Limiting the list.* #cmd("H") with up to seven classes written directly after
it, and
#cmd("ALL") or a job name after them, as in #cmd("HX TBR*"). #cmd("H") alone
shows the jobs whose names begin with the user id; #cmd("H ALL") shows all the
user may see (@ref-auth); a #cmd("PREFIX") takes the place of the user id.
#cmd("DEST") limits the list by the destination of the job, as on the Status
panel. #cmd("?") typed alone is accepted and changes nothing, since the panel
has no further fields to show. #cmd("H ?") is not the same: the #cmd("?") is
taken as a job name, and nothing is listed.

*Action characters.* #cmd("?") and #cmd("S") work as on the Status panel.
#cmd("O") releases the held output for printing (#cmd("$O")). It gives
#cmd("NOT AUTHORIZED FOR JOB") without update access. The others give
#cmd("ACTION NOT AVAILABLE YET"); to purge, use #cmd("P") on the Status panel.

*Overtyping.* #cmd("DEST") can be overtyped on the first part of the row
only, and only together with #cmd("O") in #cmd("NP"): the output goes to the
new destination, which SDSF gives to JES2 first. A new #cmd("DEST") without
#cmd("O") gives #cmd("\"O\" ACTION REQUIRED"). If a #cmd("DEST") is refused,
what was typed in #cmd("NP") stays as well. If all are good, the action
characters of that Enter are carried out.

*Profile variables.* #cmd("ISFPFX") and #cmd("ISFDST").

== O: Output Queue <ref-panels-o>

#idx("Output Queue panel")
#idx("O command")
#idx("SDSF OUTPUT")
The Output Queue panel lists the jobs that have ended and have output waiting
to be printed, that is output that is not held. The title line reads
#cmd("SDSF OUTPUT"), then #cmd("ALL CLASSES") or #cmd("CLASS") and the
classes, #cmd("ALL FORMS") or #cmd("FORM") and the forms, and #cmd("LINES")
with the lines of all the rows.

*Columns.* #cmd("NP") and #cmd("JOBNAME") stay in place; the Right and Left
keys move the others. In their order:

#deflist(width: 1.4in,
  [#cmd("NP")], [where an action character is typed.],
  [#cmd("JOBNAME")], [the name of the job.],
  [#cmd("TYPE")], [#cmd("JOB"), #cmd("STC") or #cmd("TSU").],
  [#cmd("JNUM")], [the JES2 job number.],
  [#cmd("PRTY")], [the job's priority.],
  [#cmd("C")], [the output class.],
  [#cmd("FORM")], [the forms, of the first data set\; #cmd("****") if none were
    named.],
  [#cmd("FCB")], [the FCB image, the same way.],
  [#cmd("DEST")], [where the output goes. May be overtyped.],
  [#cmd("TOT-REC")], [the records of all the job's output data sets.],
  [#cmd("SYSID")], [the system the job executed on.],
  [#cmd("NODE")], [the JES2 node, #cmd("1").],
  [#cmd("UCS")], [the print train (UCS image).],
  [#cmd("FLASH")], [the forms overlay.],
  [#cmd("BURST")], [#cmd("YES") if the output is burst.],
  [#cmd("PRMODE")], [the process mode, #cmd("LINE").],
)

The panel also has the headings #cmd("PRT-REC"), #cmd("DEVICE"),
#cmd("STATUS"), #cmd("RMT"), #cmd("O-GRP-N"), #cmd("OGI1"), #cmd("OGI2"),
#cmd("JP") and #cmd("WTR"). SDSF does not fill them yet, and they stay blank.

*Order of the rows.* The oldest comes first, by the time the job ended. The
class and the forms of a row are those of the first data set waiting to be
printed.

*Limiting the list.* #cmd("O") with up to seven classes written directly after
it, and
forms after them, as in #cmd("OA STD"); the forms may hold #cmd("*") and
#cmd("%"). #cmd("PREFIX") and #cmd("DEST") limit the list too, #cmd("DEST") by
the destination of the job, as on the Status panel.

*Action characters.* #cmd("?") and #cmd("S") work as on the Status panel. The
others give #cmd("ACTION NOT AVAILABLE YET").

*Overtyping.* Only #cmd("DEST") can be overtyped: the output of the job goes to
the new destination. The other fields only show, as JES2 has no command to
change them.

*Profile variables.* #cmd("ISFPFX") and #cmd("ISFDST").

== PR: Printers <ref-panels-pr>

#idx("Printer panel")
#idx("PR command")
#idx("SDSF PRINTER DISPLAY")
The Printer panel lists the JES2 printers of the system: their state, the forms
and classes they print, and the job an active printer is printing. The title
line reads #cmd("SDSF PRINTER DISPLAY"). The panel needs read access to
#cmd("SDSF.OPER"); without it the message is #cmd("COMMAND NOT AUTHORIZED").

Each time the panel is shown, SDSF gives the JES2 command #cmd("$DU,PRTS")
and reads the answer from the system log, so the command and its answer appear
in the log every time. If JES2 does not answer within a few seconds the message
is #cmd("NO ANSWER FROM JES2"). The other message is
#cmd("NOT ENOUGH STORAGE").

*Columns.* #cmd("NP"), which is four characters wide, and #cmd("PRINTER") stay
in place; the Right and Left keys move the others. SDSF fills these from the
answer of JES2:

#deflist(width: 1.8in,
  [#cmd("PRINTER")], [the name of the printer.],
  [#cmd("STATUS")], [its state as JES2 gives it: #cmd("INACTIVE"),
    #cmd("ACTIVE"), #cmd("DRAINED"), and so on.],
  [#cmd("SFORM")], [the forms it prints. May be overtyped.],
  [#cmd("SCLASS")], [the output classes it prints. May be overtyped.],
  [#cmd("JOBNAME"), #cmd("TYPE"), #cmd("JNUM")], [the job an active printer is
    printing.],
  [#cmd("SFCB")], [the FCB image. May be overtyped.],
  [#cmd("SUCS")], [the print train.],
  [#cmd("SEP")], [separator pages, #cmd("YES") or #cmd("NO"). May be
    overtyped.],
  [#cmd("SDEST1")], [the route, #cmd("LOCAL") or #cmd("U")#var("n"). May be
    overtyped.],
)

For #cmd("WORK-SELECTION"), #cmd("SBURST"), #cmd("SPRMODE1"), #cmd("SEPDS"),
#cmd("CKPTLINE") and #cmd("CKPTPAGE") SDSF shows the JES2 defaults, and
the other columns are blank. All the columns, in the order of the screen, are
#cmd("NP"), #cmd("PRINTER"), #cmd("STATUS"), #cmd("SFORM"), #cmd("SCLASS"),
#cmd("JOBNAME"), #cmd("TYPE"), #cmd("JNUM"), #cmd("REC-CNT"),
#cmd("REC-PRT"), #cmd("JP"), #cmd("DP"), #cmd("C"), #cmd("FORM"), #cmd("FCB"),
#cmd("UCS"), #cmd("WRITER"), #cmd("FLASH"), #cmd("DEST-NAME"), #cmd("BURST"),
#cmd("SEP"), #cmd("SEPDS"), #cmd("PRMODE"), #cmd("SFCB"), #cmd("SUCS"),
#cmd("SWRITER"), #cmd("SFLH"), #cmd("WORK-SELECTION"), #cmd("SBURST"),
#cmd("SPRMODE1"), #cmd("SPRMODE2"), #cmd("SDEST1"), #cmd("SDEST2"),
#cmd("SDEST3"), #cmd("SDEST4"), #cmd("SJOBNAME"), #cmd("M"), #cmd("NPRO"),
#cmd("MODE"), #cmd("CKPTLINE"), #cmd("CKPTPAGE"), #cmd("CKPTSEC"),
#cmd("CKPTMODE") and #cmd("CPY").

*Order of the rows.* As JES2 answers. An active printer is white, the others
are blue.

*Limiting the list.* #cmd("PR") with up to four of: a printer number, a range
#var("n")#cmd("-")#var("m") with #var("n") not above #var("m"), #cmd("LCL"),
#cmd("R")#var("n") and #cmd("RMT"). Remote printers are accepted, but none is
shown, since the answer of JES2 holds only local ones. A word that is none of
these gives #cmd("PARM INVALID"), and a fifth word #cmd("TOO MANY PARMS").
#cmd("PREFIX") and #cmd("DEST") do not limit this panel.

*Overtyping.* #cmd("SFORM"), #cmd("SCLASS"), #cmd("SEP"), #cmd("SFCB") and
#cmd("SDEST1") change what the printer is set to, by the JES2 command
#cmd("$T") with #cmd("F="), #cmd("Q="), #cmd("S="), #cmd("C=") and #cmd("R=")
(@ref-actions). #cmd("SFORM") and #cmd("SCLASS") share one field. The change
needs update access to #cmd("SDSF.OPER"); the panel says
#cmd("COMMAND ISSUED"), and Enter shows the new value. A value that is not
valid gives #cmd("INVALID SYNTAX") for #cmd("SFORM"), #cmd("SFCB") and
#cmd("SEP"),
#cmd("INVALID CLASS") for #cmd("SCLASS") and
#cmd("INVALID DESTINATION NAME") for #cmd("SDEST1").

*Action characters.* Up to four characters can be typed in #cmd("NP"). Each
gives JES2 the command named for that printer (@ref-actions):

#deflist(width: 1.0in,
  [#cmd("D")], [display the printer (#cmd("$DU")).],
  [#cmd("S")], [start the printer.],
  [#cmd("P")], [stop the printer when the output it prints is done.],
  [#cmd("Z")], [halt the printer at once\; #cmd("S") lets it go on.],
  [#cmd("I")], [interrupt the output it prints\; it is printed again later.],
  [#cmd("E")], [restart the output it prints from the beginning.],
  [#cmd("C")], [cancel the output it prints.],
  [#cmd("N")], [print one more copy of the output it prints.],
  [#cmd("B")#var("n")], [backspace\; #cmd("B5") goes back five pages.],
  [#cmd("F")#var("n")], [forward space\; #cmd("F5") skips five pages.],
)

After #cmd("B") and #cmd("F"), #cmd("D") and #cmd("C") are taken as JES2 takes
them. A form that is not valid gives #cmd("INVALID COMMAND"). #cmd("D") needs
read access to #cmd("SDSF.OPER"), the others update access\; without it the
message is #cmd("NOT AUTHORIZED FOR PRT").

*Profile variables.* None of its own.

== INIT: Initiators <ref-panels-init>

#idx("Initiator panel")
#idx("INIT command")
#idx("SDSF INITIATOR DISPLAY")
The Initiator panel lists the JES2 initiators, with the classes each selects
and the job it is running. The title line reads
#cmd("SDSF INITIATOR DISPLAY"). #cmd("INIT") takes no parameters, and the panel
needs read access to #cmd("SDSF.OPER"). Each time the panel is shown, SDSF
gives the JES2 command #cmd("$DI") and reads the answer from the system log,
so the command and its answer appear in the log every time.

*Columns.* The row is 80 columns wide, so the Left and Right keys move
nothing.

#deflist(width: 1.2in,
  [#cmd("NP")], [where an action character is typed.],
  [#cmd("ID")], [the number of the initiator.],
  [#cmd("STATUS")], [#cmd("INACTIVE"), #cmd("ACTIVE"), #cmd("DRAINED"),
    #cmd("HALTED") and so on, as JES2 gives it.],
  [#cmd("CLASSES")], [the job classes it selects, in that order. May be
    overtyped.],
  [#cmd("JOB-NAME"), #cmd("STEP-NAME"), #cmd("PROC-STEP"), #cmd("TYPE"),
    #cmd("JNUM"), #cmd("C"), #cmd("ASID")], [the job an active initiator
    runs.],
)

*Order of the rows.* As JES2 answers. An active initiator is white, the others
are blue.

*Overtyping.* #cmd("CLASSES") changes the classes the initiator selects, by the
JES2 command #cmd("$TI") (@ref-actions). JES2 keeps five at most. A value that
is not a list of classes gives #cmd("INVALID CLASS").

*Action characters.* Up to two characters can be typed in #cmd("NP"). Each gives
JES2 the command named for that initiator:

#deflist(width: 1.0in,
  [#cmd("D")], [display the initiator (#cmd("$DI")).],
  [#cmd("S")], [start it (#cmd("$SI")).],
  [#cmd("P")], [stop it once its job has ended (#cmd("$PI")).],
  [#cmd("Z")], [halt it: it takes no new job until #cmd("S") (#cmd("$ZI")).],
)

#cmd("D") needs read access to #cmd("SDSF.OPER"), the others update access\;
without it the message is #cmd("NOT AUTHORIZED FOR INIT"). Any other character
gives #cmd("INVALID COMMAND").

*Profile variables.* None of its own.

== LOG: System Log <ref-panels-log>

#idx("SYSLOG")
#idx("system log")
#idx("LOG command")
#idx("SDSF SYSLOG")
The system log panel shows the messages of the system and the commands given
to it, oldest first. SDSF reads them from the master trace table, the part of
the log the system keeps in storage, so the oldest lines drop out as new ones
come. The panel opens at the end. The title line reads #cmd("SDSF SYSLOG") and
shows the system, the date, #cmd("LINE") and the number of the line at the top,
and #cmd("COLUMNS") with the first and last column shown. When #cmd("SYSID") is
set, the title shows #cmd("0.000") where it otherwise shows #cmd("MTT"), the
system id given in place of the current system, and line 0 in place of the
current line. The panel needs read access to #cmd("SDSF.OPER").

*Rows.* A line is cut off at 255 characters. Enter, and the Down key at the end
of the log, read the log again. A #cmd("/") command is answered in the log:
SDSF waits a second and shows the log again with the answer.
#cmd("NO SYSLOG FOUND") is the message when #cmd("SYSID") names another system,
and #cmd("LOG NOT READABLE") when the log could not be read.

*Replies.* After the last line of the log come the replies the system is
waiting for, in white, the newest first, up to 30. Each shows its routing codes,
as four hexadecimal digits, and the text of its message. #cmd("ACTION")
chooses which are shown, by the routing codes of their messages: #cmd("1") to
#cmd("16"), #cmd("MVS") for 1 to 12, #cmd("USER") for 13 to 16, #cmd("ALL") or
#cmd("OFF"). A reply whose message has no routing code is shown unless the
setting is #cmd("OFF"). #cmd("REPLIES NOT READABLE") is the message when the
replies could not be read.

*Commands.* Besides the scroll commands there are #cmd("LOCATE") with a line
number or a time as #cmd("hh.mm.ss"), #cmd("FIND"), #cmd("COLS"),
#cmd("SET HEX"), #cmd("PRINT"), #cmd("SYSID"), #cmd("TOP") and
#cmd("BOTTOM") (@ref-cmd).

*Keys.* As in @ref-panels-common. The Left and Right keys move the columns, up
to column 255.

*Profile variables.* #cmd("ISFACT") and #cmd("ISFFND").
