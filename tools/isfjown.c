/* isfjown.c -- a diagnostic tool for SDSF's job authorization: lists every
** job in the queue with the owner SDSF takes for it, the one libc370 gives
** (they must agree), the entity
** SDSF builds for the class JESSPOOL, and what RAKF answers for READ and
** UPDATE on it; with a PARM, RAKF's answers for the entities it names
** (PARM='.PAYROLL.JOB00046 HERC01.PAYROLL.JOB00046'). "MINE" marks a job SDSF counts as the user's own.
**
** Output, one line per job on the terminal or SYSPRINT:
**   JOBNAME  JOBID    OWNER    MINE ENTITY                    READ UPDT
*/
#include <stdio.h>
#include <string.h>

#include <mvs/jes2.h>
#include <mvs/racf.h>

#include "../src/isf.h"

/* The user id of the address space, from its ACEE (PSAAOLD -> ASCBASXB ->
** ASXBSENV -> ACEEUSRI); blank without one
*/
static void
acee_user(char *user)
{
    unsigned ascb = *(unsigned *)0x224 & 0xFFFFFF;
    unsigned asxb = *(unsigned *)(ascb + 0x6C) & 0xFFFFFF;
    unsigned acee = asxb ? *(unsigned *)(asxb + 0xC8) & 0xFFFFFF : 0;
    int len = acee ? *(unsigned char *)(acee + 0x14) : 0;

    memset(user, 0, 9);
    if (len > 8)
        len = 8;
    if (len > 0)
        memcpy(user, (const char *)(acee + 0x15), (size_t)len);
}

int
main(int argc, char **argv)
{
    ISFROW *rows = NULL;
    char user[9], owner[9], name[9], entity[30];
    int n, i, k;
    JESJOB **lib = NULL;

    acee_user(user);
    if (argc > 1) {
        /* PARM: entities to ask RAKF about, instead of the job list */
        for (i = 1; i < argc; i++)
            printf("ISFJOWN USER=%s ENTITY=%s READ=%d UPDATE=%d\n", user,
                   argv[i],
                   racf_auth(NULL, "JESSPOOL", argv[i], RACF_ATTR_READ),
                   racf_auth(NULL, "JESSPOOL", argv[i], RACF_ATTR_UPDATE));
        return 0;
    }
    auth_init(user);
    n = st_read_all(&rows);
    {
        JES *jes = jesopen();

        lib = jes ? jesjob(jes, NULL, FILTER_NONE, 0) : NULL;
        if (jes)
            jesclose(&jes);
    }
    printf("ISFJOWN USER=%s JOBS=%d\n", user, n);
    printf("JOBNAME  JOBID    SDSF     LIBC370  MINE ENTITY                     READ UPDT\n");
    for (i = 0; i < n; i++) {
        const ISFROW *j = &rows[i];

        memcpy(owner, j->owner, 8);
        owner[8] = '\0';
        for (k = 7; k >= 0 && (owner[k] == ' ' || owner[k] == '\0'); k--)
            owner[k] = '\0';
        memcpy(name, j->name, 8);
        name[8] = '\0';
        for (k = 7; k >= 0 && (name[k] == ' ' || name[k] == '\0'); k--)
            name[k] = '\0';
        snprintf(entity, sizeof(entity), "%s.%s.%s%05d", owner, name,
                 j->type, j->number);
        {
            char id[12];
            const char *lo = "?";

            snprintf(id, sizeof(id), "%s%05d", j->type, j->number);
            for (k = 0; lib && lib[k]; k++)
                if (strcmp((const char *)lib[k]->jobid, id) == 0) {
                    lo = lib[k]->owner[0] ? (const char *)lib[k]->owner : "-";
                    break;
                }
            printf("%-8s %s %-8s %-8s ", name, id, owner[0] ? owner : "-", lo);
        }
        printf("%-4s %-26s %4d %4d\n", auth_mine(j) ? "YES" : "NO",
               entity,
               racf_auth(NULL, "JESSPOOL", entity, RACF_ATTR_READ),
               racf_auth(NULL, "JESSPOOL", entity, RACF_ATTR_UPDATE));
    }
    st_free(rows);
    if (lib)
        jesjobfr(&lib);
    return 0;
}
