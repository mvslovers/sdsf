# Test jobs

Jobs for the TSO tests. They are written
for a development system: `CLASS=A`, `MSGCLASS=H` (no printer takes it there: the
output stays on the print queue and shows on O), and ZSWA
runs ISFWTOR from `ISF.DEV.LINKLIB`. On another system change the classes
first.

| Job | What it is for |
|---|---|
| `zswa.jcl` | One WTOR with all routing codes (ISFWTOR, `PARM='SDSF WTOR AUTO'`). `test/tso/wtor.lua` needs it waiting; `mbt/init.lua` submits it before the TSO tests and answers it afterwards. |
| `zswtm.jcl` | Assembles, links and runs a program that asks five WTORs with the routing codes 1, 2, 11, 13 and 16 and waits for all of them (`TIME=1440`, so the wait does not end in S522). For looking at ACTION by eye; answer them with `/R nn,...`. |
| `zsout.jcl` | A job with a procedure step (S1/G) and several output data sets: IEBGENER with 60 lines of instream data, IDCAMS LISTCAT. For NEXT/PREV and the lines of output. |
| `zsin.jcl` | `TYPRUN=HOLD`: stays held on the input queue, for `test/tso/i.lua` (the I panel). Submit it once; it stays until it is released or purged. |
| `zsasm.jcl` | Assembles a small program with TITLE, SPACE 1/2/3 and EJECT: the listing shows how the carriage control of output is displayed. |

Submit one with mvsMF, for example

    curl -u USER:PASSWORD -X PUT -H "Content-Type: text/plain" \
         --data-binary @test/jcl/zswtm.jcl http://HOST:PORT/zosmf/restjobs/jobs
