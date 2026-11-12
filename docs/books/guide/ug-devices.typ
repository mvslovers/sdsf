#import "../bookmaster/bookmaster.typ": *

= Printers and Initiators <ug-devices>

Most of SDSF looks at jobs. Two panels look at the machinery that runs them:
the Printer panel lists the JES2 printers, which print the output of jobs, and
the Initiator panel lists the JES2 initiators, which start the jobs. On both
you can do more than look: you start a printer, stop an initiator, halt one at
once. These panels belong to the operator's side of the system, so they need
read access to the FACILITY profile #cmd("SDSF.OPER"), and every action that
changes something needs update access to it (@ug-access).

Both panels work as the lists in @ug-jobs do: an action character typed in the
NP column acts on the row, and Enter carries it out. The difference is what
happens next. An action on a printer or an initiator is a command that SDSF
gives to JES2, and JES2 decides what becomes of it. The last section of this
chapter shows what that means for what you see. The columns of the panels and
every action character are in the _SDSF Reference_, in the chapters "Panels"
and "Action Characters".

== The Printer Panel <ug-devices-pr>

#idx("Printer panel")
#idx("PR command")
#idx("printers")
*Show the panel.* Type #cmd("PR") on the command line of the primary option
menu, or of any other SDSF panel, and press Enter. The title line reads
#cmd("SDSF PRINTER DISPLAY"), and below the heading line there is one row per
printer. Without read access to #cmd("SDSF.OPER") the answer is
#cmd("COMMAND NOT AUTHORIZED") and the panel does not open. The same message
with an empty panel means that SDSF could not enter the authorized state it
needs to ask JES2 (see the last section of this chapter).

To see only some of the printers, give words after the command, up to four:
#cmd("PR 1") shows #cmd("PRINTER1"), and #cmd("PR 1-3 5") shows
#cmd("PRINTER1") to #cmd("PRINTER3") and #cmd("PRINTER5"). #cmd("LCL") shows
all the local printers, which is all of them. #cmd("R")#var("n") and
#cmd("RMT") are accepted but show nothing, since JES2 tells SDSF only about
local printers. #cmd("PR") alone shows all of them.

*Where the rows come from.* SDSF does not keep a list of printers. Each time it
reads the printers, it gives JES2 the command #cmd("$DU,PRTS") and reads JES2's
answer from the system log. So the command and its answer appear in the log
each time SDSF reads the printers: when the panel opens, and each time you
press Enter with nothing typed. If JES2 does not answer within a few
seconds, the title line says #cmd("NO ANSWER FROM JES2")\; press Enter to ask
again.

=== Reading a Row <ug-devices-prrow>

These are the columns you need first. The others are on the further pages that
the Right key (PF11) shows; the Reference describes them under "Panels", "PR:
Printers".

#deflist(width: 1.9in,
  [#cmd("PRINTER")], [The name of the printer, #cmd("PRINTER1") for printer 1.
    It stays in place when you move the columns.],
  [#cmd("STATUS")], [The state of the printer as JES2 gives it, for example
    #cmd("INACTIVE"), #cmd("ACTIVE") or #cmd("DRAINED").],
  [#cmd("SFORM")], [The forms the printer prints.],
  [#cmd("SCLASS")], [The output classes the printer prints.],
  [#cmd("JOBNAME"), #cmd("TYPE"), #cmd("JNUM")], [The job an active printer is
    printing.],
)

An active printer is white, the others are blue.

=== Starting and Stopping a Printer <ug-devices-prstart>

To start a printer:

+ Type #cmd("PR") and press Enter.
+ Type #cmd("S") in the NP column of the row of the printer, and press Enter.
+ The title line says #cmd("COMMAND ISSUED"). SDSF has given JES2 the command
  to start the printer; for #cmd("PRINTER1") it is #cmd("$SPRT1").
+ Press Enter with nothing typed. SDSF asks JES2 again, and the row shows the
  state JES2 now reports.

The row does not change by itself. After the action character the panel still
shows the state it read before, until you press Enter once more.

To take a printer out of work, you have two ways. They differ in what happens
to the output the printer is printing:

#deflist(width: 1.0in,
  [#cmd("P")], [Stops the printer when the output it is printing is done.],
  [#cmd("Z")], [Halts the printer at once. #cmd("S") lets it go on.],
)

#cmd("D") asks JES2 to display the printer; the answer is in the log. The
other action characters of the panel act on the output that is being printed:
#cmd("I") interrupts it, so that it is printed again later, #cmd("E") restarts
it from the beginning, #cmd("C") cancels it and #cmd("N") prints one more
copy. #cmd("B") and #cmd("F") back up or skip forward by pages, with the number
of pages after the letter: #cmd("B5") goes back five pages. The NP column of
this panel is four characters wide, to hold such a count. The Reference lists
them all under "Action Characters".

*Several printers at once.* You may type an action character in the NP column
of several rows and press Enter once. SDSF carries them out from the top row
down. The title line shows the message of the last one only.

=== Changing What a Printer Prints <ug-devices-print>

Some fields of a row can be overtyped: #cmd("SFORM"), #cmd("SCLASS"),
#cmd("SEP"), #cmd("SFCB") and #cmd("SDEST1"). #cmd("SFORM") and #cmd("SCLASS")
share one input field, and #cmd("SEP"), #cmd("SFCB") and #cmd("SDEST1") are on
the pages that the Right key (PF11) shows; a field can be overtyped only where
it is on the screen. To change one, type the new
value over it and press Enter. SDSF gives JES2 the command that sets it, and
the title line says #cmd("COMMAND ISSUED"). Press Enter again to read the new
value. A value that is not valid is refused before any command is given:
#cmd("INVALID SYNTAX"), #cmd("INVALID CLASS") or
#cmd("INVALID DESTINATION NAME"), and the cursor goes to the field.

Do not type an action character in the same Enter as an overtyped field. SDSF
deals with the field and leaves the action character out; type it again. The
rules for every field are in the Reference, under "Action Characters",
"Overtyping Fields".

== The Initiator Panel <ug-devices-init>

#idx("Initiator panel")
#idx("INIT command")
#idx("initiators")
*Show the panel.* Type #cmd("INIT") and press Enter. The title line reads
#cmd("SDSF INITIATOR DISPLAY"), and there is one row per initiator.
#cmd("INIT") takes no parameters; a word after it gives #cmd("TOO MANY PARMS").
As for the printers, you need read access to #cmd("SDSF.OPER"), and SDSF
reads the rows from JES2: it gives #cmd("$DI") each time it reads the
initiators, when the panel opens and when you press Enter with nothing typed,
and reads the answer from the log. The messages #cmd("NO ANSWER FROM JES2") and
#cmd("COMMAND NOT AUTHORIZED") mean what they mean on the Printer panel.

The row is only 80 columns wide, so the Left and Right keys move nothing.

#deflist(width: 1.9in,
  [#cmd("ID")], [The number of the initiator.],
  [#cmd("STATUS")], [#cmd("INACTIVE"), #cmd("ACTIVE"), #cmd("DRAINED"),
    #cmd("HALTED") and so on, as JES2 gives it.],
  [#cmd("CLASSES")], [The job classes the initiator selects.],
  [#cmd("JOB-NAME"), #cmd("STEP-NAME"), #cmd("PROC-STEP"), #cmd("TYPE"),
    #cmd("JNUM"), #cmd("C"), #cmd("ASID")], [The job an active initiator is
    running, and its step and address space.],
)

An active initiator is white, the others are blue.

=== Starting and Stopping an Initiator <ug-devices-initstart>

The action characters of this panel work as they do on the Printer panel. Type
one in the NP column of the row, which takes two characters, and press Enter:

#deflist(width: 1.0in,
  [#cmd("S")], [Starts the initiator.],
  [#cmd("P")], [Stops the initiator once the job it is running has ended.],
  [#cmd("Z")], [Halts the initiator: it takes no new job until you start it
    again with #cmd("S").],
  [#cmd("D")], [Displays the initiator: JES2 answers in the log.],
)

After #cmd("COMMAND ISSUED"), press Enter with nothing typed to read the
initiators again.

*Changing the classes.* The #cmd("CLASSES") field can be overtyped. Type the new
classes over it and press Enter; SDSF gives JES2 the command that sets them.
Classes are the letters A to Z and the digits 0 to 9. SDSF takes up to eight
and gives them to JES2, which keeps five at most, so after #cmd("COMMAND ISSUED")
look at the row or at the log. A value that is not a list of classes is refused
with #cmd("INVALID CLASS").

== Actions That Go to JES2 <ug-devices-jes2>

#idx("JES2 command")
#idx("COMMAND ISSUED")
Every action character and every overtyped field on these two panels becomes a
JES2 command, and the checks below apply to both. SDSF builds the command from the action and from the number of
the printer or of the initiator in the row: #cmd("S") on the row of
#cmd("PRINTER1") gives #cmd("$SPRT1"), and #cmd("P") on initiator 2 gives
#cmd("$PI2"). The Reference lists the command each action character gives under
"Action Characters", "The Command Each Action Issues"; this chapter does not
repeat it.

What you see depends on who refuses. There are two places where that can
happen, and they look different.

*SDSF refuses before it gives a command.* The title line says why, and no
command is given:

#deflist(width: 2.4in,
  [#cmd("INVALID COMMAND")], [The panel does not take the character you typed,
    or the text after #cmd("B") or #cmd("F") is not one it takes. The character
    stays in the NP column, so that you can correct it.],
  [#cmd("NOT AUTHORIZED FOR PRT")], [You have no update access to
    #cmd("SDSF.OPER") (for #cmd("D"), no read access), for an action character
    as well as for an overtyped field. On the Initiator panel the message is
    #cmd("NOT AUTHORIZED FOR INIT").],
  [#cmd("COMMAND NOT AUTHORIZED")], [SDSF could not enter the authorized state
    that it needs to give a command. The Reference says when that is so, under
    "Action Characters", "The Access Each Action Needs".],
)

*JES2 refuses after SDSF gave the command.* The title line says
#cmd("COMMAND ISSUED"), and that is all it says. The message means that SDSF
gave the command to the system, not that JES2 took it. If JES2 does not accept
the command, for instance because the printer is not in a state for it, the
panel does not show it. JES2's answer, the acceptance or the refusal, is
written to the system log:

+ Type #cmd("LOG") and press Enter. The log opens at its end.
+ Look for the command you gave, such as #cmd("$SPRT1"). JES2's answer is on
  the lines after it.

#cmd("LOG") needs read access to #cmd("SDSF.OPER"), which you have if you are
on these panels (@ug-log).

*Check the result, not the message.* After an action, look at the row: press
Enter with nothing typed and read #cmd("STATUS"). If it did not change, look
in the log.

*Several rows.* If you type action characters on several rows in one Enter,
the title line shows the message of the last one that gave one. It does not
say what happened to the others. Check the rows, or the log.
