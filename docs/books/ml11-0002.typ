#import "bookmaster/bookmaster.typ": *

#show: book.with(
  title: "SDSF for MVS 3.8j",
  subtitle: "Reference",
  short-title: "SDSF Reference",
  product: "SDSF",
  number: "ML11-0002-0",
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

#part("index.html", title: [SDSF Reference])[
#titlepage()
#contents()
#figures()

#heading(numbering: none)[About This Book] <about>

This book describes SDSF (sdsf), the spool and system display facility for
MVS 3.8j, in full: the commands, the panels with their columns and fields,
the action characters and the JES2 or MVS command each one issues, the
authorization rules, the differences from IBM's SDSF V1R2, and the messages.
How to use them together is the subject of the companion volume, the _SDSF
User's Guide_.

== How This Book Is Organized

#deflist(width: 1.35in,
  [Chapter 1], [“Commands”.],
  [Chapter 2], [“Panels”.],
  [Chapter 3], [“Action Characters”.],
  [Chapter 4], [“Authorization”.],
  [Chapter 5], [“Differences from IBM's SDSF V1R2”.],
  [Chapter 6], [“Messages”.],
  [Appendix A], [“PF Key Assignments”.],
  [Appendix B], [“Data Sets and Members of the Package”.],
  [Appendix C], [“The SVC Routine”.],
)

== Related Publications

#deflist(width: 1.35in,
  [ML11-0001], [_SDSF User's Guide_: starting SDSF, looking at jobs, queues,
    the running system and the log, printers and initiators, searching output,
    and installing and removing SDSF.],
)

#mainmatter()
]
#set page(numbering: "1")

#part("ref-cmd.html", include "ref/ref-cmd.typ")
#part("ref-panels.html", include "ref/ref-panels.typ")
#part("ref-actions.html", include "ref/ref-actions.typ")
#part("ref-auth.html", include "ref/ref-auth.typ")
#part("ref-diff.html", include "ref/ref-diff.typ")
#part("ref-messages.html", include "ref/ref-messages.typ")

#show: appendices
#part("apx-pfkeys.html", include "ref/apx-pfkeys.typ")
#part("apx-package.html", include "ref/apx-package.typ")
#part("apx-svc.html", include "ref/apx-svc.typ")

#part("index-terms.html", title: [Index])[
#heading(numbering: none)[Index]
#make-index()
]
