#import "../bookmaster/bookmaster.typ": *

= PF Key Assignments <apx-pfkeys>

#idx("PF keys")
#idx("keys")
This appendix lists the keys SDSF acts on and what each one does on each
panel. It names a key by the command it carries first and by its default
position after, as in "the End key (PF3)". The commands themselves are in
@ref-cmd, the panels in @ref-panels, and the messages in @ref-messages.

== How SDSF Uses the Keys <apx-pfkeys-how>

SDSF has no key assignments of its own. Its panels use the keys of ISPF, so
a key does on an SDSF panel what the command it carries tells SDSF to do. A
user who has moved a command to another key gets that command from the other
key. For the Help key and for the keys in the help and the tutorial this holds
as far as ISPF tells SDSF the assignment of the user's keys. The defaults of ISPF, with the positions this appendix names, are in
@apx-pfkeys-defaults.

SDSF learns what a key means in one of three ways:

- *The command the key carries.* For the Up, Down, Left, Right, Repeat-FIND
  and Retrieve keys, ISPF tells SDSF the command.
- *The Help key.* SDSF asks ISPF which command the key that ended the
  display carries, and shows the help if it is #cmd("HELP"). Where it cannot
  read the assignment of a key, it takes the default, and takes PF13 to PF24
  as PF1 to PF12. The help and the tutorial read their keys the same way
  (@apx-pfkeys-help).
- *The End key.* ISPF ends the display of the panel on #cmd("END"), and SDSF
  goes back.

The commands of the Help, End, Up, Down, Repeat-FIND and Retrieve keys can
also be typed on the command line, except #cmd("UP") and #cmd("DOWN") on the
primary option menu, and #cmd("RFIND") there, which give #cmd("INVALID
COMMAND"). The commands of the Left and Right keys can be typed on two panels
only: #cmd("LEFT") and #cmd("RIGHT") work on the Output Data Set panel and the
system log. On every other panel they give #cmd("INVALID COMMAND").

== The Default Keys <apx-pfkeys-defaults>

#tab(caption: [The default keys and what SDSF does with them])[
  #table(columns: (0.7in, 1.0in, 1fr),
    [Key], [Command], [What SDSF does],
    [Enter], [none], [Runs what stands on the command line, in the NP column and
      in the overtypeable fields. With none of them: on the Status, DA, Input
      Queue, Output Queue, Held Output, Printer and Initiator panels it reads
      the list again, on the system log it reads the log again, and on the
      other panels nothing happens.],
    [PF1], [#cmd("HELP")], [Shows the help of the panel
      (@apx-pfkeys-help-key).],
    [PF2], [#cmd("SPLIT")], [A command of ISPF. SDSF has no handling of its own for it.],
    [PF3], [#cmd("END")], [Leaves the panel (@apx-pfkeys-end).],
    [PF4], [#cmd("RETURN")], [A command of ISPF. SDSF has no handling of its own for
      it on its panels. In the help and the tutorial it leaves them, as #cmd("END")
      does.],
    [PF5], [#cmd("RFIND")], [Looks again for the last string of #cmd("FIND"), on
      the list panels, the Job Data Set panel, the system log and the Output Data Set
      panel (@apx-pfkeys-rfind).],
    [PF6], [#cmd("RCHANGE")], [A command of ISPF. SDSF has no handling of its own for it.],
    [PF7], [#cmd("UP")], [Scrolls up (@apx-pfkeys-scroll). In the help, goes up
      to the panel that lists the topic.],
    [PF8], [#cmd("DOWN")], [Scrolls down (@apx-pfkeys-scroll). In the help, goes
      to the next panel.],
    [PF9], [#cmd("SWAP")], [A command of ISPF. SDSF has no handling of its own for it.],
    [PF10], [#cmd("LEFT")], [Moves the columns to the left
      (@apx-pfkeys-scroll). In the help, goes back to the panel shown before.],
    [PF11], [#cmd("RIGHT")], [Moves the columns to the right
      (@apx-pfkeys-scroll). In the help, goes to the next panel.],
    [PF12], [#cmd("RETRIEVE")], [Puts a command typed before back on the
      command line (@apx-pfkeys-retrieve).],
  )
] <apx-pfkeys-table>

Where SDSF cannot read the assignment of a key, it takes PF13 to PF24 as PF1
to PF12. This is so only for the Help key and for the keys in the help and the
tutorial. Every other key on an SDSF panel is read from the command ISPF gives
it, so PF13 to PF24 do what ISPF has them do.

The books of SDSF name the keys SDSF acts on this way: the Help key (PF1),
the End key (PF3), the Repeat-FIND key (PF5), the Up key (PF7), the Down key
(PF8), the Left key (PF10), the Right key (PF11) and the Retrieve key (PF12).

== The Keys on Each Panel <apx-pfkeys-panels>

The Help key, the End key and the Retrieve key act on every panel of SDSF,
the primary option menu included. The help and the tutorial are the exception
(@apx-pfkeys-help). The scroll keys and the Repeat-FIND key
act as this table shows. "Wider" means that the row of the panel is wider
than the screen (@ref-panels).

#tab(caption: [The scroll keys and the Repeat-FIND key, by panel])[
  #table(columns: (1.5in, 1.0in, 1.6in, 1fr),
    [Panel], [Up key, Down key], [Left key, Right key], [Repeat-FIND key],
    [Primary option menu], [none], [none], [none],
    [Status], [rows], [after #cmd("?"), else reads the list again], [rows],
    [DA], [rows], [if wider], [rows],
    [Input Queue], [rows], [only after #cmd("?")], [rows],
    [Output Queue], [rows], [if wider], [rows],
    [Held Output], [rows], [if wider], [rows],
    [Printer], [rows], [if wider], [rows],
    [Initiator], [rows], [none], [rows],
    [Job Data Set], [rows], [if wider], [rows],
    [Output Data Set], [lines], [yes], [lines],
    [System log], [lines], [yes], [lines],
  )
] <apx-pfkeys-panel-table>

The menu does not scroll. A row on the Initiator panel is 80 columns wide, so
there is nothing to move.

=== The Help Key <apx-pfkeys-help-key>

#idx("Help key")
The Help key shows the help of the panel it is pressed on. It works with an
empty command line. With something typed on the command line, the text is the
command and the key is not looked at. The help that comes up is this:

#tab(caption: [The help the Help key shows])[
  #table(columns: (1.9in, 1fr),
    [Panel], [Help panel],
    [Primary option menu], [SDSF Primary Option Menu],
    [Status], [Status Panel],
    [DA], [DA Panel],
    [Input Queue], [Input Queue Panel],
    [Output Queue], [Output Queue Panel],
    [Held Output], [Held Output Panel],
    [Printer], [Printer Panel],
    [Initiator], [Initiator Panel],
    [Job Data Set], [Job Data Set Panel],
    [Output Data Set], [Output Data Set Panel],
    [System log], [System Log Panel],
  )
]

The End key leaves the help (@apx-pfkeys-help), and SDSF shows the panel
again.

=== The End Key <apx-pfkeys-end>

#idx("End key")
The End key does what the command #cmd("END") does. Where it goes depends on
the panel:

#tab(caption: [Where the End key goes])[
  #table(columns: (2.2in, 1fr),
    [Panel], [The End key goes to],
    [Primary option menu], [out of SDSF.],
    [Status, DA, Input Queue, Output Queue, Held Output, Printer, Initiator and
      the system log], [the primary option menu. This is so also when the
      panel was reached from another list panel by typing its command.],
    [Job Data Set], [the list panel on which the job was chosen.],
    [Output Data Set], [the Job Data Set panel if the output was chosen there,
      else the list panel on which the output was chosen.],
  )
]

The End key works also when the SCROLL field holds an amount that is not
valid. Every other key, the Repeat-FIND key included, then gives the message
#cmd("INVALID SCROLL AMOUNT"), except the Help key and the Retrieve key, which
SDSF handles first.

=== The Repeat-FIND Key <apx-pfkeys-rfind>

#idx("Repeat-FIND key")
The Repeat-FIND key (PF5) gives #cmd("RFIND"). It looks again for the last
string of #cmd("FIND"), in the direction of the last #cmd("FIND"). The string
is kept in the ISPF profile, so the key works in the next session too. If
there is no string, nothing happens. With something typed on the command
line, the text runs as the command and the key is not looked at.

=== The Retrieve Key <apx-pfkeys-retrieve>

#idx("Retrieve key")
The Retrieve key (PF12) puts the command typed before back on the command
line. Each further press goes one command further back. SDSF keeps the last
10 commands. After the oldest of them, the next press shows the newest again.
These are not kept: #cmd("UP"), #cmd("DOWN"), #cmd("LEFT"), #cmd("RIGHT"),
#cmd("TOP"), #cmd("BOTTOM") (and #cmd("BOT")), #cmd("WHO"), #cmd("HELP"),
#cmd("TUTOR"), #cmd("RETRIEVE"), a command that stays on the command line with
a message, and a command that was run together with a key that carries a
command. With something typed on the command line, the Retrieve key does
nothing and the text runs as the command.

== The Scroll Keys <apx-pfkeys-scroll>

#idx("scroll keys")
#idx("scroll amount")
The Up key (PF7) and the Down key (PF8) scroll rows or lines up and down.
The Left key (PF10) and the Right key (PF11) move the columns that are not
fixed. The amount of a scroll is the one in the SCROLL field. If the field holds
#cmd("MAX"), the key scrolls nothing and the field gets its last valid amount
back. A word typed
on the command line before the key is the amount for that one scroll, and the
key uses it up:

#tab(caption: [The amount typed before the Up key or the Down key])[
  #table(columns: (1.3in, 1fr),
    [Typed], [Amount],
    [#cmd("M") or #cmd("MAX")], [as far as it goes: to the top or to the end],
    [#cmd("P") or #cmd("PAGE")], [a screen],
    [#cmd("H") or #cmd("HALF")], [half a screen],
    [#cmd("D") or #cmd("DATA")], [a screen less one line],
    [#cmd("C") or #cmd("CSR")], [the line of the cursor goes to the top],
    [a number], [that many lines, up to four digits],
  )
]

Anything else gives #cmd("INVALID SCROLL AMOUNT").

The commands #cmd("UP") and #cmd("DOWN") typed on the command line take an
amount after them too, but only the full words of the table: #cmd("MAX"),
#cmd("PAGE"), #cmd("HALF"), #cmd("DATA"), #cmd("CSR") or a number. The short
forms #cmd("M"), #cmd("P"), #cmd("H"), #cmd("D") and #cmd("C") are for the
word typed before a key and give #cmd("INVALID SCROLL AMOUNT") after
#cmd("UP") or #cmd("DOWN").

Typed on the command line, #cmd("LEFT") and #cmd("RIGHT") are taken on the
Output Data Set panel and the system log only, and give #cmd("INVALID COMMAND")
on every other panel. There an amount can follow: #cmd("M"), #cmd("MAX"), a
full word or a number.

At the end of the system log the Down key reads the log again, as Enter does,
and shows what has come in.

What the Left key and the Right key move depends on the panel:

#deflist(width: 1.5in,
  [Status, Input Queue], [After #cmd("?"), the further fields.
    Each press of the Right key shows the next part, and each press of the Left
    key goes back one. Without #cmd("?"), the key does nothing on the Input
    Queue panel. On the Status panel it reads the list again, as Enter does, so
    the rows can change.],
  [DA], [The Right key shows the right part of the row, the Left key the left
    part. If the whole row fits on the screen, nothing moves.],
  [Output Queue, Held Output, Printer], [The next part of the row, as on the Status
    panel. The Left key goes back one. The amount does not count here.],
  [Job Data Set], [The columns right of #cmd("DDNAME"), by the amount: a page
    moves the width of the columns that can move, less one column, #cmd("DATA")
    and #cmd("CSR") the same, #cmd("HALF") half of the width, a number that
    many columns, and #cmd("MAX") as far as the right end of the row.],
  [Output Data Set, system log], [The lines sideways, by the amount, up to
    the limit, where the title shows column 256 on the Output Data Set panel
    and column 255 on the system log: #cmd("PAGE") and #cmd("CSR") move by the
    width of the screen,
    #cmd("HALF") by half of it, #cmd("DATA") by one column less, a number by
    that many columns, and #cmd("MAX") to the limit.],
)

== The Keys in the Help and the Tutorial <apx-pfkeys-help>

#idx("help")
#idx("tutorial")
The help and the tutorial are SDSF's own panels, and SDSF moves through them
itself. On each of their panels the key's command, or the same word typed on
the command line, does this:

#tab(caption: [The keys on a help or tutorial panel])[
  #table(columns: (0.7in, 1.0in, 1fr),
    [Key], [Command], [What it does],
    [Enter], [none], [Shows the next panel of the topic. Where a panel lists
      topics, Enter with a number typed shows that topic. At the last panel of
      a topic it goes up to the panel that lists the topic. If there is none,
      the message #cmd("END OF TOPIC") appears.],
    [PF1], [#cmd("HELP")], [Shows the panel "Using Help and the Tutorial".],
    [PF3], [#cmd("END")], [Leaves the help or the tutorial, back to the SDSF
      panel.],
    [PF4], [#cmd("RETURN")], [As the End key.],
    [PF7], [#cmd("UP")], [Goes up to the panel that lists this topic; in the
      tutorial, to the list of parts. If there is none, nothing happens.],
    [PF8], [#cmd("DOWN")], [As Enter, without a number.],
    [PF10], [#cmd("LEFT")], [Goes back to the panel shown before, through up
      to 32 panels. At the first panel, nothing happens.],
    [PF11], [#cmd("RIGHT")], [As Enter, without a number.],
  )
]

A word typed on the command line is taken as the command, and the key is
then not looked at. The End key is the exception: it leaves the help or the
tutorial at any time. Besides the words in the table, #cmd("BACK") goes back as
the Left key does, #cmd("T") or #cmd("TOP") shows the table of contents, and
#cmd("I") or #cmd("INDEX") shows the index. On the index panels, the numbers
on the panel work the same way. Any other word gives the message
#cmd("INVALID OPTION"). The Repeat-FIND key (PF5) and the Retrieve key (PF12)
are not taken here: their commands #cmd("RFIND") and #cmd("RETRIEVE") give
#cmd("INVALID OPTION"). If PF2, PF6 or PF9 reach the help with their
commands #cmd("SPLIT"), #cmd("RCHANGE") or #cmd("SWAP"), they give the same
message. The SDSF commands, such as #cmd("ST"), are not taken on
these panels.
