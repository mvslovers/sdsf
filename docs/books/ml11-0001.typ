#import "bookmaster/bookmaster.typ": *

#show: book.with(
  title: "SDSF for MVS 3.8j",
  subtitle: "User's Guide",
  short-title: "SDSF User's Guide",
  product: "SDSF",
  number: "ML11-0001-0",
  date: "November 2026",
  authors: ("Mike Großmann",),
  edition: [
    #text(font: head-font, weight: "bold", size: 11pt)[Draft (November 2026)]

    This edition applies to Version 1 Release 2 of SDSF, the spool and
    system display facility for MVS 3.8j (sdsf 1.2.0), and to all subsequent
    releases and modifications until otherwise indicated in new editions.

    *Draft.* SDSF 1.2 is still in development, and so is this book. It
    describes the state of the main branch of the repository.

    Comments on this book may be addressed to the issue tracker of the
    mvslovers/sdsf repository on GitHub.

    © Copyright Mike Großmann 2026. All rights reserved.
  ],
)

#part("index.html", title: [SDSF User's Guide])[
#titlepage()
#contents()
#figures()

#heading(numbering: none)[About This Book] <about>

This book shows how to use SDSF (sdsf), the spool and system display
facility for MVS 3.8j under ISPF: how to look at jobs and their output, how
to watch the running system and the system log, how to work with printers and
initiators, who may do what, and how SDSF is installed and removed. Every
command, panel, action character and authorization rule is described in full
in the companion volume, the _SDSF Reference_.

== How This Book Is Organized

#deflist(width: 1.35in,
  [Chapter 1], [“Introducing SDSF”: what SDSF is, who it is for, and the
    conventions of this book.],
  [Chapter 2], [“Getting Started”: starting SDSF from ISPF, the command line,
    PF keys, the NP column, scrolling and the profile.],
  [Chapter 3], [“Looking at Jobs”: the status panel, the prefix and classes,
    and the Job Data Set and Output Data Set panels.],
  [Chapter 4], [“The Queues”: the input, held output and output queues.],
  [Chapter 5], [“The Running System”: the active address spaces and the
    PF11 pages.],
  [Chapter 6], [“The System Log and Operator Work”: the log, outstanding
    replies, operator and TSO commands, system and destination.],
  [Chapter 7], [“Printers and Initiators”: the two panels and the actions that
    go to JES2.],
  [Chapter 8], [“Searching and Navigating Output”: finding text, locating
    lines, columns, hexadecimal display and moving between data sets.],
  [Chapter 9], [“Who May Do What”: your own jobs, the spool class, the operator
    profile, with worked RAKF examples.],
  [Chapter 10], [“Installing and Removing SDSF”: the short path, and
    troubleshooting.],
  [Appendix A], [“Glossary”.],
)

== Related Publications

#deflist(width: 1.35in,
  [ML11-0002], [_SDSF Reference_: the commands, the panels, the action
    characters, the authorization rules, the differences from IBM's SDSF V1R2,
    and the messages.],
)

#mainmatter()
]
#set page(numbering: "1")

#part("ug-intro.html", include "guide/ug-intro.typ")
#part("ug-start.html", include "guide/ug-start.typ")
#part("ug-jobs.html", include "guide/ug-jobs.typ")
#part("ug-queues.html", include "guide/ug-queues.typ")
#part("ug-running.html", include "guide/ug-running.typ")
#part("ug-log.html", include "guide/ug-log.typ")
#part("ug-devices.html", include "guide/ug-devices.typ")
#part("ug-search.html", include "guide/ug-search.typ")
#part("ug-access.html", include "guide/ug-access.typ")
#part("ug-install.html", include "guide/ug-install.typ")

#show: appendices
#part("ug-glossary.html", include "guide/ug-glossary.typ")

#part("index-terms.html", title: [Index])[
#heading(numbering: none)[Index]
#make-index()
]
