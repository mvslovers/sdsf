         TITLE 'IGX00011 - SDSF: APF AUTHORIZATION FOR SDSF ONLY'
*----------------------------------------------------------------------
*  IGX00011 -- an extended SVC routine: SVC 109 with code 11 in R15.
*  It turns the APF authorization of the caller's job step on or off,
*  as SVC 244 does, but only for SDSF itself.
*
*  Installed in SYS1.LPALIB; NIP puts it into the ESR table of SVC 109
*  at an IPL with CLPA (measured).
*
*  IN   R0   0                       anything else: return code 4
*       R1   1 authorization on, 0 off (anything else: off)
*       R4   A(TCB)                  set by the SVC FLIH
*       R5   A(our SVRB)
*       R6   A(entry) = our base
*       R14  return
*  OUT  R15  0  done
*            4  R0 is not 0
*            8  not called from a program (the RB before ours is no
*               PRB)
*           12  the program's name does not begin with ISF
*           16  the program, or an ISF module the task has loaded, is
*               neither from an APF library nor from the LPA
*
*  What makes it safe: only a module named ISF* that MVS loaded as
*  authorized (from an APF library or the LPA) can turn it on, so a
*  user cannot write a program of that name to get through.
*
*  RENT: no stores into this module. Runs as an SVC in supervisor
*  state, key 0, in the caller's address space.
*----------------------------------------------------------------------
IGX00011 CSECT
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
         USING IGX00011,R6
         B     START
         DC    CL8'IGX00011',CL8'SDSF'
START    DS    0H
         LA    R15,4               R0 must be 0
         LTR   R0,R0
         BNZ   DONE
*
*  The caller: the RB before ours must be a program's (a PRB).
*
         USING RBBASIC,R5
         L     R12,RBLINK          the RB before ours
         DROP  R5
         LA    R12,0(,R12)         24-bit address
         LA    R15,8
         LTR   R12,R12
         BZ    DONE
         USING RBBASIC,R12
         TM    RBSTAB1,RBFTP       the type of the RB: zero for a PRB
         BNZ   DONE
         L     R11,RBCDE           the program's CDE
         DROP  R12
         LA    R11,0(,R11)
         LTR   R11,R11
         BZ    DONE
         BAL   R10,MAJOR           an alias: its major CDE
         USING CDENTRY,R11
         LA    R15,12
         CLC   CDNAME(3),=C'ISF'   SDSF's own
         BNE   DONE
         BAL   R10,AUTHD           loaded as authorized?
         LTR   R15,R15
         BNZ   DONE
*
*  Every ISF module on the task's load list loaded as authorized too:
*  an ISF module from an unauthorized library could otherwise run here.
*
         USING TCB,R4
         L     R2,TCBLLS           the last load list element
         DROP  R4
LLELOOP  DS    0H
         LA    R2,0(,R2)
         LTR   R2,R2
         BZ    LLEDONE
         USING LLE,R2
         L     R11,LLECDPT
         LA    R11,0(,R11)
         LTR   R11,R11
         BZ    LLENEXT
         BAL   R10,MAJOR
         CLC   CDNAME(3),=C'ISF'
         BNE   LLENEXT
         BAL   R10,AUTHD
         LTR   R15,R15
         BNZ   DONE
LLENEXT  DS    0H
         L     R2,LLECHN
         B     LLELOOP
         DROP  R2
LLEDONE  DS    0H
*
*  On or off: the APF bit of the job step (JSCBAUTH), as SVC 244 does.
*
         USING TCB,R4
         L     R2,TCBJSCB
         DROP  R4
         LA    R2,0(,R2)
         USING IEZJSCB,R2
         C     R1,=F'1'
         BE    TURNON
         NI    JSCBOPTS,255-JSCBAUTH
         B     OK
TURNON   DS    0H
         OI    JSCBOPTS,JSCBAUTH
OK       DS    0H
         DROP  R2
         SR    R15,R15
DONE     DS    0H
         BR    R14
*
*  MAJOR: R11 a CDE; a minor one (an alias) is replaced by its major.
*
MAJOR    DS    0H
         TM    CDATTR,CDMIN
         BNOR  R10
         L     R11,CDXLMJP
         LA    R11,0(,R11)
         BR    R10
*
*  AUTHD: R11 a major CDE; R15 0 if the module was loaded as
*  authorized (from an APF library: CDSYSLIB; from the LPA or by NIP:
*  CDNIP), else 16.
*
AUTHD    DS    0H
         SR    R15,R15
         TM    CDATTR2,CDSYSLIB
         BOR   R10
         TM    CDATTR,CDNIP
         BOR   R10
         LA    R15,16
         BR    R10
         DROP  R11
         LTORG ,
*----------------------------------------------------------------------
*  The mappings, from the system's macros.
*----------------------------------------------------------------------
         PRINT NOGEN
         IKJTCB DSECT=YES
         IHARB ,
         IHACDE ,
         IHALLE ,
         IEZJSCB ,
         PRINT GEN
         END   IGX00011
