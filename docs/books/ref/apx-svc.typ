#import "../bookmaster/bookmaster.typ": *

= The SVC Routine <apx-svc>

#idx("SVC routine")#idx("IGX00011")#idx("SVC 109")
SDSF runs unauthorized. For the few moments in which it must read the system
log, read the outstanding replies, purge a job or give a command, it asks the
system for the *authorized state*, and it gives the state back at once. SDSF
1.2.0 comes with an SVC routine of its own that grants the state to SDSF and
to nothing else. This appendix describes the routine for the system
programmer: what it is, what must hold for it to work, how SDSF calls it,
what it answers and what the user sees when it does not work.

Which user may do what is not decided here. RAKF decides that, as @ref-auth
describes. The routine checks nothing about the user.

== What the Routine Is <apx-svc-what>

The routine is the load module #cmd("IGX00011"). It is an *extended SVC
routine*: it is entered through SVC 109 with the code 11 in register 15. The
name follows from the code: #cmd("IGX000") and the code in two digits. The SVC
number 109 and the code 11 are fixed in SDSF. There is no parameter to change
them.
#idx("extended SVC routine")

The routine does one thing. Called with register 1 set to 1, it turns on the
APF authorization of the job step of the caller. Called with register 1 set
to any other value, it turns the authorization off. This is the authorization
that SVC 244 gives, but the routine gives it only to a program of SDSF that
was loaded from a place that only a system programmer can write to
(@apx-svc-checks). While the authorization is on, the whole job step is
authorized, not only SDSF. SDSF turns the authorization off again after each
use. Where it must read protected storage, SDSF also switches the storage key
itself.

On a stock TK5 or MVS/CE system, #cmd("SYS1.LPALIB") holds the members
#cmd("IGX00013"), #cmd("IGX00014"), #cmd("IGX00026") and #cmd("IGX00027")
and no #cmd("IGX00011"), so no routine answers to code 11 until SDSF is
installed. Check before you install: if a site has an #cmd("IGX00011") of its
own, SDSF sees code 11 as installed and calls that routine instead.

== What Must Hold <apx-svc-needs>

The routine works when all of the following are true.

+ *#cmd("IGX00011") is in #cmd("SYS1.LPALIB").* The package carries the
  source of the routine. The installation job assembles it, and SMP links it
  into #cmd("SYS1.LPALIB"). Its distribution library is #cmd("SYS1.AOST4").
  The data sets of the package are listed in @apx-package.
+ *The system was IPLed with CLPA after the module was put there.* At an IPL
  with CLPA the system finds the module in the link pack area and enters its
  address into the table of SVC 109. Without CLPA the table still holds the
  entry of the invalid-SVC routine for code 11, and SDSF does not use the
  routine.
+ *SDSF is loaded from an APF-authorized library.* The load module is
  #cmd("ISFISP") in #cmd("ISF.LINKLIB"). The library has an entry in #cmd("SYS1.PARMLIB(IEAAPF00)") with the volume it
  is on, and it is in the link list (#cmd("SYS1.PARMLIB(LNKLST00)")), so that
  ISPF finds SDSF there. Keep the library out of ISPLLIB: with an
  unauthorized library in ISPLLIB, SDSF was not loaded as authorized. Keep it
  out of a STEPLIB that is not all APF-authorized too: a program found there is
  not loaded as authorized.
+ *Every other module of SDSF that the task has loaded was loaded the same
  way.* This means every module whose name begins with #cmd("ISF").

The installation steps are in the companion volume, the _SDSF User's Guide_,
in the chapter "Installing and Removing SDSF".

Because the routine trusts a module for its name and its library, protect
#cmd("ISF.LINKLIB") like any other APF library. A program whose name begins
with #cmd("ISF"), put into an APF library, can turn the authorization on.

== The Interface <apx-svc-interface>

The routine is not a general service. It answers only to the modules of SDSF.
The interface is described here so that a system programmer can read a
refusal.

#tab(caption: [Registers of a call of the routine])[
  #table(columns: (1.5in, 1fr),
    [Register], [Contents],
    [15 on entry], [The code, 11.],
    [0 on entry], [Zero. Any other value is refused with return code 4.],
    [1 on entry], [1 turns the authorization on, any other value turns it
      off.],
    [15 on return], [The return code (@apx-svc-rc).],
  )
]

The call is the instruction #cmd("SVC 109").

=== Return Codes <apx-svc-rc>

#tab(caption: [Return codes of IGX00011])[
  #table(columns: (0.6in, 1fr),
    [Code], [Meaning],
    [0], [Done. The authorization of the job step is on or off, as asked.],
    [4], [Register 0 was not 0.],
    [8], [The caller is not a program. The request block before the one of the
      routine is not a program request block, or it has no module entry.],
    [12], [The name of the calling module does not begin with #cmd("ISF").],
    [16], [The calling module, or a module whose name begins with
      #cmd("ISF") on the load list of the task, was loaded neither from an
      APF-authorized library nor from the link pack area.],
  )
]
#idx("return codes")

On a return code other than 0 the routine has changed nothing. SDSF does not
show the return code. It goes on to SVC 244 (@apx-svc-use), and the user sees
only what that gives.

=== What the Routine Checks <apx-svc-checks>

The routine makes its checks in the order of the return codes and stops at the
first that fails.

+ Register 0 is 0.
+ The caller is a program, and the system knows its module entry. For a
  module called by an alias name, the checks apply to the module itself.
+ The name of the module begins with #cmd("ISF").
+ The module was loaded as authorized: from an APF-authorized library or from
  the link pack area.
+ Every module on the load list of the task whose name begins with
  #cmd("ISF") was loaded as authorized too. A module of SDSF from an
  unauthorized library, for example a copy in a development library, makes
  the routine refuse every call of the task.

Only then does the routine turn the authorization on or off.

The routine does not check who the user is, and it does not ask RAKF. It does
not check what SDSF does while the authorization is on. Those rules are in
SDSF itself (@ref-auth).

== How SDSF Calls the Routine <apx-svc-use>

Each action that needs the authorized state asks for it in the same way, in
this order:

+ If the task is authorized already, SDSF does nothing more.
+ SDSF looks into the table of SVC 109 to see whether code 11 is installed.
  It does not call a code that is not installed, because that would end the
  task abnormally. If the code is installed, SDSF calls the routine with
  register 1 set to 1. If the routine answers 0 and the task is authorized
  afterwards, SDSF has the state.
+ In every other case SDSF uses SVC 244. Then only users who are allowed to
  use SVC 244 get the state. The _SDSF User's Guide_, chapter "Installing and
  Removing SDSF", names the access: READ on the FACILITY profile
  #cmd("SVC244").

When the action is done, SDSF turns the authorization off, through the routine
if it turned it on that way.

These actions use the state: the #cmd("LOG") panel, the outstanding replies at
the end of the log, #cmd("P") on the Status panel, every command that SDSF
gives to the system (the #cmd("/") commands, the action characters and
overtypes that issue a command, the commands that #cmd("PR") and
#cmd("INIT") give, and the log they read the answers from) and the reading of the terminal names
for the PROCSTEP column of DA and for #cmd("WHO"). The terminal names are the
exception to step 3.
SDSF does not want a message on the console for them, so it takes SVC 244 for
them only for a user with read access to #cmd("SDSF.OPER"). Where the routine
is installed, SDSF uses it for the terminal names as for the rest. The
messages that SDSF shows when it does not get the state are described in
@ref-auth and @ref-messages.
#idx("authorized state")#idx("SVC 244")#idx("terminal names")

== When It Does Not Work <apx-svc-fail>

SDSF does not tell the user which of the two ways it used. A system where the
routine does not work, but where the user may use SVC 244, looks like a system
where it works.

#tab(caption: [What goes wrong, what the user sees and what to do])[
  #table(columns: (2.0in, 1.9in, 1fr),
    [Cause], [What is seen], [What to do],
    [#cmd("IGX00011") is not in #cmd("SYS1.LPALIB"), or the system was not
      IPLed with CLPA after it was put there.],
      [SDSF uses SVC 244. A user without access to it gets
       #cmd("COMMAND NOT AUTHORIZED"), #cmd("LOG NOT READABLE") and the
       other messages of the missing state, and RAKF writes a refusal of
       SVC 244 on the console.],
      [Check that the member is in #cmd("SYS1.LPALIB"). IPL with CLPA.],
    [#cmd("ISFISP") is loaded from an unauthorized library in ISPLLIB, from a
      STEPLIB that is not all APF-authorized, or from an APF library whose
      entry in #cmd("IEAAPF00") names another volume.],
      [The routine answers 16. Seen as above.],
      [Take the library out of ISPLLIB and the STEPLIB, and make sure that
       the APF entry has the volume the library is on. ISPF finds SDSF in
       #cmd("ISF.LINKLIB") through the link list without either.],
    [Another module whose name begins with #cmd("ISF") was loaded from an
      unauthorized library.],
      [The routine answers 16. Seen as above.],
      [Find the module and take its library out of the search.],
  )
]
#idx("troubleshooting")

To check the routine, use a user who has UPDATE access to #cmd("SDSF.OPER")
(a #cmd("/") command needs UPDATE) and no access to #cmd("SVC244"), and ask
for the #cmd("LOG") and for #cmd("/D T"). If the log is shown and the system answers with
#cmd("IEE136I"), SDSF got the state from the routine. A user who may use SVC
244 passes the check without the routine. On a stock MVS/CE system, the group
ADMIN has READ access to #cmd("SVC244"), so an ADMIN user is not a test.

== Removing the Routine <apx-svc-remove>

Removing SDSF takes #cmd("IGX00011") out of #cmd("SYS1.LPALIB") and
#cmd("SYS1.AOST4"). The copy in the running link pack area stays until the
next IPL with CLPA. The removal is described in the _SDSF User's Guide_,
chapter "Installing and Removing SDSF".
