/* isf.h - what the panels of SDSF share */
#ifndef ISF_H
#define ISF_H

/* One job of the JES2 queues, as the Status panel shows it */
typedef struct {
    char name[9];
    char type[4];       /* JOB, STC or TSU */
    int number;
    int prio;
    const char *queue;
    char jclass;        /* blank if the job has none to show */
    int held;           /* held output data sets */
    char dest[9];
    char saff[5];
    char asys[5];
    int hold;           /* the job is held */
    int active;         /* it is executing */
    int pos;            /* its place among those waiting in its class */
    int group;          /* see order() in isfst.c */
    char forms[5];      /* O: the forms of its first data set */
    char owner[9];      /* the user id it runs under (JCTUSEID), blank if none */
    /* from the JCT, for the columns of ? on ST and I */
    char pname[21];     /* the programmer's name */
    char acct[5];
    char notify[8];
    char isys[5];       /* read on, executed on */
    char esys[5];
    char mclass;        /* MSGCLASS */
    unsigned rdtime, rddate, sttime, stdate;    /* as JES2 keeps them */
    unsigned cards, lines;
} ISFROW;

/* The jobs in the order of the Status panel: their number, or one of these
** if they cannot be read. Free the array with st_free.
*/
#define ST_NOOPEN    (-1)
#define ST_NOSTORAGE (-2)

int st_read(ISFROW **rows);
int st_read_all(ISFROW **rows);
/* The owners of the jobs as libc370 gives them (isfst.c): read once per
** list, owner_set puts a job's owner into its row where there is one
*/
struct jes;
struct jesjob;
struct jesjob **owners_read(struct jes *j);
void owner_set(struct jesjob **own, ISFROW *r);
void owners_free(struct jesjob ***own);   /* also the jobs the user may not see */
void st_free(ISFROW *rows);

/* The heading and one job as lines of the data area */
void st_heading(char *row, int width);
void st_row(const ISFROW *job, char *row, int width);

/* ? on ST and I: the columns from RNUM on, PROGRAMMER-NAME at col of a
** line vlen wide (as in IBM's SDSF V1R2: ST 79 of 174, I 73 of 168)
*/
#define ST_ALT_COL  79
#define ST_ALT_LEN  174
#define I_ALT_COL   73
#define I_ALT_LEN   168
void st_alt_heading(char *v, int vlen, int col);
void st_alt_row(const ISFROW *job, char *v, int vlen, int col);

/* How far page `page` of PF11 moves a line of vlen with fixedh columns of
** the heading that stay; alt: ? on ST and I. -1 if there is no such page.
*/
int line_shift(int vlen, int fixedh, int alt, int width, int page);

/* A virtual line v onto a row of the screen, see pan_line */
void line_put(const char *v, int vlen, int heading, int fixedh, char *row,
              int width, int shift);

/* P on a job: a job on the print queue loses its output, any other is
** cancelled with it. NULL if that worked, else what to say on the title.
*/
const char *st_purge(const ISFROW *job);

/* One job's SYSOUT data sets: open and find it; NULL if it is gone. The
** handle stays open for jds_load until jds_close.
*/
typedef struct {
    unsigned short dsid;
    unsigned char copies;
    char burst;             /* non-zero: BURST=YES */
    char forms[4], fcb[4], ucs[4], flash[4];
} ISFDSX;                   /* what only the PDDB of a data set knows */

typedef struct {
    struct jes *jes;
    struct jesjob **list;
    struct jesjob *job;
    struct jesdd **dd;      /* its SYSOUT data sets */
    ISFDSX *dsx;            /* the same order */
    int ndd;
    char date[7];           /* yy.ddd, the job's: the data set has none */
    int input;              /* opened with INPUT ON */
} ISFJDS;

/* The columns right of DDNAME scroll over this many, see jds_row */
#define JDS_VIRTUAL 163

/* input: the SYSIN data sets too (INPUT ON), and the JES2 ones under the
** names IBM's SDSF V1R2 gives them then
*/
int jds_open(ISFJDS *j, const ISFROW *job, int input);
void jds_close(ISFJDS *j);
void jds_heading(char *row, int width, int shift);
void jds_row(const ISFJDS *j, int i, char *row, int width, int shift);

/* The lines of output in storage, for the Output Data Set panel */
typedef struct {
    char **line;        /* the text; line[i][-1] its ASA character, blank if none */
    unsigned short *len;
    unsigned short *dsid;
    int n, room;
    void *chunks;
    int used;
    int full;           /* storage ran out: the rest is not here */
} ISFOUT;

/* One more line at the end, with that dsid. Non-zero if storage ran out.
** The replies at the end of the log carry REPLY_DSID.
*/
#define REPLY_DSID 0xFFFF

int out_add(ISFOUT *o, const char *line, unsigned len, unsigned dsid);

/* Add a data set, or all of them with dsid 0. Non-zero if it cannot be read. */
int out_load(ISFOUT *o, ISFJDS *j, unsigned dsid);
void out_free(ISFOUT *o);

/* The system log from the master trace table, oldest line first. Non-zero if
** the table cannot be read.
*/
int log_load(ISFOUT *o);
/* The outstanding replies (WTORs), newest first: up to max of them, the
** number read, or -1 if they cannot be read. They are copied from storage
** that only key 0 may read.
*/
typedef struct {
    char id[3];             /* the reply id, in a string */
    unsigned short rout;    /* routing codes 1-16, code 1 the high bit; */
    int routed;             /* 0 if the message carries none */
    char text[148];         /* time, job, then the message: as on the log */
    int len;
} ISFWTOR;

#define WTOR_MAX 30

int wtor_read(ISFWTOR *w, int max);

/* An operator command through SVC 34, as from the master console; len is at
** most 100. Non-zero if the task cannot be authorized for it.
*/
int op_command(const char *text, int len);

/* One address space, as the Display Active Users panel shows it */
typedef struct {
    int asid;
    char name[9], step[9], pstep[9];
    char type[5];           /* JOB, STC, TSU or INIT */
    int number;             /* the JES2 job number, 0 if it has none */
    char jclass;            /* blank if none */
    char pos[4];            /* IN, OUT or N/S */
    int dp, pgn, real;
    int dmn, sr;
    unsigned excp;          /* OUCBIOSM */
    double cpu;             /* CPU time of the step, TCB and SRB, seconds */
    double cpupct, sio;     /* over the interval since the last display */
} ISFDA;

/* DA's columns right of JOBNAME scroll over this many with PF11 */
#define DA_SHIFT   33
#define DA_VIRTUAL 114     /* the longest of the two layouts */

/* The address spaces in the order of their ASIDs: their number, or one of
** the ST_ values. Free the array with free().
*/
int da_read(ISFDA **rows);
/* DA's columns as DA shows them (0) or after ? (1), and the line's width */
void da_set_alt(int alt);
int da_vlen(void);
void da_heading(char *row, int width, int shift);
void da_row(const ISFDA *a, char *row, int width, int shift);
/* The column of PGN in DA's line, the field that can be overtyped */
int da_pgn(void);
#define DA_FIXED 13         /* the columns of a row that PF11 leaves */

/* The panels I, O, H, PR and INIT: their rows as lines of text, each as
** wide as all the columns of the panel (vlen); PF11 shows them from further
** right. job tells the job of a row, for the actions in NP; its number is 0
** if the row has none.
*/
#define PK_I    1
#define PK_O    2
#define PK_H    3
#define PK_PR   4
#define PK_INIT 5

typedef struct {
    int kind;
    int n, room;
    int vlen;               /* the width of a line */
    int fixedh;             /* the heading's columns that stay with PF11 */
    int alt;                /* ? on I: the further columns */
    char *head;             /* the heading, vlen */
    char *text;             /* the rows, n * vlen */
    ISFROW *job;            /* n */
    unsigned *key;          /* 2n, what the rows are sorted by */
    unsigned lines;         /* H and O: the records of the rows */
} ISFPAN;

/* What a panel shows of the rows read: non-zero to keep one. For I, H and O
** it sees the job, its class (H and O: of the output) and whether it is
** held; for PR the printer's name and number.
*/
typedef int (*ISFKEEP)(const ISFROW *row, void *arg);

/* INIT and PR: the command could not be issued, or JES2 did not answer */
#define ST_NOCMD    (-3)
#define ST_NOANSWER (-4)

/* The rows of a kind: their number or one of the ST_ values */
int pan_read(ISFPAN *p, int kind, int alt, ISFKEEP keep, void *arg);
void pan_free(ISFPAN *p);
/* How far page page of PF11 moves the lines, -1 if there is none */
int pan_shift(const ISFPAN *p, int width, int page);
/* Row i, -1 the heading, as a line of the screen */
void pan_line(const ISFPAN *p, int i, char *row, int width, int shift);

/* WHO: the logon procedure of this TSO user, empty if it cannot be read */
void who_proc(char proc[9]);
/* WHO: the terminal of this TSO user (the TSB, key 0), empty if it cannot be read */
void who_term(char term[9]);

/* Who may see and do what (isfauth.c, docs/installation.md section 8).
** auth_init with the TSO user id; auth_reset before each new list.
** auth_job: the job may be seen (update 0) or acted on (update 1);
** auth_oper: SDSF.OPER, READ (0) or UPDATE (1); auth_mine: the user's own.
*/
void auth_init(const char *userid);
void auth_reset(void);
int auth_job(const ISFROW *job, int update);
int auth_oper(int update);
int auth_mine(const ISFROW *job);
/* The authorized state for one call: SDSF's SVC (SVC 109 code 11) where it
** is installed, else SVC 244. 0 if the task is authorized now.
*/
int isf_autask(void);
void isf_uatask(void);
int isf_svc_installed(void);
int isf_quiet(void);

/* The id of this system, in a string */
void st_sysid(char id[5]);

/* Help and tutorial (isfhelp.c). isf_help shows the panels from start on
** until the End key: 0, or the return code of a DISPLAY that failed.
** help_key: 1 if the key .PFKEY names ("PF01") carries the HELP command.
*/
#define ISF_HELP_TOC   "ISFHTOC"    /* table of contents */
#define ISF_HELP_INDEX "ISFXA"      /* index, letter A */
#define ISF_HELP_HELP  "ISFHHELP"   /* how to use help */
#define ISF_TUTOR      "ISFTUTOR"   /* the tutorial's menu */
int isf_help(void *isplink, const char *start);
int help_key(void *isplink, const char *key);

#endif
