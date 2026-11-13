#import "../bookmaster/bookmaster.typ": *

= Getting Started <ug-start>

#idx("getting started")
This chapter takes you from ISPF into SDSF and shows how to move around in
it: how to start it and leave it, how to reach a panel, what the command line
and the keys do, how to act on a job from the NP column, how to scroll, and
what SDSF remembers from one session to the next. It shows the way and leaves
the details to the _SDSF Reference_. The chapters after this one build on what
you learn here.

== Starting SDSF from ISPF <ug-start-start>

#idx("starting SDSF")
#idx("TSO SDSF")
SDSF runs under ISPF, so log on to TSO and start ISPF first. On any ISPF
command line, type:

#code("TSO SDSF")

and press Enter. SDSF shows its primary option menu (@ug-start-menu). The
command #cmd("SDSF") is a CLIST that the installation puts into the SYSPROC
concatenation. Your site may also have added an entry for SDSF to the ISPF
primary option menu; if so, you may use it. The installation in this book sets
up #cmd("TSO SDSF") only.

If the answer is #cmd("COMMAND SDSF NOT FOUND"), the CLIST is not in SYSPROC.
@ug-install lists this among the things that go wrong, and says how to put it
right.

You leave SDSF with the End key (PF3) on the primary option menu, or by typing
#cmd("END") there, and you are back in ISPF. From any other SDSF panel the End
key goes back one step, as @ug-start-keys says.

== The Primary Option Menu <ug-start-menu>

#idx("primary option menu")
#idx("SDSF PRIMARY OPTION MENU")
The menu is titled #cmd("SDSF PRIMARY OPTION MENU"). It lists the panels you
can go to, each with a line that says what it shows:

#tab(caption: [The options of the primary option menu])[
  #table(columns: (0.9in, 1fr, 1.9in),
    [Option], [Shows], [Chapter],
    [#cmd("LOG")], [The system log.], [@ug-log],
    [#cmd("DA")], [The active address spaces.], [@ug-running],
    [#cmd("I")], [The jobs in the JES2 input queue.],
      [@ug-queues],
    [#cmd("O")], [The jobs in the JES2 output queue.],
      [@ug-queues],
    [#cmd("H")], [The jobs in the JES2 held output queue.],
      [@ug-queues],
    [#cmd("ST")], [The status of the jobs in the JES2 queues.],
      [@ug-jobs],
    [#cmd("PR")], [The JES2 printers on this system.],
      [@ug-devices],
    [#cmd("INIT")], [The JES2 initiators on this system.],
      [@ug-devices],
    [#cmd("TUTOR")], [A short course on SDSF.], [this chapter],
    [#cmd("END")], [Leaves SDSF.], [this chapter],
  )
]

You choose an option by typing its name on the command line, the field after
#cmd("COMMAND INPUT ===>"), and pressing Enter. The menu has no other fields
besides the command line and the SCROLL field, and it does not scroll.

For example, type #cmd("ST") and press Enter. The Status panel appears, with
one row for each job that JES2 holds. Press the End key (PF3) and you are on
the menu again.

An option may carry parameters, as in #cmd("ST IBM*"). @ug-jobs and
@ug-queues say what they select.

#cmd("TUTOR") starts the tutorial, a short course through SDSF that takes
about a quarter of an hour. It shows example panels and asks you to type on
them as you would on the real ones; nothing is done to any job. The End key
leaves the tutorial. For the details of a field or a command, press the Help
key (PF1) on any SDSF panel (@ug-start-keys).

== The Command Line <ug-start-cmdline>

#idx("command line")
#idx("commands")
Every SDSF panel has a command line after #cmd("COMMAND INPUT ===>") and, to
the right of it, a SCROLL field after #cmd("SCROLL ===>"). Type a command on
the command line and press Enter. Type commands in upper case. The line holds
up to 60 characters.

You do not have to go back to the menu to reach another panel. On a list or on
the log, type #cmd("ST") or #cmd("LOG"), and that panel appears. The End key
then goes back to the primary option menu.

#tab(caption: [The commands you use first])[
  #table(columns: (1.25in, 1fr),
    [Command], [What it does],
    [#cmd("ST"), #cmd("DA"), #cmd("I"), #cmd("O"), #cmd("H"), #cmd("PR"),
      #cmd("INIT"), #cmd("LOG")], [Show that panel.],
    [#cmd("HELP"), #cmd("TUTOR")], [Show the help of the panel you are on;
      start the tutorial.],
    [#cmd("END")], [Go back one step, or leave SDSF.],
    [#cmd("RETRIEVE")], [Put a command you gave before back on the command
      line.],
    [#cmd("WHO")], [Show your user id, logon procedure and terminal name,
      until the next Enter.],
    [#cmd("PREFIX"), #cmd("DEST")], [Limit the lists to the jobs whose names
      match, or to destinations.],
    [#cmd("/")], [Give an operator command, as in #cmd("/D T").],
    [#cmd("TSO")], [Run a TSO command, as in #cmd("TSO TIME").],
  )
]

The commands that scroll and search work only on panels that have rows or
lines to scroll and search, so not on the primary option menu.
@ug-start-scroll shows how to scroll, and @ug-search how to search. A command that a panel does not read gets #cmd("INVALID COMMAND").

A command that is wrong stays on the command line, so that you can correct it,
and a message appears on the title line, the first line of the panel, on the
right. A command that is right clears the line. When something does not work,
read the message first. The _SDSF Reference_, chapter "Messages", lists them
all.

The commands of the system side, such as #cmd("LOG") and the operator command
#cmd("/"), need access that your installation gives you. Without it SDSF
answers #cmd("COMMAND NOT AUTHORIZED") or #cmd("NOT AUTHORIZED FOR CMD").
@ug-access says who may do what.

The Reference describes every command in its chapter "Commands", with the
panels where it works.

== PF Keys <ug-start-keys>

#idx("PF keys")
#idx("keys")
SDSF has no key assignments of its own. A key does on an SDSF panel what the
command it carries tells SDSF to do. This book names a key by its command
first and by its default position after, as in "the End key (PF3)". If your
ISPF has put a command on another key, that key does what this book says of
the default key.

#tab(caption: [The keys you use in SDSF])[
  #table(columns: (1.7in, 1fr),
    [Key], [What it does],
    [Enter], [Runs what stands on the command line, in the NP column and in
      the fields you may type over. With none of them, a list panel and the
      log are read again, so that you see the present state.],
    [the Help key (PF1)], [Shows the help of the panel. With something typed
      on the command line, the text is the command and the key is not looked
      at.],
    [the End key (PF3)], [Goes back one step.],
    [the Repeat-FIND key (PF5)], [Looks again for the last string of
      #cmd("FIND") (@ug-search).],
    [the Up key (PF7), the Down key (PF8)], [Scroll up and down
      (@ug-start-scroll).],
    [the Left key (PF10), the Right key (PF11)], [Move the columns of a row
      that is wider than the screen to the left and to the right, on the
      panels where that applies (@ug-start-scroll).],
    [the Retrieve key (PF12)], [Puts the command you typed before back on the
      command line. Each further press goes one command further back. SDSF
      keeps the last 10 commands.],
  )
]

The End key goes back as far as you came:

- from the primary option menu it leaves SDSF, into ISPF\;
- from a list panel (ST, DA, I, O, H, PR, INIT) or from the log it goes to the
  primary option menu, also when you came from another list by typing its
  command\;
- from the Job Data Set panel it goes to the list on which you chose the
  job\;
- from the Output Data Set panel it goes to the Job Data Set panel if you
  chose the output there, and otherwise to the list on which you chose it.

The keys PF2, PF4, PF6 and PF9 carry the ISPF commands #cmd("SPLIT"),
#cmd("RETURN"), #cmd("RCHANGE") and #cmd("SWAP"). SDSF does nothing with them
of its own. The help and the tutorial use the keys in their own way, which
their panels tell you.

The Reference lists every key on every panel in Appendix A, "PF Key
Assignments".

== The NP Column <ug-start-np>

#idx("NP column")
#idx("action characters")
The first column of a row on a list panel is #cmd("NP"). It is where you act
on a job, an address space, a printer or an initiator. Type one or two
characters, an _action character_, in the NP column of a row and press Enter.
SDSF carries it out on that row.

Take the Status panel (#cmd("ST")) and a job of yours that has output. Type
#cmd("?") in the NP column of its row and press Enter: the Job Data Set panel
shows the data sets of the job. Press the End key (PF3) to come back. Type
#cmd("S") instead, and the Output Data Set panel shows the output of the job,
all its data sets one after the other. The End key takes you back again.
@ug-jobs goes on from here.

These are the action characters of the Status panel:

#tab(caption: [The action characters of the Status panel])[
  #table(columns: (0.7in, 1fr),
    [Typed], [What it does],
    [#cmd("?")], [Shows the data sets of the job on the Job Data Set panel.],
    [#cmd("S")], [Shows the output of the job on the Output Data Set panel.],
    [#cmd("D")], [JES2 displays the job; its answer is in the log.],
    [#cmd("L")], [JES2 lists the output of the job.],
    [#cmd("H")], [Holds the job. A held job that waits to execute does not
      start.],
    [#cmd("A")], [Releases a held job.],
    [#cmd("O")], [Releases the held output of the job for printing.],
    [#cmd("C")], [Cancels the job. Its output stays.],
    [#cmd("CD")], [Cancels the job and asks for a dump.],
    [#cmd("P")], [Cancels the job and deletes its output.],
    [#cmd("E")], [Restarts the job: JES2 puts it back on the input queue.],
  )
]

*Take care with #cmd("C"), #cmd("CD"), #cmd("P") and #cmd("E").* SDSF does not
ask again before it does what you typed. Look at the row before you press
Enter. #cmd("P") also takes away the output of the job.

Except for #cmd("?"), #cmd("S") and, on the Status panel, #cmd("P"), an action
character makes SDSF give a command to JES2. The message #cmd("COMMAND ISSUED")
on the title line says that SDSF gave the command, not that JES2 took it. The
answer of JES2 is in the system log; show it with #cmd("LOG"). On the Status
panel the rows stay as they were until you press Enter with nothing typed,
which reads the list again, so that you see the new state of the job.

#cmd("P") on the Status panel is not a command. SDSF asks JES2 itself to cancel
the job and to purge its output. The title line shows nothing if that worked,
and the list is read again at once, so that the job is gone from it.

How to type them:

- The NP column takes two characters (four on the Printer panel). Blanks in
  front are ignored, and lower case is taken as upper case.
- You may type action characters in the NP column of several rows and press
  Enter once. SDSF carries them out from the top row down. The title line
  shows the message of the last one that gave a message.
- An action character that the panel does not take gets #cmd("INVALID COMMAND")
  on ST, DA, PR and INIT, and stays in the NP column so that you can correct
  it. On I, O, H and the Job Data Set panel the answer is
  #cmd("ACTION NOT AVAILABLE YET"), and it does not stay. Those panels take
  #cmd("?") and #cmd("S") (the Job Data Set panel #cmd("S") only), and H also
  #cmd("O").
- You can change some fields by typing over them and pressing Enter, for
  example #cmd("PRTY") and #cmd("DEST") on the Status panel. SDSF gives the
  command for the change. If a changed field and an action character are in
  the same Enter, SDSF deals with the field and does not carry out the action
  character: type it again. (On the Held Output panel, #cmd("O") and a new
  #cmd("DEST") go together.)

You may act on your own jobs. For the jobs of other users, SDSF needs access
in RAKF; without it the message is #cmd("NOT AUTHORIZED FOR JOB"), or the job
is not on the list at all. @ug-access has the details.

The action characters of every panel, the command each one gives and the
access it needs are in the _SDSF Reference_, chapter "Action Characters".

== Scrolling <ug-start-scroll>

#idx("scrolling")
#idx("scroll amount")
When a panel has more rows or lines than the screen holds, use the Up key
(PF7) and the Down key (PF8) to scroll up and down. The Left key (PF10) and
the Right key (PF11) move the columns of a row that is wider than the screen;
the first columns, #cmd("NP") and the first name column, stay where they are.
(That name is the name of the job on #cmd("ST"), the name of the printer on
#cmd("PR") and #cmd("DDNAME") on the Job Data Set panel.) On the Status and
the Input Queue panel the keys move the columns only after you have typed
#cmd("?") alone on the command line; without it they read the Status list
again and do nothing on the Input Queue panel. On the Initiator panel they do
nothing. On the Output Data Set panel and on the system log they move the text
of the lines.

*How far a key scrolls.* The amount is the value in the SCROLL field, which is
on every panel:

#tab(caption: [The values of the SCROLL field])[
  #table(columns: (0.9in, 1fr),
    [Value], [Scrolls],
    [#cmd("PAGE")], [A screen. This is the value you start with.],
    [#cmd("HALF")], [Half a screen.],
    [#cmd("DATA")], [A screen less one line, so that one line of the old
      screen stays.],
    [#cmd("CSR")], [As many lines as there are above the cursor, so that the
      line under the cursor goes to the top. If the cursor is not on the
      data, a screen.],
    [a number], [That many lines. One to four digits.],
  )
]

Type another value over it and press Enter, and the keys scroll by the new
amount from then on. A value that is not valid gives
#cmd("INVALID SCROLL AMOUNT").

*One scroll by another amount.* Type a word on the command line and press a
scroll key. The word is the amount for that one scroll, and the key uses it
up.

#tab(caption: [A word typed before the Up key or the Down key])[
  #table(columns: (1.3in, 1fr),
    [Typed], [Amount],
    [#cmd("M") or #cmd("MAX")], [As far as it goes: to the top, or to the
      end.],
    [#cmd("P") or #cmd("PAGE")], [A screen.],
    [#cmd("H") or #cmd("HALF")], [Half a screen.],
    [#cmd("D") or #cmd("DATA")], [A screen less one line.],
    [#cmd("C") or #cmd("CSR")], [The line of the cursor goes to the top.],
    [a number], [That many lines.],
  )
]

For example, type #cmd("M") and press the Down key (PF8) to go to the bottom,
or #cmd("MAX") and the Up key (PF7) to go to the top. Type #cmd("2") and press
the Down key to scroll two lines. A word that is none of these gives
#cmd("INVALID SCROLL AMOUNT").

*The commands.* #cmd("UP") and #cmd("DOWN") typed on the command line scroll
too, and take an amount after them, as in #cmd("DOWN HALF") or #cmd("UP 5").
They take the full words (#cmd("MAX"), #cmd("PAGE"), #cmd("HALF"),
#cmd("DATA"), #cmd("CSR")) and numbers. The short forms #cmd("M"), #cmd("P"),
#cmd("H"), #cmd("D") and #cmd("C") are for the word before a key only.
#cmd("TOP") shows the first page and #cmd("BOTTOM") the last. #cmd("LEFT") and
#cmd("RIGHT") can be typed on the Output Data Set panel and on the log; on the
other panels only the keys move the columns.

#note[#cmd("MAX") in the SCROLL field scrolls nothing and gives no message.
The field gets its last valid amount back. Use #cmd("MAX") before a key, as
above.]

On the system log, the Down key at the end of the log reads the log again and
shows what has come in since.

What the Left key and the Right key move, panel by panel, is in the _SDSF
Reference_, chapter "Commands", under #cmd("LEFT") and #cmd("RIGHT"), and in
Appendix A, "PF Key Assignments".

== Your Profile <ug-start-profile>

#idx("profile")
#idx("ISPF profile")
SDSF keeps some of your settings in your ISPF profile, so that the next
session starts with them, also after you have logged off and on again. SDSF
reads them when it starts and writes one when it changes.

#tab(caption: [What SDSF keeps in your profile])[
  #table(columns: (1.5in, 1fr),
    [Setting], [What is kept],
    [The scroll amount], [The value of the SCROLL field. #cmd("PAGE") at
      first.],
    [#cmd("PREFIX")], [The name that limits the lists, and the two wildcard
      characters. At first #cmd("*") and #cmd("%").],
    [#cmd("DEST")], [The destinations that limit the lists, four at most.],
    [#cmd("ACTION")], [Which outstanding replies the log shows. At first
      #cmd("OFF").],
    [The last #cmd("FIND")], [The last string you looked for with #cmd("FIND")
      on the system log or on output, with its direction, so that the
      Repeat-FIND key (PF5) works there in the next session too.],
  )
]

Everything else lasts until you leave SDSF: the classes and the name that you
gave with #cmd("ST"), the classes of #cmd("I"), #cmd("O") and #cmd("H"), the
types and positions of #cmd("DA"), #cmd("SYSID"), #cmd("INPUT"),
#cmd("SET HEX") and the limit of #cmd("FINDLIM"). The next time you start SDSF
they have their defaults again. The scale line of #cmd("COLS") lasts even less:
only while the output or log display it was shown on stays open.

If the lists are shorter than you expect, a #cmd("PREFIX") or #cmd("DEST")
that you set in an earlier session may be the cause, because SDSF has kept it.
Type #cmd("PREFIX") and #cmd("DEST") with nothing after them, and the limits
are gone.

The _SDSF Reference_ lists the settings in chapter "Commands", section
"Commands That Set the Profile", and the variables that hold them in chapter
"Panels".
