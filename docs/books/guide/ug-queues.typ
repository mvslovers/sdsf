#import "../bookmaster/bookmaster.typ": *

= The Queues <ug-queues>

#idx("queues")
A job passes through JES2 in three stages. It is read in and waits for an
initiator to run it. It executes. When it has ended, its output either waits
to be printed or is held until somebody releases it. This chapter is about
the three lists that show those stages: the Input Queue panel (#cmd("I")),
the Held Output panel (#cmd("H")) and the Output Queue panel (#cmd("O")).
The Status panel (#cmd("ST")), described in @ug-jobs, shows all the stages
in one list; each panel here shows one, and all three are limited the same
way.

#tab(caption: [The three queue panels])[
  #table(columns: (0.9in, 1.55in, 1fr),
    [Command], [Panel], [What it lists],
    [#cmd("I")], [Input Queue], [Jobs that have been read in and wait to
      execute, or execute.],
    [#cmd("H")], [Held Output], [Jobs with held output: output that is not
      printed until it is released.],
    [#cmd("O")], [Output Queue], [Jobs that have ended and have output
      waiting to be printed, that is output that is not held.],
  )
]

What you do with a job on these panels is small on purpose. An action
character typed in the NP column (@ug-start) takes you to the data sets of
the job or to its output. The changes are made either on the Status panel,
which takes the action characters that hold, release, cancel and purge, or by
typing over a field of the row. The table shows where each change is made;
the sections that follow explain them.

#tab(caption: [What you want to do, and where])[
  #table(columns: (2.35in, 1fr),
    [You want to], [Do this],
    [See the data sets of a job], [#cmd("?") in the NP column, on I, H or O.],
    [Read the output of a job], [#cmd("S") in the NP column, on I, H or O.],
    [Hold a job so that it does not start], [#cmd("H") in the NP column, on
      ST.],
    [Release a held job], [#cmd("A") in the NP column, on ST.],
    [Change the class of a waiting job], [Type the new class over #cmd("C"),
      on I.],
    [Change the priority of a job], [Type the new priority over #cmd("PRTY"),
      on I or ST.],
    [Release held output for printing], [#cmd("O") in the NP column, on H (or
      on ST).],
    [Send output to another destination], [Type the new destination over
      #cmd("DEST"), on I, O or H (on H together with #cmd("O")).],
    [Cancel a job and keep its output], [#cmd("C") in the NP column, on ST.],
    [Delete the output of a job (purge)], [#cmd("P") in the NP column, on ST.],
  )
]

Three rules hold for all of them.

- *Your own jobs, and the others as far as RAKF lets you.* You always see
  your own jobs and may do anything to them. A job of somebody else is on a
  list only if RAKF gives you read access to it, and to change it you need
  update access. Without it SDSF answers #cmd("NOT AUTHORIZED FOR JOB").
  @ug-access explains how the access is given.
- *I, O and H take #cmd("?") and #cmd("S") only,* and #cmd("O") on H. Any
  other action character typed there is answered with
  #cmd("ACTION NOT AVAILABLE YET") and does not stay in the NP column. Do the
  rest on the Status panel.
- *SDSF says what it did, not what JES2 did.* When SDSF has given a command
  to JES2, the title line shows #cmd("COMMAND ISSUED"). That does not say that
  JES2 took it; JES2's answer is in the system log (@ug-log). A list does not
  always change by itself: press Enter with nothing typed to read it again.

The _SDSF Reference_ describes every field of the three panels in the chapter
"Panels", and every action character, the command it gives and the access it
needs in the chapter "Action Characters".

== The Input Queue <ug-queues-input>

#idx("Input Queue panel")
#idx("I command")
The Input Queue panel lists the jobs that have been read in and are waiting to
execute or are executing. It is the panel to look at when you ask "has my job
started yet?", "which jobs are held?" or "what is in front of mine?". The
title line reads #cmd("SDSF INPUT QUEUE DISPLAY ALL CLASSES") or, when the
list is limited, #cmd("SDSF INPUT QUEUE DISPLAY CLASS") and the classes.

=== Looking at the Queue

Type #cmd("I") on the command line. Without anything else the panel shows
batch jobs of every class. A row has these fields:

#deflist(width: 1.0in,
  [#cmd("JOBNAME")], [the name of the job.],
  [#cmd("TYPE")], [#cmd("JOB"), #cmd("STC") or #cmd("TSU").],
  [#cmd("JNUM")], [the JES2 job number.],
  [#cmd("PRTY")], [the priority, 0 to 15.],
  [#cmd("C")], [the class of the job.],
  [#cmd("POS")], [the place of a waiting job among the jobs of its class that
    are not held.],
  [#cmd("DEST")], [where the output goes.],
  [#cmd("STAT")], [#cmd("HOLD") if the job is held.],
)

The waiting jobs come first, by class, then by priority, the highest first,
and then by job number; the executing jobs follow. Executing jobs are white,
the others blue. #cmd("POS") tells you how many jobs of the class are ahead of
yours. A held job shows no #cmd("POS"): it takes no place in the line until it
is released.

#cmd("?") typed alone on the command line adds more fields after these, those
of the Status panel, such as the programmer name, the times the job was read in
and started, and the number of cards. The Right key (PF11) brings them into
view and the Left key (PF10) goes back; a second #cmd("?") takes them away
again.

=== Limiting the Queue

The list can be long. Limit it by writing the classes #emph[directly after] the
#cmd("I"), up to seven of them, and #cmd("H") or #cmd("NH") after a blank:

#deflist(width: 1.2in,
  [#cmd("IA")], [the jobs of class A.],
  [#cmd("IAB")], [classes A and B.],
  [#cmd("I H")], [the held jobs of every class.],
  [#cmd("IA H")], [the held jobs of class A.],
  [#cmd("I NH")], [the jobs that are not held.],
  [#cmd("I$#")], [the TSO users (#cmd("$")) and the started tasks
    (#cmd("#")), which the list leaves out unless you ask for them.],
)

#note[A blank decides what a letter means. #cmd("IH") shows class H, but
#cmd("I H") shows the held jobs. #cmd("I $") is refused with
#cmd("PARM INVALID"), because the classes belong directly after the
#cmd("I").]

The classes stay as you typed them until the next #cmd("I"). Two more commands
limit the lists, this one and the others: #cmd("PREFIX") limits them to the
jobs whose names match a name or a pattern (#cmd("PREFIX PAY*")), and
#cmd("DEST") to a destination (#cmd("DEST R1")). SDSF keeps both for the next
session, so when a list is empty and should not be, #cmd("PREFIX ?") and
#cmd("DEST ?") show what is set. The commands are described in the _SDSF
Reference_, chapter "Commands".

=== Acting on the Jobs

On this panel, #cmd("?") shows the data sets of the job and #cmd("S") its
output. To hold a waiting job, so that it does not start, switch to the Status
panel (#cmd("ST")), type #cmd("H") in the NP column of the job and press Enter.
SDSF gives JES2 the command and shows #cmd("COMMAND ISSUED")\; press Enter
again, and the row shows #cmd("HOLD"). The job is now on the list of
#cmd("I H"). #cmd("A") on the Status panel releases it, and #cmd("C") cancels
it. #cmd("P") purges it: it cancels the job and deletes its output, and SDSF
does not ask before it does.

Three fields of a row can be changed here, by typing over them and pressing
Enter:

#deflist(width: 1.0in,
  [#cmd("PRTY")], [the priority: digits only. JES2 decides which values it
    takes.],
  [#cmd("C")], [the class: one class, A to Z or 0 to 9. This is how a job is
    moved to another class.],
  [#cmd("DEST")], [the destination: #cmd("LOCAL"), #cmd("R")#var("n") for a
    remote, or #cmd("U")#var("n").],
)

#cmd("PRTY") and #cmd("C") stand side by side in one field: type over either
part. SDSF checks every value typed, on all the rows, before it gives any
command. If one is wrong, none is given, the values stay as you typed them and
the cursor goes to the first one in error. The messages are
#cmd("FIELD NOT NUMERIC"), #cmd("INVALID CLASS") and
#cmd("INVALID DESTINATION NAME"). A change needs update access to the job. An
action character typed in the same Enter as a change is not carried out; type
it again afterwards.

For example, job #cmd("PAYROLL") is held in class A, and you want it in class
B. Type #cmd("IA H"), type #cmd("B") over the #cmd("A") in the #cmd("C") field
of #cmd("PAYROLL"), and press Enter. The title line shows
#cmd("COMMAND ISSUED"). Press Enter again to read the list: #cmd("PAYROLL") is
no longer among the jobs of class A. It is still held; #cmd("A") on the Status
panel lets it run.

== Held Output <ug-queues-held>

#idx("Held Output panel")
#idx("H command")
#idx("held output")
Held output is output that is not printed until it is released. Output is held,
for example, when the #cmd("MSGCLASS") of the job is a held class. It stays on
the spool, where you can read it, until you release it for printing or purge
it. The Held Output panel lists the jobs that have such output. A row stands
for one job, and #cmd("DN") says how many of its data sets are held. The title
line reads #cmd("SDSF HELD OUTPUT DISPLAY"), then #cmd("ALL CLASSES") or
#cmd("CLASS") and the classes, and the lines of all the rows.

A held job and held output are two things. A held job waits to execute and does
not start. Held output belongs to a job that has ended, and does not print.

=== Looking at Held Output

Type #cmd("H"). Without anything else the panel shows only your own jobs:

#deflist(width: 1.2in,
  [#cmd("H")], [the held output of the jobs whose names begin with your user
    id.],
  [#cmd("H ALL")], [the held output of all the jobs you may see.],
  [#cmd("HX")], [class X only. Up to seven classes may follow the #cmd("H")
    directly.],
  [#cmd("HX TBR*")], [class X, the jobs whose names begin with #cmd("TBR").],
)

A #cmd("PREFIX") that you have set takes the place of the user id rule, and
#cmd("DEST") limits the list as well. If the panel is empty and you expect
output, try #cmd("H ALL") first, and then #cmd("PREFIX ?"). Unlike on the
Input Queue panel, #cmd("H ?") does not show further fields: the #cmd("?") is
taken as a job name, and nothing is listed.

The oldest comes first, by the time the job ended. The row is wide:
#cmd("NP") and #cmd("JOBNAME") stay in place, and the Right key (PF11) and the
Left key (PF10) move the others. On the first screen are the number of held
data sets, the date the job was read in, the class, forms and destination of
the output, and the number of records; the times of the job, the programmer
name and the account number are further to the right.

=== Releasing Held Output

#cmd("S") in the NP column shows the output of the job, all its data sets one
after the other, and #cmd("?") shows the list of its data sets. Both are for
reading: the output stays held.

#cmd("O") in the NP column releases the held output of the job for printing.
SDSF gives JES2 the release command and shows #cmd("COMMAND ISSUED"). Press
Enter to read the list again: the job whose output has been released is no
longer on it. Output that is not held and waits to be printed is what the
Output Queue panel shows (@ug-queues-output). #cmd("O") needs update access to
the job; without it the answer is #cmd("NOT AUTHORIZED FOR JOB").

To send the output somewhere else as it is released, type the new destination
over the #cmd("DEST") field of the row (#cmd("LOCAL"), #cmd("R")#var("n") or
#cmd("U")#var("n")) and put #cmd("O") in the NP column, both in the same
Enter. SDSF gives JES2 the destination first and then the release. A new
#cmd("DEST") without the #cmd("O") is refused with
#cmd("\"O\" ACTION REQUIRED")\; the value stays on the screen, so that you can
add the #cmd("O") and press Enter again. The field can be typed over only
while it is on the screen, that is, on the first screen of columns.

There is no action character on this panel that deletes held output. To purge
it, use #cmd("P") on the Status panel: find the job there, type #cmd("P") in its
NP column and press Enter. SDSF deletes the held output and does not ask
again, so make sure the row is the right one.

== Output Waiting to Print <ug-queues-output>

#idx("Output Queue panel")
#idx("O command")
The Output Queue panel lists the jobs that have ended and have output waiting
to be printed, that is, output that is not held. It is where output rests
between the end of a job and the printer; the Printer panel is in
@ug-devices. The title line reads #cmd("SDSF OUTPUT"), then
#cmd("ALL CLASSES") or #cmd("CLASS") and the classes, #cmd("ALL FORMS") or
#cmd("FORM") and the forms, and #cmd("LINES") with the lines of all the rows.

=== Looking at Output Waiting to Print

Type #cmd("O"). Limit the list by writing the output classes directly after the
#cmd("O"), up to seven, and the forms after a blank:

#deflist(width: 1.2in,
  [#cmd("O")], [all the output waiting to be printed.],
  [#cmd("OA")], [class A.],
  [#cmd("OAX")], [classes A and X.],
  [#cmd("O STD*")], [the output on forms that begin with #cmd("STD").],
  [#cmd("OA STD")], [class A on forms #cmd("STD").],
)

The forms may hold #cmd("*") for any number of characters and #cmd("%") for
exactly one. The class and the forms of a row are those of the first data set
of the job that waits to be printed. #cmd("$") and #cmd("#"), which stand for
the TSO users and the started tasks on the Input Queue panel, are not allowed
here. #cmd("PREFIX") and #cmd("DEST") limit the list as on the other panels;
#cmd("DEST") limits by the destination of the job. A second operand after the
forms is refused with #cmd("TOO MANY PARMS").

The oldest comes first, by the time the job ended. A row shows the name, type
and number of the job, its priority, the output class, the forms and the FCB
image, the destination and the number of records; the Right key (PF11) brings
more fields into view. Some headings of the panel, such as #cmd("PRT-REC"),
#cmd("DEVICE") and #cmd("WTR"), are blank: SDSF does not fill them yet, so a
blank there says nothing about the output.

=== Acting on Output Waiting to Print

#cmd("?") and #cmd("S") work as on the other two panels: they show the data
sets of the job and its output, which you can read before it is printed. Any
other action character gives #cmd("ACTION NOT AVAILABLE YET").

One field can be changed, #cmd("DEST"): type the new destination over it and
press Enter, and the output of the job goes there. SDSF gives JES2 the command
and the title line shows #cmd("COMMAND ISSUED"). It needs update access to the
job. The other fields only show, since JES2 has no command to change them.

To delete output that waits to be printed, use #cmd("P") on the Status panel,
as for held output. To print it, a printer must be started; that is done on
the Printer panel (@ug-devices).
