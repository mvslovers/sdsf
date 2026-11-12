#import "../bookmaster/bookmaster.typ": *

= Searching and Navigating Output <ug-search>

#idx("searching")
#idx("navigating")
A job log can run to thousands of lines. This chapter shows how to get to the
line you want without paging through the rest: how to look for a string, how
to jump to a line or to a time, how to read a line by its columns or by its
hexadecimal digits, how to tell where you are, how to bring back a command you
typed before, and how to move between the data sets of a job.

Most of what follows works on the two panels that show text: the Output Data
Set panel, which shows the output of a job, and the system log. They are
described in @ug-jobs and @ug-log. Where a command also works on the lists,
the chapter says so. This chapter is the short way through. Each command, with
all its operands and messages, is in the _SDSF Reference_ (ML11-0002),
Chapter 1, “Commands”, and the keys are in its Appendix A, “PF Key
Assignments”.

== Finding Text <ug-search-find>

#idx("FIND command")
#idx("RFIND command")
#idx("searching", "for a string")
#cmd("FIND") (or #cmd("F")) searches the data for a string. The line with the
string goes to the top of the panel, the cursor goes to the string, and the
title line says what was found. Upper and lower case are the same.

A first search, on the output of a job:

+ Type #cmd("F IEF404I") on the command line and press Enter. SDSF looks
  forward from the top line of the panel. The next line that holds
  #cmd("IEF404I") goes to the top, and the title line says
  #cmd("CHARS 'IEF404I' FOUND").
+ Press the Repeat-FIND key (PF5), or type #cmd("RFIND"), to go to the next
  line that holds it. Each press goes one hit further.
+ When the search runs to the end of the data without a hit, the message is
  #cmd("*BOTTOM OF DATA REACHED*"), and the next #cmd("FIND") starts again at
  the beginning. (When a search goes on from a hit, SDSF may leave the screen
  as it is instead; the Reference, in the section “FIND”, says when.)
+ If the string is nowhere, the message is #cmd("NO CHARS  'IEF404I' FOUND").

#cmd("FIND") with no string looks again for the last one, in the same
direction. A string with blanks goes in quotes, as in #cmd("F 'NOT CATLGD'"),
and #cmd("*") stands for the string of the last #cmd("FIND"). SDSF keeps the
last string, so in your next session #cmd("FIND") alone or PF5 looks for it
again.

*Direction.* After the string you may say where to look. #cmd("NEXT") is the
default for a new string. #cmd("PREV") goes backward from the line before the
top line, #cmd("FIRST") forward from the beginning of the data and
#cmd("LAST") backward from its end. #cmd("ALL") counts the lines that hold the
string and goes to the first one.

*Kind.* #cmd("CHARS") finds the string anywhere and is the default.
#cmd("WORD") finds it as a word of its own, #cmd("PREFIX") (#cmd("PRE")) at the
beginning of a word and #cmd("SUFFIX") (#cmd("SUF")) at its end. Letters,
digits and the characters #cmd("$"), #cmd("#") and #cmd("@") make up a word.

*Columns.* One or two numbers at the end limit the search to a part of the
line: with one, the string must begin in that column; with two, it must lie
between them. The columns are those of the title line and of the scale line
that #cmd("COLS") shows (@ug-search-columns).

*Hexadecimal.* #cmd("X'5B'") looks for the bytes you give, two digits for each.
Here, and only here, case matters.

#tab(caption: [Examples of #cmd("FIND")])[
  #table(columns: (2.0in, 1fr),
    [Command], [Finds],
    [#cmd("F IEF404I")], [The next line with #cmd("IEF404I").],
    [#cmd("F JOB PREV")], [The line before the top line that holds
      #cmd("JOB").],
    [#cmd("F 'NOT CATLGD' ALL")], [How many lines hold it, and the first.],
    [#cmd("F X'5B' 1")], [A dollar sign in column 1.],
    [#cmd("F ABEND 20 60")], [#cmd("ABEND") within columns 20 to 60.],
    [#cmd("F SYS WORD")], [#cmd("SYS") as a word of its own, not inside
      another.],
  )
]

*How far SDSF looks.* On the log and on output, one #cmd("FIND") looks
through 5000 lines at most. Then it stops with #cmd("*FINDLIM REACHED*"), and
the next #cmd("FIND") goes on from there. #cmd("FINDLIM") changes the number
(Reference, section “FINDLIM”).

*On the lists.* On the Status panel and the other lists, #cmd("FIND") looks
through the rows as you see them. The kind and the columns are accepted there
but make no difference. With the cursor on a row, the search begins at the row
after it.

*Mistakes.* #cmd("INCONSISTENT PARAMETERS") means two directions, two kinds, or
a string that does not fit in the columns you gave. #cmd("INVALID HEX STRING")
means that what stands in #cmd("X'...'") is not hexadecimal. The help for
#cmd("FIND") has the same examples. All operands and messages are in
the Reference, section “FIND”.

== Locating a Line or a Time <ug-search-locate>

#idx("LOCATE command")
#idx("searching", "by line number")
#idx("searching", "by time")
#cmd("LOCATE") (or #cmd("L")) puts a line you name at the top.

#deflist(width: 1.7in,
  [#cmd("LOCATE 5")], [Line 5 goes to the top.],
  [#cmd("L 0")], [The first line.],
  [#cmd("LOCATE 14.30.00")], [On the log only: the first line with that time or
    a later one.],
)

On the Output Data Set panel the number counts the lines of the data set you
are in (@ug-search-datasets); on the log and on the lists it counts from the
first line or row. The title line shows the line that is now at the top, as
#cmd("LINE"), so you can see where #cmd("LOCATE") has put you.

The time is written #cmd("hh.mm.ss"), with points, as the log shows it. Use
it when you know when something happened and not what it said: put the time of
a failure on the command line, and the lines from then on are on the screen.

A #cmd("LOCATE") with nothing after it gets #cmd("TOO FEW PARMS"), one with two
operands #cmd("TOO MANY PARMS"), and one that is neither a number nor a time
#cmd("PARM INVALID"). The Reference, section “LOCATE”, has them all.

#cmd("TOP") and #cmd("BOTTOM") go to the two ends of the data. How far the Up
and Down keys scroll, and the word you can type before them, is in
the Reference, section “UP and DOWN”.

== Columns and Hexadecimal Display <ug-search-columns>

#idx("COLS command")
#idx("RESET command")
#idx("hexadecimal display")
#idx("columns")
A line of output or of the log can be wider than the screen. The title line of
both panels shows #cmd("COLUMNS") and the first and last column on the screen.
On the Output Data Set panel the first column is 2, since column 1 holds the
carriage control and is never shown. The Left and Right keys (PF10 and PF11)
move the text sideways, by the width of the screen, up to column 255. With a
number typed before the key, or after the command (#cmd("RIGHT 10")), it
moves by that many columns. #cmd("M") before the key goes as far as it can.

*The scale.* #cmd("COLS") puts a line over the data that numbers the columns:
a mark after every fifth column and a digit after every tenth. It moves with
the text when you move the columns. #cmd("RESET") takes it away. It stays only
while the output or the log it was shown on stays open. Use it together with
#cmd("FIND") and its columns: put the scale up, read the column of the field
you want, and give that number to #cmd("FIND"). The Reference, section “COLS and RESET”, has the
two commands.

*Hexadecimal display.* #cmd("SET HEX ON") shows each line also in
hexadecimal. A line then takes four rows:

+ the text of the line,
+ under it, the first digit of each byte,
+ then the second digit of each byte,
+ and a line of dashes.

Read the two rows of digits down, byte by byte: the upper digit and the lower
one make the byte. That is how you tell a blank from another byte that looks
like one, or find a character that does not print. #cmd("SET HEX OFF") turns
it off, and #cmd("SET HEX") alone is the same as #cmd("SET HEX ON"). SDSF does
not keep the setting, so each session starts with it off. The command is
accepted on all panels but shows hexadecimal on the log and on the Output Data
Set panel only (Reference, section “SET”).

== Finding Out Who and Where You Are <ug-search-who>

#idx("WHO command")
#idx("title line")
#idx("SYSID command")
A command and the title line tell you who you are and where.

*Who.* #cmd("WHO") shows your user id, your logon procedure and your terminal,
as #cmd("USER-ID="), #cmd("LOGON-PROC=") and #cmd("TERMINAL-NAME="), in a line
over the headings of the panel. The line stays until the next Enter. #cmd("WHO")
takes no operand and works on every panel but the primary option menu, where it
does nothing. Use it to see which user id your access to jobs and to the log is
judged under (@ug-access).

*Where.* The title line of each panel says what you are looking at:

#deflist(width: 1.7in,
  [a list panel], [Its name, such as #cmd("SDSF STATUS DISPLAY") with the
    classes.],
  [Job Data Set panel], [#cmd("SDSF JOB DATA SET DISPLAY -") and the type,
    the name and the job number of the job.],
  [Output Data Set panel], [The job, the data set at the top
    (#cmd("DSID") and its number), the line at the top within the data
    set, and the columns on view.],
  [the log], [#cmd("SDSF SYSLOG"), the system, the date, the line at the top
    and the columns on view.],
)

A message appears on the same line, on the right. The Reference, Chapter 2, “Panels”, has the
title of each panel.

*Which system.* The log is the log of your own system unless you have chosen
another with #cmd("SYSID") (Reference, section “SYSID”). If the log is empty and the message
is #cmd("NO SYSLOG FOUND"), look at the title line: a #cmd("SYSID") that you
gave earlier may still be set. #cmd("SYSID") with the id of your own system
shows your log again.

== Retrieving Commands <ug-search-retrieve>

#idx("RETRIEVE command")
#idx("Retrieve key")
#idx("commands", "retrieving")
You often repeat a command with a small change: another string for
#cmd("FIND"), another line for #cmd("LOCATE"). The Retrieve key (PF12) puts the
command you typed before back on the command line, where you can change it and
press Enter. Each further press goes one command further back. SDSF keeps the
last 10 commands; after the oldest, the next press shows the newest again.

For example, after #cmd("SET HEX ON") and then #cmd("SET HEX OFF"), the first
press of PF12 puts #cmd("SET HEX OFF") on the command line, and the second
#cmd("SET HEX ON"). The word #cmd("RETRIEVE") typed on the command line does
the same as the key.

Not every command is kept. These are not: the scroll commands (#cmd("UP"),
#cmd("DOWN"), #cmd("LEFT"), #cmd("RIGHT"), #cmd("TOP"), #cmd("BOTTOM")),
#cmd("WHO"), #cmd("HELP"), #cmd("TUTOR"), #cmd("RETRIEVE") itself, and a
command that stayed on the command line with an error message. So scrolling
does not push the #cmd("FIND") you want to repeat out of the 10. If something
is already typed on the command line, PF12 does nothing and the text runs as
the command, so clear the line first. Appendix A of the Reference, “PF Key Assignments”, has the details.

#note[A user may have moved #cmd("RETRIEVE") to another key. The command is
what counts; PF12 is the default of ISPF (Appendix A of the Reference).]

== Moving Between the Data Sets of a Job <ug-search-datasets>

#idx("data sets", "moving between")
#idx("NEXT command")
#idx("PREV command")
The output of a job is more than one data set: the job log, the JCL, the
system messages, and what each step wrote. There are two ways to see them.

*One after the other.* Type #cmd("S") in the NP column of the job on the
Status panel (or on the DA, Input Queue, Output Queue or Held Output panel).
The Output Data Set panel then shows all data sets of the job, one after the
other, as one long output. #cmd("TOP OF DATA") stands at the start and
#cmd("BOTTOM OF DATA") at the end, once each. The #cmd("DSID") in the title
line is the data set at the top of the screen; it changes as you scroll.

*One at a time.* Type #cmd("?") in the NP column of the job to get the Job Data
Set panel, the list of its data sets, and #cmd("S") on one of them. The Output
Data Set panel then shows that data set only. The End key (PF3) goes back to the
list, and #cmd("S") on another one shows that.

*Jumping by data set.* On the Output Data Set panel of a whole job,
#cmd("NEXT") (or #cmd("N")) goes to the start of the next data set and
#cmd("PREV") (or #cmd("P")) to the start of the one before. A number after the
word moves that many: #cmd("NEXT 3"). #cmd("NEXT 0") goes to the start of the
data set you are in. Past the last data set, #cmd("NEXT") puts the last line of
the output at the top; past the first, #cmd("PREV") goes to the top of the
output.

With the commands of this chapter, this is how to read a long job quickly:

+ #cmd("S") on the job, then #cmd("F ABEND") to see whether the output holds a
  failure.
+ #cmd("NEXT") to the data set you want, and #cmd("LOCATE 100") to go to
  line 100 of it. The number counts from the start of that data set.
+ #cmd("F SYSPRINT PREV") to look back, and the Repeat-FIND key (PF5) to go
  on.
+ The End key (PF3) back to the Status panel.

#cmd("FIND") looks through all data sets of the display, not only the one at
the top, and #cmd("LOCATE") counts in the one at the top. #cmd("NEXT") and
#cmd("PREV") work only on the output of a job; on the log they do nothing and
say nothing. The Reference describes the two commands in the section “NEXT and PREV”,
and the two panels in Chapter 2, “Panels”, in the sections “Output Data Set”
and “Job Data Set”.
