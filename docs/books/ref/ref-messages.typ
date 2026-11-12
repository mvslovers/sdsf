#import "../bookmaster/bookmaster.typ": *

// A message: the text as the screen shows it, and an entry in the index.
#let msg(t) = [#idx("messages", t)#cmd(t)]

= Messages <ref-messages>

#idx("messages")
This chapter lists every message that SDSF shows, with its exact text, what
causes it and what to do about it.

== How SDSF Reports <ref-messages-how>

SDSF 1.2.0 has no message set of its own. Its messages are short texts without a
number, and the only message that has one is #cmd("ISF001E"), which SDSF
writes when it cannot start. Since there are no numbers to put in order, this
chapter groups the messages by the part of SDSF that gives them: the start,
the command line, the parameters of commands, scrolling, FIND, the settings
ACTION and SYSID and the log, PRINT, action characters, overtyping, reading
the queues, and the help. To find a message by its text, use the index at the
end of the book. The help panels #cmd("ISFHMS1") to #cmd("ISFHMS6"), titled
#cmd("HELP: Messages"), list the same messages in alphabetical order.

A message appears on the title line, the first line of a panel. It is shown
with the display that follows the command and is gone with the next one.

- On the list panels (ST, DA, I, O, H, PR and INIT) and on the Job Data Set
  panel it takes the place of the #cmd("LINE x-y (n)") figures on the right.
- On the log it follows the line number on the title line and takes the place
  of the columns. On the Output Data Set panel it starts in the same place and
  covers the line number as well. On both it is cut at the right edge of the
  screen.
- On the primary option menu it follows two dashes on the right of the title
  (#cmd("-- COMMAND ISSUED")). A message that does not fit in the room to the
  right of the title is not shown. #cmd("INVALID SCROLL AMOUNT") is the
  exception: it stands on the right without dashes.
- On the help panels it stands on the title line, after the name of the panel.

The texts are upper case. Some are shown with one blank in front of them; this
chapter leaves that blank out. In the texts, #var("n") stands for a number and
#var("x") for the string that you typed in FIND, which SDSF shows in upper
case. A string given as #cmd("X'..'") is shown as #cmd("X'..'") with the
hexadecimal digits of its bytes, and with one more blank in front of it. Where a message has two blanks inside it, as in
#cmd("NO CHARS  'x' FOUND"), the chapter keeps both, because the screen has
them.

For the commands, see @ref-cmd; for the action characters, @ref-actions; for
the access that decides several of the messages, @ref-auth.

== Start <ref-messages-start>

#tab(caption: [Message at the start])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("ISF001E ISFISP RUNS UNDER ISPF: SELECT PGM(ISFISP)")], [SDSF could
      not connect to ISPF: it was called outside ISPF. SDSF writes the message
      to the terminal, since it has no panel to show it on, and ends with
      return code 8. Start SDSF from an ISPF command line with
      #cmd("TSO SDSF").],
  )
]

== The Command Line: TSO, Operator Commands, Authorization <ref-messages-slash>

These messages come from the commands #cmd("TSO") and #cmd("/"), and from
every command or action that SDSF gives to JES2 or to the system. They can
appear on any panel.

#tab(caption: [Messages of TSO, / and of commands given to JES2])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("COMMAND PARM IS MISSING")], [#cmd("TSO") was typed with no command
      after it. SDSF clears the command line. Type #cmd("TSO") and the TSO
      command.],
    [#msg("NO COMMAND PROVIDED")], [#cmd("/") was typed with no command after
      it. The cursor stands right after the slash. Type the operator command
      after it.],
    [#msg("NOT AUTHORIZED FOR CMD")], [A command with #cmd("/") needs update
      access to SDSF.OPER, and you do not have it. Ask the system programmer
      for the access (@ref-auth). The overtyping of PGN on DA for an address
      space that has no job gives the same message (see "Overtyping").],
    [#msg("COMMAND NOT AUTHORIZED")], [SDSF could not give the command, for one
      of these reasons: SDSF did not get the authorized state that it needs
      for #cmd("/") commands, action characters and overtyping that go to JES2
      or to the system; SDSF did not get it to ask JES2 for the printers or
      the initiators; or you typed #cmd("LOG"), #cmd("PR") or #cmd("INIT")
      without read access to SDSF.OPER. Check the access (@ref-auth) and that
      the SVC routine is installed (@apx-svc).],
    [#msg("COMMAND ISSUED")], [SDSF gave the JES2 or operator command that
      your #cmd("/") command, action character or overtyping stands for. The
      message does not say that JES2 accepted it: the answer is in the log. On
      the log SDSF waits a moment and reads it again, so the answer may be
      shown already.],
  )
]

#note[The messages of a TSO command are those of TSO, not of SDSF. This
chapter does not list them.]

== Parameters of Commands <ref-messages-parms>

The commands report a wrong parameter with the same few messages. The tables
name the commands that give each one; their syntax is in @ref-cmd.

#tab(caption: [Messages about the parameters of a command])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("INVALID COMMAND")], [SDSF does not know the command, or the panel
      does not know the action character that you typed in the NP column (on
      ST, DA, PR and INIT). The command or the character stays where you typed
      it, so that you can correct it. Check the spelling. On I, O, H and the Job
      Data Set panel an unknown character gives #cmd("ACTION NOT AVAILABLE
      YET") instead.],
    [#msg("TOO FEW PARMS")], [The command needs more parameters. It is given by
      #cmd("LOCATE") without a line; #cmd("INPUT"), #cmd("SET"),
      #cmd("FINDLIM") and #cmd("SYSID") without a parameter; #cmd("PRINT") with
      a first line but no last line; and #cmd("PRINT ODSN") without a data set
      name.],
    [#msg("TOO MANY PARMS")], [The command has more parameters than it takes.
      The limits are: #cmd("ST") one name after the classes; #cmd("PREFIX")
      three; #cmd("DEST"), #cmd("DA"), #cmd("PR") and #cmd("ACTION") four;
      #cmd("I"), #cmd("O") and #cmd("H") one; #cmd("INIT"), #cmd("WHO") and
      #cmd("PRINT CLOSE") none; #cmd("LOCATE"), #cmd("INPUT"),
      #cmd("FINDLIM"), #cmd("SYSID") and, on the log and the output,
      #cmd("LEFT") and #cmd("RIGHT") one; #cmd("SET") two; #cmd("FIND") five
      words after it; #cmd("PRINT") two line numbers; #cmd("PRINT OPEN") and
      #cmd("PRINT ODSN") three parameters after the word.],
    [#msg("PARM INVALID")], [A parameter of the command is not right. The cursor
      stands on it. @tab-parm-invalid lists what each command refuses.],
    [#msg("INVALID SYNTAX")], [A command or an overtyped value could not be
      read. It is given by #cmd("FIND") (see @ref-messages-find); by
      #cmd("PREFIX") when x or y is longer than one character, when they are
      the same, or when one of them is #cmd("?") or #cmd("&"); by
      #cmd("ACTION ?") when it is not the only word; and by overtyping SFORM, SFCB or
      SEP on the Printer panel with a value that does not fit them.],
    [#msg("INCONSISTENT PARAMETERS")], [Only #cmd("FIND") gives this message
      (see @ref-messages-find).],
    [#msg("NOT AVAILABLE YET")], [The command takes no parameters yet.
      #cmd("LOG") with a parameter on the primary option menu gives it. On any
      other panel #cmd("LOG") with a parameter gives #cmd("INVALID COMMAND").],
  )
]

#tab(caption: [What #cmd("PARM INVALID") refuses])[
  #table(columns: (1.25in, 1fr),
    [Command], [What is refused],
    [#cmd("LOCATE")], [A line that is not a number of up to eight digits (on the
      log, not a time #cmd("hh.mm.ss") either).],
    [#cmd("NEXT"), #cmd("PREV")], [On the output of a job: a parameter that is
      not a number. On the log these commands do nothing and give no message.],
    [#cmd("ST")], [A name longer than eight characters.],
    [#cmd("PREFIX")], [A name longer than eight characters.],
    [#cmd("DA")], [A word that is none of #cmd("JOB"), #cmd("TSU"), #cmd("STC"),
      #cmd("INIT"), #cmd("IN"), #cmd("OUT"), #cmd("TRANS"), #cmd("READY"), also
      with #cmd("O") or #cmd("NO") in front, and #cmd("ALL"), #cmd("ALLT"),
      #cmd("ALLP"); two words with #cmd("O") in front; #cmd("ALL"),
      #cmd("ALLT") or #cmd("ALLP") together with another word.],
    [#cmd("I")], [A parameter other than #cmd("H") or #cmd("NH"), or one longer
      than eight characters.],
    [#cmd("O"), #cmd("H")], [A parameter longer than eight characters.],
    [#cmd("PR")], [A parameter that is not a number, a range #cmd("n-m") from
      the lower to the higher number, #cmd("Rn"), #cmd("LCL") or
      #cmd("RMT"), and any parameter longer than eight characters.],
    [#cmd("INPUT")], [A parameter other than #cmd("ON") or #cmd("OFF").],
    [#cmd("SET")], [A first parameter other than #cmd("HEX"), or a second one
      other than #cmd("ON") or #cmd("OFF").],
    [#cmd("FINDLIM")], [A value that is not a number of 1000 or more with up to
      seven digits.],
    [#cmd("SYSID")], [A system name longer than four characters.],
    [#cmd("ACTION")], [A word that is none of #cmd("ALL"), #cmd("OFF"),
      #cmd("MVS"), #cmd("USER") or a number; #cmd("OFF") together with another
      word.],
    [#cmd("PRINT")], [A line number that is not a number of up to eight digits.
      On a list a range of lines is refused, and the cursor stands on the
      first parameter.],
    [#cmd("PRINT OPEN")], [A class that is not one letter or digit; a number of
      copies outside 1 to 255; forms longer than four characters.],
    [#cmd("PRINT ODSN")], [A data set name longer than 44 characters; a volume
      longer than six characters; a disposition other than #cmd("OLD"),
      #cmd("SHR") or #cmd("MOD").],
  )
] <tab-parm-invalid>

== Scrolling <ref-messages-scroll>

#tab(caption: [Message of scrolling])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("INVALID SCROLL AMOUNT")], [The SCROLL field, the word that you typed
      before a scroll key, or the amount after #cmd("UP"), #cmd("DOWN"),
      #cmd("LEFT") or #cmd("RIGHT") is none of #cmd("PAGE"), #cmd("HALF"),
      #cmd("DATA"), #cmd("CSR"), #cmd("MAX") or a number of one to four digits,
      or is blank. In front of a scroll key you may also type #cmd("P"),
      #cmd("H"), #cmd("D"), #cmd("C") or #cmd("M") for these words. After
      #cmd("UP") or #cmd("DOWN") only the full words are taken, and after
      #cmd("LEFT") or #cmd("RIGHT") on the log and the output the full words
      and #cmd("M") for #cmd("MAX"). When the SCROLL
      field is wrong, the cursor stands on it. Correct the amount.],
  )
]

== FIND <ref-messages-find>

#cmd("FIND") gives the most messages. On the log and on the output of a job it
searches the data; on the lists it searches the rows as the screen shows them.
On a list, #cmd("FIND") takes #cmd("WORD"), #cmd("PREFIX"), #cmd("SUFFIX") and
columns but they make no difference: a list is always searched for the
characters, and its messages have the #cmd("CHARS") form. #cmd("FINDLIM") does
not apply to a list. The command is described in @ref-cmd.

=== The string is found

#tab(caption: [Messages when FIND finds the string])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("CHARS 'x' FOUND")], [FIND found the string. On the log and on the
      output the line goes to the top of the screen and the cursor stands on
      the hit. On a list the row goes to the top and the cursor stands in the
      NP column of that row, not on the string. With #cmd("WORD"),
      #cmd("PREFIX") or #cmd("SUFFIX") on the log and the output the text is
      #cmd("WORD  'x' FOUND"), #cmd("PREFIX 'x' FOUND") or
      #cmd("SUFFIX 'x' FOUND"). The message shows as much of the string as
      fits.],
    [#msg("n CHARS 'x' FOUND")], [The same for FIND with #cmd("ALL"); the screen goes
      to the first hit. On the log and on the output n is the number of hits:
      a line that holds the string twice counts twice. n stands in seven
      columns, and with #cmd("CHARS") and #cmd("WORD") two blanks follow it,
      with #cmd("PREFIX") and #cmd("SUFFIX") one. On a list n is the number of
      rows that hold the string, each row counts once, and one blank follows
      n.],
  )
]

=== The string is not found, or the end is reached

What a search says at the end of the data depends on the panel and on where the
search starts.

On the log and on the output of a job, #cmd("FIND") goes on from the last hit
as long as the screen has not moved. If there is no further hit, nothing
changes: the screen, the cursor and the message of the last hit stay, and no
message of the end is given. A #cmd("FIND") that starts from the screen, the
first one of a string or the first one after you scrolled, searches to the end
of the data. If it finds nothing it says that the end is reached, whether the
string is further back or not. The next #cmd("FIND") then starts at the other
end, and only that one says that the string is nowhere. A search that starts at
the beginning of the data (or backward at its end) searches all of it, and says
at once that the string is not there.

On a list, #cmd("FIND") starts after the row that the cursor is on. After a hit
the cursor stands in the NP column of the hit row, so PF5 (#cmd("RFIND")) goes
on to the next hit, and after the last hit it says that the end is reached. A
#cmd("FIND") that you type on the command line has the cursor there. It starts
at the top row of the screen, so after a hit it finds the same row again. A
search that starts at the first row of the list (at the last one backward) and
finds nothing says at once that the string is not there.

#tab(caption: [Messages when FIND does not find the string])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("*BOTTOM OF DATA REACHED*")], [A #cmd("FIND") that starts from the screen (on
      the log and the output) or after the cursor's row (on a list) went to the
      end of the data without finding the string. The next #cmd("FIND") starts
      over at the top. The asterisks are part of the text.],
    [#msg("* TOP OF DATA REACHED *")], [The same going backward, with
      #cmd("PREV"), #cmd("LAST") or a repeat of one of them: the search went to
      the start of the data without finding the string. The next one starts
      over at the end. The asterisks are part of the text.],
    [#msg("NO CHARS  'x' FOUND")], [FIND looked through all the data: the
      string is not there. With #cmd("WORD"), #cmd("PREFIX") or #cmd("SUFFIX")
      the text is #cmd("NO  WORD  'x' FOUND"), #cmd("NO PREFIX  'x' FOUND") or
      #cmd("NO SUFFIX  'x' FOUND") on the log and the output. A list always
      says #cmd("NO CHARS  'x' FOUND").],
    [#msg("*FINDLIM REACHED*")], [One FIND looked through the number of lines
      that FINDLIM allows and stopped, and the screen went to where it stopped.
      The next #cmd("FIND") goes on from there. Only on the log and on the
      output. Raise the limit with #cmd("FINDLIM") if you want one FIND to go
      further.],
    [#msg("NOT ENOUGH STORAGE")], [The output that FIND searched did not fit
      into storage, so a search that reaches the end says this instead of
      #cmd("NO CHARS  'x' FOUND"): the string may be in the part that was not
      read. See @ref-messages-read.],
  )
]

=== The command cannot be used

#tab(caption: [Messages when the FIND command is wrong])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("INVALID HEX STRING")], [A string #cmd("X'..'") holds something other
      than 0 to 9 and A to F, has an odd number of digits, is empty, or has no
      closing quote. The cursor stands on the string.],
    [#msg("INVALID LEFT BOUNDARY")], [The first column of FIND has more than three
      digits or is beyond the last column of the data: 255 on the log, 256 on
      the output of a job. A column of 0 or one that is not all digits gives
      #cmd("INVALID SYNTAX").],
    [#msg("INVALID RIGHT BOUNDARY")], [The second column of FIND has more than
      three digits or is beyond the last column of the data, as for the first
      column.],
    [#msg("INCONSISTENT PARAMETERS")], [FIND has two of #cmd("NEXT"), #cmd("PREV"),
      #cmd("FIRST"), #cmd("LAST") and #cmd("ALL"), also the same one twice, or
      two kinds (#cmd("CHARS"), #cmd("WORD"), #cmd("PREFIX"), #cmd("SUFFIX"));
      or it has two columns and the string is longer than they are wide.],
    [#msg("INVALID SYNTAX")], [An empty string, or a string in quotes that has no
      closing quote or has more after it; more than one string;
      #cmd("*") (the last string) or no string at all when there was no FIND
      before; a column of 0 or one that is not a number; more than two
      columns.],
    [#msg("TOO MANY PARMS")], [More than five words after FIND.],
  )
]

== ACTION, SYSID and the Log <ref-messages-log>

#tab(caption: [Messages of ACTION, SYSID and LOG])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("ACTION=ALL")], [The answer to #cmd("ACTION ?"): all outstanding
      replies are shown at the end of the log.],
    [#msg("ACTION=OFF")], [The answer to #cmd("ACTION ?"): no replies are shown.],
    [#msg("ACTION=1,2,...")], [The answer to #cmd("ACTION ?"): the replies with
      these routing codes are shown, for example #cmd("ACTION=1,3").],
    [#msg("NO SYSLOG FOUND")], [#cmd("SYSID") names another system than this
      one. SDSF shows only the log of this system, so the log is empty. Give
      #cmd("SYSID") with the name of this system (#cmd("SYSID ?") puts the name
      now in use on the command line).],
    [#msg("LOG NOT READABLE")], [SDSF could not get the authorized state that it
      needs to read the log. Check the SVC routine (@apx-svc) and the access
      (@ref-auth).],
    [#msg("REPLIES NOT READABLE")], [SDSF could not get the authorized state that
      it needs to read the outstanding replies for the end of the log. Check
      the same.],
  )
]

== PRINT <ref-messages-print>

#tab(caption: [Messages of PRINT])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("PRINT OPENED")], [#cmd("PRINT OPEN"), #cmd("PRINT ODSN"), or
      #cmd("PRINT") with no parameters on the log, on a list or on the menu
      when no file is open, opened the file. A first #cmd("PRINT") with line
      numbers opens a SYSOUT file without this message and gives the message
      of the lines or pages that it printed.],
    [#msg("PRINT ALREADY OPEN")], [#cmd("PRINT OPEN") or #cmd("PRINT ODSN") when
      a file is open already. The cursor stands on the word #cmd("OPEN") or
      #cmd("ODSN"). Close the file with #cmd("PRINT CLOSE") first.],
    [#msg("PRINT OPEN ERROR")], [SDSF could not open the file. It does not say
      why.],
    [#msg("PRINT NOT OPENED")], [#cmd("PRINT CLOSE") with no file open. The
      cursor stands on the word #cmd("CLOSE").],
    [#msg("PRINT CLOSED n LINE")], [#cmd("PRINT CLOSE") closed the file. n is the
      number of lines in it, in six columns. The text ends in #cmd("LINE") also
      when n is more than one. A SYSOUT file now goes to print.],
    [#msg("n LINES PRINTED")], [#cmd("PRINT") wrote n lines of the output of a
      job to the file. n stands in ten columns.],
    [#msg("n PAGES PRINTED")], [#cmd("PRINT") wrote n pages of the log to the
      file. n stands in ten columns.],
  )
]

Wrong parameters of PRINT are reported as described under "Parameters of
Commands" earlier in this chapter.

== Action Characters <ref-messages-actions>

The messages in this section come from the characters typed in the NP column.
The overtyping of fields is in the next section. The messages of "The Command
Line: TSO, Operator Commands, Authorization" (#cmd("COMMAND ISSUED"),
#cmd("COMMAND NOT AUTHORIZED")) and #cmd("INVALID COMMAND") are given here as
well.

#tab(caption: [Messages of action characters])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("NOT AUTHORIZED FOR JOB")], [You may not take this action on this job:
      all actions except D, L, ? and S need update access to the job in RAKF.
      Ask the owner or the system programmer for the access (@ref-auth).],
    [#msg("NOT AUTHORIZED FOR INIT")], [The action on an initiator needs update
      access to SDSF.OPER; D needs read access.],
    [#msg("NOT AUTHORIZED FOR PRT")], [The action on a printer needs update
      access to SDSF.OPER; D needs read access.],
    [#msg("JOB NOT FOUND")], [The job has left the queues since SDSF read the
      list, or the row has no JES2 job, as the row of an idle initiator or of an
      address space without a job on DA. Press Enter to read the list again.],
    [#msg("ACTION NOT AVAILABLE YET")], [This panel does not take the action character
      that you typed in the NP column. On I, O and H only ? and S are taken,
      and O on H; on the Job Data Set panel only S. Use the action on ST.],
    [#msg("OUTPUT NOT READABLE")], [On the Job Data Set panel: the data set that
      you chose with S could not be read.],
    [#msg("NOT AUTHORIZED")], [P on the Status panel: SDSF could not get the
      authorized state for the purge. Check the SVC routine (@apx-svc).],
    [#msg("CANNOT CANCEL THIS JOB")], [P on the Status panel: JES2 would not
      cancel the job.],
    [#msg("PURGE FAILED RC n")], [P on the Status panel: JES2 did not purge the
      job. n is the return code that JES2 gave.],
    [#msg("DATA SET DISPLAYED")], [You typed #cmd("ST") on the output of a job.
      The Status panel is read again from the top, and this is its message.],
  )
]

== Overtyping <ref-messages-overtype>

When you overtype fields on several rows, SDSF checks all of the values first.
If it refuses one, it sends nothing, every value that you typed stays where you
typed it, and the cursor stands on the refused one. Only when all are good does
it give the commands. The result of a good overtype is #cmd("COMMAND ISSUED"),
or #cmd("COMMAND NOT AUTHORIZED") when SDSF could not give the command, or
#cmd("NOT AUTHORIZED FOR JOB") and its relatives (see the table below). The
access is checked after the values, and a refusal of it does not stop the other
rows: their commands are given, and the message that stays on the screen is
that of the last field that holds a change.

#tab(caption: [Messages of overtyping])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("FIELD NOT NUMERIC")], [A priority typed over PRTY, or a value typed
      over PGN on DA, holds something other than digits, or more than three
      digits.],
    [#msg("INVALID CLASS")], [A class typed over C on I, over SCLASS on PR or over
      CLASSES on INIT is not A to Z or 0 to 9.],
    [#msg("INVALID DESTINATION NAME")], [A destination typed over DEST (or over
      the destination of a printer), or given with the #cmd("DEST") command, is
      not #cmd("LOCAL"), #cmd("ANYLOCAL"),
      #cmd("Rn"), #cmd("RMn"), #cmd("RMTn") or #cmd("Un"). n is a number of up
      to four digits.],
    [#msg("\"O\" ACTION REQUIRED")], [On H: a new DEST goes only with O in the NP
      column, which releases the job. Type O in the NP column as well, or
      take the new value away.],
    [#msg("INVALID SYNTAX")], [On PR: the value typed over SFORM, SFCB or SEP does
      not fit it.],
    [#msg("INVALID COMMAND")], [On PR: the row is not a printer.],
    [#msg("NOT AUTHORIZED FOR JOB")], [The change needs update access to the job.
      The overtyping of PGN on DA for a job gives it too.],
    [#msg("NOT AUTHORIZED FOR INIT")], [The change on INIT needs update access to
      SDSF.OPER.],
    [#msg("NOT AUTHORIZED FOR PRT")], [The change on PR needs update access to
      SDSF.OPER.],
    [#msg("NOT AUTHORIZED FOR CMD")], [The overtyping of PGN on DA for an address
      space that has no job needs update access to SDSF.OPER.],
  )
]

== Reading the Queues and the Output <ref-messages-read>

#tab(caption: [Messages when a list or an output is read])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("JES2 NOT READABLE")], [SDSF could not read the JES2 queues. Press
      Enter to read the list again.],
    [#msg("NOT ENOUGH STORAGE")], [The list or the output does not fit into the
      storage that SDSF has. On the output, what fits is shown. Log on with a
      larger region.],
    [#msg("NO ANSWER FROM JES2")], [PR or INIT: JES2 did not answer within a few
      seconds, or SDSF could not read the log while it waited for the answer.
      Press Enter.],
  )
]

== Help <ref-messages-help>

These messages appear on the title line of the help panels, except
#cmd("HELP NOT AVAILABLE"), which appears on the panel from which you asked for
the help.

#tab(caption: [Messages of the help])[
  #table(columns: (2.5in, 1fr),
    [Message], [Meaning and action],
    [#msg("END OF TOPIC")], [The help panel names neither a next panel
      nor a panel above it, and you pressed Enter. The help panels that SDSF
      ships all name one, so you see this message only on a panel of your own.
      Type #cmd("T") to see the contents.],
    [#msg("INVALID OPTION")], [What you typed is not a topic of this panel,
      nor one of the words that the help takes: #cmd("T") (#cmd("TOP")),
      #cmd("I") (#cmd("INDEX")), #cmd("HELP"), #cmd("UP"), #cmd("DOWN"),
      #cmd("LEFT"), #cmd("RIGHT"), #cmd("BACK"), #cmd("END") and
      #cmd("RETURN"). SDSF commands do not work in the help.],
    [#msg("NO HELP FOR THIS PANEL YET")], [The help of the panel is not there.
      The contents are shown instead.],
    [#msg("PANEL NOT FOUND")], [The panel of the topic that you chose is not
      there. The panel before stays. The _SDSF User's Guide_ says in which data
      sets the help panels belong.],
    [#msg("HELP NOT AVAILABLE")], [The help panels could not be shown at all:
      they are not in the ISPPLIB concatenation. The _SDSF User's Guide_ says
      where they go.],
  )
]
