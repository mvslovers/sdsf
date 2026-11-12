#import "../bookmaster/bookmaster.typ": *

= Authorization <ref-auth>

SDSF decides who may see and do what by asking RAKF, the security product of
MVS 3.8j. SDSF has no parameter module, no groups of users of its own, no
level per action and no user exit. The rules are RAKF profiles, and the
access levels of RAKF are the levels of SDSF.
#idx("authorization")#idx("RAKF")

There are two kinds of rule:

- *Jobs.* The jobs you own are always yours. For the jobs of other users SDSF
  asks RAKF about the job in the class JESSPOOL.
- *The system.* The log, the printers, the initiators, the operator commands
  and the address spaces without a job are guarded by one FACILITY profile,
  #cmd("SDSF.OPER").

This chapter describes the profiles and what SDSF asks of them
(@ref-auth-profiles), what each access level allows and denies
(@ref-auth-levels and @ref-auth-denies), every check SDSF makes
(@ref-auth-checks), the authorized state that SDSF needs besides RAKF
(@ref-auth-state), and the messages of a refusal (@ref-auth-messages). The
action characters are described in @ref-actions, the panels in @ref-panels.
How a system programmer sets the profiles up is part of the installation,
described in the companion volume, the _SDSF User's Guide_.

== Profiles, Classes and Entities <ref-auth-profiles>

A *profile* is a rule in a RAKF *class*. SDSF asks RAKF whether the logged-on
user has an access level to an *entity*, the name of the thing in question, and
RAKF answers from the profile that covers the entity. SDSF uses two classes.
#idx("profile")#idx("class")#idx("entity")

#tab(caption: [The classes and entities SDSF asks about])[
  #table(columns: (1.1in, 2.4in, 1fr),
    table.header([Class], [Entity], [Guards],),
    [JESSPOOL], [#var("owner")#cmd(".")#var("jobname")#cmd(".")#var("jobid")],
      [a job of another user],
    [FACILITY], [#cmd("SDSF.OPER")], [the system],
  )
]
#idx("JESSPOOL")#idx("FACILITY")#idx("SDSF.OPER")

RAKF is always asked about the user who is logged on.

=== Your own jobs <ref-auth-own>

#idx("own jobs")
Authorization never hides a job you own and never refuses an action on it.
SDSF does not ask RAKF about them, so no profile can take them away. Which
action characters a panel takes at all is described in @ref-actions\; the
lists can still be narrowed by #cmd("PREFIX"), #cmd("DEST") and the filters of
the panels.

SDSF finds the owner of a job as follows:

- For a batch job, the owner is the user id given with #cmd("USER=") on the
  job card.
- For a TSO user, the owner is the user's own name.
- For a started task, the owner is #cmd("SYSTEM").
- If none of these gives an owner, SDSF takes the owner from the job control
  table of the job, if that names one. JES2 4.1 leaves that field blank, so on
  MVS 3.8j this does not give an owner.

A job is yours when its owner is your user id. A job without any owner counts
as yours when its name begins with your user id.

=== The class JESSPOOL <ref-auth-jesspool>

For a job that is not yours, SDSF asks RAKF for the entity
#var("owner")#cmd(".")#var("jobname")#cmd(".")#var("jobid") in the class
JESSPOOL. The job id is the job type, #cmd("JOB"), #cmd("STC") or #cmd("TSU"),
followed by the job number in five digits. Examples:

#deflist(width: 2.6in,
  [#cmd("HERC02.PAYROLL.JOB01234")], [a batch job of HERC02],
  [#cmd("HERC02.HERC02.TSU00012")], [the TSO session of HERC02],
  [#cmd("SYSTEM.TCAS.STC00007")], [the started task TCAS],
)

A job that has no owner, and whose name does not begin with your user id, is
asked about as #cmd(".")#var("jobname")#cmd(".")#var("jobid"), with nothing in
front of the first period.

#note[RAKF cuts a JESSPOOL entity to its first eight characters before it looks
for a profile and does not compare what follows. For an owner of seven or
eight characters those eight begin with the owner's name. For a shorter owner, such as
#cmd("SYSTEM") or #cmd("HERC02"), and for a job without an owner, the first
characters of the job name are among them. SDSF follows the answer of RAKF for
every job: it remembers an answer for each first eight characters of the entity
until it next reads the lists, and that is the part RAKF compares. A profile
such as #cmd("HERC02.P*") therefore decides for the jobs of HERC02 whose names
begin with P, and the profile #cmd("*") for all jobs.]
#idx("JESSPOOL", "entity length")

Without a JESSPOOL profile, every question about a job of another user is
answered "no profile" (@ref-auth-when), and you see your own jobs only.

=== The profile SDSF.OPER <ref-auth-oper>

The entity #cmd("SDSF.OPER") in the class FACILITY guards everything that does
not belong to a job: the system log, the printers and the initiators, operator
commands given with #cmd("/"), and the address spaces that run no job, such as
the master scheduler or JES2. SDSF asks for read access or update access to
it, as @ref-auth-levels describes.

The log holds the messages of every job, the commands and replies of the
operators and the failed logons. SDSF cannot tie a line of it to an owner, so
the log is open to a user with read access to #cmd("SDSF.OPER") as a whole.

=== When SDSF asks RAKF <ref-auth-when>

SDSF asks when it first needs an answer and keeps the answer until it next
reads the jobs for a panel, which happens each time a list is displayed or
redisplayed. A change of the profiles, once RAKF has loaded them, therefore
takes effect when SDSF next shows a list; you need not leave SDSF.

*Only a permit allows.* SDSF accepts the answer "permitted" and no other. If
no profile covers the entity, RAKF answers "no profile", and SDSF treats that
as a refusal, as it treats an access level that is too low. Without a profile
for #cmd("SDSF.OPER") nobody has access to the system, and without JESSPOOL
profiles nobody sees the jobs of others. To let everyone see, give the
universal access record of the profile, the line without a group, the level
#cmd("READ").
#idx("no profile")

Several profiles can cover one entity. The one that sorts last in EBCDIC order
wins, not the most specific one: #cmd("OWN*") wins over #cmd("OWN.*").

=== Example profiles <ref-auth-example>

In the RAKF profile table the class stands in columns 1 to 8, the profile from
column 9, the group from column 53 and the access from column 61. For each
profile the line without a group, the universal access, is the one for all
users:

#screen(```
FACILITYSDSF.OPER                                           NONE
FACILITYSDSF.OPER                                   ADMIN   UPDATE
JESSPOOL*                                                   NONE
JESSPOOL*                                           ADMIN   UPDATE
```)

With these lines every user sees their own jobs, and the group ADMIN sees and
handles all jobs, the log, the printers and the initiators. With RAKF 2.0.0 the profile for
#cmd("SDSF.OPER") can also be made with the RAKF commands, which write the
same lines into the table and need the reload as well:

#screen(```
RDEFINE SDSF.OPER CLASS(FACILITY) UACC(NONE)
PERMIT SDSF.OPER CLASS(FACILITY) ID(ADMIN) ACCESS(UPDATE)
```)

Either way, RAKF must reload its profile table before the profiles take
effect: with RAKF 2.0.0, start the procedure #cmd("RAKFPROF"). The load stops
with the abend U0400 if a profile has a line for a group but no line without a
group\; RAKF then keeps the table it had.

== Access Levels <ref-auth-levels>

SDSF asks RAKF for one of two levels, which this book calls *read access* and
*update access*. RAKF has the higher levels CONTROL and ALTER too\; a user who
has one of them has update access in SDSF. SDSF asks for no level above update.
#idx("access levels")#idx("read access")#idx("update access")

#tab(caption: [What SDSF asks for])[
  #table(columns: (1.0in, 1fr, 1fr),
    table.header([Level], [On a job (JESSPOOL)], [On the system (SDSF.OPER)],),
    [Read],
      [The job is on the lists. #cmd("?") and #cmd("S") work on it, and on ST
       and DA #cmd("D") and #cmd("L").],
      [The #cmd("LOG"), #cmd("PR") and #cmd("INIT") commands. On DA, the
       address spaces without a job. #cmd("D") on a printer or an initiator.],
    [Update],
      [Every action character and overtype that changes the job.],
      [Operator commands with #cmd("/"). The other action characters and
       overtypes on printers and initiators. The PGN overtype on a DA row
       without a job.],
  )
]

Update access includes read access. A user with access #cmd("NONE"), or with
no profile, has neither.

== What Each Level Denies <ref-auth-denies>

=== Jobs

#tab(caption: [What a user can do with a job of another user])[
  #table(columns: (1.2in, 1fr, 1fr),
    table.header([Access to the job], [Allowed], [Denied],),
    [None, or no profile],
      [Nothing: the job is on no list.],
      [Seeing the job on ST, DA, I, O and H, and so everything that starts
       from its row. On PR and INIT the columns of the job that a printer or
       an initiator works on stay blank.],
    [Read],
      [The job is on the lists. #cmd("?") and #cmd("S") show its data sets and
       its output. On ST and DA, #cmd("D") and #cmd("L") work.],
      [#cmd("C"), #cmd("CD"), #cmd("P"), #cmd("A"), #cmd("H"), #cmd("E") and
       #cmd("O"), and overtyping PRTY, C or DEST of its row:
       `NOT AUTHORIZED FOR JOB`.],
    [Update], [Everything above.], [Nothing that SDSF checks.],
  )
]

Your own jobs are allowed everything (@ref-auth-own).

The lists hide a job before an action character can be typed on it. On ST, I,
O and H a job without read access is not on the list, and on DA the address
space of such a job is not either. #cmd("D") and #cmd("L") ask for read access
as well. On ST they use the answer that SDSF got when it read the list, so
they are not refused. On DA, SDSF reads the jobs again before #cmd("D"),
#cmd("L") and every action character that changes the job, and a job that may
no longer be read is not found: these answer `JOB NOT FOUND`. #cmd("?") and
#cmd("S") on DA do not ask again. They use the row as the list showed it, so
the answer is the one that SDSF got when it loaded the list.
#idx("JOB NOT FOUND")

#cmd("PREFIX") and #cmd("DEST") narrow what a list shows. They never give
access to a job that RAKF does not allow.

=== The system

#tab(caption: [What a user can do with the system])[
  #table(columns: (1.2in, 1fr, 1fr),
    table.header([Access to SDSF.OPER], [Allowed], [Denied],),
    [None, or no profile],
      [The own jobs, and the jobs of others as JESSPOOL allows.],
      [#cmd("LOG"), #cmd("PR") and #cmd("INIT"): `COMMAND NOT AUTHORIZED`.
       #cmd("/") commands: `NOT AUTHORIZED FOR CMD`. On DA, the rows without
       a job.],
    [Read],
      [#cmd("LOG"), and the outstanding replies that #cmd("ACTION") appends.
       #cmd("PR") and #cmd("INIT"). On DA, the address spaces without a job.
       #cmd("D") on printers and initiators.],
      [#cmd("/") commands: `NOT AUTHORIZED FOR CMD`. The other action
       characters on printers and initiators: `NOT AUTHORIZED FOR PRT` or
       `NOT AUTHORIZED FOR INIT`, and the same for their overtypes. The PGN
       overtype on a DA row without a job: `NOT AUTHORIZED FOR CMD`.],
    [Update], [Everything above.], [Nothing that SDSF checks.],
  )
]

SDSF checks no profile for the #cmd("TSO") command.

=== A user without a profile

A user who has no access to #cmd("SDSF.OPER") and no JESSPOOL profile for the
jobs of others sees these things and no others:

- ST, I, O and H list the user's own jobs only (@ref-auth-own).
- DA lists the address spaces of the user's own jobs, among them the user's
  own TSO session. It does not list the master scheduler or JES2.
- #cmd("LOG"), #cmd("PR") and #cmd("INIT") answer `COMMAND NOT AUTHORIZED`.
- A #cmd("/") command answers `NOT AUTHORIZED FOR CMD`.

== Every Check SDSF Makes <ref-auth-checks>

@ref-auth-table lists every question that SDSF puts to RAKF: the entity, the
class, the access level and where it applies. The first row is not put to RAKF
at all.
#idx("checks")

#tab(caption: [The checks of SDSF])[
  #table(columns: (1.2in, 0.9in, 0.7in, 1fr),
    table.header([Entity], [Class], [Access], [Where it applies],),
    [none (own job)], [none], [none],
      [On every list and for every action: the user owns the job, or the job
       has no owner and its name begins with the user id.],
    [#var("owner")#cmd(".")#var("jobname")#cmd(".")#var("jobid")], [JESSPOOL],
      [Read],
      [Whether a job is on ST, I, O and H. Whether the address space of a job
       is on DA. The job of a printer or an initiator on PR and INIT.
       #cmd("D") and #cmd("L") on ST and DA.],
    [#var("owner")#cmd(".")#var("jobname")#cmd(".")#var("jobid")], [JESSPOOL],
      [Update],
      [#cmd("C"), #cmd("CD"), #cmd("P"), #cmd("A"), #cmd("H"), #cmd("E") on ST
       and DA. #cmd("O") on ST and H. Overtyping PRTY and DEST on ST, PRTY, C
       and DEST on I, and DEST on O. DEST on H, which takes effect with
       #cmd("O"). PGN on a DA row with a job.],
    [#cmd("SDSF.OPER")], [FACILITY], [Read],
      [The #cmd("LOG") command, on every panel and on the primary option menu.
       The #cmd("PR") and #cmd("INIT") commands. The rows of DA without a job.
       #cmd("D") on PR and INIT. The terminal names of TSO users on DA, where
       SDSF cannot use its own SVC routine (@ref-auth-state).],
    [#cmd("SDSF.OPER")], [FACILITY], [Update],
      [Operator commands given with #cmd("/"). The action characters other
       than #cmd("D") on PR and INIT. Overtyping the fields of PR and CLASSES
       on INIT. PGN on a DA row without a job.],
  )
] <ref-auth-table>

SDSF first checks what you typed, an action character it does not know or an
invalid value, and then the authorization. When you overtype several fields,
SDSF first checks every value, and if one is invalid it sends nothing. It
checks the authorization afterwards, field by field: a field that is refused
is not sent, and the others are. The title line shows the message of the last
field that SDSF handled.

An action on a printer or an initiator asks for #cmd("SDSF.OPER") only, not
for the job that the device is working on. SDSF does not look at the text of a
command given with #cmd("/"): whoever has update access to #cmd("SDSF.OPER")
can give any operator command.

== The Authorized State <ref-auth-state>

Reading the log and the outstanding replies, purging a job, and giving JES2
and operator commands, among them the commands PR and INIT give to read their
data, need an authorized program, and SDSF runs unauthorized. For the moments
it needs, SDSF asks for the authorized state, and the system gives it or does
not. This is a second condition, independent of RAKF: both must hold.
#idx("authorized state")

SDSF gets the authorized state in one of two ways, in this order:

+ From its own SVC routine, installed with SDSF (@apx-svc).
+ Where that is not installed, or where it refuses the call, through SVC 244.
  Then only users who have read access to the FACILITY profile #cmd("SVC244")
  have the authorized state. A refused call of SVC 244 makes RAKF write a
  message on the console.
#idx("SVC 244")

SDSF's own SVC routine refuses the call unless SDSF itself makes it: the
calling program must be a module whose name begins with #cmd("ISF"), loaded
from an APF-authorized library or the link pack area, and so must every other
#cmd("ISF") module of the task. If SDSF is loaded from a library that is not
APF-authorized, the routine refuses and SDSF falls back to SVC 244. The routine
checks the program, not the user. Who may do what in SDSF is decided by the
access levels described above, not by the routine.

When SDSF cannot get the authorized state, it says so:

#tab(caption: [Messages when the authorized state is missing])[
  #table(columns: (1.9in, 1fr),
    table.header([Message], [When],),
    [`COMMAND NOT AUTHORIZED`],
      [An action character or an overtype that gives a command, a #cmd("/")
       command, and the #cmd("PR") and #cmd("INIT") commands, which read
       their data with a JES2 command.],
    [`LOG NOT READABLE`], [The #cmd("LOG") panel cannot read the log.],
    [`REPLIES NOT READABLE`],
      [The outstanding replies at the end of the log cannot be read after
       #cmd("ACTION").],
    [`NOT AUTHORIZED`], [#cmd("P") on the Status panel.],
  )
]

#cmd("?") and #cmd("S") need no authorized state.

One more thing depends on it. The PROCSTEP column of DA shows the terminal of a
TSO user. SDSF reads the terminal names where that causes no message on the
console: with its own SVC routine, or, where only SVC 244 is available, for a
user with read access to #cmd("SDSF.OPER") who may also use SVC 244. For any
other user the terminal names are blank.

== Messages of a Refusal <ref-auth-messages>

#tab(caption: [The messages of the authorization])[
  #table(columns: (1.9in, 1fr),
    table.header([Message], [Cause],),
    [`COMMAND NOT AUTHORIZED`],
      [#cmd("LOG"), #cmd("PR") or #cmd("INIT") without read access to
       #cmd("SDSF.OPER"). Also a command that the system refuses because the
       authorized state is missing.],
    [`NOT AUTHORIZED FOR CMD`],
      [A #cmd("/") command without update access to #cmd("SDSF.OPER"), or the
       PGN overtype on a DA row without a job.],
    [`NOT AUTHORIZED FOR JOB`],
      [An action character or overtype on a job without the access that
       @ref-auth-table gives.],
    [`NOT AUTHORIZED FOR PRT`],
      [An action character other than #cmd("D"), or an overtype, on a printer
       without update access to #cmd("SDSF.OPER").],
    [`NOT AUTHORIZED FOR INIT`],
      [An action character other than #cmd("D"), or an overtype, on an
       initiator without update access to #cmd("SDSF.OPER").],
    [`NOT AUTHORIZED`], [#cmd("P") on ST when the authorized state is missing.],
  )
]
#idx("COMMAND NOT AUTHORIZED")#idx("NOT AUTHORIZED FOR CMD")
#idx("NOT AUTHORIZED FOR JOB")#idx("NOT AUTHORIZED FOR PRT")
#idx("NOT AUTHORIZED FOR INIT")#idx("NOT AUTHORIZED")
#idx("LOG NOT READABLE")#idx("REPLIES NOT READABLE")

The messages appear on the title line. All messages of SDSF are listed in
@ref-messages.
