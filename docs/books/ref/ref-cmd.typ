#import "../bookmaster/bookmaster.typ": *

// A syntax block: upper case is typed as shown, lower case is a value.
#let fmt(src) = block(width: 100%, inset: (x: 10pt, y: 8pt), stroke: 0.6pt,
  breakable: false, code(src, size: 9pt))

= Commands <ref-cmd>

#idx("commands")
This chapter describes every SDSF command: its syntax, its operands, the
defaults, and the panels where it works. A command is what you type on the
command line, the field after #cmd("COMMAND INPUT ===>"). The characters you
type in the NP column of a row are action characters, not commands; they are
the subject of @ref-actions. The keys that stand for commands are in
@apx-pfkeys. The messages that the commands produce are quoted in this
chapter as they appear on the screen; @ref-messages lists them all.

@ref-cmd-all is the summary. Each command has a section of its own further
on.

#tab(caption: [SDSF commands])[
  #table(columns: (1.25in, 1fr, 1.55in),
    [Command], [What it does], [Section],
    [#cmd("/")], [Gives an operator command.], [@ref-cmd-slash],
    [#cmd("TSO")], [Runs a TSO command.], [@ref-cmd-tso],
    [#cmd("HELP")], [Shows the help of the panel.], [@ref-cmd-help],
    [#cmd("TUTOR")], [Starts the tutorial.], [@ref-cmd-help],
    [#cmd("END")], [Goes back one level, or leaves SDSF.], [@ref-cmd-end],
    [#cmd("RETRIEVE")], [Puts a command you gave earlier back on the command
      line.], [@ref-cmd-retrieve],
    [#cmd("WHO")], [Shows your user id, logon procedure and terminal.],
      [@ref-cmd-who],
    [#cmd("PRINT")], [Prints the log or the output of a job.],
      [@ref-cmd-print],
    [#cmd("ST")], [Shows the Status panel.], [@ref-cmd-st],
    [#cmd("DA")], [Shows the DA panel.], [@ref-cmd-da],
    [#cmd("I")], [Shows the Input Queue panel.], [@ref-cmd-i],
    [#cmd("O")], [Shows the Output Queue panel.], [@ref-cmd-o],
    [#cmd("H")], [Shows the Held Output panel.], [@ref-cmd-h],
    [#cmd("PR")], [Shows the Printer panel.], [@ref-cmd-pr],
    [#cmd("INIT")], [Shows the Initiator panel.], [@ref-cmd-init],
    [#cmd("LOG")], [Shows the system log.], [@ref-cmd-log],
    [#cmd("?")], [Shows further fields on the lists.], [@ref-cmd-qm],
    [#cmd("FIND")], [Searches for a string.], [@ref-cmd-find],
    [#cmd("NEXT"), #cmd("PREV")], [Go to a data set of the output of a job.],
      [@ref-cmd-next],
    [#cmd("LOCATE")], [Puts a given line or time at the top.],
      [@ref-cmd-locate],
    [#cmd("TOP"), #cmd("BOTTOM")], [Go to the first or the last line.],
      [@ref-cmd-top],
    [#cmd("UP"), #cmd("DOWN")], [Scroll up or down.], [@ref-cmd-updown],
    [#cmd("LEFT"), #cmd("RIGHT")], [Scroll to the left or to the right.],
      [@ref-cmd-leftright],
    [#cmd("COLS"), #cmd("RESET")], [Show and take away the column scale.],
      [@ref-cmd-cols],
    [#cmd("ACTION")], [Chooses the outstanding replies to show on the log.],
      [@ref-cmd-action],
    [#cmd("PREFIX")], [Limits the lists to jobs whose names match.],
      [@ref-cmd-prefix],
    [#cmd("DEST")], [Limits the lists to destinations.], [@ref-cmd-dest],
    [#cmd("INPUT")], [Adds the input of a job to its data sets.],
      [@ref-cmd-input],
    [#cmd("SET")], [Shows the log and the output also in hexadecimal.],
      [@ref-cmd-set],
    [#cmd("FINDLIM")], [Sets how many lines one #cmd("FIND") looks at.],
      [@ref-cmd-findlim],
    [#cmd("SYSID")], [Chooses the system whose log to show.],
      [@ref-cmd-sysid],
  )
] <ref-cmd-all>

== Syntax Conventions <ref-cmd-syntax>

#idx("commands", "syntax")
The syntax of a command is shown in a block like this one:

#fmt("FIND [string] [NEXT|PREV|FIRST|LAST|ALL] [CHARS|WORD|PREFIX|SUFFIX]
     [col1 [col2]]")

#deflist(width: 1.35in,
  [UPPER CASE], [A word in upper case is typed as shown. Type commands in
    upper case.],
  [lower case], [A word in lower case stands for a value that you supply.],
  [#cmd("[ ]")], [The brackets enclose what you may leave out. A value you
    leave out takes the default that the text names.],
  [#cmd("|")], [Separates the words from which you choose one.],
  [#cmd("...")], [The item before it may be repeated.],
)

=== The Command Line <ref-cmd-line>

The command line holds 60 characters. On an 80-column screen the field shows
fewer of them (42, as the help says). A command is a series of words separated
by blanks. The first word is the command. SDSF has no shortened forms of the
command names beyond those named in this chapter: #cmd("F") for
#cmd("FIND"), #cmd("L") for #cmd("LOCATE"), #cmd("N") and #cmd("P") for
#cmd("NEXT") and #cmd("PREV"), #cmd("PRE") for #cmd("PREFIX"), and
#cmd("BOT") for #cmd("BOTTOM").

The commands that show a list (#cmd("ST"), #cmd("I"), #cmd("O") and
#cmd("H")) take their classes right behind the letters, without a blank:
#cmd("IA"), #cmd("OZ"). For these commands, a first word of more than eight
characters is not read as one of them, and SDSF answers
#cmd("INVALID COMMAND").

Some messages of SDSF begin with a blank, for example #cmd("TOO MANY PARMS")
and #cmd("PARM INVALID"). This chapter leaves the blank out; it is not a
part of the text that matters.

As a rule, a command that is wrong stays on the command line, so that you can
correct it, and a command that is right clears the line. A few refusals clear
the line as well: #cmd("TSO") alone, #cmd("LOG") without authority, and
#cmd("NOT AVAILABLE YET") on the primary option menu. Where the text says that
the cursor is on a word, the word is the one that SDSF found wrong.

The messages in this chapter are those that the commands give. This list is
not complete: a panel also reports data it cannot read or hold, for example
#cmd("NOT ENOUGH STORAGE"), #cmd("LOG NOT READABLE"),
#cmd("REPLIES NOT READABLE"), #cmd("OUTPUT NOT READABLE") and
#cmd("JES2 NOT READABLE"). @ref-messages has them all.

=== Where a Command Works <ref-cmd-where>

SDSF has no command table. Each panel reads its own commands, and not every
panel reads all of them. @ref-cmd-wheretab says where each command works.
"Lists" are the panels ST, DA, I, O, H, PR and INIT. "Output" is the Output
Data Set panel. A command that a panel does not read gets the message
#cmd("INVALID COMMAND"). That is the answer of the primary option menu to the
commands that scroll and search, since the menu has nothing to scroll.

#tab(caption: [Where a command works])[
  #table(columns: (1.6in, 0.85in, 0.55in, 0.9in, 0.65in, 0.8in),
    align: (left, center, center, center, center, center),
    [Command], [Menu], [Lists], [Job Data Set], [Output], [Log],
    [#cmd("/"), #cmd("TSO")], [yes], [yes], [yes], [yes], [yes],
    [#cmd("HELP"), #cmd("TUTOR")], [yes], [yes], [yes], [yes], [yes],
    [#cmd("END"), #cmd("RETRIEVE")], [yes], [yes], [yes], [yes], [yes],
    [#cmd("WHO")], [no effect], [yes], [yes], [yes], [yes],
    [#cmd("PRINT")], [yes], [yes], [yes], [yes], [yes],
    [#cmd("ST"), #cmd("DA"), #cmd("I"), #cmd("O"), #cmd("H"), #cmd("PR"),
      #cmd("INIT"), #cmd("LOG")], [yes], [yes], [yes], [yes], [yes],
    [#cmd("ACTION"), #cmd("PREFIX"), #cmd("DEST"), #cmd("INPUT"),
      #cmd("SET"), #cmd("FINDLIM"), #cmd("SYSID")], [yes], [yes], [yes],
      [yes], [yes],
    [#cmd("FIND"), #cmd("RFIND")], [no], [yes], [yes], [yes], [yes],
    [#cmd("LOCATE"), #cmd("TOP"), #cmd("BOTTOM"), #cmd("UP"), #cmd("DOWN")],
      [no], [yes], [yes], [yes], [yes],
    [#cmd("LEFT"), #cmd("RIGHT") (typed)], [no], [no], [no], [yes], [yes],
    [#cmd("NEXT"), #cmd("PREV")], [no], [no], [no], [yes], [no effect],
    [#cmd("COLS"), #cmd("RESET")], [no], [no], [no], [yes], [yes],
  )
] <ref-cmd-wheretab>

The table counts what you type. The Left and Right keys also move the columns
on the lists and on the Job Data Set panel (@ref-cmd-leftright), but a typed
#cmd("LEFT") or #cmd("RIGHT") is not read there. The table does not say what a
command does where it is read. The section of the command does; for example,
#cmd("PRINT") on the primary option menu only opens a file
(@ref-cmd-print), and #cmd("LOG") on the log only clears the command line.

=== Keys That Act as Commands <ref-cmd-keys>

Some commands in this chapter also have a key. ISPF owns these keys, and SDSF
reads the command that ISPF gives it: the Up key (#cmd("UP")), the Down key
(#cmd("DOWN")), the Left key (#cmd("LEFT")), the Right key (#cmd("RIGHT")),
#cmd("RFIND") (PF5), #cmd("RETRIEVE") (PF12), the End key (#cmd("END")) and
the Help key (#cmd("HELP")). The keys are the defaults of ISPF; a user may
have moved them. @apx-pfkeys has the table.

== Commands on Every Panel <ref-cmd-every>

#idx("commands", "on every panel")
The commands in this section work on all panels, the primary option menu
included.

=== / <ref-cmd-slash>

#idx("/ command")
#idx("operator command")
#fmt("/ command")

Gives #var("command") to the system as an operator command. The command is
everything that follows the #cmd("/"); it may begin with a blank or follow
the slash at once.

You need update access to #cmd("SDSF.OPER") (@ref-auth). Without it SDSF
answers #cmd("NOT AUTHORIZED FOR CMD"). When SDSF cannot get the authority to
give the command, the answer is #cmd("COMMAND NOT AUTHORIZED"). A command that
the system does not accept still gets #cmd("COMMAND ISSUED"); the answer of
the system is in the log. A #cmd("/") with no command
after it gets #cmd("NO COMMAND PROVIDED"), and the cursor stands right after
the slash. When the command has been given, the message is
#cmd("COMMAND ISSUED").

On the log, SDSF waits one second after #cmd("COMMAND ISSUED") and then reads
the log again, so that the reply to the command is on the screen. The reply
of the system to an operator command goes to the log; to see it, give the
command on the log.

=== TSO <ref-cmd-tso>

#idx("TSO command")
#fmt("TSO command")

Runs #var("command") as a TSO command, CLIST or program, with the ISPF
service #cmd("SELECT"). The output of the command appears in line mode. When
it is done, press Enter to return to the panel, which SDSF then shows again
with the command line cleared.

#cmd("TSO") alone gets #cmd("COMMAND PARM IS MISSING"). A command that TSO
does not find gives TSO's own message in the line-mode output.

Examples:

#deflist(width: 1.35in,
  [#cmd("TSO TIME")], [The output of the TSO #cmd("TIME") command, with the
    line #cmd("TIME-").],
  [#cmd("TSO XYZZY")], [#cmd("COMMAND XYZZY NOT FOUND"), in line mode.],
)

=== HELP and TUTOR <ref-cmd-help>

#idx("help")
#idx("tutorial")
#fmt("HELP
TUTOR")

#cmd("HELP") shows the help of the panel you are on. It is the command that
the Help key (PF1) gives. #cmd("TUTOR") starts the tutorial. Neither takes an
operand: with an operand, SDSF does not read the word as one of these
commands. When the help panels are not installed, the answer is
#cmd("HELP NOT AVAILABLE").

In the help, you move with the words below. The keys that give the same
commands do the same.

#deflist(width: 1.6in,
  [Enter, #cmd("DOWN"), #cmd("RIGHT")], [Show the next panel of the topic. A
    panel that has no next panel goes to the panel that lists the topic.],
  [a number], [Shows the topic with that number.],
  [#cmd("UP")], [Shows the panel that lists the topic.],
  [#cmd("LEFT"), #cmd("BACK")], [Show the panel you saw before.],
  [#cmd("T"), #cmd("TOP")], [Show the contents.],
  [#cmd("I"), #cmd("INDEX")], [Show the index.],
  [#cmd("HELP")], [Shows the help on the help.],
  [#cmd("END"), #cmd("RETURN")], [Leave the help; you are back on the
    panel you came from.],
)

Anything else gives #cmd("INVALID OPTION"); SDSF's own commands do not work in
the help. The help also says #cmd("END OF TOPIC") at the end of a topic,
#cmd("PANEL NOT FOUND") when a panel is missing from the help library, and
#cmd("NO HELP FOR THIS PANEL YET") when there is no help for a panel; you then
see the contents.

=== END <ref-cmd-end>

#idx("END command")
#fmt("END")

Goes back one level. The End key (PF3) gives the command.

#tab(caption: [Where #cmd("END") goes])[
  #table(columns: (2.4in, 1fr),
    [On], [#cmd("END") goes to],
    [the Job Data Set panel, the Output Data Set panel], [the panel you
      came from],
    [a list panel, the log], [the primary option menu],
    [the primary option menu], [out of SDSF],
  )
]

=== RETRIEVE <ref-cmd-retrieve>

#idx("RETRIEVE command")
#fmt("RETRIEVE")

Puts a command that you gave earlier back on the command line, where you can
change it. Each further #cmd("RETRIEVE") goes one command further back; after the
oldest command that SDSF kept, the next one begins again with the newest. SDSF
keeps the last 10 commands. The Retrieve key (PF12) gives the command.

SDSF does not keep the scroll commands (#cmd("UP"), #cmd("DOWN"),
#cmd("TOP"), #cmd("BOTTOM"), #cmd("BOT"), #cmd("LEFT"), #cmd("RIGHT")) or
#cmd("WHO"), and it does not keep a command that stayed on the line with an
error message.

=== WHO <ref-cmd-who>

#idx("WHO command")
#fmt("WHO")

Shows #cmd("USER-ID="), #cmd("LOGON-PROC=") and #cmd("TERMINAL-NAME=") with
their values over the headings of the panel, until the next Enter. #cmd("WHO")
with an operand gets #cmd("TOO MANY PARMS"). On the primary option menu,
#cmd("WHO") does nothing.

=== PRINT <ref-cmd-print>

#idx("PRINT command")
#idx("printing")
#fmt("PRINT OPEN [class] [copies] [forms]
PRINT ODSN dsname [volser|*] [OLD|SHR|MOD]
PRINT CLOSE
PRINT [first last]")

Prints the log or the output of a job to a SYSOUT data set or to a data set of
your own. The first three forms open and close the file that takes the print;
the last one prints.

#cmd("PRINT OPEN") opens a SYSOUT data set.

#deflist(width: 1.1in,
  [#var("class")], [The output class, one alphanumeric character.],
  [#var("copies")], [The number of copies, 1 to 255.],
  [#var("forms")], [The forms name, up to 4 characters.],
)

Without a class, the print goes with the output of your session. The message
is #cmd("PRINT OPENED"). When a file is open already, the answer is
#cmd("PRINT ALREADY OPEN"); when SDSF cannot open the file,
#cmd("PRINT OPEN ERROR"). A class, a number of copies or a forms name that is
wrong gets #cmd("PARM INVALID"), and a word after the forms name
#cmd("TOO MANY PARMS").

#cmd("PRINT ODSN") opens a data set of your own instead: a cataloged one, or
the one on #var("volser").

#deflist(width: 1.1in,
  [#var("dsname")], [The data set name as you type it; SDSF adds no prefix.
    Quotes around it are removed. It has up to 44 characters.],
  [#var("volser")], [The volume, up to 6 characters. #cmd("*") or no
    volume lets the system find the data set.],
  [#cmd("OLD"), #cmd("SHR"), #cmd("MOD")], [The disposition. The default is
    #cmd("OLD"), which writes the data set anew; #cmd("MOD") adds to it.],
)

The messages are those of #cmd("PRINT OPEN"), and more: no data set name gets
#cmd("TOO FEW PARMS"), a word after the disposition #cmd("TOO MANY PARMS"), and a name,
volume or disposition that is wrong #cmd("PARM INVALID").

#cmd("PRINT CLOSE") closes the file; a SYSOUT data set is then printed. The
message is #cmd("PRINT CLOSED"), the number of lines and #cmd("LINE"). When
no file is open the answer is #cmd("PRINT NOT OPENED"); an operand gets
#cmd("TOO MANY PARMS"). A file that is still
open when you leave SDSF is closed for you.

#cmd("PRINT first last") prints the lines from #var("first") to #var("last").
On the log these are the line numbers of the log; on output they are the lines
of the whole output of the job. If no file is open, SDSF opens SYSOUT first.
Both numbers must be digits, otherwise the answer is #cmd("PARM INVALID").
When #var("last") is lower than #var("first"), SDSF prints the line
#var("first") only. One number alone gets #cmd("TOO FEW PARMS"), and three
numbers get #cmd("TOO MANY PARMS"). On a list
panel, #cmd("PRINT 1 2") gets #cmd("PARM INVALID").

#cmd("PRINT") alone, on the Output Data Set panel, prints all of the output.
On any other panel it only opens SYSOUT, as #cmd("PRINT OPEN") does. When a
file is open already, it does nothing and says nothing, where #cmd("PRINT OPEN")
answers #cmd("PRINT ALREADY OPEN"). On the log, #cmd("PRINT first last") also
puts line #var("first") at the top of the screen.

The message after a print is the number of lines and #cmd("LINES PRINTED").
The log is printed in pages of 60 lines under a heading with the system, the
date and the page number, and the message then counts the pages:
#cmd("PAGES PRINTED").

== Commands That Switch Panels <ref-cmd-switch>

#idx("commands", "switching panels")
Each of these commands shows a panel, which replaces the one you are on.
#cmd("END") on it takes you to the primary option menu (@ref-cmd-end).

#tab(caption: [The commands that show a panel])[
  #table(columns: (1.0in, 1fr),
    [Command], [Panel],
    [#cmd("ST")], [the Status panel],
    [#cmd("DA")], [the DA panel],
    [#cmd("I")], [the Input Queue panel],
    [#cmd("O")], [the Output Queue panel],
    [#cmd("H")], [the Held Output panel],
    [#cmd("PR")], [the Printer panel],
    [#cmd("INIT")], [the Initiator panel],
    [#cmd("LOG")], [the system log],
  )
]

What a list shows depends on the parameters of its command and on the
settings of #cmd("PREFIX") (@ref-cmd-prefix) and #cmd("DEST")
(@ref-cmd-dest), which the sections below say panel by panel.

=== ST <ref-cmd-st>

#idx("ST command")
#idx("Status panel")
#fmt("STclasses [name]")

Shows the Status panel.

#deflist(width: 1.35in,
  [#var("classes")], [Up to 6 characters, A to Z and 0 to 9, directly after
    #cmd("ST"). The first word is thus at most 8 characters long. Without
    classes the panel shows all classes, and the title says
    #cmd("SDSF STATUS DISPLAY ALL CLASSES"); with classes, it says
    #cmd("SDSF STATUS DISPLAY CLASS x").],
  [#var("name")], [A job name or a pattern, up to 8 characters. The
    characters #cmd("*") and #cmd("%") are wildcards: #cmd("*") stands for any
    number of characters, #cmd("%") for exactly one, unless #cmd("PREFIX") has
    set other characters (@ref-cmd-prefix). Without a name, all job names.],
)

Classes and name stay as you typed them until the next #cmd("ST"). With
classes, the panel leaves out the print queue, the TSO users and the started
tasks. The name, #cmd("PREFIX") and #cmd("DEST") all apply together: a job
must satisfy each of them to be on the panel.

A name of more than 8 characters gets #cmd("PARM INVALID"), and a third word
gets #cmd("TOO MANY PARMS"). #cmd("ST") on the Output Data Set panel returns
to the Status panel with the message #cmd("DATA SET DISPLAYED").
#cmd("?") alone shows the further fields (@ref-cmd-qm).

Examples:

#deflist(width: 1.35in,
  [#cmd("ST")], [All classes, all job names.],
  [#cmd("ST IBM*")], [The jobs whose names begin with #cmd("IBM").],
  [#cmd("ST %NIT")], [The jobs whose names have four characters and end in
    #cmd("NIT"), such as #cmd("INIT").],
  [#cmd("ST ABCDEFGHI")], [#cmd("PARM INVALID"): the name has 9
    characters.],
)

=== DA <ref-cmd-da>

#idx("DA command")
#idx("DA panel")
#fmt("DA [word ...]")

Shows the DA panel, the address spaces that are active. You may give up to
four words. A word adds a type to the display, limits the display to one
type or position, or leaves one out.

#deflist(width: 1.7in,
  [#cmd("JOB"), #cmd("TSU"), #cmd("STC"), #cmd("INIT")], [The types of
    address space. The default is #cmd("JOB"), #cmd("TSU") and #cmd("STC").],
  [#cmd("IN"), #cmd("OUT"), #cmd("TRANS"), #cmd("READY")], [The positions. The
    default is #cmd("IN") and #cmd("OUT").],
  [#var("type")], [Adds the type to those shown.],
  [#var("position")], [Shows that position only. It replaces the default
    positions: #cmd("DA IN") is the same as #cmd("DA OIN"). Several position
    words add up to each other.],
  [#cmd("O")#var("type") or #cmd("O")#var("position")], [Shows only that type
    or position, for example #cmd("OJOB") or #cmd("OIN"). Only one such word
    is allowed.],
  [#cmd("NO")#var("type") or #cmd("NO")#var("position")], [Leaves that type or
    position out, for example #cmd("NOTSU").],
  [#cmd("ALL"), #cmd("ALLT"), #cmd("ALLP")], [All types and positions; all
    types; all positions. Each stands alone.],
)

The positions that SDSF tells apart on MVS 3.8j are #cmd("IN") and #cmd("OUT").
#cmd("TRANS") and #cmd("READY") are accepted, but they select no address
space: #cmd("DA TRANS") and #cmd("DA READY") show no address space at all.

More than four words get #cmd("TOO MANY PARMS"). A word that DA does not know
gets #cmd("PARM INVALID"), and the cursor stands on it.

#note[#cmd("OUT") is a position, not #cmd("O") and #cmd("UT"): DA reads a word
that begins with #cmd("O") as a limiting word unless it begins with
#cmd("OU").]

An initiator that runs a job shows as that job, not as an initiator.
#cmd("?") alone changes the order of the columns (@ref-cmd-qm).

Examples:

#deflist(width: 1.35in,
  [#cmd("DA OJOB")], [Only batch jobs.],
  [#cmd("DA NOTSU")], [No TSO users.],
  [#cmd("DA OIN")], [Only the address spaces that are in.],
  [#cmd("DA OINIT")], [Only the initiators.],
  [#cmd("DA ALL")], [All types and positions.],
)

=== I <ref-cmd-i>

#idx("I command")
#idx("Input Queue panel")
#fmt("Iclasses [H|NH]")

Shows the Input Queue panel, the jobs that wait to run.

#deflist(width: 1.35in,
  [#var("classes")], [Up to 7 characters directly after #cmd("I"): the job
    classes A to Z and 0 to 9, #cmd("$") for the TSO users and #cmd("#") for
    the started tasks. Without classes the panel shows batch jobs only. The
    title names the classes.],
  [#cmd("H")], [Only the jobs that are held.],
  [#cmd("NH")], [Only the jobs that are not held.],
)

An operand other than #cmd("H") or #cmd("NH") gets #cmd("PARM INVALID"), and
the cursor stands on it. A second operand gets #cmd("TOO MANY PARMS").
#cmd("?") alone shows the further fields (@ref-cmd-qm).

Examples: #cmd("IA") (class A), #cmd("I$") (the TSO users), #cmd("I H") (the
held jobs), #cmd("I NH") (the jobs that are not held).

#note[A blank decides what a letter means. #cmd("IH") shows class H;
#cmd("I H") shows the held jobs. #cmd("I $") is #cmd("PARM INVALID"), because
the classes belong directly after the #cmd("I").]

=== O <ref-cmd-o>

#idx("O command")
#idx("Output Queue panel")
#fmt("Oclasses [forms]")

Shows the Output Queue panel, the output that is waiting to print and is not
held.

#deflist(width: 1.35in,
  [#var("classes")], [Up to 7 characters directly after #cmd("O"): A to Z and
    0 to 9. #cmd("$") and #cmd("#") are not allowed.],
  [#var("forms")], [A forms name of up to 8 characters, or a pattern with the
    wildcards #cmd("*") and #cmd("%") as for #cmd("ST").],
)

SDSF matches the classes and the forms against the first data set of the job
that waits to print. #cmd("PREFIX") and #cmd("DEST") apply as well. A second
operand gets #cmd("TOO MANY PARMS"), and a forms name that is too long
#cmd("PARM INVALID").

=== H <ref-cmd-h>

#idx("H command")
#idx("Held Output panel")
#fmt("Hclasses [ALL|name]")

Shows the Held Output panel, the output that is held.

#deflist(width: 1.35in,
  [#var("classes")], [Up to 7 characters directly after #cmd("H"): A to Z and
    0 to 9.],
  [#cmd("ALL")], [The output of all jobs.],
  [#var("name")], [A job name or a pattern with the wildcards #cmd("*") and
    #cmd("%"), up to 8 characters.],
)

Without #cmd("ALL") or a name, #cmd("H") shows only the output of the jobs
whose names begin with your user id. A #cmd("PREFIX") that you have set takes
the place of that rule. #cmd("DEST") applies, and on this panel it limits by
the destination of the job, the one that ST shows. A second operand gets #cmd("TOO MANY PARMS"),
and a name that is too long #cmd("PARM INVALID"). #cmd("?") alone is accepted
and changes nothing.

=== PR <ref-cmd-pr>

#idx("PR command")
#idx("Printer panel")
#fmt("PR [word ...]")

Shows the Printer panel. You may give up to four words.

#deflist(width: 1.35in,
  [#var("n")], [A printer number.],
  [#var("n")-#var("m")], [The printers from #var("n") to #var("m"). #var("n")
    must not be higher than #var("m"); #cmd("2-1") is refused.],
  [#cmd("LCL")], [The local printers.],
  [#cmd("Rn")], [A remote printer.],
  [#cmd("RMT")], [The remote printers.],
)

SDSF selects the printers by #var("n"), #var("n")-#var("m") and #cmd("LCL").
#cmd("Rn") and #cmd("RMT") are accepted, but they match no printer. #cmd("PR")
does not accept #cmd("RMn"), which #cmd("DEST") does. A word that is none of
these gets #cmd("PARM INVALID"), and the cursor stands on it. Five words get
#cmd("TOO MANY PARMS").

You need read access to #cmd("SDSF.OPER"); without it the answer is
#cmd("COMMAND NOT AUTHORIZED"). #cmd("PREFIX") and #cmd("DEST") do not limit
this panel.

Examples: #cmd("PR 2"), #cmd("PR 1-2"). #cmd("PR 2-1") and #cmd("PR X") get
#cmd("PARM INVALID").

=== INIT <ref-cmd-init>

#idx("INIT command")
#idx("Initiator panel")
#fmt("INIT")

Shows the Initiator panel. #cmd("INIT") has no parameters; a word after it
gets #cmd("TOO MANY PARMS"). As for #cmd("PR"), you need read access to
#cmd("SDSF.OPER"), and #cmd("PREFIX") and #cmd("DEST") do not limit the
panel.

=== LOG <ref-cmd-log>

#idx("LOG command")
#idx("system log")
#fmt("LOG")

Shows the system log. You need read access to #cmd("SDSF.OPER"); without it
the answer is #cmd("COMMAND NOT AUTHORIZED"). #cmd("LOG") takes no operand:
with one, the lists answer #cmd("INVALID COMMAND") and the primary option menu
#cmd("NOT AVAILABLE YET"). On the log itself, #cmd("LOG") only clears the
command line.

The log is the log of the system that #cmd("SYSID") chose (@ref-cmd-sysid).
It ends with the outstanding replies that #cmd("ACTION") asked for
(@ref-cmd-action).

=== ? <ref-cmd-qm>

#idx("? command")
#idx("further fields")
#fmt("?")

A question mark alone on the command line changes the fields that a list
shows, or their order. It is not the #cmd("?") action character, which you
type in the NP column.

#deflist(width: 1.6in,
  [ST], [Toggles between the usual fields and the further fields. The Left and
    Right keys page through the further fields.],
  [I], [Toggles between the usual fields and the further fields.],
  [DA], [Toggles the order of the columns.],
  [H], [Is accepted and changes nothing.],
  [Menu, O, PR, INIT, Job Data Set, Output Data Set, log], [Are not allowed;
    the answer is #cmd("INVALID COMMAND").],
)

=== Enter on an Empty Line <ref-cmd-enter>

Enter with nothing on the command line reads the list again. On the log it
reads the log again, and the display stays at the end of the log if it was at
the end. On the Job Data Set panel and on the Output Data Set panel Enter does
nothing.

== Commands That Search and Scroll <ref-cmd-search>

#idx("commands", "searching")
#idx("commands", "scrolling")
These commands work on every panel that has something to move through: the
lists, the Job Data Set panel, the Output Data Set panel and the log. The
primary option menu does not read them.

=== FIND <ref-cmd-find>

#idx("FIND command")
#idx("searching")
#fmt("FIND [string] [NEXT|PREV|FIRST|LAST|ALL] [CHARS|WORD|PREFIX|SUFFIX]
     [col1 [col2]]")

#cmd("F") is the short form. #cmd("FIND") searches the lines of the panel for a
string. It has up to five words; more get #cmd("TOO MANY PARMS").

The string is the first word. You can give it in several ways:

#deflist(width: 1.7in,
  [text], [The characters up to the next blank. Upper and lower case are
    the same.],
  [#cmd("'text'"), #cmd("\"text\"")], [The characters between the quotes,
    blanks too. The quotes are not part of the string.],
  [#cmd("X'hex'")], [The bytes, two hexadecimal digits for each. Here case
    matters: SDSF finds exactly the bytes you gave.],
  [#cmd("*")], [The string of the last #cmd("FIND").],
  [no string], [#cmd("FIND") again, in the direction, the kind and the
    columns of the last one.],
)

The direction says where the search starts and where it goes. A new string is
searched forward.

#deflist(width: 1.7in,
  [#cmd("NEXT")], [Forward from the top line of the panel. After a hit, the
    search goes on right behind that hit.],
  [#cmd("PREV")], [Backward from the line before the top line.],
  [#cmd("FIRST")], [Forward from the beginning of the data.],
  [#cmd("LAST")], [Backward from the end of the data.],
  [#cmd("ALL")], [Counts the hits in all of the data, and goes to the
    first.],
)

The kind says what counts as a hit. The default is #cmd("CHARS").

#deflist(width: 1.7in,
  [#cmd("CHARS")], [The string anywhere.],
  [#cmd("WORD")], [The string as a word of its own. Letters, digits and the
    national characters #cmd("$"), #cmd("#") and #cmd("@") are the characters
    of a word.],
  [#cmd("PREFIX")], [The string at the beginning of a word. #cmd("PRE") is
    the same.],
  [#cmd("SUFFIX")], [The string at the end of a word. #cmd("SUF") is the
    same.],
)

#note[SDSF also accepts #cmd("CHAR") for #cmd("CHARS"). The help does not
name it.]

The columns are one or two numbers of up to three digits each. A number above
the last column gets #cmd("INVALID LEFT BOUNDARY") or
#cmd("INVALID RIGHT BOUNDARY"). The last column is 255 on the log, 256 on the
output of a job and 254 on the lists and the Job Data Set panel. The
order of the two does not matter. With one column, the hit must begin there;
with two, it must lie between them. A string that is longer than the two
columns allow gets #cmd("INCONSISTENT PARAMETERS").

When SDSF finds the string, the line with the hit goes to the top of the panel
and the cursor goes to the hit. The message says what was found:

#deflist(width: 1.9in,
  [#cmd("CHARS 'x' FOUND")], [#cmd("WORD"), #cmd("PREFIX") and #cmd("SUFFIX")
    take the place of #cmd("CHARS") for those kinds. After
    #cmd("ALL"), the number of hits stands in front of the kind, in 7
    columns.],
  [#cmd("NO CHARS  'x' FOUND")], [The string is nowhere in the data. SDSF says
    so at once when the search began at the beginning of the data, or, backward,
    at its end.],
  [#cmd("*BOTTOM OF DATA REACHED*")], [The search began at the top line of the
    screen and ran to the end without a hit. The next #cmd("FIND") starts at
    the beginning, and only that one says that the string is nowhere. It does
    so only while the screen is as the message left it.],
  [#cmd("* TOP OF DATA REACHED *")], [The same, backward.],
  [#cmd("*FINDLIM REACHED*")], [The search looked at as many lines as
    #cmd("FINDLIM") allows and stopped (@ref-cmd-findlim). The next
    #cmd("FIND") goes on from there.],
)

On the log and on the output of a job, a #cmd("FIND") or #cmd("RFIND") that
starts from the previous hit and finds nothing further leaves the screen, the
cursor and the message of that hit as they were. You do not get
#cmd("*BOTTOM OF DATA REACHED*") then; you get it only when the search began
at the top line of the screen.

A mistake in the command gives one of these messages instead:

#deflist(width: 1.9in,
  [#cmd("INCONSISTENT PARAMETERS")], [Two directions, two kinds, or a string
    that does not fit the columns.],
  [#cmd("INVALID HEX STRING")], [The string of an #cmd("X'...'") is not
    hexadecimal; the cursor is on it.],
  [#cmd("INVALID SYNTAX")], [Anything else wrong with the command.],
)

SDSF keeps the last string in the profile (@ref-cmd-profile-kept), up to 57
characters of it.

On the Output Data Set panel and on the log, #cmd("FIND") looks in the text of
the lines. #cmd("FINDLIM") limits the number of lines that one #cmd("FIND")
looks at. On the lists and on the Job Data Set panel, #cmd("FIND") looks
through the rows as you see them, always as #cmd("CHARS"). The kind and the
columns are accepted there and have no effect. When the cursor is on a row, the
search begins at the row after it, not at the top row. A hit puts the cursor at
the beginning of its row, not on the string, and the number of hits after
#cmd("ALL") stands in front of the message without the field of 7 columns.

#cmd("RFIND") repeats the last #cmd("FIND"). The PF5 key gives it. If you have
typed something on the command line, PF5 runs that command instead; for
#cmd("ABC") the answer is #cmd("INVALID COMMAND").

Examples:

#deflist(width: 1.7in,
  [#cmd("F INIT ALL")], [Counts the lines with #cmd("INIT") and goes to the
    first.],
  [#cmd("F INIT PREV")], [The last hit of #cmd("INIT") before the top line.],
)

=== NEXT and PREV <ref-cmd-next>

#idx("NEXT command")
#idx("PREV command")
#fmt("NEXT [n]
PREV [n]")

#cmd("N") and #cmd("P") are the short forms. On the Output Data Set panel of a
job, #cmd("NEXT") goes to a later data set of the output, and #cmd("PREV") to
an earlier one.

#deflist(width: 1.35in,
  [#var("n")], [The number of data sets to move. The default is 1.
    #cmd("NEXT 0") goes to the start of the data set that you are in.],
)

When no data set is left forward, the last line of the output goes to the top.
When none is left back, the top of the output goes to the top. An operand that
is not a number gets #cmd("PARM INVALID"), and the cursor stands on it.

The commands work only on the output of a job. On the log they do nothing and
say nothing.

=== LOCATE <ref-cmd-locate>

#idx("LOCATE command")
#fmt("LOCATE n
LOCATE hh.mm.ss")

#cmd("L") is the short form. #cmd("LOCATE") puts the line you name at the top.

#deflist(width: 1.35in,
  [#var("n")], [A line number. On the Output Data Set panel, SDSF counts the
    lines in the data set you are in. On the log and on the lists, it counts
    the rows from the first. #cmd("LOCATE 0") goes to the first line.],
  [#var("hh.mm.ss")], [On the log only: the first line with that time or a
    later one.],
)

A #cmd("LOCATE") with no operand gets #cmd("TOO FEW PARMS"), and with two,
#cmd("TOO MANY PARMS"). Any other operand gets #cmd("PARM INVALID").

Examples: #cmd("LOCATE 5") puts line 5 at the top; #cmd("L 0") goes to the
top; #cmd("LOCATE ABC") gets #cmd("PARM INVALID"); #cmd("L 5 6") gets
#cmd("TOO MANY PARMS").

=== TOP and BOTTOM <ref-cmd-top>

#idx("TOP command")
#idx("BOTTOM command")
#fmt("TOP
BOTTOM")

#cmd("TOP") shows the first page. #cmd("BOTTOM") shows the last page;
#cmd("BOT") is the short form.

=== UP and DOWN <ref-cmd-updown>

#idx("UP command")
#idx("DOWN command")
#idx("scroll amount")
#fmt("UP [PAGE|HALF|DATA|CSR|n|MAX]
DOWN [PAGE|HALF|DATA|CSR|n|MAX]")

Scrolls up or down by an amount. The Up key (PF7) and the Down key (PF8) give
these commands.

#deflist(width: 1.35in,
  [#cmd("PAGE")], [As many lines as the panel shows.],
  [#cmd("HALF")], [Half of them.],
  [#cmd("DATA")], [One line fewer than the panel shows, so that one line of the
    old page stays.],
  [#cmd("CSR")], [As many lines as there are above the cursor, so that the
    line under the cursor goes to the top. When the cursor is not on the data,
    a page.],
  [#var("n")], [A number of up to 4 digits: that many lines.],
  [#cmd("MAX")], [To the first line (#cmd("UP")) or the last (#cmd("DOWN")).],
)

Without an operand, the amount is the one in the SCROLL field. The default is
#cmd("PAGE"). SDSF keeps the amount in the profile
(@ref-cmd-profile-kept). The SCROLL field takes #cmd("PAGE"), #cmd("HALF"),
#cmd("DATA"), #cmd("CSR") or a number of 1 to 4 digits. #cmd("MAX") in the
field raises no message, and the last amount comes back. An amount that is
none of these gets #cmd("INVALID SCROLL AMOUNT"). On the log, the Down key (PF8) at
the end reads the log again; a typed #cmd("DOWN") does not.

*A word before a scroll key.* When you type #cmd("M"), #cmd("P"),
#cmd("H"), #cmd("D"), #cmd("C"), #cmd("MAX") or a number on the command line
and then press a scroll key, the word is the amount for that one scroll, and
the key uses it up. For example, #cmd("M") and PF8 go to the bottom;
#cmd("MAX") and PF7 go to the top; #cmd("2") and PF8 scroll 2 lines. Another
word, such as #cmd("XY"), gets #cmd("INVALID SCROLL AMOUNT"). The commands
#cmd("UP") and #cmd("DOWN") themselves take the full words only.

=== LEFT and RIGHT <ref-cmd-leftright>

#idx("LEFT command")
#idx("RIGHT command")
#fmt("LEFT [PAGE|HALF|DATA|CSR|n|MAX]
RIGHT [PAGE|HALF|DATA|CSR|n|MAX]")

Scrolls to the left or to the right. The Left key (PF10) and the Right key
(PF11) give these commands. What moves depends on the panel.

#deflist(width: 1.7in,
  [Output Data Set panel, log], [The text of the lines. The title shows the
    columns on view (#cmd("COLUMNS")), up to column 255. #cmd("MAX") or
    #cmd("M") goes as far as it can.],
  [Job Data Set panel], [The columns after #cmd("DDNAME").],
  [ST], [The further fields, when you have asked for them with #cmd("?").],
  [I, O, H, PR, INIT], [The pages of columns.],
  [DA], [One step to the right part of the columns, and one back.],
)

On the lists and on the Job Data Set panel, only the keys move the columns. A
typed #cmd("LEFT") or #cmd("RIGHT") is read only on the Output Data Set panel
and on the log; on the other panels it gets #cmd("INVALID COMMAND"). The
primary option menu does not read these commands at all.

On the Output Data Set panel and on the log you may type an amount after the
word, as for #cmd("UP") and #cmd("DOWN"), for example #cmd("RIGHT 10"). A
second operand gets #cmd("TOO MANY PARMS") and an amount that is not valid
#cmd("INVALID SCROLL AMOUNT"). On the Job Data Set panel the keys read the
amount as well (@ref-cmd-updown). On ST, DA and the lists of I, O, H, PR and
INIT, the keys ignore an amount on the command line and clear it.

=== COLS and RESET <ref-cmd-cols>

#idx("COLS command")
#idx("RESET command")
#fmt("COLS
RESET")

On the Output Data Set panel and on the log, #cmd("COLS") shows a scale line
with the column numbers, and #cmd("RESET") takes it away. Neither takes an
operand. With one, SDSF does not read the word as one of these commands, and
the usual answer is #cmd("INVALID COMMAND").

== Commands That Set the Profile <ref-cmd-profile>

#idx("profile")
#idx("commands", "profile")
These commands set how SDSF selects and shows. They work on every panel, the
primary option menu included, and each applies at once to the panel you are
on and to the panels you show next.

Some of the settings SDSF keeps for your next session; the others last until
you leave SDSF. @ref-cmd-profile-kept says which.

#tab(caption: [What SDSF keeps in your profile])[
  #table(columns: (3.2in, 1fr),
    [Setting], [Kept],
    [#cmd("ACTION")], [yes],
    [#cmd("PREFIX")], [yes],
    [#cmd("DEST")], [yes],
    [the SCROLL amount], [yes],
    [the last #cmd("FIND") string], [yes],
    [#cmd("FINDLIM"), #cmd("SYSID"), #cmd("INPUT"), #cmd("SET HEX"),
      #cmd("COLS")], [no],
  )
] <ref-cmd-profile-kept>

=== ACTION <ref-cmd-action>

#idx("ACTION command")
#idx("outstanding replies")
#fmt("ACTION [code ...]
ACTION ?
ACTION OFF")

Chooses which outstanding replies SDSF shows on the log. An outstanding reply
is a message of the system that waits for an answer. The replies follow the
last line of the log, newest first, in high intensity. Each shows its routing
codes as four hexadecimal digits, and then the time, the job and the message,
as on the log. SDSF shows up to 30. A reply without a routing code is shown
unless the setting is #cmd("OFF"). #cmd("ACTION") with no operand changes
nothing and says nothing.

You may give up to four words; a fifth gets #cmd("TOO MANY PARMS").
#cmd("ACTION ?") with other words gets #cmd("INVALID SYNTAX").

#deflist(width: 1.35in,
  [#cmd("1") to #cmd("16")], [A routing code. The code is added to those
    already set.],
  [#cmd("MVS")], [The codes 1 to 12.],
  [#cmd("USER")], [The codes 13 to 16.],
  [#cmd("ALL")], [All codes.],
  [#cmd("OFF")], [No outstanding replies. #cmd("OFF") stands alone; with other
    words it gets #cmd("PARM INVALID").],
  [#cmd("?")], [Shows the setting in the title line: #cmd("ACTION=OFF"),
    #cmd("ACTION=ALL") or a list of codes such as #cmd("ACTION=1,2,3"). The
    command line is cleared.],
)

The default is #cmd("OFF"). A word that is not a number or one of these words
gets #cmd("PARM INVALID"). A number above 16, and #cmd("0"), change nothing. On the log, the
replies appear at once. SDSF keeps the setting in the profile.

Examples: #cmd("ACTION 2 3") adds the codes 2 and 3; #cmd("ACTION MVS") adds
the codes 1 to 12; #cmd("ACTION OFF 3") gets #cmd("PARM INVALID").

=== PREFIX <ref-cmd-prefix>

#idx("PREFIX command")
#fmt("PREFIX [name [x [y]]]")

#cmd("PRE") is the short form. #cmd("PREFIX") limits the lists to the jobs
whose names match #var("name"). It takes up to three operands; a
fourth gets #cmd("TOO MANY PARMS").

#deflist(width: 1.35in,
  [#var("name")], [A job name or a pattern, up to 8 characters. The whole job
    name must match: #cmd("PREFIX TBR") shows only the job #cmd("TBR"), and
    #cmd("PREFIX TBR*") the jobs whose names begin with #cmd("TBR"). A longer
    name gets #cmd("PARM INVALID").],
  [#var("x")], [One character that stands for any number of characters, in
    place of the default #cmd("*"). The pattern of #cmd("ST"), #cmd("O") and
    #cmd("H") then uses these characters too.],
  [#var("y")], [One character that stands for exactly one character, in
    place of the default #cmd("%").],
)

A #var("x") or #var("y") of more than one character gets
#cmd("INVALID SYNTAX"). So do #var("x") and #var("y") that are the same, and
#cmd("?") and #cmd("&") as characters.

#cmd("PREFIX") alone takes the limit away, so that the lists show all jobs.
#cmd("PREFIX ?") puts the setting on the command line, as
#cmd("PREFIX name * %"), so that you can read it or change it.

The prefix limits ST, I, O and H. On H it takes the place of the rule that
shows only the jobs under your user id. DA, PR and INIT are not limited. SDSF
keeps the prefix in the profile.

Examples: #cmd("PRE TBR*") shows the jobs whose names begin with #cmd("TBR"),
and #cmd("PRE") alone shows all of them again. After #cmd("PREFIX A - +"), the
pattern #cmd("ST A-") is the one that #cmd("ST A*") would be.

=== DEST <ref-cmd-dest>

#idx("DEST command")
#fmt("DEST [dest ...]")

Limits the lists to the destinations you name. You may give up to four words;
five get #cmd("TOO MANY PARMS").

#deflist(width: 1.35in,
  [#cmd("LOCAL"), #cmd("ANYLOCAL")], [The local destination.],
  [#cmd("Rn"), #cmd("RMn"), #cmd("RMTn")], [A remote destination, where
    #var("n") has up to 4 digits. SDSF changes the name to #cmd("Rn").],
  [#cmd("Un")], [A user destination.],
)

Another name gets #cmd("INVALID DESTINATION NAME"), and the cursor stands on
it. #cmd("DEST") alone shows all destinations again; #cmd("DEST ?") puts the
setting on the command line.

The destination limits ST, I, O and H. On O and H it limits by the destination
of the job, the one that ST shows, not by the destination of each data set. SDSF keeps it in the profile.

Examples: #cmd("DEST LOCAL"), #cmd("DEST R7"). #cmd("DEST XYZZY") gets
#cmd("INVALID DESTINATION NAME").

=== INPUT <ref-cmd-input>

#idx("INPUT command")
#fmt("INPUT ON|OFF")

#cmd("INPUT ON") adds the input of a job (its JCL and the data in the stream)
to the data sets that the Job Data Set panel lists, and that you get with
#cmd("S") on a job. The default is #cmd("OFF"). #cmd("INPUT") with no operand
gets #cmd("TOO FEW PARMS"); with two, #cmd("TOO MANY PARMS"); with another
word, #cmd("PARM INVALID"). SDSF does not keep the setting.

=== SET <ref-cmd-set>

#idx("SET command")
#idx("hexadecimal display")
#fmt("SET HEX [ON|OFF]")

#cmd("SET HEX ON") shows every line of the log and of the output also in
hexadecimal. Each line then takes four rows: the text, the first digit of
each byte, the second digit of each byte, and a line of dashes. #cmd("SET HEX OFF") turns it off;
#cmd("SET HEX") alone is the same as #cmd("SET HEX ON"). The default is
#cmd("OFF"). #cmd("SET") alone gets #cmd("TOO FEW PARMS"), an operand other
than #cmd("HEX") gets #cmd("PARM INVALID"), and more than two operands get
#cmd("TOO MANY PARMS"). The command is accepted on all panels but has an
effect only on the log and on the Output Data Set panel. SDSF does not keep the setting.

=== FINDLIM <ref-cmd-findlim>

#idx("FINDLIM command")
#fmt("FINDLIM n
FINDLIM ?")

Sets the number of lines that one #cmd("FIND") looks at on the log and on
output before it stops with
#cmd("*FINDLIM REACHED*"). #var("n") is a number from 1000 to 9999999, at most
7 digits; the default is 5000. Any other value gets #cmd("PARM INVALID"), and
no operand gets #cmd("TOO FEW PARMS"). #cmd("FINDLIM ?") puts
#cmd("FINDLIM n") on the command line. SDSF does not keep the setting.

=== SYSID <ref-cmd-sysid>

#idx("SYSID command")
#fmt("SYSID name
SYSID ?")

Chooses the system whose log to show. #var("name") is a system ID of up to 4
characters; a longer one gets #cmd("PARM INVALID"). With no operand the answer
is #cmd("TOO FEW PARMS"); with two, #cmd("TOO MANY PARMS"). #cmd("SYSID ?")
puts #cmd("SYSID xxxx") on the command line.

On the log, the command takes effect at once. The log of a system other than
your own is empty, and the message is #cmd("NO SYSLOG FOUND"). Your own ID
shows the log again. SDSF does not keep the setting.

Examples: #cmd("SYSID XXXX") (an ID that is not your system's:
#cmd("NO SYSLOG FOUND")), #cmd("SYSID ABCDEFGHI") (#cmd("PARM INVALID")).
