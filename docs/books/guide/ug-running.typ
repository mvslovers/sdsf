#import "../bookmaster/bookmaster.typ": *

= The Running System <ug-running>

#idx("address space")
The Status panel shows jobs and where they are on the JES2 queues. This
chapter is about the other question: what is running on the system right now.
SDSF answers it on the DA panel, which lists the address spaces that are
active. The chapter shows how to read the list, how to make it shorter, and how
to see the columns that do not fit on the screen. Every column, word and
message is described in full in the _SDSF Reference_: in the section “DA:
Active Address Spaces” of the chapter “Panels”, and in the section “DA” of the
chapter “Commands”.

== The Active Address Spaces <ug-running-da>

#idx("DA panel")
#idx("DA command")
#idx("active address spaces")
Type #cmd("DA") on the command line of the primary option menu, or of another
list panel, and press Enter. The DA panel (Display Active users) lists the
address spaces that are active on the system: batch jobs, started tasks and TSO
users, and, if you ask for them, idle initiators (@ug-running-choose). For each
one it shows what the address space uses: the processor, I/O and real storage.
The End key (PF3) takes you back to the primary option menu.

=== The Title Line <ug-running-title>

#idx("title line")
The title line reads #cmd("SDSF DA"), the id of the system, #cmd("PAGING"),
#cmd("SIO") and #cmd("CPU"), each of the last three with a number.

#deflist(width: 1.2in,
  [#cmd("PAGING")], [is always 0.00. SDSF does not measure paging yet. The
    #cmd("PAGING") column of the rows is the same.],
  [#cmd("SIO")], [is the sum of the I/O rates (EXCPs per second) of the address
    spaces.],
  [#cmd("CPU")], [is the sum of their shares of the processor, in percent.],
)

#idx("interval")
The rates are taken over the time between two displays of the panel. The first
time the panel is shown, #cmd("SIO") and #cmd("CPU") are 0, and so is every
rate in the rows. Press Enter with nothing on the command line: the panel is
read again and shows the rates of the time since the last display. The sums add
up only the address spaces that were also in the earlier measurement. They
include address spaces that the panel does not show, so a sum can be larger than
the sum of the rows on the screen.

=== Reading a Row <ug-running-rows>

#idx("row")
#idx("ASID")
A row is one address space. The rows are in the order of their address space
ids (#cmd("ASID")). A row is white, or blue while the address space is swapped
out. If the list is longer than the screen, the Up key (PF7) and the Down key
(PF8) scroll it (@ug-start).

The first columns, those you see when the panel is shown for the first time,
are these:

#deflist(width: 1.2in,
  [#cmd("JOBNAME")], [the name of the job, started task, TSO user or
    initiator. It stays in place when the columns move.],
  [#cmd("STEPNAME")], [the step running, for a batch job\; the procedure of a
    started task\; the logon procedure of a TSO user.],
  [#cmd("PROCSTEP")], [the step of the procedure\; for a TSO user, the
    terminal.],
  [#cmd("TYPE")], [#cmd("JOB") for a batch job, #cmd("STC") for a started task,
    #cmd("TSU") for a TSO user. It is blank for an idle initiator.],
  [#cmd("JNUM")], [the JES2 job number, if the address space has one.],
  [#cmd("C")], [the job class.],
  [#cmd("POS")], [#cmd("IN") in storage, #cmd("OUT") swapped out, #cmd("N/S")
    not swappable.],
  [#cmd("DP")], [the dispatching priority, in hexadecimal.],
  [#cmd("PGN")], [the performance group. You may overtype it
    (@ug-running-pgn).],
  [#cmd("REAL")], [the frames of real storage the address space holds.],
  [#cmd("PAGING")], [always 0.00.],
  [#cmd("SIO")], [the I/O (EXCPs) per second since the panel was last shown.],
  [#cmd("CPU%")], [the share of the processor since the panel was last shown.],
)

#idx("JNUM")
*The job number.* SDSF takes the job number from JES2: it is the number of the
executing job of the same name and type. An address space that has no JES2 job,
such as JES2 itself, and an idle initiator have none.

#idx("master address space")
*The master address space.* Its row has #cmd("ASID") 1. Its #cmd("JNUM") is the
number of the executing #cmd("SYSLOG") task, and the action characters on its
row act on that task.

*An initiator that runs a job.* It shows as that job, not as an initiator. A
row of type #cmd("INIT") is an idle initiator.

=== Doing Something with a Row <ug-running-act>

#idx("action character")
Type an action character in the NP column of a row and press Enter, as on the
Status panel (@ug-start). A row that has a JES2 job takes these:

#deflist(width: 0.7in,
  [#cmd("?")], [shows the data sets of the job (@ug-jobs).],
  [#cmd("S")], [browses its output (@ug-jobs).],
  [#cmd("D")], [displays the job: JES2 answers with its status.],
  [#cmd("L")], [lists its output: JES2 answers with its data sets.],
  [#cmd("C")], [cancels the job.],
  [#cmd("CD")], [cancels the job with a dump.],
  [#cmd("P")], [cancels the job and purges its output.],
  [#cmd("A")], [releases the job.],
  [#cmd("H")], [holds the job.],
  [#cmd("E")], [restarts the job.],
)

JES2's answers go to the system log (@ug-log), and the list is read again after
the action. The access each action needs is in the section “The Access Each Action Needs” of the chapter “Action Characters” of the _SDSF Reference_. #cmd("O") is
not taken on the DA panel and gives #cmd("INVALID COMMAND"). A row without a
JES2 job, such as an idle initiator, takes none of the action characters and
gives #cmd("JOB NOT FOUND").

=== Moving an Address Space to Another Performance Group <ug-running-pgn>

#idx("PGN")
#idx("performance group")
#idx("overtyping")
Type the number of the new group over the #cmd("PGN") of the row and press
Enter. SDSF gives the operator command #cmd("E")
#var("name")#cmd(",PERFORM=")#var("n"). It needs update access to the job, or,
for an address space without a job, to #cmd("SDSF.OPER") (@ug-access). The field
can be overtyped only where it is on the screen (@ug-running-pf11), and an
action character typed in the same Enter is not carried out: type it again.

== Choosing Which Address Spaces to See <ug-running-choose>

#idx("DA command")
#idx("type")
#idx("position")
Without a word after it, #cmd("DA") shows batch jobs, TSO users and started
tasks, whether they are in storage or swapped out. On a busy system that is a
long list. Give #cmd("DA") up to four words to see fewer address spaces, or, for
the idle initiators, more.

=== The Types and the Positions <ug-running-words>

An address space has a type and a position. The words that name them are:

#deflist(width: 1.8in,
  [#cmd("JOB"), #cmd("TSU"), #cmd("STC"), #cmd("INIT")], [the types: batch
    jobs, TSO users, started tasks, idle initiators.],
  [#cmd("IN"), #cmd("OUT")], [the positions: in storage, or swapped out. An
    address space that is not swappable counts as in.],
)

#cmd("TRANS") and #cmd("READY") are accepted as positions, but they select
nothing, since SDSF sees only #cmd("IN") and #cmd("OUT"). #cmd("DA TRANS") shows
no address space.

=== Showing More, Showing Fewer <ug-running-limit>

A word alone adds to what #cmd("DA") shows. A word with #cmd("O") in front shows
that and nothing else, and a word with #cmd("NO") in front shows everything but
that:

#deflist(width: 1.8in,
  [#var("type")], [adds the type: #cmd("DA INIT") shows the idle initiators as
    well.],
  [#var("position")], [shows that position only. It replaces the default
    positions: #cmd("DA OUT") shows only the address spaces that are swapped
    out.],
  [#cmd("O")#var("type"), #cmd("O")#var("position")], [only that type or
    position, for example #cmd("OJOB") or #cmd("OOUT"). Only one such word.],
  [#cmd("NO")#var("type"), #cmd("NO")#var("position")], [everything but that
    type or position, for example #cmd("NOTSU").],
  [#cmd("ALL"), #cmd("ALLT"), #cmd("ALLP")], [all types and positions, all
    types, all positions. Each stands alone.],
)

Some examples:

#deflist(width: 1.8in,
  [#cmd("DA OJOB")], [batch jobs only.],
  [#cmd("DA NOTSU")], [no TSO users.],
  [#cmd("DA NOTSU OUT")], [the swapped-out address spaces, but no TSO users.],
  [#cmd("DA INIT")], [the usual address spaces and the idle initiators.],
  [#cmd("DA OINIT")], [only the idle initiators.],
  [#cmd("DA ALL")], [every type and position.],
)

Every #cmd("DA") with words starts from what #cmd("DA") alone shows: the words
are not added to those of the #cmd("DA") before. To go back to the usual list,
type #cmd("DA") with nothing after it.

#idx("PARM INVALID")
#idx("TOO MANY PARMS")
A word that is none of these gives #cmd("PARM INVALID"), and the cursor stands
on it. So does #cmd("ALL"), #cmd("ALLT") or #cmd("ALLP") together with another
word. More than four words give #cmd("TOO MANY PARMS"). Correct the command and
press Enter again. A word that begins with #cmd("O") is read as one with
#cmd("O") in front, unless it begins with #cmd("OU"), so #cmd("OUT") is a
position.

The DA panel has no limit by name, and #cmd("PREFIX") and #cmd("DEST") do not
limit it.

=== Who Sees What <ug-running-who>

#idx("SDSF.OPER")
A row that has a JES2 job is shown when you may read the job (@ug-access). The
rows that have none, such as JES2 and the idle initiators, need read access to
#cmd("SDSF.OPER"). The master address space is such a row only while no
#cmd("SYSLOG") task is executing; while one is, the row has the number of that
task and follows the rule for jobs.

== The PF11 Pages <ug-running-pf11>

#idx("PF11")
#idx("further fields")
#idx("Right key")
A row of the DA panel is 113 or 114 columns wide, more than the 80 of a
screen. The Right key (PF11) shows the part of the row that did not fit, and
the Left key (PF10) goes back to the start. #cmd("NP") and #cmd("JOBNAME") stay
in place. The Right key moves the columns after #cmd("JOBNAME") once, as far as
the end of the row, so a second press moves nothing more. If your screen is as
wide as the row, nothing moves. An amount typed on the command line before the
key is ignored: the amount does not count on the DA panel.

The columns that come after those of @ug-running-rows are these:

#tab(caption: [The columns on the right of the DA panel])[
  #table(columns: (1.2in, 1fr),
    [Column], [What it shows],
    [#cmd("ASID")], [the address space id.],
    [#cmd("EXCP-CNT")], [the I/O (EXCPs) of the address space so far.],
    [#cmd("CPU-TIME")], [the processor time of the current step, in seconds.],
    [#cmd("SR")], [why the address space was swapped out: #cmd("TI") and
      #cmd("TO"), terminal input or output wait\; #cmd("LW"), long wait\;
      #cmd("XS"), auxiliary storage shortage\; #cmd("RS"), real storage
      shortage\; #cmd("DW"), detected wait\; #cmd("RQ"), requested\; #cmd("NQ"),
      enqueue exchange\; #cmd("EX"), exchange\; #cmd("US"), unilateral.],
    [#cmd("DMN")], [the domain.],
  )
] <ug-running-right-columns>

#cmd("EXCP-CNT") and #cmd("CPU-TIME") are totals, for the address space and for
the current step. #cmd("SIO") and #cmd("CPU%") are rates over the time between
two displays.

#note[On a screen of 80 columns, the first column of the moved part can show
without its first characters, so that the heading reads #cmd("OS") for
#cmd("POS").]

#idx("? command")
#idx("order of the columns")
=== Another Order of the Columns <ug-running-qm>

#cmd("?") typed alone on the command line, with nothing else, changes the order
of the columns after #cmd("JOBNAME"). It is not the #cmd("?") action character.
The order is then #cmd("STEPNAME"), #cmd("PROCSTEP"), #cmd("TYPE"),
#cmd("JNUM"), #cmd("C"), #cmd("ASID"), #cmd("EXCP-CNT"), #cmd("CPU-TIME"),
#cmd("REAL"), #cmd("PAGING"), #cmd("SIO"), #cmd("CPU%"), #cmd("DP"), #cmd("POS"),
#cmd("SR"), #cmd("PGN") and #cmd("DMN"). The Right key and the Left key work in
this order as in the other. A second #cmd("?") returns to the first order. The
section “?” of the chapter “Commands” of the _SDSF Reference_ has the command,
and the appendix “PF Key Assignments” the keys.
