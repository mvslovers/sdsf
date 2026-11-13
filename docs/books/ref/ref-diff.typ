#import "../bookmaster/bookmaster.typ": *

= Differences from IBM's SDSF V1R2 <ref-diff>

SDSF is modelled on what IBM's SDSF V1R2 shows and does: the panels, their
titles, headings and columns, the colours, the action characters, the
overtypeable fields and the messages. This chapter lists where SDSF 1.2.0
departs from it in what you see and type, and what SDSF does not do yet.
#idx("IBM's SDSF V1R2")#idx("differences")

A difference is listed only where it is known. Where this chapter
says nothing about a command or a panel, it does not claim that the two are
alike. The names of panels, commands and columns are those of the screen; the
chapters named in the tables describe each item in full.

== Where SDSF Differs <ref-diff-differs>

In each of these SDSF shows or does something other than IBM's SDSF V1R2.

#tab(caption: [Differences in behaviour])[
  #table(columns: (1.3in, 1fr, 1fr),
    table.header([Item], [SDSF], [IBM's SDSF V1R2],),
    [The log (#cmd("LOG"))],
      [Reads the master trace table, the log that the system keeps in storage,
       so the oldest lines drop out as new ones come. The title shows
       #cmd("MTT") where the data set of the log would be. See
       @ref-panels-log.],
      [Shows the system log data set; the title names the job and the data
       set number.],
    [The heading of #cmd("PRINT") on the log],
      [Names #cmd("MTT") and today's date. See @ref-cmd-print.],
      [Names the job and the data set of the system log.],
    [Replies on the log],
      [The outstanding replies at the end of the log are in high intensity.
       See @ref-cmd-action.],
      [They are white.],
    [#cmd("INPUT ON")],
      [Adds the JCL and the data in the stream of a job to its data sets. The
       other data sets keep their DD names, such as #cmd("JESMSGLG") and
       #cmd("JESJCL"). See @ref-cmd-input.],
      [Also shows the data sets of JES2 under other names, such as
       #cmd("$JES2LOG") and #cmd("$JCLIMG").],
    [Action character #cmd("L")],
      [Gives #cmd("$L") with the job, as @ref-actions-cmds shows.],
      [Gives the same command with the operand #cmd("ALL") added.],
    [#cmd("COLS") and #cmd("RESET")],
      [Work on the Output Data Set panel and on the log only. See
       @ref-cmd-cols.],
      [Work on the list panels too; the title then shows the columns.],
    [#cmd("WHO")],
      [Shows #cmd("USER-ID="), #cmd("LOGON-PROC=") and
       #cmd("TERMINAL-NAME="). See @ref-cmd-who.],
      [Also shows #cmd("GROUP-INDEX=").],
    [PRTY and C on the Input Queue panel],
      [One field; type over either part. See @ref-panels-i.],
      [Two fields, each with its own stop of the Tab key.],
    [The DA title],
      [#cmd("SIO") and #cmd("CPU") are 0 the first time the panel is shown,
       since SDSF measures the rates between two displays. See
       @ref-panels-da.],
      [Shows #cmd("CPU") already on the first display.],
  )
]

== What SDSF Does Not Do Yet <ref-diff-missing>

These are gaps: the panel, the command or the column is there, but the
function behind it is not built.

#tab(caption: [Gaps])[
  #table(columns: (1.5in, 1fr),
    table.header([Item], [What SDSF does],),
    [Action characters on I, O and H],
      [I and O take #cmd("?") and #cmd("S"), H also #cmd("O"). Any other
       character answers #cmd("ACTION NOT AVAILABLE YET") and does not stay in
       the NP column. The Job Data Set panel takes #cmd("S") only. See
       @ref-actions-panels.],
    [Overtyping on O and H],
      [Only #cmd("DEST") can be overtyped. See @ref-actions-overtype.],
    [Columns left blank],
      [The Job Data Set, Input Queue, Held Output and Output Queue panels have
       headings that SDSF does not fill: the columns stay blank. The sections
       @ref-panels-jds, @ref-panels-i, @ref-panels-h and @ref-panels-o name
       them.],
    [Printer columns],
      [On the Printer panel #cmd("WORK-SELECTION"), #cmd("SBURST"),
       #cmd("SPRMODE1"), #cmd("SEPDS"), #cmd("CKPTLINE") and #cmd("CKPTPAGE")
       show the JES2 defaults for every printer. SDSF does not read the value
       of the printer. See @ref-panels-pr.],
    [#cmd("PAGING") on DA],
      [Always #cmd("0.00"), in the title and in the column. See
       @ref-panels-da.],
    [#cmd("DA TRANS"), #cmd("DA READY")],
      [Accepted, but they select no address space. See @ref-cmd-da.],
    [#cmd("LOG") with a parameter],
      [Answers #cmd("NOT AVAILABLE YET"). See @ref-panels-log.],
  )
]

== What SDSF Adds <ref-diff-adds>

#cmd("ACTION ?") shows the setting in the title line, as #cmd("ACTION=OFF"),
#cmd("ACTION=ALL") or a list of routing codes, and clears the command line. In
IBM's SDSF V1R2 the command shows nothing. See @ref-cmd-action.

== Authorization and Messages <ref-diff-auth>

SDSF asks RAKF who may see and do what. @ref-auth describes the rules.

The messages are those of SDSF, among them those of #cmd("ACTION"),
#cmd("FIND"), #cmd("LOCATE"), #cmd("DEST"), #cmd("PRINT") and #cmd("TSO"), and
#cmd("COMMAND ISSUED"). Where a function is not built, the message says so with
#cmd("NOT AVAILABLE YET"). All messages are listed in @ref-messages.
