#import "../bookmaster/bookmaster.typ": *

= Looking at Jobs <ug-jobs>

This is the chapter you will use most. You submitted a job: where is it, did
it end, and what did it print? SDSF answers in three steps. The Status panel
lists the jobs. From a job you go to the Job Data Set panel, which lists the
data sets the job wrote. From a data set you go to the Output Data Set
panel, which shows its text. Each step is one action character typed in the
NP column, and the End key (PF3) takes you back, one panel at a time.

This chapter shows the way. The columns of each panel, every action character
and every message are in the _SDSF Reference_, in the chapters "Panels",
"Action Characters" and "Messages". Starting SDSF, the NP column and the
scrolling keys are in @ug-start.

== The Status Panel <ug-jobs-st>

#idx("Status panel")
#idx("ST command")
The Status panel lists the jobs that JES2 holds: batch jobs, started tasks and
TSO users, waiting to execute, executing, or ended and waiting for their
output to be printed.

*Show the panel.* Type #cmd("ST") on the command line of the primary option
menu, or of any other SDSF panel, and press Enter. The title line reads
#cmd("SDSF STATUS DISPLAY ALL CLASSES"), and below the heading line there is
one row per job.

*Which jobs you see.* You see your own jobs, and the jobs of other users as
far as RAKF lets you read them. A job you may not read is not listed. If you
see only your own jobs and expected more, the system has no rule that lets
you read the others; @ug-access explains the rules.

=== Reading a Row <ug-jobs-row>

These are the columns you need to follow a job. The others are explained in
the Reference, under "Panels", "ST: Status".

#deflist(width: 1.2in,
  [#cmd("JOBNAME")], [The name of the job, started task or TSO user.],
  [#cmd("TYPE")], [#cmd("JOB") for a batch job, #cmd("STC") for a started
    task, #cmd("TSU") for a TSO user.],
  [#cmd("JNUM")], [The JES2 job number. Two jobs of the same name differ in
    it.],
  [#cmd("QUEUE")], [Where the job is: #cmd("EXECUTION") while it waits for an
    initiator and while it runs, #cmd("PRINT") when it has ended and its
    output is still on the spool.],
  [#cmd("C")], [The job class of a batch job. A job that has ended, a started
    task and a TSO user have none.],
  [#cmd("POS")], [The place of a waiting job among the jobs of its class.],
  [#cmd("HDN")], [The number of the job's held output data sets; blank when
    there is none.],
  [#cmd("DEST")], [Where the output goes: #cmd("LOCAL") or a remote.],
  [#cmd("STAT")], [#cmd("HOLD") if the job is held.],
)

Executing jobs are white; the others are blue. A job that waits to execute
shows #cmd("EXECUTION") in #cmd("QUEUE"), not #cmd("INPUT")\; its #cmd("POS")
tells how many jobs of its class are ahead of it.

*The order of the rows.* The jobs that wait to execute come first, by class,
then by priority, the highest first, then by job number. After them come the
executing batch jobs, the TSO users and the started tasks. The jobs on the
print queue, the ones that have ended, come last. When the list is longer
than the screen, the Down key (PF8) shows the rest.

=== Following a Job <ug-jobs-follow>

You have submitted the job #cmd("MYJOB"). To see where it is:

+ Type #cmd("ST") on the command line and press Enter.
+ Find the row of #cmd("MYJOB") and read #cmd("QUEUE"). While the job waits
  or runs it shows #cmd("EXECUTION")\; when the job has ended it shows
  #cmd("PRINT").
+ To see the job's new state later, press Enter with nothing typed on the
  command line. SDSF reads the list again.

The list does not change by itself. A job that ended after SDSF read the list
is still shown as executing until you press Enter on an empty command line.
The same is true after an action character: the row stays as it was until the
list is read again.

*Finding a job in a long list.* Type #cmd("FIND MYJOB") and press Enter: the
row with the name goes to the top of the list. The Repeat-FIND key (PF5)
looks for the next one. To show only the job, limit the list, as the next
section describes.

== The Prefix and Classes <ug-jobs-prefix>

#idx("PREFIX command")
#idx("class")
On a busy system the list is long. Three things make it shorter: the classes
and a name on the #cmd("ST") command, the #cmd("PREFIX") command, and the
#cmd("DEST") command. A job must satisfy all of them that are in force to be
on the list.

=== Classes and a Name on ST <ug-jobs-stclass>

Write the classes directly after #cmd("ST"), without a blank, and the name
after a blank. Press Enter after each of these:

#deflist(width: 1.6in,
  [#cmd("STA")], [Only the batch jobs of class A.],
  [#cmd("STAB")], [The jobs of classes A and B. Up to six classes may be
    given.],
  [#cmd("ST PAY*")], [Only the jobs whose names begin with #cmd("PAY").],
  [#cmd("STA PAY*")], [Both: class A, and names that begin with
    #cmd("PAY").],
  [#cmd("ST")], [All classes and all names again.],
)

In a name, #cmd("*") stands for any number of characters and #cmd("%") for
exactly one: #cmd("ST HERC%1") shows the jobs named #cmd("HERC"), any one
character, #cmd("1"). Without a wildcard the whole name must match:
#cmd("ST MYJOB") shows only the jobs named #cmd("MYJOB").

When you give classes, the title line reads #cmd("SDSF STATUS DISPLAY CLASS A")
(with the classes you gave), and *the list leaves out the jobs that have no
class*: the jobs that have ended and wait on the print queue, the TSO users
and the started tasks. If you look for a job that has ended, do not give a
class.

The classes and the name last until the next #cmd("ST"). Typing #cmd("ST")
alone starts again with all of them.

=== The Prefix <ug-jobs-prefixcmd>

#cmd("PREFIX") limits the lists to the jobs whose names match a name, as the
name of #cmd("ST") does, but it works on more panels and it stays.

+ Type #cmd("PREFIX TBR*") and press Enter.
+ Type #cmd("ST") and press Enter. Only the jobs whose names begin with
  #cmd("TBR") are listed.
+ To see all jobs again, type #cmd("PREFIX") alone and press Enter.

The prefix limits the Status panel and the Input Queue, Output Queue and Held
Output panels. It does not limit DA, PR and INIT. SDSF keeps the prefix in
your ISPF profile, so it is still in force when you start SDSF the next time.
On the Status panel, a name typed with #cmd("ST") applies as well: the job
must match both.

*When the list is empty and should not be.* A prefix or a destination from an
earlier session may be hiding your jobs. Type #cmd("PREFIX ?") and press
Enter: SDSF puts the setting on the command line, as #cmd("PREFIX name * %"),
and you can read it. Type #cmd("PREFIX") alone to take it away. Do the same
with #cmd("DEST ?") and #cmd("DEST") for the destination.

=== The Destination <ug-jobs-dest>

#cmd("DEST") limits the lists to the jobs whose output goes to the
destinations you name, for example #cmd("DEST R1") for remote 1 or
#cmd("DEST LOCAL"). #cmd("DEST") alone shows all destinations again. SDSF
keeps it in the profile, like the prefix. The Reference describes both
commands, under "Commands".

== Looking at the Data Sets of a Job <ug-jobs-ds>

#idx("data set", "of a job")
Everything a job wrote to the spool, SDSF shows as the data sets of the job.
Every job has three that JES2 writes itself:

#deflist(width: 1.2in,
  [#cmd("JESMSGLG")], [The job log: when the job started and ended, and the
    messages.],
  [#cmd("JESJCL")], [The JCL as JES2 read it.],
  [#cmd("JESYSMSG")], [The messages of the system: the steps, their data sets
    and their return codes.],
)

The others are the data sets that the programs of the job write, such as
#cmd("SYSPRINT"). There are two ways to look at them:

#deflist(width: 1.2in,
  [#cmd("?")], [Lists the data sets of the job, and lets you pick one.],
  [#cmd("S")], [Shows the text of all the data sets of the job, one after the
    other.],
)

*Pick a data set.*

+ On the Status panel, move the cursor to the NP column of the row of the job.
  The Tab key goes from field to field; a row has more fields than NP, since
  #cmd("PRTY") and #cmd("DEST") can be overtyped.
+ Type #cmd("?") and press Enter. The Job Data Set panel appears
  (@ug-jobs-jds).
+ Type #cmd("S") in the NP column of the data set you want and press Enter.
  The Output Data Set panel shows its text (@ug-jobs-ods).
+ Press the End key (PF3) to go back to the Job Data Set panel, and again to
  go back to the Status panel.

*Read everything.* Type #cmd("S") in the NP column of the job on the Status
panel instead of #cmd("?"), and press Enter. The Output Data Set panel shows
all the data sets of the job one after the other. Press the End key (PF3) to
go back to the Status panel.

#cmd("?") and #cmd("S") work in the same way on the DA, Input Queue, Output
Queue and Held Output panels (@ug-queues and @ug-running). Whichever panel you start
from, you reach only the jobs it lists, and so only jobs you may read.

*The input of a job.* The Job Data Set panel normally lists what the job
wrote. Type #cmd("INPUT ON") on the command line and press Enter, and the
data sets of the next job you pick also include the job's input: its JCL
as JES2 converted it and the data in its input stream. #cmd("INPUT OFF") takes
it away again. SDSF does not keep the setting; it is #cmd("OFF") each time
SDSF starts.

== The Job Data Set Panel <ug-jobs-jds>

#idx("Job Data Set panel")
#idx("SDSF JOB DATA SET DISPLAY")
The Job Data Set panel lists the data sets of one job. The title line reads
#cmd("SDSF JOB DATA SET DISPLAY -"), the type and the name of the job, and its
JES2 job number in parentheses, for example #cmd("(J1240)"). There is one
row per data set, in the order the job has them.

#code("SDSF JOB DATA SET DISPLAY - JOB MYJOB    (J1240   )    LINE 1-4 (4)
COMMAND INPUT ===>                                        SCROLL ===> PAGE
NP DDNAME   STEP-NAME PROC-STEP DSID C REC-CNT PAGE-CNT BYTE-CNT CC RMT
   JESMSGLG JES2                   2 A      14                    1
   JESJCL   JES2                   3 A       9                    1
   JESYSMSG JES2                   4 A      17                    1
   SYSPRINT STEP1                102 A       6                    1")

The columns that tell you what a data set is:

#deflist(width: 1.6in,
  [#cmd("DDNAME")], [The DD name of the data set.],
  [#cmd("STEP-NAME"), #cmd("PROC-STEP")], [The step that wrote it, and its
    procedure step. The data sets of JES2 show #cmd("JES2").],
  [#cmd("DSID")], [The number of the data set within the job.],
  [#cmd("C")], [Its output class.],
  [#cmd("REC-CNT")], [Its records: the number of lines you will see.],
  [#cmd("CC")], [The copies to print.],
)

#cmd("NP") and #cmd("DDNAME") stay in place. The panel is wider than the
screen: the Right key (PF11) shows the columns to the right of
#cmd("DDNAME"), among them the forms and the date, and the Left key (PF10)
goes back. Some headings, such as #cmd("PAGE-CNT") and #cmd("BYTE-CNT"), are
not filled in yet and stay blank.

*What you can do here.* #cmd("S") in the NP column shows the data set on the
Output Data Set panel. Any other action character gives
#cmd("ACTION NOT AVAILABLE YET")\; the actions on a job, such as cancel and
hold, are for the Status panel. If the data set that you chose cannot be read,
the panel says #cmd("OUTPUT NOT READABLE"). #cmd("FIND") looks for a string in
the rows. The commands that show another panel, #cmd("ST"), #cmd("DA"),
#cmd("I"), #cmd("O"), #cmd("H"), #cmd("PR"), #cmd("INIT") and #cmd("LOG"), work
here as everywhere. The End key (PF3) goes back to the panel on which you
chose the job. The Reference describes every column under "Panels", "Job Data
Set".

== The Output Data Set Panel <ug-jobs-ods>

#idx("Output Data Set panel")
#idx("SDSF OUTPUT DISPLAY")
The Output Data Set panel shows the text of the output as it would be
printed. You get it with #cmd("S") on a job, which shows all its data sets
one after the other, or with #cmd("S") on a data set of the Job Data Set
panel, which shows that data set only.

#code("SDSF OUTPUT DISPLAY MYJOB    JOB  1240 DSID   102 LINE       1
COMMAND INPUT ===>                                        SCROLL ===> PAGE
***************************** TOP OF DATA *****************************
 IDCAMS  SYSTEM SERVICES
   LISTCAT LEVEL(HERC01)
 NONVSAM ------- HERC01.MYJOB.DATA
 IDC0001I FUNCTION COMPLETED, HIGHEST CONDITION CODE WAS 0
 IDC0002I IDCAMS PROCESSING COMPLETE. MAXIMUM CONDITION CODE WAS 0
**************************** BOTTOM OF DATA ***************************")

*The title line.* It shows the job, the data set at the top of the screen
(#cmd("DSID") and its number), #cmd("LINE") and the number of the line at the
top within that data set, and #cmd("COLUMNS") with the first and last column
shown. The columns start at 02: column 1 holds the carriage control and is
never shown. One record is one line. The lines #cmd("TOP OF DATA") and
#cmd("BOTTOM OF DATA") stand once, at the start and at the end of everything
shown. If you came with #cmd("S") on a job, the data sets follow one another
under a single pair of such lines, and the title line tells which of them is
at the top.

#block(breakable: false)[
*Moving about.*

#deflist(width: 1.9in,
  [the Down key (PF8), the Up key (PF7)], [Scroll down and up, by the amount
    in the SCROLL field.],
  [the Right key (PF11), the Left key (PF10)], [Move to the right and left,
    up to column 255.],
  [#cmd("BOTTOM"), #cmd("TOP")], [Go to the end or the start.],
  [#cmd("NEXT"), #cmd("PREV")], [Go to the start of the next or of the
    previous data set; #cmd("NEXT 2") skips one.],
  [#cmd("LOCATE 100")], [Puts line 100 of the data set at the top.],
  [#cmd("FIND ABEND")], [Looks for a string; the Repeat-FIND key (PF5) looks
    for the next one.],
)
]

A word typed on the command line before a scroll key is the amount for that
move: #cmd("M") for as far as it goes, #cmd("P") for a page, #cmd("H") for
half a page. @ug-search describes finding text and the other ways of
moving. #cmd("PRINT") writes the output to a SYSOUT data set or to a data
set of your own; the Reference describes it under "Commands".

*You cannot change the output.* What you type over the lines is not kept.

*Leaving.* The End key (PF3) goes back to the panel before: to the Job Data
Set panel if you came by it, otherwise to the Status panel. The command
#cmd("ST") goes to a new Status panel at once, and says
#cmd("DATA SET DISPLAYED") on the title line.

*Big output.* If the output is bigger than the storage SDSF has, the panel
shows what fits and says #cmd("NOT ENOUGH STORAGE"). #cmd("S") on one data set
of the Job Data Set panel shows that data set alone.
