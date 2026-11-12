/* isfst.c - the jobs on the JES2 queues for the Status panel
**
** The job queue elements of the checkpoint carry nearly everything shown.
** Only the class of a batch job takes a read of its JCT from the spool.
**
** The order follows IBM's SDSF V1R2, looked at with jobs whose number, priority,
** class and name do not go together: first the jobs waiting to execute, by
** class, then the executing ones, batch jobs before TSO users before started
** tasks, then the print queue. Within those, the higher priority first, then
** the number. Running batch jobs go by class too, as the waiting ones do: the
** measurement fits that, but also priority or number alone.
** Neither the queue chains nor the array of elements give this order: the
** chains reach only a part of the elements.
*/
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <mvs/apf.h>
#include <mvs/jes2.h>
#include <mvs/mtt.h>
#include <ibm/jes2/jct.h>
#include <ext/array.h>
#include <ext/time64.h>
#include <ibm/mvs/cvt.h>
#include <ibm/mvs/ieecucm.h>
#include <ibm/jes2/iot.h>
#include <ibm/jes2/pddb.h>

#include "isf.h"

/* The attributes of the data area, see ispplib/isflist */
#define A_BLUE  0x05    /* a job that is not executing, the heading */
#define A_WHITE 0x07    /* an executing job */
#define A_RED   0x10    /* can be overtyped, executing */
#define A_GREEN 0x11    /* can be overtyped, not executing */
#define A_NP    0x1D    /* the NP column */
#define A_GIN   0x12    /* overtyped and read (ST, I): not executing */
#define A_RIN   0x13    /* the same, executing */

/* The groups of the list, in their order */
#define G_WAITING 0
#define G_RUNJOB  1
#define G_RUNTSU  2
#define G_RUNSTC  3
#define G_OTHER   4
#define G_PRINT   5

/* The columns of the line; each attribute takes the position before it */
#define C_NP    1
#define C_NAME  4
#define C_TYPE  13
#define C_NUM   17      /* 5 wide, on the right */
#define C_PRTY  24      /* 3 wide, on the right */
#define C_QUEUE 28
#define C_CLASS 39
#define C_POS   42
#define C_HDN   46      /* 3 wide, on the right */
#define C_DEST  50
#define C_SAFF  59
#define C_ASYS  64
#define C_STAT  69

/* The queue's name by the type of the element, executing first */
static const char *
queue_name(unsigned char type)
{
    if (type & _XEQ)
        return "EXECUTION";
    if (type & _INPUT)
        return "INPUT";
    if (type & _XMIT)
        return "XMIT";
    if (type & _SETUP)
        return "SETUP";
    if (type & _RECEIVE)
        return "RECEIVE";
    if (type & (_OUTPUT | _HARDCPY))
        return "PRINT";
    return "UNKNOWN";
}

/* The id of this system from the SMCA */
void
st_sysid(char id[5])
{
    unsigned cvt = *(unsigned *)0x10;
    unsigned smca = *(unsigned *)(cvt + 0xC4);

    memcpy(id, (char *)smca + 16, 4);
    id[4] = '\0';
}

static void
fill(ISFROW *r, const __JQE *q, const char *sysid)
{
    unsigned no = q->JQEJOBNO;

    memset(r, 0, sizeof(*r));
    memcpy(r->name, q->JQEJNAME, 8);
    /* JES2 numbers the three kinds in ranges of its own */
    strcpy(r->type, no >= 20000 ? "TSU" : no >= 10000 ? "STC" : "JOB");
    r->number = (int)(no % 10000);
    r->prio = q->JQEPRIO >> 4;
    r->queue = queue_name(q->JQETYPE);
    r->jclass = ' ';
    r->held = q->JQEHLDCT >> 4;
    if ((q->JQEPRTRT & 0xFF) == 0)
        strcpy(r->dest, "LOCAL");
    else
        snprintf(r->dest, sizeof(r->dest), "R%u", q->JQEPRTRT & 0xFF);
    /* One system: an affinity less than all of them is this one */
    if ((q->JQEFLAG2 & QUESYSAF) != QUESYSAF && (q->JQEFLAG2 & QUESYSAF) != 0)
        strcpy(r->saff, sysid);
    if (q->JQEFLAGS & QUEBUSY)
        strcpy(r->asys, sysid);
    r->hold = (q->JQEFLAGS & (QUEHOLDA | QUEHOLD1 | QUEHOLD2)) != 0;
    r->active = (q->JQETYPE & _XEQ) != 0 && (q->JQEFLAGS & QUEBUSY) != 0;
    if ((q->JQETYPE & _XEQ) == 0)
        r->group = (q->JQETYPE & (_OUTPUT | _HARDCPY)) ? G_PRINT : G_OTHER;
    else if (!r->active)
        r->group = G_WAITING;
    else
        r->group = r->type[0] == 'J' ? G_RUNJOB
                 : r->type[0] == 'T' ? G_RUNTSU : G_RUNSTC;
}

/* The order of the panel. The queues other than execution and print did not
** occur in the measurement: their place is a guess.
*/
static int
order(const void *pa, const void *pb)
{
    const ISFROW *a = pa, *b = pb;

    if (a->group != b->group)
        return a->group - b->group;
    if ((a->group == G_WAITING || a->group == G_RUNJOB)
        && a->jclass != b->jclass)
        return (unsigned char)a->jclass - (unsigned char)b->jclass;
    if (a->prio != b->prio)
        return b->prio - a->prio;
    return a->number - b->number;
}

/* POS: the place among the jobs of a class that are not held */
static void
positions(ISFROW *r, int n)
{
    char jclass = 0;
    int i, place = 0;

    for (i = 0; i < n && r[i].group == G_WAITING; i++) {
        if (r[i].jclass != jclass) {
            jclass = r[i].jclass;
            place = 0;
        }
        if (!r[i].hold)
            r[i].pos = ++place;
    }
}

/* The class of a batch job, from its JCT */
/* Some bytes of the JCT as a string, blank on the right cut off */
static void
jct_text(char *out, const unsigned char *p, int n)
{
    int i, end = 0;

    for (i = 0; i < n; i++) {
        out[i] = p[i] < 0x40 ? ' ' : (char)p[i];
        if (out[i] != ' ')
            end = i + 1;
    }
    out[end] = '\0';
}

static void
job_class(JES *j, const __JQE *q, char *buf, ISFROW *r, const char *sysid)
{
    const __JCT *jct = (const __JCT *)buf;

    /* the JCT: the class of a batch job, the owner of every one, and what
    ** ? shows on ST and I
    */
    memset(r->owner, ' ', 8);
    r->owner[8] = '\0';
    r->pname[0] = r->acct[0] = r->notify[0] = r->esys[0] = '\0';
    strcpy(r->isys, sysid);
    r->mclass = ' ';
    r->rdtime = r->rddate = r->sttime = r->stdate = r->cards = r->lines = 0;
    if (spool_read(j->js[0], q->JQETRAK, buf, j->cp->hct._BUFSIZE) != 0)
        return;
    if (strcmp(r->type, "JOB") == 0) {
        /* waiting or executing: the class of the queue it is on, which $T
        ** changes; JQETYPE is the class's character less X'80' (measured
        ** on a test system: A X'41', J X'51', S X'62', Z X'69', 0 X'70', 9 X'79').
        ** Else the class it was read with.
        */
        unsigned char c = (unsigned char)(q->JQETYPE | 0x80);

        if ((q->JQETYPE & (_DUMMY | _XEQ)) == _XEQ && isalnum(c))
            r->jclass = (char)c;
        else
            r->jclass = (char)jct->JCTCLASS;
    }
    memcpy(r->owner, jct->JCTUSEID, 8);
    for (int k = 0; k < 8; k++)
        if ((unsigned char)r->owner[k] < 0x40)
            r->owner[k] = ' ';
    jct_text(r->pname, jct->JCTPNAME, 20);
    jct_text(r->acct, jct->JCTACCTN, 4);
    jct_text(r->notify, jct->JCTTSUID, 7);
    jct_text(r->esys, jct->JCTEXSID, 4);
    {
        char rd[5];

        jct_text(rd, jct->JCTRDSID, 4);
        if (rd[0])
            strcpy(r->isys, rd);
    }
    r->mclass = jct->JCTMCLAS >= 0x40 ? (char)jct->JCTMCLAS : ' ';
    r->rdtime = jct->JCTRDRON;
    r->rddate = jct->JCTRDTON;
    r->sttime = jct->JCTXEQON;
    r->stdate = jct->JCTXDTON;
    r->cards = jct->JCTCARDS;
    r->lines = jct->JCTLINES;
}

/* ---- The owner of a job ----
**
** JES2 4.1 leaves JCTUSEID blank (measured on a test system: every one of 118 jobs,
** also those with USER= on the job card from mvsMF or from the TSO SUBMIT
** exit IKJEFF10). libc370's jesjob() takes the owner as FTPD sees it: USER=
** from the internal text of a batch job, the name of a TSO session, SYSTEM
** for a started task. SDSF takes the same, so both build the same JESSPOOL
** entities <owner>.<jobname>.<jobid>. JCTUSEID stays where jesjob() has
** nothing.
*/
JESJOB **
owners_read(JES *j)
{
    return jesjob(j, NULL, FILTER_NONE, 0);
}

void
owner_set(JESJOB **own, ISFROW *r)
{
    char id[12];
    int i, k;

    if (own == NULL)
        return;
    snprintf(id, sizeof(id), "%s%05d", r->type, r->number);
    for (i = 0; own[i] != NULL; i++) {
        const char *o = (const char *)own[i]->owner;
        const char *n = (const char *)own[i]->jobname;
        size_t len = strlen(n);

        /* the name: libc370's ends with its last character, ours is
        ** padded with blanks
        */
        if (strcmp((const char *)own[i]->jobid, id) != 0 || len > 8
            || strncmp(n, r->name, len) != 0
            || (len < 8 && r->name[len] != ' ' && r->name[len] != '\0'))
            continue;
        if (o[0] == '\0')
            return;
        memset(r->owner, ' ', 8);
        for (k = 0; k < 8 && o[k] != '\0'; k++)
            r->owner[k] = o[k];
        r->owner[8] = '\0';
        return;
    }
}

void
owners_free(JESJOB ***own)
{
    if (*own != NULL)
        jesjobfr(own);
    *own = NULL;
}

static int st_read_x(ISFROW **rows, int filter);

int
st_read(ISFROW **rows)
{
    return st_read_x(rows, 1);
}

/* All jobs, also those the user may not see: for DA's job numbers only,
** whose rows are filtered afterwards
*/
int
st_read_all(ISFROW **rows)
{
    return st_read_x(rows, 0);
}

static int
st_read_x(ISFROW **rows, int filter)
{
    char sysid[5];
    JES *j;
    __JQE *q;
    int total, active = 0, n = 0, i;
    ISFROW *out;
    char *buf;
    JESJOB **own;

    *rows = NULL;
    if ((j = jesopen()) == NULL)
        return ST_NOOPEN;
    st_sysid(sysid);
    /* The area ends on a block, not on an element: a pointer difference
    ** here is garbage, the compiler takes it for an exact multiple.
    */
    total = (int)(((char *)j->cp->jqeend - (char *)j->cp->jqe)
                  / (int)sizeof(__JQE));
    for (i = 0; i < total; i++) {
        q = j->cp->jqe + i;
        if (q->JQETYPE != _FREE && q->JQETYPE != _PURGE)
            active++;
    }
    out = malloc(((size_t)active + 1) * sizeof(*out));
    buf = malloc(4096u > j->cp->hct._BUFSIZE ? 4096u : j->cp->hct._BUFSIZE);
    if (out == NULL || buf == NULL) {
        free(out);
        free(buf);
        jesclose(&j);
        return ST_NOSTORAGE;
    }
    auth_reset();
    own = owners_read(j);
    for (i = 0; i < total; i++) {
        q = j->cp->jqe + i;
        if (q->JQETYPE != _FREE && q->JQETYPE != _PURGE && n < active) {
            fill(&out[n], q, sysid);
            job_class(j, q, buf, &out[n], sysid);
            owner_set(own, &out[n]);
            /* a job the user may not see is on no list (JESSPOOL) */
            if (!filter || auth_job(&out[n], 0))
                n++;
        }
    }
    owners_free(&own);
    free(buf);
    jesclose(&j);
    qsort(out, (size_t)n, sizeof(*out), order);
    positions(out, n);
    *rows = out;
    return n;
}

void
st_free(ISFROW *rows)
{
    free(rows);
}

static void
put(char *row, int width, int col, const char *text)
{
    size_t n = strlen(text);

    if (col < width)
        memcpy(row + col, text, n < (size_t)(width - col) ? n : (size_t)(width - col));
}

void
st_heading(char *row, int width)
{
    row[0] = A_BLUE;
    put(row, width, C_NP, "NP");
    put(row, width, C_NAME, "JOBNAME");
    put(row, width, C_TYPE - 1, "TYPE");
    put(row, width, C_NUM, "JNUM");
    put(row, width, C_PRTY - 1, "PRTY");
    put(row, width, C_QUEUE, "QUEUE");
    put(row, width, C_CLASS, "C");
    put(row, width, C_POS, "POS");
    put(row, width, C_HDN, "HDN");
    put(row, width, C_DEST, "DEST");
    put(row, width, C_SAFF, "SAFF");
    put(row, width, C_ASYS, "ASYS");
    put(row, width, C_STAT, "STAT");
}

void
st_row(const ISFROW *job, char *row, int width)
{
    char t[12];
    char plain = job->active ? A_WHITE : A_BLUE;
    char over = job->active ? A_RIN : A_GIN;

    row[0] = A_NP;
    row[C_NAME - 1] = plain;
    put(row, width, C_NAME, job->name);
    put(row, width, C_TYPE, job->type);
    snprintf(t, sizeof(t), "%5d", job->number);
    put(row, width, C_NUM, t);
    /* PRTY can be overtyped from column 23 on, as in IBM's SDSF V1R2 */
    row[C_PRTY - 2] = over;
    snprintf(t, sizeof(t), "%3d", job->prio);
    put(row, width, C_PRTY, t);
    row[C_QUEUE - 1] = plain;
    put(row, width, C_QUEUE, job->queue);
    row[C_CLASS] = job->jclass;
    if (job->pos > 0) {
        snprintf(t, sizeof(t), "%3d", job->pos);
        put(row, width, C_POS, t);
    }
    if (job->held > 0) {
        snprintf(t, sizeof(t), "%3d", job->held);
        put(row, width, C_HDN, t);
    }
    row[C_DEST - 1] = over;
    put(row, width, C_DEST, job->dest);
    row[C_SAFF - 1] = plain;
    put(row, width, C_SAFF, job->saff);
    put(row, width, C_ASYS, job->asys);
    if (job->hold)
        put(row, width, C_STAT, "HOLD");
}

/* ? on ST and I: RNUM (blank: the jobs are local), then the JCT's. As
** as in IBM's SDSF V1R2, the times and dates show even if JES2 set none.
*/
void
st_alt_heading(char *v, int vlen, int col)
{
    put(v, vlen, col - 5, "RNUM");
    put(v, vlen, col, "PROGRAMMER-NAME");
    put(v, vlen, col + 21, "ACCT");
    put(v, vlen, col + 26, "NOTIFY");
    put(v, vlen, col + 34, "ISYS");
    put(v, vlen, col + 39, "RD-TIME");
    put(v, vlen, col + 47, "RD-DATE");
    put(v, vlen, col + 55, "ESYS");
    put(v, vlen, col + 60, "ST-TIME");
    put(v, vlen, col + 68, "ST-DATE");
    put(v, vlen, col + 76, "CARDS");
    put(v, vlen, col + 82, "MC");
    put(v, vlen, col + 85, "TOT-LINES");
}

static void
alt_time(char *v, int vlen, int col, unsigned t)
{
    char s[12];

    t /= 100;
    snprintf(s, sizeof(s), "%2u:%02u:%02u", t / 3600 % 100, t / 60 % 60, t % 60);
    put(v, vlen, col, s);
}

static void
alt_date(char *v, int vlen, int col, unsigned d)
{
    char s[12];

    snprintf(s, sizeof(s), "%2X.%03X", (d >> 16) & 0xFF, (d & 0xFFFF) >> 4);
    put(v, vlen, col, s);
}

void
st_alt_row(const ISFROW *job, char *v, int vlen, int col)
{
    char t[12];

    put(v, vlen, col, job->pname);
    put(v, vlen, col + 21, job->acct);
    put(v, vlen, col + 26, job->notify);
    put(v, vlen, col + 34, job->isys);
    alt_time(v, vlen, col + 39, job->rdtime);
    alt_date(v, vlen, col + 48, job->rddate);
    put(v, vlen, col + 55, job->esys);
    alt_time(v, vlen, col + 60, job->sttime);
    alt_date(v, vlen, col + 69, job->stdate);
    snprintf(t, sizeof(t), "%5u", job->cards % 100000u);
    put(v, vlen, col + 76, t);
    if (col + 82 < vlen)
        v[col + 82] = job->mclass;
    snprintf(t, sizeof(t), "%10u", job->lines);
    put(v, vlen, col + 85, t);
}

const char *
st_purge(const ISFROW *job)
{
    static char msg[40];
    char id[12];
    int rc, ok;

    snprintf(id, sizeof(id), "%s%05d", job->type, job->number);
    /* JES2 takes these requests from an authorized caller only, and ISPF
    ** must not run under that: it holds for these calls alone.
    */
    if (isf_autask() != 0)
        return "NOT AUTHORIZED";
    /* The SYSOUT request reaches held output only; the rest of a job on the
    ** print queue goes with the cancel request.
    */
    if (job->group == G_PRINT)
        jesdelj(job->name, id);
    rc = jescanj(job->name, id, 1);
    /* the first request may have taken the last of it */
    ok = rc == CANJ_OK || (job->group == G_PRINT && rc == CANJ_NOJB);
    isf_uatask();
    if (ok)
        return NULL;
    if (rc == CANJ_ICAN)
        return "CANNOT CANCEL THIS JOB";
    snprintf(msg, sizeof(msg), "PURGE FAILED RC %d", rc);
    return msg;
}

/* ---- One job's data sets ---- */

/* The fixed part of a line: NP and DDNAME; what follows scrolls. The
** columns are those of IBM's SDSF V1R2, numbered on the line before scrolling.
*/
#define J_NP    1
#define J_DD    4
#define J_FIXED 12
#define J_STEP  13
#define J_PROC  23
#define J_DSID  32      /* 5 wide, on the right */
#define J_C     38
#define J_REC   40      /* 7 wide, on the right */
#define J_PAGE  48
#define J_BYTE  57
#define J_CC    66
#define J_RMT   69
#define J_NODE  73
#define J_OGRP  78
#define J_PRM   87
#define J_BRST  96
#define J_DATE  102
#define J_FORM  120
#define J_DNAM  129
#define J_FCB   139
#define J_UCS   144
#define J_WTR   149
#define J_FLSH  158

/* The fields of the PDDBs of the job, from its IOTs */
static void
jds_pddbs(ISFJDS *j, char *buf)
{
    JES *jes = j->jes;
    unsigned chain[2];
    int c, i;

    chain[0] = j->job->iotmttr;
    chain[1] = j->job->spinmttr;
    for (c = 0; c < 2; c++) {
        unsigned mttr = chain[c];
        int cap = 1000;

        while (mttr != 0 && cap-- > 0) {
            char *end = buf + jes->cp->hct._BUFSIZE;
            __PDDB *p;

            if (spool_read(jes->js[0], mttr, buf, jes->cp->hct._BUFSIZE) != 0)
                break;
            for (p = (__PDDB *)(buf + jes->cp->pddb1);
                 (char *)(p + 1) <= end && p->PDBDSKEY != 0; p++) {
                for (i = 0; i < j->ndd; i++) {
                    ISFDSX *x = &j->dsx[i];

                    if (j->dd[i]->dsid != p->PDBDSKEY)
                        continue;
                    x->copies = p->PDBCOPYS;
                    x->burst = (p->PDBFLAG2 & PDB2BRST) != 0;
                    memcpy(x->forms, p->PDBFORMS, 4);
                    memcpy(x->fcb, p->PDBFCB, 4);
                    memcpy(x->ucs, p->PDBUCS, 4);
                    memcpy(x->flash, p->PDBFLASH, 4);
                }
            }
            mttr = ((__IOT *)buf)->IOTIOTTR;
        }
    }
}

int
jds_open(ISFJDS *j, const ISFROW *job, int input)
{
    char id[12];
    char *buf;
    unsigned count, i;

    memset(j, 0, sizeof(*j));
    snprintf(id, sizeof(id), "%s%05d", job->type, job->number);
    if ((j->jes = jesopen()) == NULL)
        return 0;
    j->list = jesjob(j->jes, id, FILTER_JOBID, 1);
    if (j->list == NULL || arraycount(&j->list) == 0) {
        jds_close(j);
        return 0;
    }
    j->job = j->list[0];
    count = arraycount(&j->job->jesdd);
    j->dd = malloc((count + 1) * sizeof(*j->dd));
    j->dsx = calloc(count + 1, sizeof(*j->dsx));
    buf = malloc(4096u > j->jes->cp->hct._BUFSIZE ? 4096u : j->jes->cp->hct._BUFSIZE);
    if (j->dd == NULL || j->dsx == NULL || buf == NULL) {
        free(buf);
        jds_close(j);
        return 0;
    }
    /* everything but input is output: libc370 leaves the flags at 0 for
    ** a data set its walk of the JCT and IOTs does not find, as those of
    ** the SYSLOG task (libc370#781)
    */
    /* with INPUT ON the input too, as in IBM's SDSF V1R2: the internal text and
    ** the instream data, not the JCL as read nor the journal
    */
    j->input = input;
    for (i = 0; i < count; i++) {
        JESDD *dd = j->job->jesdd[i];

        if (!(dd->flag & FLAG_SYSIN)
            || (input && dd->dsid != DSID_INJCL && dd->dsid != DSID_INJNL))
            j->dd[j->ndd++] = dd;
    }
    jds_pddbs(j, buf);
    free(buf);
    {
        /* A job that never started has no start time: its year is 1970 */
        struct tm *tm = gmtime64(&j->job->start_time64);

        if (tm == NULL || tm->tm_year < 71)
            tm = gmtime64(&j->job->submit_time64);
        if (tm != NULL && tm->tm_year >= 71)
            snprintf(j->date, sizeof(j->date), "%02d.%03d",
                     tm->tm_year % 100, tm->tm_yday + 1);
    }
    return 1;
}

void
jds_close(ISFJDS *j)
{
    free(j->dd);
    free(j->dsx);
    j->dd = NULL;
    j->dsx = NULL;
    if (j->list != NULL)
        jesjobfr(&j->list);
    if (j->jes != NULL)
        jesclose(&j->jes);
}

/* A line of the data area from the fixed part and the scrolling one */
static void
jds_join(char *row, int width, const char *line, int shift)
{
    int n = width - J_FIXED;
    int from = J_FIXED + shift;

    if (from < JDS_VIRTUAL)
        memcpy(row + J_FIXED, line + from,
               (size_t)(n < JDS_VIRTUAL - from ? n : JDS_VIRTUAL - from));
}

void
jds_heading(char *row, int width, int shift)
{
    char v[JDS_VIRTUAL + 1];

    memset(v, ' ', sizeof(v));
    row[0] = A_BLUE;
    put(row, width, J_NP, "NP");
    put(row, width, J_DD, "DDNAME");
    put(v, JDS_VIRTUAL, J_STEP, "STEP-NAME");
    put(v, JDS_VIRTUAL, J_PROC, "PROC-STEP");
    put(v, JDS_VIRTUAL, J_DSID + 1, "DSID");
    put(v, JDS_VIRTUAL, J_C, "C");
    put(v, JDS_VIRTUAL, J_REC, "REC-CNT");
    put(v, JDS_VIRTUAL, J_PAGE, "PAGE-CNT");
    put(v, JDS_VIRTUAL, J_BYTE, "BYTE-CNT");
    put(v, JDS_VIRTUAL, J_CC, "CC");
    put(v, JDS_VIRTUAL, J_RMT, "RMT");
    put(v, JDS_VIRTUAL, J_NODE, "NODE");
    put(v, JDS_VIRTUAL, J_OGRP, "O-GRP-N");
    put(v, JDS_VIRTUAL, J_PRM, "PRMODE");
    put(v, JDS_VIRTUAL, J_BRST, "BURST");
    put(v, JDS_VIRTUAL, J_DATE, "CREATE-DATE-TIME");
    put(v, JDS_VIRTUAL, J_FORM, "FORMS");
    put(v, JDS_VIRTUAL, J_DNAM, "DEST-NAME");
    put(v, JDS_VIRTUAL, J_FCB, "FCB");
    put(v, JDS_VIRTUAL, J_UCS, "UCS");
    put(v, JDS_VIRTUAL, J_WTR, "WTR-NAME");
    put(v, JDS_VIRTUAL, J_FLSH, "FLASH");
    jds_join(row, width, v, shift);
}

/* Four bytes of the PDDB; stars when JES2 left them empty */
static void
put4(char *v, int col, const char *field)
{
    int i, blank = 1;

    for (i = 0; i < 4; i++) {
        char c = field[i];

        if (c == '\0')
            c = ' ';
        if (c != ' ')
            blank = 0;
        v[col + i] = c;
    }
    if (blank)
        memset(v + col, '*', 4);
}

void
jds_row(const ISFJDS *j, int i, char *row, int width, int shift)
{
    const JESDD *dd = j->dd[i];
    const ISFDSX *x = &j->dsx[i];
    char v[JDS_VIRTUAL + 1];
    char t[12];
    const char *step = (const char *)dd->stepname;
    const char *ddname = (const char *)dd->ddname;
    /* JES2's data sets keep the names libc370 gives them, also with INPUT
    ** ON (IBM's SDSF V1R2 says $JES2LOG, $JCLIMG, ... there; not taken, on purpose)
    */
    if (dd->flag & FLAG_JES2)
        step = "JES2";

    memset(v, ' ', sizeof(v));
    row[0] = A_NP;
    row[J_DD - 1] = A_BLUE;
    put(row, width, J_DD, ddname);
    put(v, JDS_VIRTUAL, J_STEP, step);
    put(v, JDS_VIRTUAL, J_PROC, (const char *)dd->procstep);
    snprintf(t, sizeof(t), "%5u", dd->dsid);
    put(v, JDS_VIRTUAL, J_DSID, t);
    v[J_C] = (char)dd->oclass;
    snprintf(t, sizeof(t), "%7u", dd->records);
    put(v, JDS_VIRTUAL, J_REC, t);
    if (x->copies > 0) {
        snprintf(t, sizeof(t), "%2u", x->copies);
        put(v, JDS_VIRTUAL, J_CC, t);
    }
    put(v, JDS_VIRTUAL, J_PRM, "LINE");
    put(v, JDS_VIRTUAL, J_BRST, x->burst ? "YES" : "NO");
    put(v, JDS_VIRTUAL, J_DATE, j->date);
    put4(v, J_FORM, x->forms);
    put4(v, J_FCB, x->fcb);
    put4(v, J_UCS, x->ucs);
    put4(v, J_FLSH, x->flash);
    jds_join(row, width, v, shift);
}

/* ---- The lines of output ---- */

#define CHUNK 32000

typedef struct chunk {
    struct chunk *next;
    char text[CHUNK];
} CHUNK_T;

typedef struct {
    ISFOUT *o;
    unsigned dsid;
    char cc;            /* the ASA character of the line, blank if none */
} OUTCTX;

static int
out_line(const char *line, unsigned len, void *arg)
{
    OUTCTX *c = arg;
    ISFOUT *o = c->o;
    CHUNK_T *ch = o->chunks;
    char *at;

    if (len > 255)
        len = 255;
    if (o->n == o->room) {
        int room = o->room ? o->room * 2 : 1000;
        char **nl = realloc(o->line, (size_t)room * sizeof(*nl));
        unsigned short *ln, *ds;

        if (nl == NULL) {
            o->full = 1;
            return 1;
        }
        o->line = nl;
        ln = realloc(o->len, (size_t)room * sizeof(*ln));
        if (ln == NULL) {
            o->full = 1;
            return 1;
        }
        o->len = ln;
        ds = realloc(o->dsid, (size_t)room * sizeof(*ds));
        if (ds == NULL) {
            o->full = 1;
            return 1;
        }
        o->dsid = ds;
        o->room = room;
    }
    if (ch == NULL || o->used + (int)len + 1 > CHUNK) {
        CHUNK_T *nw = malloc(sizeof(*nw));

        if (nw == NULL) {
            o->full = 1;
            return 1;
        }
        nw->next = ch;
        o->chunks = ch = nw;
        o->used = 0;
    }
    /* the line's carriage control in the byte before its text */
    at = ch->text + o->used;
    *at++ = c->cc;
    memcpy(at, line, len);
    o->used += (int)len + 1;
    o->line[o->n] = at;
    o->len[o->n] = (unsigned short)len;
    o->dsid[o->n] = (unsigned short)c->dsid;
    o->n++;
    return 0;
}

/*
 * One record of a data set is one line, as on IBM's SDSF V1R2: a record without
 * text is a blank line, and how the record would move the paper is not
 * shown (measured with an assembler listing: SPACE 1, 2 and 3 each give one
 * blank line there, a heading printed with a triple space none). Only a
 * machine code that moves the paper at once is no line at all: it carries
 * no text, as the page eject in front of a job log.
 */
static int
out_rec(const char *line, unsigned len, unsigned cc, void *arg)
{
    OUTCTX *c = arg;

    if ((cc & JESCC_MACH) && (JESCC_BYTE(cc) & 0x03) == 0x03)
        return 0;
    c->cc = (cc & JESCC_ASA) ? (char)JESCC_BYTE(cc) : ' ';
    return out_line(line, len, arg) != 0 ? -1 : 0;
}

int
out_add(ISFOUT *o, const char *line, unsigned len, unsigned dsid)
{
    OUTCTX c;

    c.o = o;
    c.dsid = dsid;
    c.cc = ' ';
    return out_line(line, len, &c);
}

int
out_load(ISFOUT *o, ISFJDS *j, unsigned dsid)
{
    OUTCTX c;
    int i, bad = 0;

    c.o = o;
    c.cc = ' ';
    for (i = 0; i < j->ndd && !o->full; i++) {
        if (dsid != 0 && j->dd[i]->dsid != dsid)
            continue;
        c.dsid = j->dd[i]->dsid;
        if (jesprtcc(j->jes, j->job, c.dsid, out_rec, &c, NULL) != 0)
            bad = 1;
    }
    return bad;
}

int
log_load(ISFOUT *o)
{
    CMTT *t;
    MTENTRY **e;
    unsigned n, i;
    OUTCTX c;

    /* the trace table is read in key 0: authorized through SDSF's SVC
    ** first, so that libc370 does not turn to SVC 244 by itself
    */
    if (isf_autask() != 0)
        return 1;
    t = cmtt_new();
    isf_uatask();
    if (t == NULL)
        return 1;
    e = cmtt_get_array(t);
    n = e ? arraycount(&e) : 0;
    c.o = o;
    c.dsid = 0;
    c.cc = ' ';
    for (i = 0; i < n && !o->full; i++) {
        char line[256];
        int len = e[i]->mtentlen, k;

        if (len <= 0)
            continue;
        if (len > 255)
            len = 255;
        for (k = 0; k < len; k++) {
            unsigned char ch = (unsigned char)e[i]->mtentdat[k];

            line[k] = ch < 0x40 ? ' ' : (char)ch;
        }
        while (len > 1 && line[len - 1] == ' ')
            len--;
        /* the trace table has the hour blank in front, IBM's SDSF V1R2 log a zero:
        ** 0000  3.48.59 becomes 0000 03.48.59
        */
        if (len > 12 && line[5] == ' ' && isdigit((unsigned char)line[6])
            && line[7] == '.' && line[10] == '.')
            line[5] = '0';
        out_line(line, (unsigned)len, &c);
    }
    cmtt_free(&t);
    return 0;
}

void
out_free(ISFOUT *o)
{
    CHUNK_T *ch = o->chunks;

    while (ch != NULL) {
        CHUNK_T *next = ch->next;

        free(ch);
        ch = next;
    }
    free(o->line);
    free(o->len);
    free(o->dsid);
    memset(o, 0, sizeof(*o));
}

/* ---- The outstanding replies ---- */

/* The parts of an ORE and of its WQE that are needed, at their offsets in
** IHAORE and IHAWQE of MVS 3.8j.
*/
#define ORE_LEN     32      /* ORESIZE in OS/VS2 */
#define ORE_LKP     0       /* the next ORE */
#define ORE_XC      7       /* buffer flags */
#define ORE_DELETE  0x20    /* OREBUFC: to be deleted, not to be shown */
#define ORE_WQE     12
#define WQE_LEN     192
#define WQE_TS      13      /* time, 8; a blank, the job, 8; a blank, text */
#define WQE_TEXT    146     /* from WQE_TS to the end of the text */
#define WQE_MCSF1   172
#define WQE_MCSA    0x80    /* routing and descriptor codes are there */
#define WQE_ROUT    176

static unsigned char ore_copy[WTOR_MAX][ORE_LEN];
static unsigned char wqe_copy[WTOR_MAX][WQE_LEN];

/* An address that can be one of the chain: not zero, below 16 MB */
static int
plausible(unsigned a)
{
    return a != 0 && a < 0x01000000 && (a & 3) == 0;
}

/* The OREs and WQEs are in storage that a program in key 8 cannot read
** (measured: S0C4, protection). They are copied in key 0 into the module's
** own storage, got in key 8: nothing is allocated in key 0. The chain may
** change meanwhile, there is no lock: the walk stops at the count the UCM
** names, at WTOR_MAX, and at any pointer that cannot be right.
*/
int
wtor_read(ISFWTOR *w, int max)
{
    CVT *cvt = *(CVT **)0x10;
    UCM *ucm = (UCM *)cvt->cvtcucb;
    unsigned ore;
    int n = 0, limit, i, k;
    unsigned char key;

    if (max > WTOR_MAX)
        max = WTOR_MAX;
    if (isf_autask() != 0)
        return -1;
    if (__super(PSWKEY0, &key) != 0) {
        isf_uatask();
        return -1;
    }
    limit = ucm->ucmrqnr + 4;
    if (limit > max)
        limit = max;
    ore = (unsigned)ucm->ucmrpyq & 0xFFFFFF;
    while (n < limit && plausible(ore)) {
        unsigned wqe;

        memcpy(ore_copy[n], (void *)ore, ORE_LEN);
        wqe = *(unsigned *)(ore_copy[n] + ORE_WQE) & 0xFFFFFF;
        if (!plausible(wqe))
            break;
        memcpy(wqe_copy[n], (void *)wqe, WQE_LEN);
        n++;
        ore = *(unsigned *)(ore_copy[n - 1] + ORE_LKP) & 0xFFFFFF;
    }
    __prob(key, NULL);
    isf_uatask();

    for (i = 0, k = 0; i < n; i++) {
        const unsigned char *o = ore_copy[i], *q = wqe_copy[i];
        int len = WQE_TEXT;

        if (o[ORE_XC] & ORE_DELETE)
            continue;
        w[k].id[0] = (char)o[4];
        w[k].id[1] = (char)o[5];
        w[k].id[2] = '\0';
        w[k].routed = (q[WQE_MCSF1] & WQE_MCSA) != 0;
        w[k].rout = (unsigned short)(q[WQE_ROUT] << 8 | q[WQE_ROUT + 1]);
        memcpy(w[k].text, q + WQE_TS, WQE_TEXT);
        while (len > 0 && (w[k].text[len - 1] == ' '
                           || (unsigned char)w[k].text[len - 1] < 0x40))
            len--;
        {
            int c;

            for (c = 0; c < len; c++)
                if ((unsigned char)w[k].text[c] < 0x40)
                    w[k].text[c] = ' ';
        }
        w[k].len = len;
        w[k].text[len] = '\0';
        k++;
    }
    return k;
}

/* ---- Operator commands ---- */

int
op_command(const char *text, int len)
{
    unsigned char buf[128];         /* IEECDCM: length, flags, the text */
    unsigned char *p = buf;
    unsigned char key;

    if (len > 100)
        len = 100;
    memset(buf, 0, sizeof(buf));
    buf[1] = 104;
    memset(buf + 4, ' ', sizeof(buf) - 4);
    memcpy(buf + 4, text, (size_t)len);
    if (isf_autask() != 0)
        return 1;
    if (__super(PSWKEY0, &key) != 0) {
        isf_uatask();
        return 1;
    }
    __asm__ volatile("  L   1,%0\n"
                     "  SLR 0,0\n"
                     "  SVC 34"
                     :
                     : "m"(p)
                     : "0", "1", "14", "15");
    __prob(key, NULL);
    isf_uatask();
    return 0;
}


/* ---- The address spaces, for DA ---- */

/* Offsets in the control blocks of MVS 3.8j, from an assembly of IHAASCB,
** IRAOUCB and IEECHAIN on the system. All of these blocks are in common
** storage that key 8 can read (measured); what an address space keeps in
** its private area cannot be reached without cross memory, which MVS 3.8j
** does not have.
*/
#define ASVT_MAXU   0x204
#define ASVT_ENTY   0x210
#define ASVT_AVAIL  0x80000000u
#define ASCB_ASID   0x24
#define ASCB_DP     0x2B
#define ASCB_CSCB   0x38
#define ASCB_TSB    0x3C
#define TSB_TRMID   0x68    /* TSBTRMID, the terminal's name (IKJTSB) */
#define ASCB_RCTF   0x66
#define ASCB_OUT    0x04
#define ASCB_OUCB   0x90
#define ASCB_FMCT   0x98
#define ASCB_JBNI   0xAC
#define ASCB_JBNS   0xB0
#define ASCB_EJST   0x40    /* TOD clock format: bit 51 is a microsecond */
#define ASCB_SRBT   0xC8
#define OUCB_IOSM   0x6C
#define OUCB_SFL    0x11
#define OUCB_NSW    0x80
#define OUCB_NPG    0x18
#define OUCB_DMN    0x24
#define OUCB_SRC    0x25
#define CH_KEY      0x08
#define CH_CLS      0x10
#define CH_TRKID    0x1C
#define CH_INITID   0x03
#define CH_PROCSN   0x20
#define CH_STEP     0x40

#define AT4(p, o)   (*(const unsigned *)((const char *)(p) + (o)))
#define AT2(p, o)   (*(const unsigned short *)((const char *)(p) + (o)))
#define AT1(p, o)   (*(const unsigned char *)((const char *)(p) + (o)))

/* An address that can point into common storage: not zero, below 16 MB */
static const char *
common(unsigned a)
{
    a &= 0xFFFFFF;
    return a != 0 ? (const char *)a : NULL;
}

/* Eight characters of a control block as a name; blank if it holds none */
static void
cbname(char *out, const char *p)
{
    int i, n = 0;

    for (i = 0; p != NULL && i < 8; i++) {
        unsigned char c = (unsigned char)p[i];

        if (c < 0x40)
            break;
        out[i] = (char)c;
        if (c != ' ')
            n = i + 1;
    }
    out[n] = '\0';
}

/* The terminal names of TSO users, from their TSBs: fetch-protected key-0
** storage (measured: key 8 cannot read it). Copied in one authorized
** window, only where that is quiet (isf_quiet). n TSBs at tsb,
** names to term; a name that cannot be read stays empty.
*/
static void
tsb_names(const unsigned *tsb, char (*term)[9], int n)
{
    unsigned char key;
    int i;

    for (i = 0; i < n; i++)
        term[i][0] = '\0';
    if (n == 0 || isf_quiet() != 0)
        return;
    if (__super(PSWKEY0, &key) == 0) {
        for (i = 0; i < n; i++)
            if (tsb[i] != 0)
                memcpy(term[i], (const char *)(tsb[i] & 0xFFFFFF) + TSB_TRMID, 8);
        __prob(key, NULL);
    }
    isf_uatask();
    for (i = 0; i < n; i++) {
        int k;

        term[i][8] = '\0';
        for (k = 0; k < 8; k++)
            if ((unsigned char)term[i][k] <= 0x40) {
                term[i][k] = '\0';
                break;
            }
    }
}

int
da_read(ISFDA **rows)
{
    CVT *cvt = *(CVT **)0x10;
    const char *asvt = (const char *)cvt->cvtasvt;
    unsigned max = AT4(asvt, ASVT_MAXU), i;
    ISFROW *jobs = NULL;
    ISFDA *a;
    int njobs = st_read_all(&jobs), n = 0, k, nt = 0;
    unsigned *tsb;              /* the TSO users' TSBs, for their terminals */
    int *tsbrow;
    char (*term)[9];

    a = calloc(max + 1, sizeof(*a));
    tsb = calloc(max + 1, sizeof(*tsb));
    tsbrow = calloc(max + 1, sizeof(*tsbrow));
    term = calloc(max + 1, sizeof(*term));
    if (a == NULL || tsb == NULL || tsbrow == NULL || term == NULL) {
        free(a);
        free(tsb);
        free(tsbrow);
        free(term);
        st_free(jobs);
        return ST_NOSTORAGE;
    }
    for (i = 0; i < max; i++) {
        unsigned e = AT4(asvt, ASVT_ENTY + 4 * i);
        const char *ascb, *oucb, *cscb, *nm;
        ISFDA *r = &a[n];

        if (e & ASVT_AVAIL)
            continue;
        if ((ascb = common(e)) == NULL)
            continue;
        r->asid = AT2(ascb, ASCB_ASID);
        oucb = common(AT4(ascb, ASCB_OUCB));
        if (common(AT4(ascb, ASCB_JBNI)) != NULL) {
            /* a batch job: the name is the key of the job's own CSCB */
            nm = common(AT4(ascb, ASCB_JBNI));
            cscb = nm - CH_KEY;
            strcpy(r->type, "JOB");
            cbname(r->step, cscb + CH_STEP);
        } else {
            nm = common(AT4(ascb, ASCB_JBNS));
            cscb = common(AT4(ascb, ASCB_CSCB));
            if (common(AT4(ascb, ASCB_TSB)) != NULL) {
                strcpy(r->type, "TSU");
                tsb[nt] = AT4(ascb, ASCB_TSB) & 0xFFFFFF;
                tsbrow[nt++] = n;
            }
            else if (cscb != NULL && AT1(cscb, CH_TRKID) == CH_INITID)
                strcpy(r->type, "INIT");
            else
                strcpy(r->type, "STC");
            if (cscb != NULL)
                cbname(r->step, cscb + CH_CLS);
        }
        cbname(r->name, nm);
        if (r->name[0] == '\0')
            continue;
        /* the terminal of a TSO user is in its TSB, which key 8 cannot read */
        if (cscb != NULL && strcmp(r->type, "TSU") != 0)
            cbname(r->pstep, cscb + CH_PROCSN);
        r->dp = AT1(ascb, ASCB_DP);
        r->real = AT2(ascb, ASCB_FMCT);
        if (oucb != NULL && (AT1(oucb, OUCB_SFL) & OUCB_NSW))
            strcpy(r->pos, "N/S");
        else if (AT1(ascb, ASCB_RCTF) & ASCB_OUT)
            strcpy(r->pos, "OUT");
        else
            strcpy(r->pos, "IN");
        {
            /* the high words count 2**20 microseconds, the low ones 2**-12 */
            double hi = (double)AT4(ascb, ASCB_EJST) + (double)AT4(ascb, ASCB_SRBT);
            double lo = (double)AT4(ascb, ASCB_EJST + 4) + (double)AT4(ascb, ASCB_SRBT + 4);

            r->cpu = (hi * 1048576.0 + lo / 4096.0) / 1000000.0;
        }
        if (oucb != NULL) {
            r->excp = AT4(oucb, OUCB_IOSM);
            r->pgn = AT1(oucb, OUCB_NPG);
            r->dmn = AT1(oucb, OUCB_DMN);
            r->sr = AT1(oucb, OUCB_SRC);
        }
        r->jclass = ' ';
        /* the number from JES2: the executing job of this name and kind;
        ** the master address space shows that of the SYSLOG task
        */
        for (k = 0; k < njobs; k++) {
            const ISFROW *j = &jobs[k];
            const char *want = r->asid == 1 ? "SYSLOG" : r->name;
            size_t wl = strlen(want);

            /* the names from JES2 are blank on the right */
            if (!j->active || strncmp(j->name, want, wl) != 0
                || (wl < 8 && j->name[wl] != ' ' && j->name[wl] != '\0'))
                continue;
            if (r->asid != 1 && strcmp(r->type, "INIT") != 0
                && strcmp(j->type, r->type) != 0)
                continue;
            if (strcmp(r->type, "INIT") == 0)
                break;
            r->number = j->number;
            r->jclass = j->jclass;
            break;
        }
        n++;
    }
    st_free(jobs);
    /* a TSO user's PROCSTEP is the terminal, as in IBM's SDSF V1R2 */
    tsb_names(tsb, term, nt);
    for (k = 0; k < nt; k++)
        snprintf(a[tsbrow[k]].pstep, sizeof(a[tsbrow[k]].pstep), "%s", term[k]);
    free(tsb);
    free(tsbrow);
    free(term);
    *rows = a;
    return n;
}

/* The columns of DA, those of IBM's SDSF V1R2: JOBNAME stays, the rest is a
** line of DA_VIRTUAL columns that PF11 moves left by DA_SHIFT
*/
#define D_NAME  4
#define D_FIXEDH 12     /* where the moving columns begin: in the heading, */
#define D_FIXED 13      /* and in a row (so IBM's SDSF V1R2 has them) */
#define D_STEP  13
#define D_PSTEP 22
#define D_TYPE  31
#define D_NUM   36      /* 5 wide, on the right */
#define D_CLASS 42
#define D_POS   44
#define D_DP    48
#define D_PGN   51      /* 3 wide, on the right */
#define D_REAL  55      /* 4 wide, on the right */
#define D_PAGE  59      /* 7 wide, on the right */
#define D_SIO   66
#define D_CPU   73
#define D_ASID  80      /* 5 wide, on the right */
#define D_EXCP  86      /* 9 wide, on the right */
#define D_TIME  96      /* 10 wide, on the right */
#define D_SR    107
#define D_DMN   110     /* 3 wide, on the right */

/* The procedure this TSO user logged on with: the class field of the own
** address space's CSCB, as DA shows it for a TSO user
*/
void
who_term(char term[9])
{
    const char *ascb = common(*(const unsigned *)0x224);    /* PSAAOLD */
    unsigned tsb = ascb != NULL ? AT4(ascb, ASCB_TSB) & 0xFFFFFF : 0;
    char t[1][9];

    term[0] = '\0';
    if (tsb == 0)
        return;
    tsb_names(&tsb, t, 1);
    strcpy(term, t[0]);
}

void
who_proc(char proc[9])
{
    const char *ascb = common(*(const unsigned *)0x224);    /* PSAAOLD */
    const char *cscb = ascb != NULL ? common(AT4(ascb, ASCB_CSCB)) : NULL;

    proc[0] = '\0';
    if (cscb != NULL)
        cbname(proc, cscb + CH_CLS);
}

/* A number with commas between the thousands, right in w columns */
static void
commas(char *out, int w, unsigned n)
{
    char d[16], t[24];
    int len = snprintf(d, sizeof(d), "%u", n), i, k = 0;

    for (i = 0; i < len; i++) {
        if (i > 0 && (len - i) % 3 == 0)
            t[k++] = ',';
        t[k++] = d[i];
    }
    t[k] = '\0';
    snprintf(out, (size_t)w + 1, "%*s", w, t);
}

/* The swap-out reason as RMF names it */
static const char *
swap_reason(int code)
{
    static const char *const name[] = {
        "", "TI", "TO", "LW", "XS", "RS", "DW", "RQ", "NQ", "EX", "US"
    };

    return code > 0 && code < (int)(sizeof(name) / sizeof(name[0])) ? name[code] : "";
}

/* Copy a line of DA_VIRTUAL columns to the screen: the fixed part, then
** the rest from shift on
*/
static void
da_shift(char *row, int width, const char *v, int shift, int fixed, int vlen)
{
    int c;

    /* a screen wider than the line gets blanks after its end */
    for (c = 0; c < width; c++) {
        int from = c < fixed ? c : c + shift;

        row[c] = from < vlen ? v[from] : ' ';
    }
}

/* The columns right of TYPE, JNUM and C: as DA shows them, and after the
** command ? (as in IBM's SDSF V1R2: ASID, EXCP-CNT, CPU-TIME first, DP,
** POS, SR, PGN, DMN last). h* where the heading's word starts, the others
** where a value starts.
*/
typedef struct {
    int vlen;
    int pos, dp, pgn, real, page, sio, cpu, asid, excp, time, sr, dmn;
    int hpos, hdp, hpgn, hreal, hpage, hsio, hcpu, hasid, hexcp, htime, hsr, hdmn;
} DACOLS;

static const DACOLS da_cols[2] = {
    { 113, D_POS, D_DP, D_PGN, D_REAL, D_PAGE, D_SIO, D_CPU, D_ASID, D_EXCP, D_TIME, D_SR, D_DMN,
      D_POS, D_DP, D_PGN, D_REAL, D_PAGE + 1, D_SIO + 3, D_CPU + 2, D_ASID + 1, D_EXCP,
      D_TIME + 1, D_SR, D_DMN },
    { 114, 100, 97, 107, 71, 75, 82, 89, 43, 49, 59, 104, 111,
      100, 97, 107, 70, 76, 85, 91, 44, 49, 60, 104, 111 },
};
static int da_alt;

void
da_set_alt(int alt)
{
    da_alt = alt != 0;
}

int
da_vlen(void)
{
    return da_cols[da_alt].vlen;
}

void
da_heading(char *row, int width, int shift)
{
    const DACOLS *k = &da_cols[da_alt];
    char v[DA_VIRTUAL + 1];

    memset(v, ' ', sizeof(v));
    v[0] = A_BLUE;
    put(v, k->vlen, C_NP, "NP");
    put(v, k->vlen, D_NAME, "JOBNAME");
    put(v, k->vlen, D_STEP, "STEPNAME");
    put(v, k->vlen, D_PSTEP, "PROCSTEP");
    put(v, k->vlen, D_TYPE, "TYPE");
    put(v, k->vlen, D_NUM, "JNUM");
    put(v, k->vlen, D_CLASS, "C");
    put(v, k->vlen, k->hpos, "POS");
    put(v, k->vlen, k->hdp, "DP");
    put(v, k->vlen, k->hpgn, "PGN");
    put(v, k->vlen, k->hreal, "REAL");
    put(v, k->vlen, k->hpage, "PAGING");
    put(v, k->vlen, k->hsio, "SIO");
    put(v, k->vlen, k->hcpu, "CPU%");
    put(v, k->vlen, k->hasid, "ASID");
    put(v, k->vlen, k->hexcp, "EXCP-CNT");
    put(v, k->vlen, k->htime, "CPU-TIME");
    put(v, k->vlen, k->hsr, "SR");
    put(v, k->vlen, k->hdmn, "DMN");
    da_shift(row, width, v, shift, D_FIXEDH, k->vlen);
}

int
da_pgn(void)
{
    return da_cols[da_alt].pgn;
}

void
da_row(const ISFDA *a, char *row, int width, int shift)
{
    const DACOLS *k = &da_cols[da_alt];
    char v[DA_VIRTUAL + 1], t[24];
    /* as in IBM's SDSF V1R2: an address space swapped out in blue, the others in
    ** white; PGN, which can be overtyped, in red (green when swapped
    ** out)
    */
    int out = strcmp(a->pos, "OUT") == 0;
    char plain = out ? A_BLUE : A_WHITE;

    memset(v, ' ', sizeof(v));
    v[0] = A_NP;
    v[D_NAME - 1] = plain;
    put(v, k->vlen, D_NAME, a->name);
    put(v, k->vlen, D_STEP, a->step);
    put(v, k->vlen, D_PSTEP, a->pstep);
    put(v, k->vlen, D_TYPE, strcmp(a->type, "INIT") == 0 ? "" : a->type);
    if (a->number > 0) {
        snprintf(t, sizeof(t), "%5d", a->number);
        put(v, k->vlen, D_NUM, t);
    }
    v[D_CLASS] = a->jclass;
    put(v, k->vlen, k->pos, a->pos);
    snprintf(t, sizeof(t), "%02X", a->dp);
    put(v, k->vlen, k->dp, t);
    v[k->pgn - 1] = out ? A_GIN : A_RIN;
    if (a->pgn > 0) {
        snprintf(t, sizeof(t), "%3d", a->pgn);
        put(v, k->vlen, k->pgn, t);
    }
    v[k->pgn + 3] = plain;
    snprintf(t, sizeof(t), "%4d", a->real);
    put(v, k->vlen, k->real, t);
    put(v, k->vlen, k->page, "   0.00");
    snprintf(t, sizeof(t), "%7.2f", a->sio);
    put(v, k->vlen, k->sio, t);
    snprintf(t, sizeof(t), "%7.2f", a->cpupct);
    put(v, k->vlen, k->cpu, t);
    snprintf(t, sizeof(t), "%5d", a->asid);
    put(v, k->vlen, k->asid, t);
    commas(t, 9, a->excp);
    put(v, k->vlen, k->excp, t);
    snprintf(t, sizeof(t), "%10.2f", a->cpu);
    put(v, k->vlen, k->time, t);
    put(v, k->vlen, k->sr, swap_reason(a->sr));
    if (a->dmn > 0) {
        snprintf(t, sizeof(t), "%3d", a->dmn);
        put(v, k->vlen, k->dmn, t);
    }
    da_shift(row, width, v, shift, D_FIXED, k->vlen);
}
