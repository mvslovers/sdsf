#import "../bookmaster/bookmaster.typ": *

= Who May Do What <ug-access>

#idx("authorization")#idx("RAKF")
SDSF decides who may see and do what by asking RAKF, the security product of
MVS 3.8j. SDSF keeps no list of users of its own and has no parameter module:
the rules are RAKF profiles, and the access levels of RAKF are the levels of
SDSF. This chapter tells you, as a user, what to expect, and tells the system
programmer how to give people what they need. It shows the rules by example.
The complete rules, every check SDSF makes and every message of a refusal are
in the chapter "Authorization" of the _SDSF Reference_.

There are two kinds of rule:

- *Jobs.* The jobs you own are always yours. For the jobs of other users SDSF
  asks RAKF about each job, in the class JESSPOOL, which this book calls the
  spool class.
- *The system.* The log, the printers, the initiators, the operator commands
  and the address spaces without a job are guarded by one profile in the class
  FACILITY, #cmd("SDSF.OPER"), the operator profile.

For the log, for operator commands and for purging a job SDSF needs one more
thing besides RAKF, the authorized state. It is described at the end of
"The Operator Profile".

== Your Own Jobs <ug-access-own>

#idx("own jobs")
The jobs that run under your user id are yours. You see them on every list
and you may do to them everything the panel offers. SDSF does not ask RAKF
about them, so no profile can take them away from you or limit what you do
with them. You need no profile at all to work with your own jobs.

SDSF finds the owner of a job like this:

- A batch job belongs to the user id given with #cmd("USER=") on the job card.
- A TSO session belongs to the user whose name it carries. Your own TSO
  session is therefore among your own jobs, and DA shows it.
- A started task belongs to #cmd("SYSTEM"), so it is not yours.
- A job for which none of this gives an owner counts as yours when its name
  begins with your user id.

For example, you are #cmd("HERC02"). A batch job #cmd("PAYROLL") with
#cmd("USER=HERC02") on its job card is yours. So is a job #cmd("HERC02A")
that was submitted without #cmd("USER="), because it has no owner and its name
begins with your user id. A job with #cmd("USER=HERC03") on its job card
belongs to #cmd("HERC03"), whatever its name is.

Your own jobs can still be left out of a list: #cmd("PREFIX"), #cmd("DEST")
and the filters of the panels narrow what a list shows, for your own jobs as
for all others (@ug-jobs). They never give you a job that RAKF does not allow.

A user who has no other access sees nothing but these jobs. ST, I, O and H
list the own jobs. DA lists the address spaces of the own jobs, among them the
own TSO session, but not the master scheduler or JES2. #cmd("LOG"),
#cmd("PR") and #cmd("INIT") answer `COMMAND NOT AUTHORIZED` in the title line,
and a #cmd("/") command answers `NOT AUTHORIZED FOR CMD`.

== Other Users' Jobs and the Spool Class <ug-access-spool>

#idx("JESSPOOL")#idx("spool class")#idx("entity")
For a job that is not yours, SDSF asks RAKF for an access level to the job in
the class JESSPOOL. The *entity*, the name that SDSF asks about, is made of
the owner, the job name and the job id, separated by periods. The job id is the
job type, #cmd("JOB"), #cmd("STC") or #cmd("TSU"), followed by the job number
in five digits. Three examples:

#deflist(width: 2.6in,
  [#cmd("HERC02.PAYROLL.JOB01234")], [a batch job of HERC02],
  [#cmd("HERC02.HERC02.TSU00012")], [the TSO session of HERC02],
  [#cmd("SYSTEM.TCAS.STC00007")], [the started task TCAS],
)

RAKF answers from the *profile* that covers the entity. SDSF asks for one of
two access levels, which this book calls *read access* and *update access*.
RAKF has the higher levels CONTROL and ALTER too, and a user who has one of
them has update access in SDSF.
#idx("read access")#idx("update access")#idx("profile")

#tab(caption: [What access to a job of another user gives])[
  #table(columns: (1.2in, 1fr),
    table.header([Access to the job], [What you can do],),
    [None, or no profile],
      [Nothing: the job is on no list, and so nothing can be done to it.],
    [Read],
      [The job is on the lists (ST, DA, I, O and H). You can look at its data
       sets and its output with #cmd("?") and #cmd("S"), and on ST and DA use
       #cmd("D") and #cmd("L").],
    [Update],
      [Everything above, and every action character and overtype that changes
       the job: #cmd("C"), #cmd("CD"), #cmd("P"), #cmd("A"), #cmd("H"),
       #cmd("E"), #cmd("O"), and overtyping the fields of its row.],
  )
]

A job that you may not read is not refused with a message. It is just not on
the list: the Status panel shows the jobs you may see and no others, and on DA
the address space of such a job is missing. You cannot type an action
character on a row that is not there.

With read access to a job you can see it and its output, but you cannot change
it. Suppose #cmd("HERC03") has read access to the jobs of #cmd("HERC02"), and
the job #cmd("PAYROLL") of #cmd("HERC02") is on the Status panel. #cmd("HERC03")
types #cmd("S") in the NP column of that row and browses the output. Typing
#cmd("C") there instead, to cancel the job, brings
`NOT AUTHORIZED FOR JOB` in the title line, and the job runs on. With update
access to the job, the #cmd("C") works.
#idx("NOT AUTHORIZED FOR JOB")

SDSF asks when it first needs an answer and keeps it until it next reads the
jobs for a panel, which happens each time a list is displayed or redisplayed.
A change of the profiles takes effect when SDSF next shows a list, once RAKF
has loaded the new profiles. You need not leave SDSF.

=== Which Profile Covers a Job <ug-access-cover>

Two things about the way RAKF matches the entity matter when you write
profiles.

*RAKF looks at the first eight characters only.* It cuts a JESSPOOL entity to
its first eight characters before it looks for a profile, and does not
compare what follows. For an owner of seven or eight characters, those eight
begin with the owner's name. For a shorter owner, such as #cmd("HERC02") or
#cmd("SYSTEM"), the first characters of the job name are among them. A profile
such as #cmd("HERC02.P*") therefore decides for the jobs of #cmd("HERC02")
whose names begin with P, and the profile #cmd("*") decides for all jobs. A
profile cannot tell jobs apart by more than these eight characters. A job
without an owner, whose name does not begin with your user id, is asked about
as #cmd(".jobname.jobid"), with nothing before the first period. Its entity
starts with the period, so no profile that begins with an owner's name covers
it; only a profile such as #cmd("*") does.

*The profile that sorts last wins.* Several profiles can cover one entity.
The one that sorts last in EBCDIC order is used, not the most specific one:
#cmd("OWN*") wins over #cmd("OWN.*"). A profile that wins replaces the lines
of the others: every group that needs access to the jobs it covers must have a
line of its own in it.
#idx("profile", "which wins")

== The Operator Profile <ug-access-oper>

#idx("SDSF.OPER")#idx("FACILITY")#idx("operator profile")
The profile #cmd("SDSF.OPER") in the class FACILITY guards everything that
does not belong to a job: the system log, the printers and the initiators,
the operator commands given with #cmd("/"), and the address spaces that run no
job, such as the master scheduler or JES2. Again SDSF asks for read access or
update access.

#tab(caption: [What access to SDSF.OPER gives])[
  #table(columns: (1.2in, 1fr),
    table.header([Access to SDSF.OPER], [What you can do],),
    [None, or no profile],
      [Nothing of the system. The own jobs, and the jobs of others as the
       spool class allows. #cmd("LOG"), #cmd("PR") and #cmd("INIT") answer
       `COMMAND NOT AUTHORIZED`, a #cmd("/") command
       `NOT AUTHORIZED FOR CMD`. On DA, the rows without a job are missing.],
    [Read],
      [The #cmd("LOG") command, with the outstanding replies that
       #cmd("ACTION") appends to it. The #cmd("PR") and #cmd("INIT") commands,
       and #cmd("D") on a printer or an initiator. On DA, the address spaces
       without a job.],
    [Update],
      [Everything above, and operator commands with #cmd("/"), the other
       action characters and overtypes on printers and initiators, and the
       PGN overtype on a DA row without a job.],
  )
]

Without the access, the title line shows a message:
`COMMAND NOT AUTHORIZED` for #cmd("LOG"), #cmd("PR") and #cmd("INIT"),
`NOT AUTHORIZED FOR CMD` for a #cmd("/") command,
`NOT AUTHORIZED FOR PRT` and `NOT AUTHORIZED FOR INIT` for an action on a
printer or an initiator.
#idx("COMMAND NOT AUTHORIZED")#idx("NOT AUTHORIZED FOR CMD")
#idx("NOT AUTHORIZED FOR PRT")#idx("NOT AUTHORIZED FOR INIT")

Three things to know before you give access to this profile:

- *The log is open as a whole.* The log holds the messages of every job, the
  commands and replies of the operators and the failed logons. SDSF cannot
  tie a line of it to an owner. A user with read access to #cmd("SDSF.OPER")
  can read all of it.
- *Update access allows every operator command.* SDSF does not look at the
  text of a command given with #cmd("/"). Whoever has update access to
  #cmd("SDSF.OPER") can give any operator command.
- *The device decides, not its job.* An action on a printer or an initiator
  asks for #cmd("SDSF.OPER") only, not for the access to the job that the
  device is working on.

The profile #cmd("SDSF.OPER") and the spool class are independent. Read access
to #cmd("SDSF.OPER") does not show you the jobs of others: that needs access to
the jobs, as described in @ug-access-spool.

=== The Authorized State <ug-access-state>

#idx("authorized state")
Reading the log and the outstanding replies, purging a job, and giving JES2
and operator commands need an authorized program, and SDSF runs unauthorized.
For the moments it needs, SDSF asks for the authorized state. This is a second
condition, independent of RAKF: both must hold. A user with update access to
#cmd("SDSF.OPER") still gets `COMMAND NOT AUTHORIZED` for a command if SDSF
cannot enter the authorized state.

SDSF enters it through an SVC routine of its own, installed with SDSF
(@ug-install). Where that is not installed, or where it refuses the call
because SDSF was not loaded from an APF-authorized library, SDSF uses SVC 244.
Then only users who have read access to the FACILITY profile #cmd("SVC244")
can do these things. The Reference describes the routine in the appendix "The
SVC Routine".
#idx("SVC 244")

When SDSF cannot enter the authorized state, it says so in the title line:

#tab(caption: [Messages when the authorized state is missing])[
  #table(columns: (1.9in, 1fr),
    table.header([Message], [When],),
    [`COMMAND NOT AUTHORIZED`],
      [An action character or overtype that gives a command, a #cmd("/")
       command, and #cmd("PR") and #cmd("INIT").],
    [`LOG NOT READABLE`], [The #cmd("LOG") panel cannot read the log.],
    [`REPLIES NOT READABLE`],
      [The outstanding replies at the end of the log cannot be read.],
    [`NOT AUTHORIZED`], [#cmd("P") on the Status panel.],
  )
]

#cmd("?") and #cmd("S") need no authorized state.

== Worked RAKF Examples <ug-access-examples>

The RAKF profiles are lines in a table; on TK5 and MVS/CE it is the member
#cmd("PROFILES") of #cmd("SYS1.SECURE.CNTL"). The class stands in columns 1 to
8, the profile from column~9, the group from column~53 and the access from
column~61. For each profile the line without a group is the universal
access, the access of every user, and it must be there: with RAKF 2.0.0 the
load of the table stops with the abend U0400 if a profile has a line for a
group but no line without a group, and RAKF then keeps the table it had.
RAKF 2.0.0 also sorts the table itself when it loads it, so the order of the
lines does not matter; a line that appears twice for the same class, profile
and group stops the load with the abend U0300, even if the access differs.
With an earlier RAKF, keep the table in sort order, the line without a group
first. The examples keep the lines of one profile together and the line
without a group first, which is right for every RAKF release and easy to read.
#idx("profile table")

After you change the table, RAKF must load it before the profiles take
effect: with RAKF 2.0.0, start the procedure #cmd("RAKFPROF")
(#cmd("S RAKFPROF")). SDSF sees the new profiles when it next shows a list.

=== Everyone Sees Their Own Jobs, One Group May Do Everything <ug-access-ex1>

#screen(```
FACILITYSDSF.OPER                                           NONE
FACILITYSDSF.OPER                                   ADMIN   UPDATE
JESSPOOL*                                                   NONE
JESSPOOL*                                           ADMIN   UPDATE
```)

The universal access is NONE, so a user sees the own jobs only. The group
ADMIN has update access to #cmd("SDSF.OPER") and to every job: it sees and
handles all jobs, the log, the printers and the initiators, and may give
operator commands.

With RAKF 2.0.0 the profile for #cmd("SDSF.OPER") can also be made with the
RAKF commands. They write the same lines into the table and need the reload
as well:

#screen(```
RDEFINE SDSF.OPER CLASS(FACILITY) UACC(NONE)
PERMIT SDSF.OPER CLASS(FACILITY) ID(ADMIN) ACCESS(UPDATE)
```)

=== Everyone May Look at All Jobs <ug-access-ex2>

#screen(```
FACILITYSDSF.OPER                                           NONE
FACILITYSDSF.OPER                                   ADMIN   UPDATE
JESSPOOL*                                                   READ
JESSPOOL*                                           ADMIN   UPDATE
```)

The universal access of the profile #cmd("*") is READ. Every user sees all
jobs and their output and can use #cmd("D") and #cmd("L"), but cannot change a
job of another user. The system stays closed to them, as in the first example.

=== Operators Read the Log, Administrators May Do Everything <ug-access-ex3>

#screen(```
FACILITYSDSF.OPER                                           NONE
FACILITYSDSF.OPER                                   ADMIN   UPDATE
FACILITYSDSF.OPER                                   OPER    READ
JESSPOOL*                                                   NONE
JESSPOOL*                                           ADMIN   UPDATE
JESSPOOL*                                           OPER    READ
```)

A user of the group OPER has read access to #cmd("SDSF.OPER") and read access
to every job. The user sees the log, the printers, the initiators and all jobs
and address spaces, and can use #cmd("D") on a printer or an initiator, but
cannot give a #cmd("/") command and cannot change a job.

=== One Group Looks at the Jobs of One User <ug-access-ex4>

Add these lines to the JESSPOOL lines of the first example, after the lines of
#cmd("*"):

#screen(```
JESSPOOLHERC02.*                                            NONE
JESSPOOLHERC02.*                                    ADMIN   UPDATE
JESSPOOLHERC02.*                                    TEAM    READ
```)

The group TEAM now has read access to the jobs whose owner is #cmd("HERC02").
A job of HERC02 that has no owner, such as #cmd("HERC02A") submitted without
#cmd("USER="), is asked about as #cmd(".HERC02A"); this profile does not cover
it, and #cmd("*") decides for it. For the jobs of the other users nothing
changes. The profile #cmd("HERC02.*") sorts after
#cmd("*"), so it is the one that counts for the jobs of #cmd("HERC02")
(@ug-access-cover). It replaces the lines of #cmd("*") for these jobs, which is
why it repeats the line of ADMIN: without it, ADMIN would get the universal
access NONE for the jobs of #cmd("HERC02"). Write #cmd("HERC02.P*") instead to
limit it to the jobs of #cmd("HERC02") whose names begin with P.

=== Checking a Profile <ug-access-check>

Reload the table and log on as a user of the group in question. #cmd("WHO")
shows the user id that SDSF works with. Then look at what the user sees:

- On ST, I, O and H, the jobs of other users appear as far as the spool class
  allows.
- #cmd("LOG"), #cmd("PR") and #cmd("INIT") open, or answer
  `COMMAND NOT AUTHORIZED`.
- A #cmd("/") command is given, or answers `NOT AUTHORIZED FOR CMD`.
- On DA the master scheduler and JES2 are on the list, or they are not.

A user who has no access sees only the own jobs and meets the refusals
described under "Your Own Jobs". Use such a user to check that a profile does
not give too much.

== When RAKF Has No Spool Class <ug-access-nospool>

#idx("no profile")
SDSF accepts the answer "permitted" and no other. If RAKF has no profile for
the entity of a job, it answers "no profile", and SDSF treats that as a
refusal, as it treats an access level that is too low. Where RAKF has no
JESSPOOL profile for the jobs of other users, for example because the profile
table has none at all, you see nothing of them:

- ST, I, O and H list your own jobs only.
- DA lists the address spaces of your own jobs, and the rows without a job
  only if you have read access to #cmd("SDSF.OPER").
- A job of another user cannot be shown, browsed or changed, and no message
  says so: the job is just not there.

SDSF does not fall back to something more lenient: there is no setting that
lets it show every job without RAKF, and no default for a missing profile
that shows the jobs of others.

The profile #cmd("SDSF.OPER") works the same way. Without a profile for it,
nobody has access to the system, and #cmd("LOG"), #cmd("PR"), #cmd("INIT") and
#cmd("/") commands are refused for everyone.

The two kinds of rule are independent. A user with update access to
#cmd("SDSF.OPER") but no JESSPOOL profile can read the log and give operator
commands, and sees the own jobs and the address spaces without a job, but not
the jobs of other users. To let everyone see the jobs, define the profile
#cmd("*") in the class JESSPOOL with the universal access READ
(@ug-access-ex2). To give a group more, add a line with the group
(@ug-access-ex1).
