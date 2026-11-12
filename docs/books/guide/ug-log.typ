#import "../bookmaster/bookmaster.typ": *

= The System Log and Operator Work <ug-log>

The operator's console is not on your screen, but SDSF lets you reach it: you
can read what the system has said, see which messages wait for an answer, give
the system a command, and run a TSO command, all from the command line of any
SDSF panel. This chapter shows how. The commands and the messages are
described in full in the _SDSF Reference_, in the chapters "Commands" and
"Messages". Who is allowed to do these things is the subject of @ug-access and
of the chapter "Authorization" in the Reference; this chapter says only where
an answer such as #cmd("NOT AUTHORIZED FOR CMD") comes from.

== The System Log <ug-log-log>

#idx("system log")
#idx("LOG command")
The system log lists the messages of the system and the commands that were
given to it, the oldest first.

*Show the log.* Type #cmd("LOG") on the command line of any SDSF panel and
press Enter. The title line reads #cmd("SDSF SYSLOG"), followed by the system,
the date, #cmd("LINE") with the number of the line at the top, and
#cmd("COLUMNS") with the first and the last column shown. The log opens at its
end: the newest lines are on the screen, and the last one is followed by
#cmd("BOTTOM OF DATA"). You need read access to #cmd("SDSF.OPER")\; without
it SDSF answers #cmd("COMMAND NOT AUTHORIZED") and does not show the log.

*What the log holds.* SDSF reads the lines from the master trace table, the
part of the log that the system keeps in storage. It is not the whole history
of the system: when new lines come, the oldest ones drop out. A message older
than the table reaches is not there to be found.

=== Reading the Log <ug-log-read>

#deflist(width: 2.1in,
  [Up key (PF7), Down key (PF8)], [Scroll up and down by the amount in the
    SCROLL field.],
  [#cmd("TOP"), #cmd("BOTTOM")], [The first and the last line.],
  [#cmd("LOCATE 120")], [Line 120 goes to the top. #cmd("LOCATE 0") goes to the
    first line.],
  [#cmd("LOCATE 14.30.00")], [The first line of that time or later goes to the
    top. The time is written #cmd("hh.mm.ss").],
  [#cmd("FIND string")], [Looks for the text, as it does in output
    (@ug-search).],
  [Left key (PF10), Right key (PF11)], [Show the columns to the left and to
    the right. A line of the log is cut off at column 255.],
)

To bring in the lines that have come since you opened the log, press Enter
with nothing on the command line: SDSF reads the log again, and a display that
stood at the end stays at the end. The Down key does the same when the display
is already at the end.

If SDSF cannot read the log, the title line says #cmd("LOG NOT READABLE"): it
could not get the authority it needs. The Reference, under "Messages", says
what to check.

=== Printing the Log <ug-log-print>

#idx("PRINT command")
To keep a part of the log, print it to a SYSOUT data set.

+ Look up the numbers of the first and of the last line you want. The title
  line shows the number of the line at the top.
+ Type #cmd("PRINT 100 250") and press Enter. SDSF opens the SYSOUT data set
  if it is not open yet, and prints the lines from 100 to 250 in pages of 60
  lines. The message gives the number of pages, #cmd("PAGES PRINTED").
+ Type #cmd("PRINT CLOSE") and press Enter. SDSF closes the data set, and the
  system prints it. The message is #cmd("PRINT CLOSED").

Without a class, the print goes with the output of your session. A file that is
still open when you leave SDSF is closed for you. The class, the number of
copies and the forms of the print, and printing to a data set of your own, are
described in the Reference, under "Commands", "PRINT".

*Leaving the log.* The End key (PF3) takes you to the primary option menu. You
can also type the command of another panel, for example #cmd("ST"), and press
Enter.

== Outstanding Replies <ug-log-replies>

#idx("outstanding replies")
#idx("ACTION command")
Some messages of the system wait for an answer: the system or a program asks
the operator something and goes no further until it gets the reply. These are
the outstanding replies. The log shows such a message when it is issued, but
the line scrolls away, and a long log is a poor place to find out what is
still open. SDSF can therefore append the open replies to the end of the log.

=== Showing the Outstanding Replies <ug-log-action>

SDSF does not show them at first. You ask with #cmd("ACTION"), which chooses
the messages by their routing codes, the numbers 1 to 16 that the system gives
each message.

+ Type #cmd("ACTION ALL") and press Enter. All outstanding replies will be
  shown, whatever their routing codes.
+ Type #cmd("LOG") and press Enter. After the last line of the log come the
  replies, the newest first, in white, up to 30 of them. Each begins with its
  routing codes as four hexadecimal digits and goes on with the message as the
  log shows it, with the time and the job that asked.
+ To see which setting is in force, type #cmd("ACTION ?") and press Enter. The
  title line says #cmd("ACTION=ALL"), #cmd("ACTION=OFF") or the list of the
  codes, such as #cmd("ACTION=1,2,3").

You can narrow the choice. #cmd("ACTION 1") shows the replies that are routed
to code 1. The codes you name are added to those already set, so that
#cmd("ACTION 1") followed by #cmd("ACTION 2 3") gives #cmd("ACTION=1,2,3").
#cmd("ACTION MVS") stands for the codes 1 to 12, #cmd("ACTION USER") for 13 to
16, and #cmd("ACTION OFF") takes all of them away again; #cmd("OFF") must
stand alone. A reply whose message has no routing code is shown with every
setting except #cmd("OFF").

SDSF keeps the setting in your profile, so the replies are still shown, or
still hidden, the next time you start SDSF. If you do not want them, give
#cmd("ACTION OFF"). When you give #cmd("ACTION") on the log, the replies
change at once.

*When a reply you expect is not there.* Look at the setting with
#cmd("ACTION ?"): it may be #cmd("OFF"), or lack the routing code of that
message. Press Enter on an empty command line to read the log and the replies
again. If the title line says #cmd("REPLIES NOT READABLE"), SDSF could not get
the authority it needs to read them, as with the log itself.

You need read access to #cmd("SDSF.OPER") to see the replies, the same access
as for the log.

=== Answering a Reply <ug-log-answer>

SDSF has no action character for a reply. You answer with the operator command
that gives a reply, typed with a slash on the command line of the log, as the
next section describes.

+ Show the outstanding replies as above, and find the one to answer. The reply
  number is the number after the #cmd("@") sign in the line.
+ Type #cmd("/R nn,answer") on the command line and press Enter. Put the
  reply number in place of #var("nn"), and in place of #var("answer") the text
  that the message asks for. For the reply number 12 and the answer
  #cmd("YES") it is #cmd("/R 12,YES").
+ SDSF answers #cmd("COMMAND ISSUED"). It waits a second and reads the log
  again. The reply is gone from the end of the log, and the command you gave
  is among the lines of the log.

#cmd("COMMAND ISSUED") says that SDSF has given the command, not that the
system took the answer. If the reply is still at the end of the log, press
Enter on an empty command line once more, and read the lines above it for the
message of the system.

Answering needs update access to #cmd("SDSF.OPER"), as every operator command
does.

== Issuing Operator Commands <ug-log-slash>

#idx("operator command")
#idx("/ command")
An operator command is an MVS or a JES2 command, given to the system as from
the master console. SDSF gives it when the command line begins with a slash.

*Give a command.* Type #cmd("/") and the command, with or without a blank
after the slash, and press Enter. Examples are #cmd("/D A,L") and
#cmd("/$DI"). The command works on every panel: the primary option menu, the
lists, the Job Data Set and Output Data Set panels, and the log. The command
line is cleared, and the title line says #cmd("COMMAND ISSUED").

*Read the answer.* The answer of the system to an operator command goes to the
system log. It does not come back to the command line.

+ Type #cmd("LOG") and press Enter.
+ Give the command on the log: type #cmd("/D T") and press Enter. SDSF waits
  one second and reads the log again, so that the answer is, as a rule, on the
  screen at the end of the log.
+ If the answer is not there yet, press Enter on an empty command line to read
  the log again.

If you gave the command on another panel, the answer is in the log all the
same: type #cmd("LOG") and look at its end.

#cmd("COMMAND ISSUED") tells that SDSF gave the command. It does not tell that
the system accepted it: a command that the system refuses also gets
#cmd("COMMAND ISSUED"), and the refusal is in the log. Look there when the
effect you expected does not show.

*A slash with nothing after it.* The message is #cmd("NO COMMAND PROVIDED").
The slash stays on the command line, and the cursor stands right behind it.
Type the command after it, or clear the line. Take care that the slash does not
stay in front of the next thing you type: it would be given to the system as an
operator command and not read as an SDSF command.

*When the command is refused.*

#deflist(width: 2.2in,
  [#cmd("NOT AUTHORIZED FOR CMD")], [You have no update access to
    #cmd("SDSF.OPER"), and SDSF has not given the command. The system
    programmer can give you the access (@ug-access).],
  [#cmd("COMMAND NOT AUTHORIZED")], [SDSF could not get the authority it needs
    to give the command. This is a matter of the installation of SDSF; the
    Reference, under "Messages", says what to check.],
)

SDSF does not look at the text of the command. A user with update access to
#cmd("SDSF.OPER") can give any operator command; the access is the whole of the
protection, which is why it is given with care (@ug-access). The command line
holds 60 characters, of which an 80-column screen shows 42.

The same message, #cmd("COMMAND ISSUED"), follows an action character or an
overtyped field that makes SDSF give a JES2 command, for example to cancel or
to hold a job; the answer to these is also in the log. The action characters
are the subject of the chapters on the lists, and the Reference lists them all.

== Issuing TSO Commands <ug-log-tso>

#idx("TSO command")
Where an operator command goes to the system, a TSO command runs in your own
session. SDSF hands it to ISPF, which runs it as a TSO command, a CLIST or a
program.

*Run a command.* Type #cmd("TSO") and the command, for example
#cmd("TSO TIME"), and press Enter. The screen becomes that of the command, in
line mode: what the command writes appears as lines. When the command is done,
press Enter. SDSF shows the panel you came from again, with the command line
cleared. The command works on every panel.

#deflist(width: 1.6in,
  [#cmd("TSO TIME")], [The output of the TSO command #cmd("TIME"), with the
    line #cmd("TIME-").],
  [#cmd("TSO XYZZY")], [The command is not found. TSO says
    #cmd("COMMAND XYZZY NOT FOUND") in the line-mode output.],
  [#cmd("TSO")], [With no command: #cmd("COMMAND PARM IS MISSING"), and the
    command line is cleared. Type #cmd("TSO") and a command.],
)

*TSO or slash.* The two commands look alike and are not. Choose by where the
command is to run:

#tab(caption: [A TSO command and an operator command])[
  #table(columns: (1.1in, 1fr, 1fr),
    [], [#cmd("TSO") and a command], [#cmd("/") and a command],
    [Runs], [in your TSO session], [in the system, as from the master
      console],
    [Commands], [TSO commands, CLISTs and programs], [MVS and JES2 commands],
    [The answer], [on the screen, in line mode], [in the system log],
    [Needs], [nothing that SDSF asks for], [update access to
      #cmd("SDSF.OPER")],
    [Message], [none; the panel comes back], [#cmd("COMMAND ISSUED")],
  )
]

SDSF asks RAKF nothing for #cmd("TSO"): what the command may do is decided by
TSO and by the security of your session, as it would be outside SDSF. The
Reference, under "Authorization", lists every check that SDSF makes.

== System and Destination <ug-log-sysdest>

SDSF has two settings that limit what you see by a place: the system, which
chooses the log, and the destination, which chooses the jobs by where their
output goes. They have nothing to do with each other.

=== The System <ug-log-system>

#idx("SYSID command")
#cmd("SYSID") names the system whose log the log panel shows.

SDSF reads the log of its own system only. With the ID of any other system the
log is empty, and the title line says #cmd("NO SYSLOG FOUND"). The command is
for the log; the other panels do not change with it. The setting does not
last: it is gone when you leave SDSF.

*Find the ID of your system.* Show the log. The title line shows the ID of the
system after #cmd("MTT"). Or type #cmd("SYSID ?") and press Enter: SDSF puts
#cmd("SYSID") and the ID of the system on the command line.

*Set a system.* Type #cmd("SYSID") and the ID, up to four characters, and press
Enter. On the log the command takes effect at once. For an ID that is not your
system's, the title line shows #cmd("0.000") where it had #cmd("MTT"), the ID
you gave, and #cmd("NO SYSLOG FOUND"), and the log is empty. To get your own
log back, type #cmd("SYSID") and the ID of your own system.

An ID of more than four characters gets #cmd("PARM INVALID"), none gets
#cmd("TOO FEW PARMS"), and two get #cmd("TOO MANY PARMS"). The command line
keeps what you typed, so that you can correct it.

=== The Destination <ug-log-dest>

#idx("DEST command")
#idx("destination")
The destination of a job is where its output goes: #cmd("LOCAL") for the local
destination, or a remote or a user destination. The Status, Output Queue and
Held Output panels show it in the #cmd("DEST") column. The #cmd("DEST")
command limits the Status, Input Queue, Output Queue and Held Output panels to
the jobs whose output goes to the destinations you name, by the destination of
the job as the Status panel shows it. The Reference, under "Commands", has the
rules.

#deflist(width: 1.6in,
  [#cmd("DEST LOCAL")], [Only the jobs whose output goes to the local
    destination.],
  [#cmd("DEST R7")], [Only the jobs for remote 7. #cmd("RM7") and #cmd("RMT7")
    mean the same.],
  [#cmd("DEST U12")], [Only the jobs for the user destination 12.],
  [#cmd("DEST LOCAL R7")], [The jobs of both. You may name up to four
    destinations.],
  [#cmd("DEST ?")], [Puts the setting on the command line, so that you can read
    it.],
  [#cmd("DEST")], [Takes the limit away: all destinations again.],
)

A name that is not a destination gets #cmd("INVALID DESTINATION NAME"), and
the cursor stands on it. SDSF keeps the destination in your profile, as it
keeps the prefix, so it is still in force the next time you start SDSF. A
destination you forgot is a common reason for a list that lacks jobs you know
exist: when a list is shorter than you expect, type #cmd("DEST ?") and
#cmd("PREFIX ?"), and take away what is not needed (@ug-jobs).

The command only limits the lists. To change where the output of a job goes,
overtype the #cmd("DEST") field in the row of the job. @ug-jobs and
@ug-queues say how, and the Reference, under "Panels", has the rules for each
panel.
