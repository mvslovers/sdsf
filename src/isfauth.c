/* isfauth.c -- who may see and do what, from RAKF.
**
** The rules (docs/installation.md section 8):
** - the user's own jobs (the job's owner, as libc370 and FTPD take it, is
**   the user) always,
**   every action;
** - other users' jobs through the class JESSPOOL, entity
**   <owner>.<jobname>.<jobid> as FTPD asks it: READ to see them, UPDATE to
**   act on them;
** - the system (the log, printers, initiators, the system's address
**   spaces, / commands) through the FACILITY profile SDSF.OPER: READ to
**   see, UPDATE to act.
** Only a permit (return code 0) allows: no profile (4) refuses.
*/
#include <stdio.h>
#include <string.h>

#include <mvs/apf.h>
#include <mvs/racf.h>

#include "isf.h"

static char user[9];

/* The answers, kept until the next auth_reset() (each new list): -1 not
** asked yet, 0 refused, 1 permitted; [0] READ, [1] UPDATE. JESSPOOL is
** kept per first 8 characters of the entity <owner>.<jobname>.<jobid>:
** RAKF cuts a JESSPOOL entity to 8 characters before it matches a profile,
** so jobs with the same 8 get the same answer. For an
** owner of 7 or 8 characters that is the owner; a shorter owner (SYSTEM,
** HERC02) or none brings characters of the job name in, and a profile such
** as HERC02.P* tells such jobs apart.
*/
#define CACHE_MAX 64
#define ENT_KEY 8
static struct {
    char key[ENT_KEY + 1];
    signed char ok[2];
} cache[CACHE_MAX];
static int ncache;
static signed char oper[2] = { -1, -1 };

static void
trim(char *dst, const char *src, size_t n)
{
    size_t k = 0;

    while (k < n && src[k] != ' ' && src[k] != '\0') {
        dst[k] = src[k];
        k++;
    }
    dst[k] = '\0';
}

void
auth_reset(void)
{
    ncache = 0;
    oper[0] = oper[1] = -1;
}

void
auth_init(const char *userid)
{
    trim(user, userid, 8);
    auth_reset();
}

static int
permitted(const char *cls, const char *resource, int update)
{
    return racf_auth(NULL, cls, resource,
                     update ? RACF_ATTR_UPDATE : RACF_ATTR_READ) == 0;
}

int
auth_oper(int update)
{
    int u = update != 0;

    if (oper[u] < 0)
        oper[u] = (signed char)permitted("FACILITY", "SDSF.OPER", u);
    return oper[u];
}

/* The job's owner is the user. The owner is libc370's (owner_set in
** isfst.c): USER= of a batch job, the name of a TSO session, SYSTEM for a
** started task; JES2 4.1 leaves JCTUSEID blank. A job with none: IBM's
** rule, the job name begins with the user id.
*/
int
auth_mine(const ISFROW *job)
{
    char owner[9];

    if (user[0] == '\0')
        return 0;
    trim(owner, job->owner, 8);
    if (owner[0] != '\0')
        return strcmp(owner, user) == 0;
    return strncmp(job->name, user, strlen(user)) == 0;
}

int
auth_job(const ISFROW *job, int update)
{
    char owner[9], name[9], entity[30];
    int u = update != 0, i;

    if (auth_mine(job))
        return 1;
    trim(owner, job->owner, 8);
    trim(name, job->name, 8);
    snprintf(entity, sizeof(entity), "%s.%s.%s%05d", owner, name,
             job->type, job->number);
    for (i = 0; i < ncache; i++)
        if (strncmp(cache[i].key, entity, ENT_KEY) == 0)
            break;
    if (i == ncache) {
        if (ncache == CACHE_MAX)
            return permitted("JESSPOOL", entity, u);
        snprintf(cache[i].key, sizeof(cache[i].key), "%.8s", entity);
        cache[i].ok[0] = cache[i].ok[1] = -1;
        ncache++;
    }
    if (cache[i].ok[u] < 0)
        cache[i].ok[u] = (signed char)permitted("JESSPOOL", entity, u);
    return cache[i].ok[u];
}

/* ---- Authorized state: our SVC, else SVC 244 ----
**
** SDSF's own SVC is an extended SVC routine, SVC 109 code 11 (IGX00011 in
** the LPA). Code 11 must not be called where it is not installed, so the
** ESR table of SVC 109 is looked at first: an installed code holds an
** address other than the invalid-SVC routine's, which code 0 holds.
*/
static int via_svc;     /* the authorization was turned on by our SVC */

static int
esr11_installed(void)
{
    unsigned cvt = *(unsigned *)0x10 & 0xFFFFFF;
    unsigned scvt = *(unsigned *)(cvt + 0xC8) & 0xFFFFFF;      /* CVTABEND */
    unsigned svct = *(unsigned *)(scvt + 0x84) & 0xFFFFFF;     /* SCVTSVCT */
    unsigned esr = *(unsigned *)(svct + 109 * 8) & 0xFFFFFF;   /* SVC 109 */

    if (esr == 0)
        return 0;
    return (*(unsigned *)(esr + 11 * 8) & 0xFFFFFF)
        != (*(unsigned *)esr & 0xFFFFFF);
}

static int
apf_now(void)
{
    int rc;

    __asm__("TESTAUTH FCTN=1\n\tST 15,%0" : "=m"(rc) : : "0", "1", "14", "15", "memory");
    return rc == 0;
}

static int
sdsf_svc(int on)
{
    int rc;

    __asm__("SR 0,0\n\t"
            "L 1,%1\n\t"
            "LA 15,11\n\t"
            "SVC 109\n\t"
            "ST 15,%0"
            : "=m"(rc) : "m"(on) : "0", "1", "14", "15", "memory");
    return rc;
}

int
isf_autask(void)
{
    if (apf_now())
        return 0;
    if (esr11_installed() && sdsf_svc(1) == 0 && apf_now()) {
        via_svc = 1;
        return 0;
    }
    return __autask();
}

void
isf_uatask(void)
{
    if (via_svc) {
        sdsf_svc(0);
        via_svc = 0;
        return;
    }
    __uatask();
}

/* As isf_autask, but only where asking makes no noise: SDSF's SVC checks
** nothing RAKF logs, SVC 244 makes RAKF log a refusal on the console. So
** 244 only for a user with SDSF.OPER (asked with LOG=NONE). For reading
** what is nice to have (the terminal names), not for what the user asked.
*/
int
isf_quiet(void)
{
    if (apf_now())
        return 0;
    if (esr11_installed() && sdsf_svc(1) == 0 && apf_now()) {
        via_svc = 1;
        return 0;
    }
    if (auth_oper(0))
        return __autask();
    return -1;
}

/* What isf_autask would use: 1 our SVC, 0 SVC 244 */
int
isf_svc_installed(void)
{
    return esr11_installed();
}

