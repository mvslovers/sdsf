# Authorization and the SVC routine

Two independent conditions decide what SDSF does for a user. Both must hold:

1. **RAKF says the user may** (`src/isfauth.c`). That is a question about the user.
2. **SDSF has the authorized state** for the moment it needs it (`isf_autask`). That is a question about the program.

The Reference chapter "Authorization" and the User's Guide chapter "Who May Do What" describe the rules for users. This file is about how the code does it.

## RAKF

All checks go through libc370's `racf_auth` with `LOG=NONE`, so a refusal writes nothing on the console. Only a return code of 0 allows (`permitted()`). Any other answer is a refusal, including "no profile" (RC 4), and there is no lenient fallback.

| What | Class | Entity | Level |
|---|---|---|---|
| the user's own jobs | none | none | always allowed |
| another user's job | `JESSPOOL` | `owner.jobname.jobid`, for example `HERC02.PAYROLL.JOB00046` | READ to see and look, UPDATE to change (cancel, purge, hold, release, overtype) |
| the system: LOG, PR, INIT, `/`, address spaces without a job on DA | `FACILITY` | `SDSF.OPER` | READ to see, UPDATE for actions and `/` |

- **Own job** (`auth_mine`): the owner libc370 gives equals the user id. A job without an owner counts as the user's own if its name begins with the user id.
- **Owner** (`owner_set` in `isfst.c`): libc370 gives `USER=` of a batch job from the converted JCL, the name of a TSO session, `SYSTEM` for a started task. JES2 4.1 leaves the job's own user field blank (see #22, closed).
- **Ownerless jobs:** a job without an owner that is not the user's own is asked about as `.jobname.jobid`, with nothing before the first period.
- **Eight characters:** RAKF cuts the JESSPOOL entity to 8 characters. Profiles cannot tell jobs apart beyond `HERC02.P` and similar. Several profiles can cover one entity; the one that sorts last in EBCDIC wins, not the most specific.
- **Cache:** the answers are cached per list, keyed on the first 8 characters of the entity (`ENT_KEY`). The cache is reset at the start of every job read (`auth_reset` from `st_read`), so a profile change takes effect with the next list. A cache key that did not follow RAKF's 8-character cut once showed jobs that RAKF would hide and hid jobs it would show; the key must stay what RAKF compares.
- **The RAKF profile table:** it is `SYS1.SECURE.CNTL(PROFILES)` on TK5 and MVS/CE, and `S RAKFPROF` reloads it. A bad reload keeps the old table. With RAKF 2.0.0, a table that does not load at IPL keeps JES2 from starting (#43).

## The authorized state

Some reads and requests need an APF-authorized caller or key 0:

- the master trace table (the log);
- the outstanding replies;
- the terminal names of TSO users;
- purge;
- operator and JES2 commands through SVC 34, which includes the `$DU` and `$DI` behind PR and INIT.

SDSF runs unauthorized and turns the authorization on only around these calls.

`isf_autask()`:

1. Already authorized (`TESTAUTH`): done.
2. Is SVC 109 code 11 installed? The ESR table of SVC 109 is looked at first, because calling an uninstalled code is not safe. An installed code holds an address other than code 0's.
3. If it is installed, call it with R1 = 1, then check `TESTAUTH` again.
4. Otherwise `__autask()`: libc370's SVC 244. #74 removes this step.

`isf_uatask()` turns it off again by the same way it was turned on. `isf_quiet()` is the variant for things that are only nice to have, the terminal names. It uses SVC 244 only for a user with SDSF.OPER, because a refused SVC 244 makes RAKF write a message on the console.

Watch for libc370 calls that authorize themselves. `cmtt_new()` calls `__autask()` itself when the caller is not authorized. `log_load` therefore authorizes through SDSF's routine first. Any new libc370 call that needs the authorized state must be wrapped the same way.

## IGX00011

`asm/igx00011.asm` is an extended SVC routine, SVC 109 code 11, about 160 lines of assembler. It is RENT, REUS and REFR, and runs in supervisor state, key 0, in the caller's address space. It turns the APF bit of the caller's job step on or off, as SVC 244 does, but only for SDSF itself:

| R15 | Meaning |
|---|---|
| 0 | done |
| 4 | R0 was not 0 |
| 8 | the caller is not a program (the RB before the SVRB is not a PRB) |
| 12 | the program's name does not begin with `ISF` |
| 16 | the program, or another `ISF` module the task has loaded, came neither from an APF library nor from the LPA |

What makes it safe: only a module named `ISF*` that MVS loaded as authorized can turn it on, so a user cannot write a program of that name to get through. The routine checks the program, not the user; RAKF decides for the user.

**Installation.** The SMP package carries it as source. The install job assembles it with IFOX00 and links it into `SYS1.LPALIB`, with `SYS1.AOST4` as its distribution library (`[module.IGX00011.smp]` in `mbt.toml`). It takes effect at the next IPL with CLPA. On TK5 and MVS/CE, code 11 of SVC 109 is free (`IGX00013`, `14`, `26` and `27` are taken).

**Testing.** `ISFSVCT` turns the authorization on and off and reports the return codes. Linked under another name, it must get RC 12. An upgrade that links in an old copy from `SYS1.LPALIB` loses REFR (see pitfalls.md).

**Changing it.** Any change needs:
- an IPL with CLPA on a throwaway system;
- `ISFSVCT` for all return codes;
- a check that the module is still marked refreshable after the SMP install.
