/* isfpan.c - the rows of the panels I, O, H, PR and INIT
**
** Each row is kept as one line of text as wide as all of the panel's
** columns (the virtual line); PF11 shows it from further right. The columns,
** their headings and how far PF11 moves are those of IBM's SDSF V1R2.
**
** I comes from the jobs of the Status panel. H and O read the job's PDDBs
** from the spool: held and not held SYSOUT data sets. Initiators and
** printers are known only to JES2 in its own address space, which MVS 3.8j
** cannot reach: INIT and PR issue $DI and $DU,PRTS and read the answer from
** the master trace table, so each display of them leaves the command and
** its answer in the system log.
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <mvs/jes2.h>
#include <ibm/jes2/jct.h>
#include <ibm/jes2/iot.h>
#include <ibm/jes2/pddb.h>

#include "isf.h"

/* The attributes of the data area, see ispplib/isflist */
#define A_BLUE  0x05
#define A_WHITE 0x07
#define A_RED   0x10    /* can be overtyped, active */
#define A_GREEN 0x11    /* can be overtyped, not active */
#define A_NP    0x1D
#define A_GIN   0x12    /* overtyped and read (I): not active */
#define A_RIN   0x13    /* the same, active */

static void
put(char *v, int vlen, int col, const char *text)
{
    size_t n = strlen(text);

    if (col < vlen)
        memcpy(v + col, text, n < (size_t)(vlen - col) ? n : (size_t)(vlen - col));
}

/* Four bytes of a PDDB; stars when JES2 left them empty */
static void
put4(char *v, int col, const unsigned char *field)
{
    int i, blank = 1;

    for (i = 0; i < 4; i++) {
        char c = (char)field[i];

        if (c == '\0')
            c = ' ';
        if (c != ' ')
            blank = 0;
        v[col + i] = c;
    }
    if (blank)
        memset(v + col, '*', 4);
}

/* Some bytes of a control block as a string, blank on the right cut off */
static void
field(char *out, const unsigned char *p, int n)
{
    int i, end = 0;

    for (i = 0; i < n; i++) {
        unsigned char c = p[i];

        out[i] = c < 0x40 ? ' ' : (char)c;
        if (out[i] != ' ')
            end = i + 1;
    }
    out[end] = '\0';
}

/* Time of day and date as JES2 keeps them in the JCT: hundredths of a
** second since midnight, and 0CYYDDDF packed. Nothing if JES2 set none.
*/
static void
jct_time(char *v, int vlen, int col, unsigned t)
{
    char s[12];

    if (t == 0)
        return;
    t /= 100;
    snprintf(s, sizeof(s), "%2u:%02u:%02u", t / 3600, t / 60 % 60, t % 60);
    put(v, vlen, col, s);
}

static void
jct_date(char *v, int vlen, int col, unsigned d)
{
    char s[12];

    if (d == 0)
        return;
    snprintf(s, sizeof(s), "%02X.%03X", (d >> 16) & 0xFF, (d & 0xFFFF) >> 4);
    put(v, vlen, col, s);
}

/* ---- The list of rows ---- */

static int
pan_room(ISFPAN *p)
{
    if (p->n == p->room) {
        int room = p->room ? p->room * 2 : 32;
        char *t = realloc(p->text, (size_t)room * (size_t)p->vlen);
        ISFROW *j;
        unsigned *k;

        if (t == NULL)
            return 0;
        p->text = t;
        j = realloc(p->job, (size_t)room * sizeof(*j));
        if (j == NULL)
            return 0;
        p->job = j;
        k = realloc(p->key, (size_t)room * 2 * sizeof(*k));
        if (k == NULL)
            return 0;
        p->key = k;
        p->room = room;
    }
    return 1;
}

/* A new row, blank, its job empty; NULL if storage ran out */
static char *
pan_add(ISFPAN *p)
{
    char *v;

    if (!pan_room(p))
        return NULL;
    v = p->text + (size_t)p->n * (size_t)p->vlen;
    memset(v, ' ', (size_t)p->vlen);
    memset(&p->job[p->n], 0, sizeof(p->job[p->n]));
    p->key[2 * p->n] = p->key[2 * p->n + 1] = 0;
    p->job[p->n].jclass = ' ';
    p->n++;
    return v;
}

void
pan_free(ISFPAN *p)
{
    free(p->head);
    free(p->text);
    free(p->job);
    free(p->key);
    memset(p, 0, sizeof(*p));
}

/* The heading of each panel and the width of its virtual line */
static const char h_i[] =
    "NP JOBNAME TYPE JNUM  PRTY C  POS DEST     RMT NODE SAFF ASYS STAT";
static const char h_h[] =
    "NP JOBNAME TYPE JNUM  DN  CRDATE  C FORM FCB  DEST      RMT NODE"
    "   TOT-REC RNUM  PROGRAMMER-NAME      ACCT NOTIFY  ISYS RD-TIME "
    "RD-DATE ESYS ST-TIME ST-DATE END-TIME END-DATE CARDS PR STATUS U"
    "CS JC BURST PRMODE   WTR     MC FLASH";
static const char h_o[] =
    "NP JOBNAME TYPE JNUM  PRTY C FORM FCB  DEST       TOT-REC   PRT-"
    "REC DEVICE   STATUS SYSID RMT  NODE O-GRP-N  OGI1 OGI2 JP UCS  W"
    "TR      FLASH BURST PRMODE";
static const char h_pr[] =
    "NP   PRINTER  STATUS  SFORM SCLASS          JOBNAME TYPE JNUM  R"
    "EC-CNT REC-PRT  JP DP  C FORM FCB  UCS  WRITER  FLASH DEST-NAME "
    "BURST SEP SEPDS PRMODE   SFCB SUCS SWRITER  SFLH WORK-SELECTION "
    "                          SBURST SPRMODE1 SPRMODE2 SDEST1   SDES"
    "T2   SDEST3   SDEST4   SJOBNAME M   NPRO MODE CKPTLINE CKPTPAGE "
    "CKPTSEC CKPTMODE CPY";
static const char h_init[] =
    "NP ID STATUS     CLASSES  JOB-NAME STEP-NAME PROC-STEP TYPE JNUM  C ASID";

static int
pan_init(ISFPAN *p, int kind, int alt)
{
    const char *h;
    int vlen, fixedh;

    memset(p, 0, sizeof(*p));
    p->kind = kind;
    p->alt = alt && kind == PK_I;
    switch (kind) {
    case PK_I:    h = h_i;    vlen = p->alt ? I_ALT_LEN : 80; fixedh = 12; break;
    case PK_H:    h = h_h;    vlen = 230; fixedh = 12; break;
    case PK_O:    h = h_o;    vlen = 157; fixedh = 12; break;
    case PK_PR:   h = h_pr;   vlen = 341; fixedh = 14; break;
    default:      h = h_init; vlen = 80;  fixedh = 12; break;
    }
    p->vlen = vlen;
    p->fixedh = fixedh;
    if ((p->head = malloc((size_t)vlen)) == NULL)
        return 0;
    memset(p->head, ' ', (size_t)vlen);
    p->head[0] = A_BLUE;
    put(p->head, vlen, 1, h);
    if (p->alt)
        st_alt_heading(p->head, vlen, I_ALT_COL);
    return 1;
}

/* How far page `page` of PF11 moves the line; -1 if there is no such page.
** As in IBM's SDSF V1R2 with 80 columns: the first page goes on right after
** the screen, every further one shows its last column again, the last one
** ends with the line. O differs by a column or two: its own numbers.
*/
int
line_shift(int vlen, int fixedh, int alt, int width, int page)
{
    int max = vlen - width, s, k;

    if (page == 0)
        return 0;
    if (max <= 0)
        return -1;
    /* ? on ST and I (IBM's SDSF V1R2): the first page one column less */
    s = width - fixedh - (alt ? 1 : 0);
    for (k = 1; k < page; k++) {
        if (s >= max)
            return -1;
        s += width - 1 - fixedh;
    }
    return s < max ? s : max;
}

int
pan_shift(const ISFPAN *p, int width, int page)
{
    static const int o80[] = { 0, 67, 77 };

    if (page > 0 && p->kind == PK_O && width == 80 && p->vlen > width)
        return page < 3 ? o80[page] : -1;
    return line_shift(p->vlen, p->fixedh, p->alt, width, page);
}

/* Row i (-1 the heading) for a screen of width columns: the columns up to
** the fixed ones as they are, the rest from shift on. The fixed part of a
** row is one column wider than that of the heading, as in IBM's SDSF V1R2.
*/
void
line_put(const char *v, int vlen, int heading, int fixedh, char *row,
         int width, int shift)
{
    int fixed = heading ? fixedh : fixedh + 1;
    int c;

    if (shift == 0)
        fixed = width;
    for (c = 0; c < width; c++) {
        int from = c < fixed ? c : c + shift;

        row[c] = from < vlen ? v[from] : ' ';
    }
}

void
pan_line(const ISFPAN *p, int i, char *row, int width, int shift)
{
    const char *v = i < 0 ? p->head : p->text + (size_t)i * (size_t)p->vlen;

    line_put(v, p->vlen, i < 0, p->fixedh, row, width, shift);
}

/* ---- I: the jobs on the input and execution queues ---- */

static int
read_i(ISFPAN *p, ISFKEEP keep, void *arg)
{
    ISFROW *jobs;
    int n = st_read(&jobs), i;
    char t[12];

    if (n < 0)
        return n;
    for (i = 0; i < n; i++) {
        const ISFROW *j = &jobs[i];
        char *v;

        /* as in IBM's SDSF V1R2: the executing ones too (I$ shows the TSO users) */
        if (strcmp(j->queue, "PRINT") == 0)
            continue;
        if (keep != NULL && !keep(j, arg))
            continue;
        if ((v = pan_add(p)) == NULL)
            break;
        p->job[p->n - 1] = *j;
        v[0] = A_NP;
        v[3] = j->active ? A_WHITE : A_BLUE;
        /* PRTY, C and DEST can be overtyped (as in IBM's SDSF V1R2); one
        ** attribute for each run of them: Wally ISPF cuts a screen's data
        ** stream at 3584 bytes, and each colour change costs about ten
        */
        v[22] = v[34] = j->active ? A_RIN : A_GIN;
        v[29] = v[43] = v[3];
        put(v, p->vlen, 4, j->name);
        put(v, p->vlen, 13, j->type);
        snprintf(t, sizeof(t), "%5d", j->number);
        put(v, p->vlen, 17, t);
        snprintf(t, sizeof(t), "%3d", j->prio);
        put(v, p->vlen, 24, t);
        /* the class of a TSO user is $, of a started task # (IBM's SDSF V1R2) */
        v[28] = strcmp(j->type, "TSU") == 0 ? '$' : strcmp(j->type, "STC") == 0 ? '#'
              : j->jclass;
        if (j->pos > 0) {
            snprintf(t, sizeof(t), "%3d", j->pos);
            put(v, p->vlen, 31, t);
        }
        put(v, p->vlen, 35, j->dest);
        put(v, p->vlen, 48, "   1");
        put(v, p->vlen, 53, j->saff);
        put(v, p->vlen, 58, j->asys);
        if (j->hold)
            put(v, p->vlen, 63, "HOLD");
        if (p->alt)
            st_alt_row(j, v, p->vlen, I_ALT_COL);
    }
    st_free(jobs);
    return p->n;
}

/* ---- H and O: the SYSOUT data sets of the jobs, held or not ---- */

/* What one job has of held (or not held) SYSOUT */
typedef struct {
    int count;              /* data sets */
    unsigned records;
    unsigned char oclass;   /* those of the first data set */
    const __PDDB *first;
    __PDDB copy;
} SUMS;

#define SEEN_MAX 128

static void
sum_pddbs(JES *jes, unsigned mttr, char *buf, int held, SUMS *s,
          unsigned short *seen, int *nseen)
{
    int cap = 1000;
    unsigned size = jes->cp->hct._BUFSIZE;

    while (mttr != 0 && cap-- > 0) {
        const __IOT *iot = (const __IOT *)buf;
        unsigned end;
        const __PDDB *pd;
        int k;

        if (spool_read(jes->js[0], mttr, buf, size) != 0)
            break;
        /* IOTPDDBP bounds the PDDBs, see libc370's jesjob */
        end = iot->IOTPDDBP;
        if (end < jes->cp->pddb1 || end > size - sizeof(__PDDB) + 1)
            end = size - sizeof(__PDDB) + 1;
        for (pd = (const __PDDB *)(buf + jes->cp->pddb1);
             (const char *)pd < buf + end && pd->PDBDSKEY != 0; pd++) {
            if (pd->PDBMTTR == 0 || (pd->PDBFLAG1 & (PDB1NULL | PDB1NSOT)))
                continue;
            if (pd->PDBDSKEY == PDBINJCL || pd->PDBDSKEY == PDBINTXT
                || pd->PDBDSKEY == PDBINJNL)
                continue;
            if (((pd->PDBFLAG1 & PDB1HOLD) != 0) != held)
                continue;
            for (k = 0; k < *nseen && seen[k] != pd->PDBDSKEY; k++)
                ;
            if (k < *nseen)
                continue;
            if (*nseen < SEEN_MAX)
                seen[(*nseen)++] = pd->PDBDSKEY;
            if (s->count++ == 0) {
                s->copy = *pd;
                s->first = &s->copy;
                s->oclass = pd->PDBCLASS;
            }
            s->records += pd->PDBRECCT;
        }
        mttr = iot->IOTIOTTR;
    }
}

/* The rows by their keys, lowest first; equal ones keep their order */
static const unsigned *sort_key;

static int
by_key(const void *a, const void *b)
{
    int x = *(const int *)a, y = *(const int *)b;
    const unsigned *kx = sort_key + 2 * x, *ky = sort_key + 2 * y;

    if (kx[0] != ky[0])
        return kx[0] < ky[0] ? -1 : 1;
    if (kx[1] != ky[1])
        return kx[1] < ky[1] ? -1 : 1;
    return x - y;
}

static void
pan_sort(ISFPAN *p)
{
    int *ix = malloc((size_t)(p->n > 0 ? p->n : 1) * sizeof(*ix));
    char *text = malloc((size_t)(p->n > 0 ? p->n : 1) * (size_t)p->vlen);
    ISFROW *job = malloc((size_t)(p->n > 0 ? p->n : 1) * sizeof(*job));
    int i;

    if (ix != NULL && text != NULL && job != NULL) {
        for (i = 0; i < p->n; i++)
            ix[i] = i;
        sort_key = p->key;
        qsort(ix, (size_t)p->n, sizeof(*ix), by_key);
        for (i = 0; i < p->n; i++) {
            memcpy(text + (size_t)i * (size_t)p->vlen,
                   p->text + (size_t)ix[i] * (size_t)p->vlen, (size_t)p->vlen);
            job[i] = p->job[ix[i]];
        }
        memcpy(p->text, text, (size_t)p->n * (size_t)p->vlen);
        memcpy(p->job, job, (size_t)p->n * sizeof(*job));
    }
    free(ix);
    free(text);
    free(job);
}

static int
read_ho(ISFPAN *p, int held, ISFKEEP keep, void *arg)
{
    JES *jes;
    char *buf, *jbuf;
    unsigned size;
    int total, i, k;
    char sysid[5];
    unsigned short seen[SEEN_MAX];
    JESJOB **own;

    auth_reset();
    if ((jes = jesopen()) == NULL)
        return ST_NOOPEN;
    st_sysid(sysid);
    size = jes->cp->hct._BUFSIZE;
    buf = malloc(size > 4096 ? size : 4096);
    jbuf = malloc(size > 4096 ? size : 4096);
    if (buf == NULL || jbuf == NULL) {
        free(buf);
        free(jbuf);
        jesclose(&jes);
        return ST_NOSTORAGE;
    }
    own = owners_read(jes);
    /* see st_read: the area ends on a block */
    total = (int)(((char *)jes->cp->jqeend - (char *)jes->cp->jqe)
                  / (int)sizeof(__JQE));
    for (i = 0; i < total; i++) {
        const __JQE *q = jes->cp->jqe + i;
        const __JCT *jct = (const __JCT *)jbuf;
        unsigned no = q->JQEJOBNO;
        ISFROW job;
        SUMS s;
        char t[24], *v;
        int nseen = 0;

        if (q->JQETYPE == _FREE || q->JQETYPE == _PURGE)
            continue;
        /* H: a job with held data sets; O: one on the print queue */
        if (held && (q->JQEHLDCT >> 4) == 0)
            continue;
        /* on the execution queue the low bits are the class, not a queue */
        if (!held && ((q->JQETYPE & _XEQ) || !(q->JQETYPE & (_OUTPUT | _HARDCPY))))
            continue;
        memset(&job, 0, sizeof(job));
        memcpy(job.name, q->JQEJNAME, 8);
        job.name[8] = '\0';
        strcpy(job.type, no >= 20000 ? "TSU" : no >= 10000 ? "STC" : "JOB");
        job.number = (int)(no % 10000);
        job.prio = q->JQEPRIO >> 4;
        job.queue = "PRINT";
        if (spool_read(jes->js[0], q->JQETRAK, jbuf, size) != 0)
            continue;
        /* who may see it, as on ST (isfauth.c): its owner from the JCT */
        memcpy(job.owner, jct->JCTUSEID, 8);
        for (k = 0; k < 8; k++)
            if ((unsigned char)job.owner[k] < 0x40)
                job.owner[k] = ' ';
        job.owner[8] = '\0';
        owner_set(own, &job);
        if (!auth_job(&job, 0))
            continue;
        memset(&s, 0, sizeof(s));
        sum_pddbs(jes, jct->JCTIOT, buf, held, &s, seen, &nseen);
        sum_pddbs(jes, jct->JCTSPIOT, buf, held, &s, seen, &nseen);
        if (s.count == 0)
            continue;
        job.jclass = (char)s.oclass;
        field(job.forms, s.first->PDBFORMS, 4);
        /* the job's destination, as ST shows it: what DEST goes by on O
        ** and H (IBM's SDSF V1R2), and what $RALL changes when DEST is
        ** overtyped (the data sets' own PDBDEST stays as it was)
        */
        if ((q->JQEPRTRT & 0xFF) == 0)
            strcpy(job.dest, "LOCAL");
        else
            snprintf(job.dest, sizeof(job.dest), "R%u", q->JQEPRTRT & 0xFFu);
        if (keep != NULL && !keep(&job, arg))
            continue;
        if ((v = pan_add(p)) == NULL)
            break;
        p->job[p->n - 1] = job;
        p->job[p->n - 1].jclass =
            strcmp(job.type, "JOB") == 0 ? (char)jct->JCTCLASS : ' ';
        /* as in IBM's SDSF V1R2: in the order the jobs ended */
        p->key[2 * (p->n - 1)] = jct->JCTXDTOF;
        p->key[2 * (p->n - 1) + 1] = jct->JCTXEQOF;
        p->lines += s.records;
        v[0] = A_NP;
        v[3] = A_BLUE;
        put(v, p->vlen, 4, job.name);
        put(v, p->vlen, 13, job.type);
        snprintf(t, sizeof(t), "%5d", job.number);
        put(v, p->vlen, 17, t);
        if (held) {
            /* C and DEST can be overtyped (as in IBM's SDSF V1R2); DEST
            ** takes input, with O in NP
            */
            v[34] = A_GREEN;
            v[46] = A_GIN;
            v[36] = v[55] = A_BLUE;
            snprintf(t, sizeof(t), "%2d", s.count);
            put(v, p->vlen, 23, t);
            jct_date(v, p->vlen, 26, jct->JCTRDTON);
            v[35] = (char)s.oclass;
            put4(v, 37, s.first->PDBFORMS);
            put4(v, 42, s.first->PDBFCB);
            put(v, p->vlen, 47, job.dest);
            put(v, p->vlen, 61, "   1");
            snprintf(t, sizeof(t), "%7u", s.records);
            put(v, p->vlen, 68, t);
            field(t, jct->JCTPNAME, 20);
            put(v, p->vlen, 82, t);
            field(t, jct->JCTACCTN, 4);
            put(v, p->vlen, 103, t);
            field(t, jct->JCTTSUID, 7);
            put(v, p->vlen, 108, t);
            field(t, jct->JCTRDSID, 4);
            put(v, p->vlen, 116, t[0] ? t : sysid);
            jct_time(v, p->vlen, 121, jct->JCTRDRON);
            jct_date(v, p->vlen, 130, jct->JCTRDTON);
            field(t, jct->JCTEXSID, 4);
            put(v, p->vlen, 137, t);
            jct_time(v, p->vlen, 142, jct->JCTXEQON);
            jct_date(v, p->vlen, 151, jct->JCTXDTON);
            jct_time(v, p->vlen, 158, jct->JCTXEQOF);
            jct_date(v, p->vlen, 167, jct->JCTXDTOF);
            snprintf(t, sizeof(t), "%5u", jct->JCTCARDS);
            put(v, p->vlen, 176, t);
            snprintf(t, sizeof(t), "%2d", job.prio);
            put(v, p->vlen, 182, t);
            put4(v, 192, s.first->PDBUCS);
            if (strcmp(job.type, "JOB") == 0)
                v[197] = (char)jct->JCTCLASS;
            put(v, p->vlen, 199, (s.first->PDBFLAG2 & PDB2BRST) ? "YES" : "NO");
            put(v, p->vlen, 205, "LINE");
            v[223] = (char)jct->JCTMCLAS;
            put4(v, 225, s.first->PDBFLASH);
        } else {
            /* PRTY, C, FORM, FCB, DEST, UCS, WTR and FLASH can be
            ** overtyped (not yet compared with a held row)
            */
            v[22] = v[122] = A_GREEN;
            v[39] = A_GIN;      /* DEST takes input */
            v[48] = v[141] = A_BLUE;
            snprintf(t, sizeof(t), "%4d", job.prio);
            put(v, p->vlen, 23, t);
            v[28] = (char)s.oclass;
            put4(v, 30, s.first->PDBFORMS);
            put4(v, 35, s.first->PDBFCB);
            put(v, p->vlen, 40, job.dest);
            snprintf(t, sizeof(t), "%7u", s.records);
            put(v, p->vlen, 51, t);
            field(t, jct->JCTEXSID, 4);
            put(v, p->vlen, 85, t[0] ? t : sysid);
            put(v, p->vlen, 96, "   1");
            put4(v, 123, s.first->PDBUCS);
            put4(v, 137, s.first->PDBFLASH);
            put(v, p->vlen, 143, (s.first->PDBFLAG2 & PDB2BRST) ? "YES" : "NO");
            put(v, p->vlen, 149, "LINE");
        }
    }
    owners_free(&own);
    free(buf);
    free(jbuf);
    jesclose(&jes);
    pan_sort(p);
    return p->n;
}

/* ---- INIT and PR: the answer of JES2 to a display command ---- */

/* The text of a line of the log: after the 24 columns of flags, time and
** job; blank on both sides cut off.
*/
static const char *
log_text(const ISFOUT *o, int i, int *len)
{
    const char *s = o->line[i];
    int n = o->len[i];

    if (n <= 24) {
        *len = 0;
        return s;
    }
    s += 24;
    n -= 24;
    while (n > 0 && *s == ' ') {
        s++;
        n--;
    }
    while (n > 0 && s[n - 1] == ' ')
        n--;
    *len = n;
    return s;
}

/* How often cmd stands alone on the log, and the line after the last one */
static int
echoes(const ISFOUT *o, const char *cmd, int *after)
{
    int i, n = 0, len, cl = (int)strlen(cmd);

    *after = o->n;
    for (i = 0; i < o->n; i++) {
        const char *s = log_text(o, i, &len);

        if (len == cl && memcmp(s, cmd, (size_t)cl) == 0) {
            n++;
            *after = i + 1;
        }
    }
    return n;
}

/* The lines of $HASP000 that follow the echo, in o; they start at *first */
#define HASP "$HASP000"

static int
answer_lines(const ISFOUT *o, int from, int *first)
{
    int i, n = 0, len;

    *first = from;
    for (i = from; i < o->n; i++) {
        const char *s = log_text(o, i, &len);

        if (len >= 8 && memcmp(s, HASP, 8) == 0)
            n++;
    }
    return n;
}

/* Issue cmd and wait for its answer, at most about three seconds: the log
** in o, the answer from *from on. 0, or ST_NOCMD or ST_NOANSWER.
*/
static int
ask_jes2(const char *cmd, ISFOUT *o, int *from)
{
    int before, after, tries, last = -1;

    memset(o, 0, sizeof(*o));
    if (log_load(o) != 0)
        return ST_NOANSWER;
    before = echoes(o, cmd, &after);
    out_free(o);
    if (op_command(cmd, (int)strlen(cmd)) != 0)
        return ST_NOCMD;
    for (tries = 0; tries < 30; tries++) {
        int now, first, n;

        usleep(100000);
        if (log_load(o) != 0)
            return ST_NOANSWER;
        now = echoes(o, cmd, &after);
        if (now > before || (now == before && before > 0 && tries > 10)) {
            n = answer_lines(o, after, &first);
            /* the answer is complete when it no longer grows */
            if (n > 0 && n == last) {
                *from = first;
                return 0;
            }
            last = n;
        }
        out_free(o);
    }
    return ST_NOANSWER;
}

/* The next word of s from *at on, in w; 0 at the end */
static int
word(const char *s, int len, int *at, char *w, int size)
{
    int n = 0;

    while (*at < len && s[*at] == ' ')
        (*at)++;
    if (*at >= len)
        return 0;
    while (*at < len && s[*at] != ' ') {
        if (n < size - 1)
            w[n++] = s[*at];
        (*at)++;
    }
    w[n] = '\0';
    return 1;
}

/* The job of a kind and number an initiator or a printer names:
** INIT  1 ACTIVE   JOB 2736 C=A
*/
static const ISFROW *
find_job(const ISFROW *jobs, int n, const char *type, const char *num)
{
    int i, no = atoi(num);

    if (strlen(type) != 3 || no <= 0)
        return NULL;
    for (i = 0; i < n; i++)
        if (jobs[i].number == no && strcmp(jobs[i].type, type) == 0)
            return &jobs[i];
    return NULL;
}

static int
read_init(ISFPAN *p)
{
    ISFOUT o;
    ISFROW *jobs = NULL;
    ISFDA *das = NULL;
    int from, rc, i, njobs, nda;

    if ((rc = ask_jes2("$DI", &o, &from)) != 0)
        return rc;
    njobs = st_read(&jobs);
    nda = da_read(&das);
    for (i = from; i < o.n; i++) {
        char w[6][24], t[12], *v;
        int len, at = 8, k;
        const char *s = log_text(&o, i, &len);

        if (len < 8 || memcmp(s, HASP, 8) != 0)
            continue;
        for (k = 0; k < 6; k++)
            if (!word(s, len, &at, w[k], sizeof(w[k])))
                w[k][0] = '\0';
        if (strcmp(w[0], "INIT") != 0)
            continue;
        if ((v = pan_add(p)) == NULL)
            break;
        v[0] = A_NP;
        v[3] = A_BLUE;
        snprintf(t, sizeof(t), "%2d", atoi(w[1]));
        put(v, p->vlen, 4, t);
        put(v, p->vlen, 7, w[2]);
        /* the classes come last, with C= in front */
        for (k = 3; k < 6; k++)
            if (memcmp(w[k], "C=", 2) == 0)
                put(v, p->vlen, 18, w[k] + 2);
        /* CLASSES can be overtyped (as in IBM's SDSF V1R2) */
        v[17] = A_GIN;
        v[26] = A_BLUE;
        if (strcmp(w[2], "ACTIVE") == 0) {
            const ISFROW *j = njobs > 0 ? find_job(jobs, njobs, w[3], w[4]) : NULL;
            int a;

            v[3] = v[26] = A_WHITE;
            v[17] = A_RIN;
            if (j != NULL) {
                p->job[p->n - 1] = *j;
                put(v, p->vlen, 27, j->name);
                put(v, p->vlen, 56, j->type);
                snprintf(t, sizeof(t), "%5d", j->number);
                put(v, p->vlen, 61, t);
                v[67] = j->jclass;
            }
            /* the step and the address space, from DA's reading */
            for (a = 0; j != NULL && a < nda; a++) {
                size_t nl = strlen(das[a].name);

                if (strncmp(j->name, das[a].name, nl) != 0
                    || (nl < 8 && j->name[nl] != ' ' && j->name[nl] != '\0'))
                    continue;
                put(v, p->vlen, 36, das[a].step);
                put(v, p->vlen, 46, das[a].pstep);
                snprintf(t, sizeof(t), "%4d", das[a].asid);
                put(v, p->vlen, 69, t);
                break;
            }
        }
    }
    out_free(&o);
    st_free(jobs);
    free(das);
    return p->n;
}

/* One printer of $DU,PRTS: the line with its name and the one after it.
** PRINTER1  00E INACTIVE F=STD1,OPER P=N R=LOCAL    C=6   ,STD
**                        T=0   ,STD S=Y LIM=0-* Q=A
*/
static void
printer_row(ISFPAN *p, char *v, const char *s, int len, const ISFROW *jobs,
            int njobs, int cont)
{
    char w[40], t[12], kind[4] = "";
    int at = 8, n = cont ? 5 : 0;

    if (cont)
        goto words;
    v[0] = A_NP;
    /* NP is four wide on PR (B and F take a count), so the row's own
    ** attribute stands in column 5 (IBM's SDSF V1R2)
    */
    v[5] = A_BLUE;
    put(v, p->vlen, 135, "NO");
    put(v, p->vlen, 139, "NO");
    put(v, p->vlen, 178, "(W,R,Q,PMD,LIM/F,T,C,P)");
    put(v, p->vlen, 219, "NO");
    put(v, p->vlen, 226, "LINE");
    put(v, p->vlen, 303, "       0");
    put(v, p->vlen, 312, "     100");
words:
    while (word(s, len, &at, w, sizeof(w))) {
        n++;
        if (n == 1) {
            put(v, p->vlen, 6, w);
        } else if (n == 3) {
            put(v, p->vlen, 15, w);
            if (strcmp(w, "ACTIVE") == 0)
                v[5] = A_WHITE;
        } else if (memcmp(w, "F=", 2) == 0) {
            char *c = strchr(w, ',');

            if (c != NULL)
                *c = '\0';
            put(v, p->vlen, 24, w + 2);
        } else if (memcmp(w, "Q=", 2) == 0) {
            put(v, p->vlen, 29, w + 2);
        } else if (memcmp(w, "R=", 2) == 0) {
            put(v, p->vlen, 244, w + 2);
        } else if (memcmp(w, "C=", 2) == 0) {
            put(v, p->vlen, 154, w + 2);
        } else if (memcmp(w, "T=", 2) == 0) {
            put(v, p->vlen, 159, w + 2);
        } else if (memcmp(w, "S=", 2) == 0) {
            put(v, p->vlen, 135, w[2] == 'Y' ? "YES" : "NO ");
        } else if (n == 4) {
            snprintf(kind, sizeof(kind), "%.3s", w);
        } else if (n == 5 && jobs != NULL) {
            /* an active printer names its job after the status, as an
            ** initiator does (not seen yet)
            */
            const ISFROW *j = find_job(jobs, njobs, kind, w);

            if (j != NULL) {
                p->job[p->n - 1] = *j;
                put(v, p->vlen, 45, j->name);
                put(v, p->vlen, 53, j->type);
                snprintf(t, sizeof(t), "%5d", j->number);
                put(v, p->vlen, 58, t);
            }
        }
    }
    /* SFORM and SCLASS can be overtyped: green, red when the printer is
    ** active (as in IBM's SDSF V1R2)
    */
    {
        char over = v[5] == A_WHITE ? A_RED : A_GREEN;
        char in = v[5] == A_WHITE ? A_RIN : A_GIN;

        /* as in IBM's SDSF V1R2: SFORM, SCLASS; SEP, SEPDS; SFCB, SUCS,
        ** SWRITER, SFLH; SBURST, SDEST1; SJOBNAME to the end of the line
        ** (M, NPRO, MODE, the checkpoint fields and CPYMOD, after the help).
        ** Those whose command is measured and JES2 4.1 takes take input:
        ** SFORM, SCLASS, SEP, SFCB and SDEST1; the others keep the
        ** colour only.
        */
        v[23] = v[134] = v[153] = v[243] = in;
        v[138] = v[158] = v[218] = v[279] = over;
        v[44] = v[144] = v[177] = v[225] = v[252] = v[5];
    }
}

static int
read_pr(ISFPAN *p, ISFKEEP keep, void *arg)
{
    ISFOUT o;
    ISFROW *jobs = NULL;
    int from, rc, i, njobs;
    char *v = NULL;

    if ((rc = ask_jes2("$DU,PRTS", &o, &from)) != 0)
        return rc;
    njobs = st_read(&jobs);
    for (i = from; i < o.n; i++) {
        int len, at = 8;
        const char *s = log_text(&o, i, &len);
        char w[24];

        if (len < 8 || memcmp(s, HASP, 8) != 0 || !word(s, len, &at, w, sizeof(w)))
            continue;
        if (memcmp(w, "PRINTER", 7) == 0 || memcmp(w, "PRT", 3) == 0) {
            ISFROW pr;

            /* the filter sees the printer's number in number */
            memset(&pr, 0, sizeof(pr));
            snprintf(pr.name, sizeof(pr.name), "%.8s", w);
            pr.number = atoi(w + (w[1] == 'R' && w[2] == 'I' ? 7 : 3));
            if (keep != NULL && !keep(&pr, arg)) {
                v = NULL;
                continue;
            }
            if ((v = pan_add(p)) == NULL)
                break;
            printer_row(p, v, s, len, jobs, njobs > 0 ? njobs : 0, 0);
        } else if (v != NULL && len > 16 && memcmp(s + 8, "        ", 8) == 0) {
            /* the continuation: more of the printer's settings, indented
            ** under them; another answer in between is none
            */
            printer_row(p, v, s, len, NULL, 0, 1);
        } else {
            v = NULL;
        }
    }
    out_free(&o);
    st_free(jobs);
    return p->n;
}

int
pan_read(ISFPAN *p, int kind, int alt, ISFKEEP keep, void *arg)
{
    int n;

    if (!pan_init(p, kind, alt))
        return ST_NOSTORAGE;
    switch (kind) {
    case PK_I:    n = read_i(p, keep, arg); break;
    case PK_H:    n = read_ho(p, 1, keep, arg); break;
    case PK_O:    n = read_ho(p, 0, keep, arg); break;
    case PK_PR:   n = read_pr(p, keep, arg); break;
    default:      n = read_init(p); break;
    }
    return n;
}
