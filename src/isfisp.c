/* ISFISP - the entry of SDSF under ISPF
**
** Started from the ISPF primary option menu with
** SELECT PGM(ISFISP) NOCHECK NEWAPPL(ISF). The panel ISFMENU (ispplib/)
** must be in the ISPPLIB concatenation, this module in the ISPLLIB one:
** ISPLINK is loaded from there.
*/
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dynit.h>
#include <mvs/link.h>
#include <mvs/clock.h>
#include <mvs/jes2.h>
#include <time.h>
#include <unistd.h>

#include "isf.h"

#define VERSION "V1R2"   /* the release of SDSF it follows */
#define CMDLEN  60
#define SCRLEN  4
#define LINELEN 160     /* the widest screen ISPF gives us here */
#define MAXROWS 62

typedef struct {
    void *isplink;
    int width;
    char cmd[CMDLEN];
    char scr[SCRLEN];
    char saved[SCRLEN];     /* the scroll amount in the user's profile */
    char csr[8];            /* the field the cursor goes to */
    char csrpos[9];         /* where in it, 8 for ISPF and an end */
    char line[LINELEN];
    int depth;
    int rows;               /* of the data area, heading included */
    char *buf;              /* the data area: width * rows */
    char *area;             /* the whole area: the command row, then buf */
    ISFROW *jobs;
    ISFDA *das;             /* the address spaces of DA */
    ISFDA *daprev;          /* all of them at the display before, */
    int ndaprev;
    unsigned dalast[2];     /* and the TOD clock then */
    double dacpu, dasio;    /* the system's rates over the interval */
    int datype, dapos;      /* which types and positions DA shows */
    int njobs;
    int top;                /* the first line of data on the screen */
    int shown;              /* lines of data on the screen */
    int left;               /* the first column on the Output panel */
    char cmdend;            /* the attribute that ends the command row, for
                            ** one display; 0 is the usual one */
    /* FIND, for the log and the output of jobs alike */
    char find[CMDLEN + 1];  /* the string last searched for */
    int flen;               /* its length; 0 before the first FIND */
    int fback;              /* the search goes backward */
    int fkind;              /* CHARS, WORD, PREFIX or SUFFIX */
    int fexact;             /* X'..' or C'..': upper and lower case differ */
    int fsc, fec;           /* the columns a hit must be in; 0: any */
    int fbase;              /* the column of a line's first byte */
    int findlim;            /* FINDLIM: the lines one FIND looks at */
    int input;              /* INPUT ON: the SYSIN data sets of a job too */
    int hex;                /* SET HEX ON: output in hexadecimal */
    int cols;               /* COLS: a scale line over the output */
    int who;                /* WHO: the user's line, for one display */
    /* PRINT: the print file, open from PRINT OPEN (or the first PRINT)
    ** to PRINT CLOSE; the lines of the Output panel shown, NULL elsewhere
    */
    FILE *prf;
    char prdd[9];
    int prsysout;           /* SYSOUT, freed at CLOSE to be printed */
    int prn;                /* lines printed since OPEN */
    int prpage;             /* pages of the log printed since OPEN */
    const ISFOUT *pout;
    int pjob;               /* the lines are a job's: the first byte is
                            ** its carriage control */
    /* an action refused stays in NP for the next display, the cursor on
    ** the first one (IBM's SDSF V1R2); keep[r] for row r of the area, blank if none
    */
    char keep[MAXROWS][5];
    int kept;
    /* the fields that can be overtyped: the data area as it was shown, to
    ** see what changed; a value refused stays in its field for the next
    ** display, the cursor on it (IBM's SDSF V1R2)
    */
    char *shadow;
    struct { int row, col; char text[16]; } ov[16]; /* kept as typed */
    int nov, ovcur;
    char retr[10][CMDLEN];  /* RETRIEVE: the last commands, newest first */
    int nretr, rpos;
    char rlast[CMDLEN];     /* the command of the display before */
    /* FIND on a list: row i of the list panel shown, as on the screen */
    void (*rowtext)(void *d, int i, char *row);
    void *curjds;           /* the Job Data Set panel's data sets */
    int fline, fcol;        /* the last hit; fline -1: none on this screen */
    int fwrap;              /* the end was reached: the next one wraps */
    int crow;               /* the list row the cursor was on, -1 if none */
    int ftop;               /* the top line of the screen after that */
    char fmsg[48];          /* the message, which carries the string; the
                            ** screen's edge cuts it */
    char fndv[61];          /* in the profile as ISFFND: N or P, the length
                            ** in two digits, the string */
    int cmdpos;             /* where on the command line the cursor goes */
    int ds_shown;           /* ST comes from the Output Data Set panel */
    /* ACTION: the routing codes whose replies the log shows, code 1 the
    ** high bit; 0 is OFF. In the profile as ISFACT, four hex digits.
    */
    unsigned short action;
    char actv[5];
    char amsg[48];
    int tail;               /* rows under the data for the replies */
    /* What the Status panel shows: the classes and the name of the last ST,
    ** and PREFIX, which goes before that name. PREFIX is kept in the
    ** profile as ISFPFX: the name, then the characters for * and %.
    */
    char stclass[7];
    char stname[9];
    char prefix[9];
    char pany, pone;
    char pfxv[11];
    /* DEST: up to four destinations the lists are limited to (ours LOCAL or
    ** Rn), kept in the profile as ISFDST
    */
    char dest[4][9];
    int ndest;
    char sysid[5];          /* SYSID: the system whose log is shown, "" ours */
    int daalt;              /* ? on DA: the other order of the columns */
    int stalt, ialt;        /* ? on ST and I: the further columns */
    int stpage;             /* ST with ?: the page of PF11 */
    char dstv[36];
    ISFWTOR wtor[WTOR_MAX];
    /* I, O, H, PR and INIT: which of them, its rows, and what each of
    ** them shows (their parameters, kept until the next command of it)
    */
    int pkind;
    ISFPAN pan;
    char iclass[10];        /* I: classes, $ for TSU, # for STC */
    int iheld;              /* I: 1 held only, 2 not held only */
    char hclass[10], hname[9];
    int hall;               /* H ALL: every job, not only the user's */
    char oclass[10], oforms[9];
    char prsel[4][9];       /* PR: numbers, ranges n-m, Rn, LCL, RMT */
    int nprsel;
    char user[9];
    /* Help: the help panel of what is shown (as SDSF's ISFHELP), and the
    ** key that ended the display (ISFPFK, from .PFKEY): without .HELP on
    ** the panel, ISPF ends the DISPLAY on the Help key with RC 0, like
    ** Enter (Wally ISPF)
    */
    const char *help;
    char pfk[4];
} DLG;

/* ISPLINK takes addresses, the last with its high-order bit set */
static int
vdefine(DLG *d, const char *name, char *buf, int len)
{
    char service[9] = "VDEFINE ";
    char format[9] = "CHAR    ";
    char list[12];
    int flen = len;
    unsigned plist[5];

    snprintf(list, sizeof(list), "(%s)", name);
    plist[0] = (unsigned)service;
    plist[1] = (unsigned)list;
    plist[2] = (unsigned)buf;
    plist[3] = (unsigned)format;
    plist[4] = (unsigned)&flen | 0x80000000;
    return __call(d->isplink, plist);
}

/* VGET or VPUT of one variable in the user's profile */
static int
profile(DLG *d, const char *service, const char *name)
{
    char svc[9], list[12];
    char pool[9] = "PROFILE ";
    unsigned plist[3];

    snprintf(svc, sizeof(svc), "%-8s", service);
    snprintf(list, sizeof(list), "(%s)", name);
    plist[0] = (unsigned)svc;
    plist[1] = (unsigned)list;
    plist[2] = (unsigned)pool | 0x80000000;
    return __call(d->isplink, plist);
}

/* Copy a system variable; an empty string if ISPF has none */
static void
system_var(DLG *d, const char *var, char *value, int size)
{
    char service[9] = "VCOPY   ";
    char name[9];
    char mode[9] = "MOVE    ";
    int len = size - 1;
    unsigned plist[5];

    snprintf(name, sizeof(name), "%-8s", var);
    memset(value, 0, (size_t)size);
    plist[0] = (unsigned)service;
    plist[1] = (unsigned)name;
    plist[2] = (unsigned)&len;
    plist[3] = (unsigned)value;
    plist[4] = (unsigned)mode | 0x80000000;
    if (__call(d->isplink, plist) != 0)
        value[0] = '\0';
}

/* The size of the screen from the system variables; 80 by 24 if they
** cannot say.
*/
static void
screen_size(DLG *d)
{
    char value[9];

    system_var(d, "ZSCREENW", value, sizeof(value));
    d->width = atoi(value);
    if (d->width < 80)
        d->width = 80;
    if (d->width > LINELEN)
        d->width = LINELEN;
    system_var(d, "ZSCREEND", value, sizeof(value));
    d->depth = atoi(value);
    if (d->depth < 24)
        d->depth = 24;
    if (d->depth > MAXROWS)
        d->depth = MAXROWS;
    d->rows = d->depth - 2;
}

static int
display(DLG *d, const char *panel)
{
    char service[9] = "DISPLAY ";
    char name[9];
    unsigned plist[2];

    snprintf(name, sizeof(name), "%-8s", panel);
    plist[0] = (unsigned)service;
    plist[1] = (unsigned)name | 0x80000000;
    return __call(d->isplink, plist);
}

/* The first line of a screen: the version, the title in the middle with
** dashes on both sides; a short message takes the place of the dashes on
** the right.
*/
static void
title(DLG *d, const char *text, const char *msg)
{
    int tlen = (int)strlen(text);
    int pos = (d->width - tlen) / 2 - 1;    /* the field starts in column 2 */
    int end = pos + tlen;

    memset(d->line, '-', (size_t)d->width);
    memset(d->line + d->width, ' ', (size_t)(LINELEN - d->width));
    memcpy(d->line, VERSION, strlen(VERSION));
    d->line[pos - 2] = ' ';
    d->line[pos - 1] = ' ';
    memcpy(d->line + pos, text, (size_t)tlen);
    d->line[end] = ' ';
    d->line[end + 1] = ' ';
    if (msg != NULL && msg[0] == ' ')
        msg++;
    if (msg != NULL && strcmp(msg, "INVALID SCROLL AMOUNT") == 0) {
        /* this one stands on the right, without dashes (IBM's SDSF V1R2) */
        int mlen = (int)strlen(msg);

        memset(d->line + end + 2, ' ', (size_t)(d->width - end - 2));
        memcpy(d->line + d->width - 2 - mlen, msg, (size_t)mlen);
        return;
    }
    if (msg != NULL) {
        int mlen = (int)strlen(msg);

        memset(d->line + end + 2, ' ', (size_t)(d->width - end - 2));
        if (end + 5 + mlen <= d->width) {
            memcpy(d->line + end + 2, "-- ", 3);
            memcpy(d->line + end + 5, msg, (size_t)mlen);
        }
    }
}

static void cmd_word(const DLG *d, int which, char *word, int size);
static void cursor_to(DLG *d, const char *field);
static int help_cmd(DLG *d, const char **msg);

/* RETRIEVE, as in IBM's SDSF V1R2: the commands that were taken, newest
** first; a command that stays on the line with a message is not taken,
** scrolling and WHO are not kept, RETRIEVE goes one further back each time.
** Before a display: the command of the display before is kept if it went.
*/
static void
retr_before(DLG *d)
{
    int i, blank = 1;

    for (i = 0; i < CMDLEN; i++)
        if (d->cmd[i] != ' ' && d->cmd[i] != '\0')
            blank = 0;
    if (d->rlast[0] != '\0' && blank) {
        memmove(d->retr[1], d->retr[0], sizeof(d->retr[0]) * 9);
        memcpy(d->retr[0], d->rlast, CMDLEN);
        if (d->nretr < 10)
            d->nretr++;
        d->rpos = 0;
    }
    d->rlast[0] = '\0';
}

/* After a display: RETRIEVE (the command or a key with it) puts the next
** older command on the line and says 1, for showing the panel again;
** anything else typed is remembered for retr_before.
*/
static int
retr_after(DLG *d)
{
    static const char *const skip[] = {
        "UP", "DOWN", "TOP", "BOTTOM", "BOT", "LEFT", "RIGHT", "WHO", NULL
    };
    char word[9], verb[9];
    int i;

    system_var(d, "ZVERB", verb, sizeof(verb));
    cmd_word(d, 0, word, sizeof(word));
    if (strcmp(word, "RETRIEVE") == 0
        || (word[0] == '\0' && strncmp(verb, "RETRIEVE", 8) == 0)) {
        memset(d->cmd, ' ', CMDLEN);
        if (d->nretr > 0) {
            memcpy(d->cmd, d->retr[d->rpos], CMDLEN);
            d->rpos = (d->rpos + 1) % d->nretr;
        }
        cursor_to(d, "ISFCMD");
        return 1;
    }
    if (word[0] == '\0' || (verb[0] != '\0' && verb[0] != ' '))
        return 0;
    for (i = 0; skip[i] != NULL; i++)
        if (strcmp(word, skip[i]) == 0)
            return 0;
    memcpy(d->rlast, d->cmd, CMDLEN);
    return 0;
}

/* A panel with a data area. The command row is part of the area: the ISPF
** here does not send an attribute at the end of a line from the panel's
** body, but it does from an area. Without that one the scroll field runs on
** over the data, which can then be typed on and looks bright.
*/
#define R_CMD   19      /* attribute of the command field in the row */
#define R_SCR(w) ((w) - 18)
static int
list_display(DLG *d)
{
    int s = R_SCR(d->width);
    int cmdlen = s - R_CMD - 1;
    int rc, i;
    char *row = d->area;
    char end = d->cmdend;

    if (cmdlen > CMDLEN)
        cmdlen = CMDLEN;
    retr_before(d);
again:
    memset(row, ' ', (size_t)d->width);
    row[0] = 0x07;
    memcpy(row + 1, "COMMAND INPUT ===>", 18);
    row[R_CMD] = 0x1E;
    memcpy(row + R_CMD + 1, d->cmd, (size_t)cmdlen);
    row[s] = 0x07;
    memcpy(row + s + 1, "SCROLL ===>", 11);
    row[s + 12] = 0x1F;
    memcpy(row + s + 13, d->scr, SCRLEN);
    /* the last attribute of the row reaches into the data after it */
    row[s + 17] = end ? end : 0x05;
    d->cmdend = 0;
    /* the fields of that row are places in the area for the cursor */
    if (memcmp(d->csr, "ISFCMD  ", 8) == 0)
        snprintf(d->csrpos, sizeof(d->csrpos), "%-8d", R_CMD + 2 + d->cmdpos);
    else if (memcmp(d->csr, "ISFS    ", 8) == 0)
        snprintf(d->csrpos, sizeof(d->csrpos), "%-8d", s + 14);
    d->cmdpos = 0;
    memcpy(d->csr, "ISFBUF  ", 8);
    if (d->kept) {
        int r, first = 0;

        for (r = 1; r < d->rows; r++)
            if (d->keep[r][0] != '\0') {
                memcpy(d->buf + r * d->width + 1, d->keep[r], strlen(d->keep[r]));
                if (first == 0)
                    first = r;
                d->keep[r][0] = '\0';
            }
        if (first > 0)
            snprintf(d->csrpos, sizeof(d->csrpos), "%-8d", (first + 1) * d->width + 2);
        d->kept = 0;
    }
    if (d->who) {
        /* WHO: over the first row of the area, for this display (IBM's SDSF V1R2) */
        char line[LINELEN + 1], proc[9], term[9];
        size_t n;

        who_proc(proc);
        /* Wally ISPF has no ZTERMID: the TSB has the terminal's name */
        who_term(term);
        n = (size_t)snprintf(line, sizeof(line),
                             " USER-ID=%-8s  LOGON-PROC=%-8s  TERMINAL-NAME=%-8s",
                             d->user, proc, term);
        memset(d->buf, ' ', (size_t)d->width);
        memcpy(d->buf, line, n < (size_t)d->width ? n : (size_t)d->width);
        d->who = 0;
    }
    /* the area as the program made it: a value kept from a refusal counts
    ** as typed again
    */
    memcpy(d->shadow, d->buf, (size_t)(d->width * d->rows));
    for (i = 0; i < d->nov; i++) {
        memcpy(d->buf + d->ov[i].row * d->width + d->ov[i].col, d->ov[i].text,
               strlen(d->ov[i].text));
        if (i == d->ovcur)
            snprintf(d->csrpos, sizeof(d->csrpos), "%-8d",
                     (d->ov[i].row + 1) * d->width + d->ov[i].col + 1);
    }
    d->nov = 0;
    rc = display(d, "ISFLIST");
    /* where the cursor was: FIND on a list goes on from that row (IBM's SDSF V1R2) */
    d->crow = -1;
    if (memcmp(d->csr, "ISFBUF  ", 8) == 0) {
        int arow = (atoi(d->csrpos) - 1) / d->width;

        if (arow >= 2)
            d->crow = d->top + arow - 2;
    }
    memcpy(d->cmd, row + R_CMD + 1, (size_t)cmdlen);
    memcpy(d->scr, row + s + 13, SCRLEN);
    for (i = 0; i < CMDLEN; i++)
        if (d->cmd[i] == '\0')
            d->cmd[i] = ' ';
    for (i = 0; i < SCRLEN; i++)
        if (d->scr[i] == '\0')
            d->scr[i] = ' ';
    if (rc == 0) {
        const char *hm;

        if (help_cmd(d, &hm)) {
            if (hm != NULL) {
                /* on the right of the title, over whatever stands there */
                size_t n = strlen(hm);

                memcpy(d->line + d->width - 1 - n, hm, n);
            }
            cursor_to(d, "ISFCMD");
            d->cmdpos = 0;
            goto again;
        }
    }
    /* PF5 on a list: RFIND as a command, for scroll_command */
    if (rc == 0 && d->rowtext != NULL) {
        char verb[9];
        int k = 0;

        while (k < CMDLEN && d->cmd[k] == ' ')
            k++;
        system_var(d, "ZVERB", verb, sizeof(verb));
        if (memcmp(verb, "RFIND", 5) == 0 && k == CMDLEN)
            memcpy(d->cmd, "RFIND", 5);
    }
    if (rc == 0 && retr_after(d))
        goto again;
    return rc;
}

/* The title of a list: the text on the left, the lines or a message on
** the right.
*/
static void
list_title(DLG *d, const char *text, const char *msg)
{
    char right[40];
    int shown = d->shown;
    int last = d->top + shown < d->njobs ? d->top + shown : d->njobs;
    int pos = 55;
    int n;

    if (msg != NULL)
        snprintf(right, sizeof(right), "%s", msg);
    else
        snprintf(right, sizeof(right), "LINE %d-%d (%d)",
                 d->njobs ? d->top + 1 : 0, last, d->njobs);
    n = (int)strlen(right);
    if (pos + n > d->width - 1)     /* the field has its attribute */
        pos = d->width - 1 - n;
    memset(d->line, ' ', LINELEN);
    memcpy(d->line, text, strlen(text));
    memcpy(d->line + pos, right, (size_t)n);
}

/* Word number n (0 is the first) of the command line, in a string */
static void
cmd_word(const DLG *d, int which, char *word, int size)
{
    int i = 0, n = 0;

    for (;;) {
        while (i < CMDLEN && d->cmd[i] == ' ')
            i++;
        if (which-- == 0)
            break;
        while (i < CMDLEN && d->cmd[i] != ' ' && d->cmd[i] != '\0')
            i++;
    }
    while (i < CMDLEN && d->cmd[i] != ' ' && d->cmd[i] != '\0'
           && n < size - 1)
        word[n++] = d->cmd[i++];
    word[n] = '\0';
}

/* 1 if the first word is longer than a command's 8 characters: IBM's SDSF V1R2
** takes no panel command then (IABCDEFGH is INVALID COMMAND)
*/
static int
first_long(const DLG *d)
{
    char w[CMDLEN + 1];

    cmd_word(d, 0, w, sizeof(w));
    return strlen(w) > 8;
}

static void
cursor_to(DLG *d, const char *field)
{
    size_t n = strlen(field);

    memset(d->csr, ' ', sizeof(d->csr));
    memcpy(d->csr, field, n < sizeof(d->csr) ? n : sizeof(d->csr));
    memcpy(d->csrpos, "1       ", 8);
}

/* The help panel of I, O, H, PR or INIT */
static const char *
pan_help(int kind)
{
    switch (kind) {
    case PK_I:
        return "ISFHIQ";
    case PK_O:
        return "ISFHOQ";
    case PK_H:
        return "ISFHHQ";
    case PK_PR:
        return "ISFHPR";
    default:
        return "ISFHIT";
    }
}

/* After a display: HELP, TUTOR or the Help key show the help of the panel
** or the tutorial (isfhelp.c); 1 then, for showing the panel again, with
** *msg if the help panels cannot be shown.
*/
static int
help_cmd(DLG *d, const char **msg)
{
    char word[9], arg[9], key[5];
    const char *start;

    cmd_word(d, 0, word, sizeof(word));
    cmd_word(d, 1, arg, sizeof(arg));
    memcpy(key, d->pfk, 4);
    key[4] = '\0';
    if (strcmp(word, "TUTOR") == 0 && arg[0] == '\0')
        start = ISF_TUTOR;
    else if ((strcmp(word, "HELP") == 0 && arg[0] == '\0')
             || (word[0] == '\0' && help_key(d->isplink, key)))
        start = d->help != NULL ? d->help : ISF_HELP_TOC;
    else
        return 0;
    memset(d->cmd, ' ', CMDLEN);
    memset(d->pfk, ' ', sizeof(d->pfk));
    *msg = isf_help(d->isplink, start) != 0 ? "HELP NOT AVAILABLE" : NULL;
    return 1;
}

/* An amount that stays: PAGE, HALF, DATA, CSR or a number of 1 to 4 digits,
** blank on the right.
*/
static int
scroll_valid(const char *scr)
{
    static const char *const list[] = {
        "PAGE", "HALF", "DATA", "CSR ", NULL
    };
    int i, n = SCRLEN;

    for (i = 0; list[i] != NULL; i++)
        if (memcmp(scr, list[i], SCRLEN) == 0)
            return 1;
    while (n > 0 && scr[n - 1] == ' ')
        n--;
    if (n == 0)
        return 0;
    for (i = 0; i < n; i++)
        if (scr[i] < '0' || scr[i] > '9')
            return 0;
    return 1;
}

/* Keep a valid scroll amount in the profile. MAX, as on IBM's SDSF V1R2, raises
** no message, scrolls nothing and the last amount comes back in the field.
*/
#define SCROLL_BAD  0
#define SCROLL_GOOD 1
#define SCROLL_MAX  2

static int
scroll_check(DLG *d)
{
    if (memcmp(d->scr, "MAX ", SCRLEN) == 0) {
        memcpy(d->scr, d->saved, SCRLEN);
        return SCROLL_MAX;
    }
    if (!scroll_valid(d->scr))
        return SCROLL_BAD;
    if (memcmp(d->scr, d->saved, SCRLEN) != 0) {
        profile(d, "VPUT", "ISFS");
        memcpy(d->saved, d->scr, SCRLEN);
    }
    return SCROLL_GOOD;
}

/* The lines an amount scrolls by; 0 if there is nothing to scroll */
static int
scroll_lines(const DLG *d, const char *amount)
{
    int shown = d->shown;

    if (memcmp(amount, "PAGE", SCRLEN) == 0)
        return shown;
    if (memcmp(amount, "HALF", SCRLEN) == 0)
        return shown / 2 > 0 ? shown / 2 : 1;
    if (memcmp(amount, "DATA", SCRLEN) == 0)
        return shown > 1 ? shown - 1 : 1;
    if (memcmp(amount, "CSR ", SCRLEN) == 0) {
        /* the line under the cursor goes to the top; off the data, a page */
        if (memcmp(d->csr, "ISFBUF  ", 8) == 0) {
            char pos[9];
            int row;

            memcpy(pos, d->csrpos, 8);
            pos[8] = '\0';
            row = (atoi(pos) - 1) / d->width;
            /* a list has its heading on the first row */
            row -= 1 + d->rows - d->shown - d->tail;   /* and the command row */
            if (row > 0)
                return row;
        }
        return shown;
    }
    return atoi(amount);
}

static void
scroll_to(DLG *d, int top)
{
    int last = d->njobs - 1;

    if (top > last)
        top = last;
    if (top < 0)
        top = 0;
    d->top = top;
}

/* The data area of the Status panel from the jobs read */
static void
st_fill(DLG *d)
{
    char v[ST_ALT_LEN];
    int r, shift;

    memset(d->buf, ' ', (size_t)(d->width * d->rows));
    if (!d->stalt) {
        st_heading(d->buf, d->width);
        for (r = 1; r < d->rows && d->top + r - 1 < d->njobs; r++)
            st_row(&d->jobs[d->top + r - 1], d->buf + r * d->width, d->width);
        return;
    }
    /* ?: a line of ST_ALT_LEN, moved by PF11 as in IBM's SDSF V1R2 */
    if ((shift = line_shift(ST_ALT_LEN, 12, 1, d->width, d->stpage)) < 0)
        shift = d->stpage = 0;
    memset(v, ' ', sizeof(v));
    st_heading(v, ST_ALT_LEN);
    st_alt_heading(v, ST_ALT_LEN, ST_ALT_COL);
    line_put(v, ST_ALT_LEN, 1, 12, d->buf, d->width, shift);
    for (r = 1; r < d->rows && d->top + r - 1 < d->njobs; r++) {
        memset(v, ' ', sizeof(v));
        st_row(&d->jobs[d->top + r - 1], v, ST_ALT_LEN);
        st_alt_row(&d->jobs[d->top + r - 1], v, ST_ALT_LEN, ST_ALT_COL);
        line_put(v, ST_ALT_LEN, 0, 12, d->buf + r * d->width, d->width, shift);
    }
}

/* The rows with something typed in NP: their numbers and what was typed,
** w characters (2, on PR 4), blanks in front taken away, blank on the right
*/
#define NPMAX 5
static int
np_typed(const DLG *d, int *which, char (*action)[NPMAX], int w)
{
    int r, n = 0;

    for (r = 1; r < d->rows; r++) {
        const char *row = d->buf + r * d->width;
        int k, m = 0, any = 0;

        for (k = 0; k < w; k++) {
            char c = row[1 + k];

            if (c == '\0')
                c = ' ';
            if (c != ' ')
                any = 1;
            if (c != ' ' || m > 0)
                action[n][m++] = c;
        }
        if (!any)
            continue;
        while (m < w)
            action[n][m++] = ' ';
        action[n][w] = '\0';
        which[n++] = r - 1;
    }
    return n;
}

/* Keep what was typed in NP of area row r for the next display */
static void
np_keep(DLG *d, int r, const char *action)
{
    snprintf(d->keep[r], sizeof(d->keep[r]), "%s", action);
    d->kept = 1;
}

/* An action that goes to JES2 as a command: the message for the title */
static const char *
action_issue(const char *cmd)
{
    return op_command(cmd, (int)strlen(cmd)) != 0 ? "COMMAND NOT AUTHORIZED"
                                                  : "COMMAND ISSUED";
}

/* An action on PR, w = 4 characters blank on the right, for printer row i:
** the JES2 command into cmd (as in IBM's SDSF V1R2: D $DU,PRTn, S $SPRTn,
** P $PPRTn; the others after the same pattern), 0 if it is no action
*/
static int
pr_command(const ISFPAN *p, int i, const char *a, char *cmd, size_t size)
{
    const char *v = p->text + (size_t)i * (size_t)p->vlen;
    char rest[4];
    int n = 0, k;

    if (memcmp(v + 6, "PRINTER", 7) != 0)
        return 0;
    n = atoi(v + 13);
    if (n <= 0)
        return 0;
    for (k = 0; k < 3 && a[1 + k] != ' ' && a[1 + k] != '\0'; k++)
        rest[k] = a[1 + k];
    rest[k] = '\0';
    if (k < 3 && a[1 + k] != '\0' && strspn(a + 1 + k, " ") != strlen(a + 1 + k))
        return 0;               /* something after a blank */
    if (a[0] == 'B' || a[0] == 'F') {
        /* nnn pages, D the data set, C the checkpoint, nnC before it */
        int digits = (int)strspn(rest, "0123456789");

        if (rest[0] == '\0')
            snprintf(cmd, size, "$%cPRT%d", a[0], n);
        else if ((digits > 0 && rest[digits] == '\0')
                 || (digits == 0 && (strcmp(rest, "D") == 0 || strcmp(rest, "C") == 0))
                 || (digits > 0 && digits <= 2 && strcmp(rest + digits, "C") == 0))
            snprintf(cmd, size, "$%cPRT%d,%s", a[0], n, rest);
        else
            return 0;
        return 1;
    }
    if (rest[0] != '\0' || strchr("DSPZIECN", a[0]) == NULL)
        return 0;
    if (a[0] == 'D')
        snprintf(cmd, size, "$DU,PRT%d", n);
    else
        snprintf(cmd, size, "$%cPRT%d", a[0], n);
    return 1;
}

/* An action on INIT, 2 characters, for initiator row i: D $DIn (as
** as in IBM's SDSF V1R2), P $PIn, S $SIn, Z $ZIn; 0 if it is none of them
*/
static int
init_command(const ISFPAN *p, int i, const char *a, char *cmd, size_t size)
{
    const char *v = p->text + (size_t)i * (size_t)p->vlen;
    int n = atoi(v + 4);

    if (n <= 0 || a[1] != ' ' || strchr("DPSZ", a[0]) == NULL)
        return 0;
    snprintf(cmd, size, "$%cI%d", a[0], n);
    return 1;
}

/* An action on a job, 2 characters, for DA and ST: the command into cmd
** (as in IBM's SDSF V1R2: D $DTnnnn, L $LTnnnn,ALL; the others after the
** same pattern), 0 if it is none of them. type is JOB, STC, TSU or INIT.
*/
static int
job_command(const char *type, int number, const char *act, char *cmd, size_t size)
{
    char t = strcmp(type, "STC") == 0 ? 'S' : strcmp(type, "TSU") == 0 ? 'T' : 'J';

    if (strcmp(act, "D ") == 0 || strcmp(act, "C ") == 0 || strcmp(act, "A ") == 0
        || strcmp(act, "H ") == 0 || strcmp(act, "E ") == 0 || strcmp(act, "O ") == 0)
        snprintf(cmd, size, "$%c%c%d", act[0], t, number);
    else if (strcmp(act, "L ") == 0)
        /* IBM's SDSF V1R2 adds ,ALL; JES2 4.1 refuses it (INVALID OPERAND) */
        snprintf(cmd, size, "$L%c%d", t, number);
    else if (strcmp(act, "CD") == 0)
        snprintf(cmd, size, "$C%c%d,D", t, number);
    else if (strcmp(act, "P ") == 0)
        snprintf(cmd, size, "$C%c%d,P", t, number);
    else
        return 0;
    return 1;
}

/* ---- Overtyping ---- */

/* A field that can be overtyped: its columns in a row, what it is */
typedef struct {
    int col, len;
    char what;              /* P priority, C class, D destination */
} OVF;

/* As in IBM's SDSF V1R2: ST PRTY and DEST; I PRTY, C and DEST */
static const OVF ov_st[] = { { 23, 4, 'P' }, { 50, 8, 'D' }, { 0, 0, 0 } };
static const OVF ov_i[] = { { 23, 4, 'P' }, { 28, 1, 'C' }, { 35, 8, 'D' }, { 0, 0, 0 } };

/* Field f of area row r: 1 if it is not as shown, its text into raw (as
** typed) and v (blanks around it taken away, upper case)
*/
static int
ov_get(const DLG *d, int r, const OVF *f, char *raw, char *v)
{
    const char *now = d->buf + r * d->width + f->col;
    const char *was = d->shadow + r * d->width + f->col;
    int i, n = 0, changed = 0;

    for (i = 0; i < f->len; i++) {
        char c = now[i] == '\0' ? ' ' : (char)toupper((unsigned char)now[i]);

        raw[i] = c;
        if (c != was[i])
            changed = 1;
        if (c != ' ' || n > 0)
            v[n++] = c;
    }
    raw[f->len] = '\0';
    while (n > 0 && v[n - 1] == ' ')
        n--;
    v[n] = '\0';
    return changed;
}

static int dest_name(const char *w, char *out, size_t size);

/* The command for a changed field of a job into cmd (empty if the value
** is the job's already); the message if the value is refused
*/
static const char *
ov_command(const ISFROW *j, char what, const char *v, char *cmd, size_t size)
{
    char t = strcmp(j->type, "STC") == 0 ? 'S' : strcmp(j->type, "TSU") == 0 ? 'T' : 'J';
    char dn[9];

    cmd[0] = '\0';
    switch (what) {
    case 'P':
        /* the range is JES2's to check */
        if (strspn(v, "0123456789") != strlen(v) || strlen(v) > 3)
            return "FIELD NOT NUMERIC";
        if (atoi(v) != j->prio)
            snprintf(cmd, size, "$T%c%d,P=%d", t, j->number, atoi(v));
        return NULL;
    case 'C':
        if (!isalnum((unsigned char)v[0]))
            return "INVALID CLASS";
        if (v[0] != j->jclass)
            snprintf(cmd, size, "$T%c%d,C=%c", t, j->number, v[0]);
        return NULL;
    default:
        if (!dest_name(v, dn, sizeof(dn)))
            return "INVALID DESTINATION NAME";
        if (strcmp(dn, j->dest) != 0)
            snprintf(cmd, size, "$RALL,J=%c%d,D=%s", t, j->number, dn);
        return NULL;
    }
}

/* The fields f overtyped on the rows of a list of jobs (row r of the area
** the job jobs[top + r - 1]): all checked first, as in IBM's SDSF V1R2, and if one
** is refused nothing goes, every value typed stays and the cursor goes to
** the refused one; else a JES2 command for each. NULL if nothing changed.
*/
static const char *
ov_jobs(DLG *d, const OVF *f, const ISFROW *jobs, int n)
{
    const char *msg = NULL, *bad = NULL;
    int pass, r, k;

    d->nov = 0;
    for (pass = 0; pass < 2; pass++) {
        for (r = 1; r < d->rows && d->top + r - 1 < n; r++) {
            const ISFROW *j = &jobs[d->top + r - 1];

            for (k = 0; f[k].len > 0; k++) {
                char raw[9], v[9], cmd[40];
                const char *why;

                if (f[k].col + f[k].len > d->width || !ov_get(d, r, &f[k], raw, v)
                    || v[0] == '\0')
                    continue;
                why = ov_command(j, f[k].what, v, cmd, sizeof(cmd));
                if (pass == 0) {
                    /* every field is checked; the values typed come back
                    ** as far as there is room for them
                    */
                    int room = d->nov < (int)(sizeof(d->ov) / sizeof(d->ov[0]));

                    if (why != NULL && bad == NULL) {
                        bad = why;
                        d->ovcur = room ? d->nov : -1;
                    }
                    if (room) {
                        d->ov[d->nov].row = r;
                        d->ov[d->nov].col = f[k].col;
                        strcpy(d->ov[d->nov].text, raw);
                        d->nov++;
                    }
                    continue;
                }
                if (cmd[0] == '\0')
                    continue;
                msg = !auth_job(j, 1) ? "NOT AUTHORIZED FOR JOB" : action_issue(cmd);
            }
        }
        if (bad != NULL)
            return bad;
        d->nov = 0;
    }
    return msg;
}

static int da_job(const ISFDA *x, const ISFROW *jobs, int n, ISFROW *out);

/* O: DEST, as on ST ($RALL,J=,D=). JES2 4.1 has no $TO for O's other
** fields, which IBM's SDSF V1R2 sends.
*/
static const OVF ov_o[] = { { 40, 8, 'D' }, { 0, 0, 0 } };

/* H: a new DEST goes only with O in NP, the release; without it IBM's SDSF V1R2
** says "O" ACTION REQUIRED and keeps the value. The $R of each row
** that is to go into dest[row]; NULL, or why nothing goes.
*/
static const char *
ov_held(DLG *d, char (*dest)[40])
{
    static const OVF f = { 47, 8, 'D' };
    int which[MAXROWS];
    char action[MAXROWS][NPMAX];
    int n = np_typed(d, which, action, 2), r, k;
    const char *bad = NULL;

    d->nov = 0;
    for (r = 1; r < d->rows && d->top + r - 1 < d->njobs; r++) {
        const ISFROW *j = &d->pan.job[d->top + r - 1];
        char raw[16], v[16], cmd[40];
        const char *why;
        int o = 0;

        if (f.col + f.len > d->width || !ov_get(d, r, &f, raw, v) || v[0] == '\0')
            continue;
        why = ov_command(j, 'D', v, cmd, sizeof(cmd));
        if (why == NULL && cmd[0] == '\0')
            continue;
        for (k = 0; k < n; k++)
            if (which[k] == r - 1 && strcmp(action[k], "O ") == 0)
                o = 1;
        if (why == NULL && !o)
            why = "\"O\" ACTION REQUIRED";
        if (why != NULL) {
            if (bad == NULL) {
                bad = why;
                d->ovcur = d->nov < (int)(sizeof(d->ov) / sizeof(d->ov[0])) ? d->nov : -1;
            }
            if (d->nov < (int)(sizeof(d->ov) / sizeof(d->ov[0]))) {
                d->ov[d->nov].row = r;
                d->ov[d->nov].col = f.col;
                strcpy(d->ov[d->nov].text, raw);
                d->nov++;
            }
            continue;
        }
        snprintf(dest[r - 1], 40, "%s", cmd);
    }
    if (bad != NULL) {
        /* what was typed in NP stays as well, for the next Enter */
        for (k = 0; k < n; k++)
            np_keep(d, which[k] + 1, action[k]);
        return bad;
    }
    d->nov = 0;
    return NULL;
}

/* The fields that can be overtyped on PR, INIT and DA, columns in the
** virtual line (as in IBM's SDSF V1R2): PR SFORM, SCLASS, SEP, SFCB,
** SDEST1; INIT CLASSES; DA PGN (its column from isfst.c)
*/
static const OVF ov_pr[] = {
    { 24, 4, 'F' }, { 29, 15, 'Q' }, { 135, 3, 'S' }, { 154, 4, 'C' }, { 244, 8, 'R' },
    { 0, 0, 0 }
};
static const OVF ov_init[] = { { 18, 8, 'I' }, { 0, 0, 0 } };

/* What a changed field of row i asks for: the command into cmd (empty if
** none), or the message why the value is refused; *deny the message if
** the user may not give it
*/
typedef const char *(*OVBUILD)(DLG *d, int i, char what, const char *v,
                                char *cmd, size_t size, const char **deny);

static int
all_classes(const char *v, size_t max)
{
    size_t i, n = strlen(v);

    if (n == 0 || n > max)
        return 0;
    for (i = 0; i < n; i++)
        if (!((v[i] >= 'A' && v[i] <= 'Z') || (v[i] >= '0' && v[i] <= '9')))
            return 0;
    return 1;
}

/* PR and INIT: the printer's or the initiator's number from its row */
static const char *
ov_build_pan(DLG *d, int i, char what, const char *v, char *cmd, size_t size,
             const char **deny)
{
    const char *t = d->pan.text + (size_t)i * (size_t)d->pan.vlen;

    cmd[0] = '\0';
    *deny = NULL;
    if (what == 'I') {
        if (!all_classes(v, 8))
            return "INVALID CLASS";
        snprintf(cmd, size, "$TI%d,%s", atoi(t + 4), v);
        if (!auth_oper(1))
            *deny = "NOT AUTHORIZED FOR INIT";
        return NULL;
    }
    if (memcmp(t + 6, "PRINTER", 7) != 0)
        return "INVALID COMMAND";
    switch (what) {
    case 'F':
        if (!all_classes(v, 4))
            return "INVALID SYNTAX";
        snprintf(cmd, size, "$TPRT%d,F=%s", atoi(t + 13), v);
        break;
    case 'Q':
        if (!all_classes(v, 15))
            return "INVALID CLASS";
        snprintf(cmd, size, "$TPRT%d,Q=%s", atoi(t + 13), v);
        break;
    case 'C':
        if (!all_classes(v, 4))
            return "INVALID SYNTAX";
        snprintf(cmd, size, "$TPRT%d,C=%s", atoi(t + 13), v);
        break;
    case 'R': {
        char dn[9];

        if (!dest_name(v, dn, sizeof(dn)))
            return "INVALID DESTINATION NAME";
        snprintf(cmd, size, "$TPRT%d,R=%s", atoi(t + 13), dn);
        break;
    }
    default:
        if (strcmp(v, "YES") != 0 && strcmp(v, "Y") != 0
            && strcmp(v, "NO") != 0 && strcmp(v, "N") != 0)
            return "INVALID SYNTAX";
        snprintf(cmd, size, "$TPRT%d,S=%c", atoi(t + 13), v[0]);
        break;
    }
    if (!auth_oper(1))
        *deny = "NOT AUTHORIZED FOR PRT";
    return NULL;
}

/* DA: PGN, a RESET of the address space (E name,PERFORM=n on IBM's SDSF V1R2) */
static const char *
ov_build_da(DLG *d, int i, char what, const char *v, char *cmd, size_t size,
            const char **deny)
{
    const ISFDA *a = &d->das[i];

    (void)what;
    cmd[0] = '\0';
    *deny = NULL;
    if (strspn(v, "0123456789") != strlen(v) || strlen(v) > 3)
        return "FIELD NOT NUMERIC";
    if (atoi(v) == a->pgn)
        return NULL;
    snprintf(cmd, size, "E %s,PERFORM=%d", a->name, atoi(v));
    /* the job's update access, as for its actions; without a job the
    ** system's
    */
    if (a->number > 0) {
        ISFROW *jobs = NULL, j;
        int nj = st_read(&jobs);

        if (!da_job(a, jobs, nj > 0 ? nj : 0, &j) || !auth_job(&j, 1))
            *deny = "NOT AUTHORIZED FOR JOB";
        st_free(jobs);
    } else if (!auth_oper(1)) {
        *deny = "NOT AUTHORIZED FOR CMD";
    }
    return NULL;
}

/* The fields f overtyped on the rows of PR, INIT or DA, as ov_jobs does
** for ST and I: all checked first; a refusal stops all, the values typed
** stay and the cursor goes to it. The columns are those of the virtual
** line: those from fixed on move left by shift (PF11). NULL if nothing
** changed.
*/
static const char *
ov_area(DLG *d, const OVF *f, int fixed, int shift, int n, OVBUILD build)
{
    const char *msg = NULL, *bad = NULL;
    int pass, r, k;

    d->nov = 0;
    for (pass = 0; pass < 2; pass++) {
        for (r = 1; r < d->rows && d->top + r - 1 < n; r++) {
            for (k = 0; f[k].len > 0; k++) {
                char raw[16], v[16], cmd[48];
                const char *why, *deny;
                OVF at = f[k];

                if (shift > 0 && at.col >= fixed) {
                    at.col -= shift;
                    if (at.col < fixed)
                        continue;
                }
                if (at.col + at.len > d->width || !ov_get(d, r, &at, raw, v)
                    || v[0] == '\0')
                    continue;
                why = build(d, d->top + r - 1, at.what, v, cmd, sizeof(cmd), &deny);
                if (pass == 0) {
                    int room = d->nov < (int)(sizeof(d->ov) / sizeof(d->ov[0]));

                    if (why != NULL && bad == NULL) {
                        bad = why;
                        d->ovcur = room ? d->nov : -1;
                    }
                    if (room) {
                        d->ov[d->nov].row = r;
                        d->ov[d->nov].col = at.col;
                        strcpy(d->ov[d->nov].text, raw);
                        d->nov++;
                    }
                    continue;
                }
                if (cmd[0] == '\0')
                    continue;
                msg = deny != NULL ? deny : action_issue(cmd);
            }
        }
        if (bad != NULL)
            return bad;
        d->nov = 0;
    }
    return msg;
}

/* The commands of scrolling, on every panel but the menu. DOWN and UP keep
** to the data: MAX goes to its end.
*/
static const char *list_find(DLG *d, int *bad);
static const char *list_search(DLG *d, int how, int all);

static int
scroll_command(DLG *d, const char *word, const char *arg, const char **msg)
{
    int bottom = d->njobs - d->shown;

    /* on a list: LOCATE n puts row n at the top, FIND looks in the rows
    ** (the log and output panels take both before this)
    */
    if (strcmp(word, "LOCATE") == 0 || strcmp(word, "L") == 0) {
        char more[9];
        size_t n = strlen(arg);

        cmd_word(d, 2, more, sizeof(more));
        if (n == 0) {
            *msg = " TOO FEW PARMS";
            return 2;
        }
        if (more[0] != '\0') {
            *msg = " TOO MANY PARMS";
            return 2;
        }
        if (n > 8 || strspn(arg, "0123456789") != n) {
            const char *p = strstr(d->cmd, arg);

            d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
            *msg = " PARM INVALID";
            return 2;
        }
        scroll_to(d, atoi(arg) > 0 ? atoi(arg) - 1 : 0);
        return 1;
    }
    if ((strcmp(word, "FIND") == 0 || strcmp(word, "F") == 0) && d->rowtext != NULL) {
        int bad;

        *msg = list_find(d, &bad);
        return bad ? 2 : 1;
    }
    if (strcmp(word, "RFIND") == 0 && d->rowtext != NULL) {
        /* PF5: the last string again, in the direction of the last FIND */
        if (d->flen > 0)
            *msg = list_search(d, 0, 0);    /* F_NONE */
        else
            memset(d->cmd, ' ', CMDLEN);
        return 1;
    }

    if (strcmp(word, "TOP") == 0) {
        scroll_to(d, 0);
        return 1;
    }
    if (strcmp(word, "BOTTOM") == 0 || strcmp(word, "BOT") == 0) {
        scroll_to(d, bottom);
        return 1;
    }
    if (strcmp(word, "DOWN") == 0 || strcmp(word, "UP") == 0) {
        char amount[SCRLEN];
        int n;

        if (arg[0] == '\0') {
            memcpy(amount, d->scr, SCRLEN);
        } else if (strcmp(arg, "MAX") == 0) {
            scroll_to(d, word[0] == 'D' ? bottom : 0);
            return 1;
        } else {
            size_t l = strlen(arg);

            memset(amount, ' ', SCRLEN);
            memcpy(amount, arg, l < SCRLEN ? l : SCRLEN);
            if (l > SCRLEN || !scroll_valid(amount)) {
                *msg = "INVALID SCROLL AMOUNT";
                return 2;
            }
        }
        n = scroll_lines(d, amount);
        scroll_to(d, word[0] == 'D' ? d->top + n : d->top - n);
        return 1;
    }
    return 0;
}

/* A word on the command line in front of a scroll key overrides the amount
** for that one scroll, and is used up by it: MAX or M, PAGE or P, HALF or H,
** DATA or D, CSR or C, or a number. Returns 0 if the word is none of these;
** *max tells of MAX.
*/
static int
key_amount(DLG *d, int sc, char *amount, int *max)
{
    static const struct {
        const char *word, *amt;
    } names[] = {
        { "P", "PAGE" }, { "PAGE", "PAGE" }, { "H", "HALF" }, { "HALF", "HALF" },
        { "D", "DATA" }, { "DATA", "DATA" }, { "C", "CSR " }, { "CSR", "CSR " },
        { NULL, NULL }
    };
    char word[9];
    int i;

    *max = 0;
    cmd_word(d, 0, word, sizeof(word));
    if (word[0] == '\0') {
        memcpy(amount, d->scr, SCRLEN);
        if (sc == SCROLL_MAX)
            memcpy(amount, "0   ", SCRLEN);
        return 1;
    }
    if (strcmp(word, "M") == 0 || strcmp(word, "MAX") == 0) {
        *max = 1;
    } else {
        size_t l = strlen(word);

        memset(amount, ' ', SCRLEN);
        for (i = 0; names[i].word != NULL; i++)
            if (strcmp(word, names[i].word) == 0)
                memcpy(amount, names[i].amt, SCRLEN);
        if (amount[0] == ' ') {
            if (l > SCRLEN)
                return 0;
            memcpy(amount, word, l);
            if (!scroll_valid(amount))
                return 0;
        }
    }
    memset(d->cmd, ' ', CMDLEN);
    return 1;
}

/* DOWN or UP from a key */
static const char *
scroll_key(DLG *d, const char *verb, int sc)
{
    char amount[SCRLEN];
    int max;

    if (!key_amount(d, sc, amount, &max))
        return "INVALID SCROLL AMOUNT";
    if (max) {
        scroll_to(d, verb[0] == 'D' ? d->njobs - d->shown : 0);
    } else {
        int n = scroll_lines(d, amount);

        scroll_to(d, verb[0] == 'D' ? d->top + n : d->top - n);
    }
    return NULL;
}

/* A character of a word, for WORD, PREFIX and SUFFIX: letters, digits and
** the national characters $ # @ (on IBM's SDSF V1R2 HASP373 is a SUFFIX of
** $HASP373); anything else ends a word.
*/
static int
word_char(const char *t, int len, int c)
{
    return c >= 0 && c < len && (isalnum((unsigned char)t[c]) || t[c] == '$'
                                 || t[c] == '#' || t[c] == '@');
}

/* The kinds of FIND */
#define K_CHARS  0
#define K_WORD   1
#define K_PREFIX 2
#define K_SUFFIX 3

/* Where the last FIND's string is in the lines, from line, col on: upper
** and lower case are the same (the commands come in upper case) unless the
** string was X'..' or C'..'. The hit must be of the kind of FIND (a WORD
** stands alone, a PREFIX starts a word, a SUFFIX ends one) and within the
** columns. Backward the hit may start at col at the most. 1 and *at if it
** is there; 2 if FINDLIM lines were looked at, *at the line it stopped at.
*/
static int
find_in(const DLG *d, const ISFOUT *o, int n, int back, int line, int col,
        int *at, int *atcol)
{
    const char *s = d->find;
    int looked = 0;

    for (; back ? line >= 0 : line < o->n; line += back ? -1 : 1) {
        if (d->findlim > 0 && looked++ >= d->findlim) {
            *at = line;
            return 2;       /* FINDLIM: it stops here */
        }
        const char *t = line >= 0 && line < o->n ? o->line[line] : NULL;
        int len = t != NULL ? o->len[line] : 0;
        int c = back ? (col < len - n ? col : len - n) : col;

        for (; t != NULL && (back ? c >= 0 : c + n <= len); c += back ? -1 : 1) {
            int k = 0, before, after;

            if (d->fexact)
                while (k < n && t[c + k] == s[k])
                    k++;
            else
                while (k < n && toupper((unsigned char)t[c + k]) == s[k])
                    k++;
            if (k < n)
                continue;
            if (d->fsc > 0 && (d->fec > 0 ? c + d->fbase < d->fsc
                                          : c + d->fbase != d->fsc))
                continue;
            if (d->fec > 0 && c + n - 1 + d->fbase > d->fec)
                continue;
            before = word_char(t, len, c - 1);
            after = word_char(t, len, c + n);
            if ((d->fkind == K_WORD && (before || after))
                || (d->fkind == K_PREFIX && (before || !after))
                || (d->fkind == K_SUFFIX && (!before || after)))
                continue;
            *at = line;
            *atcol = c;
            return 1;
        }
        col = back ? LINELEN * 4 : 0;
    }
    return 0;
}

/* The words of a FIND that this one knows */
#define F_NONE  0
#define F_NEXT  1
#define F_PREV  2
#define F_FIRST 3
#define F_LAST  4

/* What a FIND command says besides its string and direction */
typedef struct {
    int kind, exact, sc, ec;
    int all;                /* ALL: count the hits, go to the first */
} FOPT;

/* The kind in the messages, as IBM's SDSF V1R2 has them: " CHARS 'x' FOUND",
** "NO CHARS  'x' FOUND", " WORD  'x' FOUND", "NO  WORD  'x' FOUND"; those
** of PREFIX and SUFFIX that find nothing are not seen yet
*/
static const char *const kind_found[] = { " CHARS", " WORD ", "PREFIX", "SUFFIX" };
static const char *const kind_none[] = {
    "NO CHARS  ", "NO  WORD  ", "NO PREFIX  ", "NO SUFFIX  "
};

/* A string in quotes at c: 'x', "x", or X'..' in hex, two digits a byte
** (as in IBM's SDSF V1R2; C'..' and T'..' are no strings of their own there). Its
** bytes go to str, the end of it to *next. 0 if it is none; -1 if it is
** wrong, -2 if the hex string is.
*/
static int
quoted(const char *c, const char *end, char *str, int *len, int *exact,
       const char **next)
{
    char kind = ' ', q;
    const char *w;
    int n;

    if (*c == 'X' && c + 1 < end && (c[1] == '\'' || c[1] == '"'))
        kind = *c++;
    if (*c != '\'' && *c != '"')
        return 0;
    q = *c++;
    for (w = c; c < end && *c != q; c++)
        ;
    if (c >= end || c == w)
        return kind == 'X' ? -2 : -1;
    n = (int)(c - w);
    *next = c + 1;
    *exact = kind == 'X';
    if (kind != 'X') {
        memcpy(str, w, (size_t)n);
        *len = n;
        return 1;
    }
    if (n % 2 != 0 || (int)strspn(w, "0123456789ABCDEF") < n)
        return -2;
    for (*len = 0; *len < n / 2; (*len)++) {
        char h[3];

        h[0] = w[2 * *len];
        h[1] = w[2 * *len + 1];
        h[2] = '\0';
        str[*len] = (char)strtoul(h, NULL, 16);
    }
    return 1;
}

/* Read FIND string [NEXT|PREV|FIRST|LAST|ALL] [CHARS|WORD|PREFIX|SUFFIX]
** [start-col [end-col]] after the first word of the command. A string in
** quotes may hold blanks; X'..' is in hex, X'..' and C'..' tell upper from
** lower case; * is the string of the last FIND, no string at all repeats
** the last FIND as it was. NULL if it can be done, else the message.
*/
static const char *
find_parse(DLG *d, char *str, int *len, int *how, FOPT *f)
{
    const char *c = d->cmd, *end = d->cmd + CMDLEN;
    int parms = 0, ncol = 0, kind = -1;

    *len = -1;
    *how = F_NONE;
    memset(f, 0, sizeof(*f));
    while (c < end && *c == ' ')
        c++;
    while (c < end && *c != ' ')    /* FIND or F */
        c++;
    /* as in IBM's SDSF V1R2, too many words come first: a string in quotes is one */
    {
        const char *k = c;
        int words = 0;

        for (;;) {
            while (k < end && *k == ' ')
                k++;
            if (k >= end)
                break;
            words++;
            if (*k == 'X' && k + 1 < end && (k[1] == '\'' || k[1] == '"'))
                k++;
            if (*k == '\'' || *k == '"') {
                char q = *k++;

                while (k < end && *k != q)
                    k++;
                if (k < end)
                    k++;
            }
            while (k < end && *k != ' ')
                k++;
        }
        if (words > 5)
            return " TOO MANY PARMS";
    }
    for (;;) {
        char word[CMDLEN + 1];
        const char *w, *next;
        int n, q, exact = 0;

        while (c < end && *c == ' ')
            c++;
        if (c >= end)
            break;
        if (++parms > 5)
            return " TOO MANY PARMS";
        if ((q = quoted(c, end, word, &n, &exact, &next)) != 0) {
            if (q == -2) {
                d->cmdpos = (int)(c - d->cmd);
                return " INVALID HEX STRING";
            }
            if (q < 0 || *len >= 0)
                return "INVALID SYNTAX";
            memcpy(str, word, (size_t)n);
            *len = n;
            f->exact = exact;
            c = next;
            if (c < end && *c != ' ')
                return "INVALID SYNTAX";
            continue;
        }
        for (w = c; c < end && *c != ' '; c++)
            ;
        n = (int)(c - w);
        memcpy(word, w, (size_t)n);
        word[n] = '\0';
        if (strcmp(word, "NEXT") == 0 || strcmp(word, "PREV") == 0
            || strcmp(word, "FIRST") == 0 || strcmp(word, "LAST") == 0
            || strcmp(word, "ALL") == 0) {
            if (*how != F_NONE || f->all)
                return " INCONSISTENT PARAMETERS";
            if (word[0] == 'A')
                f->all = 1;
            else
                *how = word[0] == 'N' ? F_NEXT : word[0] == 'P' ? F_PREV
                     : word[0] == 'F' ? F_FIRST : F_LAST;
            continue;
        }
        if (strcmp(word, "CHARS") == 0 || strcmp(word, "CHAR") == 0
            || strcmp(word, "WORD") == 0 || strcmp(word, "PREFIX") == 0
            || strcmp(word, "PRE") == 0 || strcmp(word, "SUFFIX") == 0
            || strcmp(word, "SUF") == 0) {
            if (kind >= 0)
                return " INCONSISTENT PARAMETERS";
            kind = word[0] == 'C' ? K_CHARS : word[0] == 'W' ? K_WORD
                 : word[0] == 'P' ? K_PREFIX : K_SUFFIX;
            continue;
        }
        if (isdigit((unsigned char)word[0])) {
            int v = atoi(word);

            if ((int)strspn(word, "0123456789") != n || v < 1 || ncol >= 2)
                return "INVALID SYNTAX";
            if (n > 3 || v > 254 + d->fbase)
                return ncol == 0 ? " INVALID LEFT BOUNDARY" : " INVALID RIGHT BOUNDARY";
            /* the columns either way round, as in IBM's SDSF V1R2 */
            if (ncol++ == 0) {
                f->sc = v;
            } else if (v < f->sc) {
                f->ec = f->sc;
                f->sc = v;
            } else {
                f->ec = v;
            }
            continue;
        }
        if (*len >= 0)
            return "INVALID SYNTAX";
        if (strcmp(word, "*") == 0) {
            if (d->flen == 0)
                return "INVALID SYNTAX";
            *len = d->flen;
            memcpy(str, d->find, (size_t)*len);
            f->exact = d->fexact;
        } else {
            *len = n;
            memcpy(str, word, (size_t)n);
        }
    }
    f->kind = kind >= 0 ? kind : K_CHARS;
    if (f->ec > 0 && *len > f->ec - f->sc + 1)
        return " INCONSISTENT PARAMETERS";
    if (*len < 0) {                 /* again, as the last one */
        if (d->flen == 0)
            return "INVALID SYNTAX";
        *len = d->flen;
        memcpy(str, d->find, (size_t)*len);
        if (kind < 0 && ncol == 0) {
            /* FIND alone or with a direction: the last one's kind and
            ** columns
            */
            f->kind = d->fkind;
            f->sc = d->fsc;
            f->ec = d->fec;
        }
        f->exact = d->fexact;
        if (*how == F_NONE && !f->all)
            *how = d->fback ? F_PREV : F_NEXT;
        return NULL;
    }
    if (*how == F_NONE && (*len != d->flen || f->exact != d->fexact
                           || memcmp(str, d->find, (size_t)*len) != 0))
        *how = F_NEXT;              /* a new string goes forward */
    return NULL;
}

/* The message of a FIND, with as much of the string as fits. The blanks are
** those of IBM's SDSF V1R2: two before the string when it is not found, one before
** CHARS when it is.
*/
static const char *
find_msg(DLG *d, const char *before, const char *after)
{
    int room = (int)sizeof(d->fmsg) - 1 - (int)strlen(before)
             - (int)strlen(after) - 2;

    if (d->fexact) {
        /* a hex string shows as one, with a blank in front (IBM's SDSF V1R2) */
        char hex[2 * CMDLEN + 1];
        int i, n = d->flen;

        for (i = 0; i < n; i++)
            snprintf(hex + 2 * i, 3, "%02X", (unsigned char)d->find[i]);
        room -= 2;
        snprintf(d->fmsg, sizeof(d->fmsg), "%s X'%.*s'%s", before,
                 2 * n < room ? 2 * n : room, hex, after);
        return d->fmsg;
    }
    snprintf(d->fmsg, sizeof(d->fmsg), "%s'%.*s'%s", before,
             d->flen < room ? d->flen : room, d->find, after);
    return d->fmsg;
}

/* Search the lines and scroll to the hit, which becomes the top line. A
** search goes on from the last hit while the screen stays where that put
** it, else from the top line of the screen; FIRST and LAST start at an end.
** When the end is reached, the next search starts again at the other one.
** Line i of the data is line i + 1 of the panel, after TOP OF DATA.
*/
static const char *
find_do(DLG *d, const ISFOUT *o, const char *str, int len, int how,
        const FOPT *f)
{
    char up[CMDLEN], before[24], after[24];
    int line, col, at, atcol, i, from_hit = 0, whole = 0, count = 0;
    int exact = f != NULL ? f->exact : d->fexact;

    for (i = 0; i < len; i++)
        up[i] = exact ? str[i] : (char)toupper((unsigned char)str[i]);
    if (len != d->flen || memcmp(up, d->find, (size_t)len) != 0
        || (f != NULL && (f->kind != d->fkind || f->sc != d->fsc
                          || f->ec != d->fec || f->exact != d->fexact))) {
        d->fline = -1;          /* another string starts at the screen */
        d->fwrap = 0;
    }
    if (f != NULL) {
        d->fkind = f->kind;
        d->fexact = f->exact;
        d->fsc = f->sc;
        d->fec = f->ec;
    }
    memcpy(d->find, up, (size_t)len);
    d->flen = len;
    if (how != F_NONE)
        d->fback = how == F_PREV || how == F_LAST;
    /* kept in the profile: a fresh SDSF finds the string again */
    snprintf(d->fndv, sizeof(d->fndv), "%c%02d%-57.*s",
             d->fback ? 'P' : 'N', len, len, d->find);
    profile(d, "VPUT", "ISFFND");
    if (f != NULL && f->all) {
        /* ALL: the hits of the whole data, then the first of them */
        int l = 0, c = 0;

        while (find_in(d, o, len, 0, l, c, &at, &atcol) == 1) {
            count++;
            l = at;
            c = atcol + 1;
        }
        how = F_FIRST;
        d->fback = 0;
    }
    if (how == F_FIRST || how == F_LAST
        || (d->fwrap && d->top == d->ftop)) {
        line = d->fback ? o->n - 1 : 0;
        col = d->fback ? LINELEN * 4 : 0;
        whole = 1;
    } else if (d->fline >= 0 && d->top == d->ftop) {
        line = d->fline;
        col = d->fback ? d->fcol - 1 : d->fcol + 1;
        from_hit = 1;
    } else {
        line = d->top > 0 ? d->top - 1 : 0;
        col = 0;
        if (d->fback) {
            line--;
            col = LINELEN * 4;
        }
    }
    /* a search that starts at the beginning of the data (or backward at
    ** its end) searches all of it: as in IBM's SDSF V1R2 it says at once that the
    ** string is nowhere
    */
    if (!d->fback ? line <= 0 && col <= 0 : line >= o->n - 1 && col >= LINELEN * 4)
        whole = 1;
    d->fwrap = 0;
    snprintf(before, sizeof(before), "%s", kind_none[d->fkind]);
    i = find_in(d, o, len, d->fback, line, col, &at, &atcol);
    if (i == 2) {
        /* as far as FINDLIM goes: the screen there, the next FIND goes on */
        scroll_to(d, at + 1);
        d->fline = -1;
        return "*FINDLIM REACHED*";
    }
    if (i == 0) {
        /* none after the last hit: as in IBM's SDSF V1R2 the screen, the cursor on
        ** that hit and the message of it stay
        */
        if (from_hit) {
            at = d->fline;
            atcol = d->fcol;
            goto hit;
        }
        /* as in IBM's SDSF V1R2: a search from the screen that reaches the end
        ** says so, whether the string is elsewhere or not; the next one
        ** starts at the other end, and only that one says it is nowhere
        */
        d->fline = -1;
        if (whole)
            return o->full ? "NOT ENOUGH STORAGE"
                           : find_msg(d, before, " FOUND");
        d->fwrap = 1;
        d->ftop = d->top;
        return d->fback ? " * TOP OF DATA REACHED *"
                        : "*BOTTOM OF DATA REACHED*";
    }
hit:
    scroll_to(d, at + 1);
    d->fline = at;
    d->fcol = atcol;
    d->ftop = d->top;
    /* the columns move to show the hit if it is not on the screen */
    if (atcol < d->left || atcol + len > d->left + d->width) {
        d->left = atcol + len <= d->width ? 0 : atcol;
        if (d->left > 255 - d->width)
            d->left = 255 - d->width;
    }
    /* the cursor goes to the hit: its line is the first of the data, the
    ** row after the command row in the area
    */
    memcpy(d->csr, "ISFBUF  ", 8);
    snprintf(d->csrpos, sizeof(d->csrpos), "%-8d",
             (d->cols ? 2 : 1) * d->width + (atcol - d->left) + 1);
    /* ALL puts the number of hits in front, in seven columns */
    snprintf(after, sizeof(after), " FOUND");
    if (count > 0)
        snprintf(before, sizeof(before), "%7d %s ", count, kind_found[d->fkind]);
    else
        snprintf(before, sizeof(before), "%s ", kind_found[d->fkind]);
    return find_msg(d, before, after);
}

/* NEXT and PREV: the panel goes to the start of a data set n after or
** before the one at its top; NEXT 0 to the start of that one. Past the
** last data set the last line comes to the top, before the first the top
** of the data.
*/
static const char *
next_prev(DLG *d, const ISFOUT *o, int back, const char *arg)
{
    int n = 1, cur = 0, want, k, i;
    int at = d->top - 1;        /* the data line at the top */

    if (arg[0] != '\0') {
        for (i = 0; arg[i] != '\0'; i++)
            if (!isdigit((unsigned char)arg[i])) {
                const char *p = strstr(d->cmd, arg);

                d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
                return " PARM INVALID";
            }
        n = atoi(arg);
    }
    if (o->n == 0)
        return NULL;
    if (at < 0)
        at = 0;
    if (at >= o->n)
        at = o->n - 1;
    for (i = 1; i <= at; i++)
        if (o->dsid[i] != o->dsid[i - 1])
            cur++;
    want = back ? cur - n : cur + n;
    /* before the first: the top of the data, as in IBM's SDSF V1R2 */
    if (want < 0) {
        scroll_to(d, 0);
        return NULL;
    }
    for (i = 0, k = 0; i < o->n; i++) {
        if (i > 0 && o->dsid[i] != o->dsid[i - 1])
            k++;
        if (k == want)
            break;
    }
    if (i >= o->n)              /* past the last: its last line on top */
        i = o->n - 1;
    scroll_to(d, i + 1);
    return NULL;
}

/* ACTION, on every panel: which outstanding replies the log shows. Up to
** four of: routing codes 1 to 16, MVS (1-12), USER (13-16), ALL, or OFF
** alone; they add to what was set. ? says what is set (IBM's SDSF V1R2 shows
** nothing). NULL if there is nothing to say; the command line is cleared
** unless it was wrong.
*/
static const char *
action_cmd(DLG *d)
{
    unsigned short set = d->action;
    int i, n = 0, off = 0;
    char w[9];

    /* as in IBM's SDSF V1R2: up to four words; OFF stands alone; a code beyond 16,
    ** and ACTION without a word, change nothing and say nothing
    */
    cmd_word(d, 5, w, sizeof(w));
    if (w[0] != '\0')
        return " TOO MANY PARMS";
    for (i = 1; i <= 4; i++) {
        cmd_word(d, i, w, sizeof(w));
        if (w[0] == '\0')
            break;
        n++;
        if (strcmp(w, "?") == 0) {
            int c, at;

            if (n > 1 || (cmd_word(d, 2, w, sizeof(w)), w[0] != '\0'))
                return "INVALID SYNTAX";
            if (d->action == 0)
                snprintf(d->amsg, sizeof(d->amsg), "ACTION=OFF");
            else if (d->action == 0xFFFF)
                snprintf(d->amsg, sizeof(d->amsg), "ACTION=ALL");
            else {
                at = snprintf(d->amsg, sizeof(d->amsg), "ACTION=");
                for (c = 1; c <= 16; c++)
                    if (d->action & (0x8000 >> (c - 1)))
                        at += snprintf(d->amsg + at, sizeof(d->amsg) - (size_t)at,
                                       "%s%d", at > 7 ? "," : "", c);
            }
            memset(d->cmd, ' ', CMDLEN);
            return d->amsg;
        }
        if (strcmp(w, "ALL") == 0)
            set = 0xFFFF;
        else if (strcmp(w, "OFF") == 0)
            off = i;
        else if (strcmp(w, "MVS") == 0)
            set |= 0xFFF0;
        else if (strcmp(w, "USER") == 0)
            set |= 0x000F;
        else {
            int c, k;

            for (k = 0; w[k] != '\0'; k++)
                if (w[k] < '0' || w[k] > '9') {
                    const char *p = strstr(d->cmd, w);

                    d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
                    return " PARM INVALID";
                }
            c = atoi(w);
            if (c >= 1 && c <= 16)
                set |= (unsigned short)(0x8000 >> (c - 1));
        }
    }
    if (off) {
        if (n > 1) {
            const char *p = strstr(d->cmd, "OFF");

            d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
            return " PARM INVALID";
        }
        set = 0;
    }
    if (set != d->action) {
        d->action = set;
        snprintf(d->actv, sizeof(d->actv), "%04X", set);
        profile(d, "VPUT", "ISFACT");
    }
    memset(d->cmd, ' ', CMDLEN);
    return NULL;
}

/* Read the log again, and the outstanding replies that ACTION asks for: as
** on IBM's SDSF V1R2 they follow the last line of the log, newest first, in the form
** of a log line with the routing codes in front. NULL, or what went wrong.
*/
static const char *
log_read(DLG *d, ISFOUT *o)
{
    const char *msg = NULL;
    int n, i;

    out_free(o);
    if (d->sysid[0] != '\0') {
        /* SYSID of another system: IBM's SDSF V1R2 shows an empty log */
        d->fline = -1;
        d->fwrap = 0;
        return "NO SYSLOG FOUND";
    }
    if (log_load(o) != 0)
        msg = "LOG NOT READABLE";
    d->fline = -1;
    d->fwrap = 0;
    if (d->action == 0)
        return msg;
    n = wtor_read(d->wtor, WTOR_MAX);
    if (n < 0)
        return msg != NULL ? msg : "REPLIES NOT READABLE";
    for (i = 0; i < n; i++) {
        const ISFWTOR *w = &d->wtor[i];
        char line[160];
        int l;

        if (w->routed && (w->rout & d->action) == 0)
            continue;
        l = snprintf(line, sizeof(line), "%04X %s", w->routed ? w->rout : 0, w->text);
        if (l > (int)sizeof(line) - 1)
            l = (int)sizeof(line) - 1;
        out_add(o, line, (unsigned)l, REPLY_DSID);
    }
    return msg;
}

/* A command line that starts with /: the rest goes to the system as an
** operator command, on every panel; one that starts with TSO, see tso_cmd. 0 if the line is no such command, else
** 1 with the message in *msg; the line is cleared when it went out.
*/
/* TSO followed by a TSO command, CLIST or program name, on every panel:
** ISPF runs it with SELECT CMD(); its output comes in line mode and the
** panel is back after Enter, with no message (IBM's SDSF V1R2). TSO alone is
** refused with COMMAND PARM IS MISSING.
*/
static int
tso_cmd(DLG *d, int i, const char **msg)
{
    char service[9] = "SELECT  ";
    char buf[CMDLEN + 8];
    int end = CMDLEN, len;
    unsigned plist[3];

    i += 3;
    while (i < CMDLEN && d->cmd[i] == ' ')
        i++;
    while (end > i && (d->cmd[end - 1] == ' ' || d->cmd[end - 1] == '\0'))
        end--;
    if (end <= i) {
        memset(d->cmd, ' ', CMDLEN);    /* IBM's SDSF V1R2 clears the line */
        *msg = "COMMAND PARM IS MISSING";
        return 1;
    }
    len = snprintf(buf, sizeof(buf), "CMD(%.*s)", end - i, d->cmd + i);
    memset(d->cmd, ' ', CMDLEN);
    plist[0] = (unsigned)service;
    plist[1] = (unsigned)&len;
    plist[2] = (unsigned)buf | 0x80000000;
    __call(d->isplink, plist);
    /* the screen was the command's: the panel is shown in full again */
    *msg = NULL;
    return 1;
}

static int
slash_cmd(DLG *d, const char **msg)
{
    int i = 0, end = CMDLEN, after;

    while (i < CMDLEN && d->cmd[i] == ' ')
        i++;
    if (i + 3 <= CMDLEN && memcmp(d->cmd + i, "TSO", 3) == 0
        && (i + 3 == CMDLEN || d->cmd[i + 3] == ' ' || d->cmd[i + 3] == '\0'))
        return tso_cmd(d, i, msg);
    if (i >= CMDLEN || d->cmd[i] != '/')
        return 0;
    after = ++i;
    while (i < CMDLEN && d->cmd[i] == ' ')
        i++;
    while (end > i && (d->cmd[end - 1] == ' ' || d->cmd[end - 1] == '\0'))
        end--;
    if (end <= i) {
        *msg = "NO COMMAND PROVIDED";
        d->cmdpos = after;      /* right after the /, as in IBM's SDSF V1R2 */
        return 1;
    }
    if (!auth_oper(1)) {
        *msg = "NOT AUTHORIZED FOR CMD";
        return 1;
    }
    if (op_command(d->cmd + i, end - i) != 0) {
        *msg = "COMMAND NOT AUTHORIZED";
        return 1;
    }
    memset(d->cmd, ' ', CMDLEN);
    *msg = "COMMAND ISSUED";
    return 1;
}

/* A job name against a pattern: any stands for any characters, one for a
** single one. The name is blank on the right.
*/
static int
name_match(const char *pat, const char *name, char any, char one)
{
    const char *star = NULL, *back = NULL;
    char n[9];
    const char *s = n;
    int i;

    for (i = 0; i < 8 && name[i] != ' ' && name[i] != '\0'; i++)
        n[i] = name[i];
    n[i] = '\0';
    while (*s != '\0') {
        if (*pat != '\0' && *pat != any && (*pat == one || *pat == *s)) {
            pat++;
            s++;
        } else if (*pat == any) {
            star = pat++;
            back = s;
        } else if (star != NULL) {
            pat = star + 1;
            s = ++back;
        } else {
            return 0;
        }
    }
    while (*pat == any)
        pat++;
    return *pat == '\0';
}

/* ST, ST name, STclasses, STclasses name: the first word starts with ST,
** up to six classes may follow it. 0 if the words are no ST command, 1 if
** they are one and it is set, 2 if it is wrong: then *msg says why.
*/
static int
st_parse(DLG *d, const char *word, const char **msg)
{
    char third[9], name[CMDLEN + 1];
    size_t n = strlen(word), i;

    if (n < 2 || word[0] != 'S' || word[1] != 'T' || n > 8 || first_long(d))
        return 0;
    for (i = 2; i < n; i++)
        if (!((word[i] >= 'A' && word[i] <= 'Z')
              || (word[i] >= '0' && word[i] <= '9')))
            return 0;
    cmd_word(d, 1, name, sizeof(name));
    cmd_word(d, 2, third, sizeof(third));
    if (third[0] != '\0') {
        *msg = " TOO MANY PARMS";
        return 2;
    }
    if (strlen(name) > 8) {
        *msg = " PARM INVALID";
        return 2;
    }
    snprintf(d->stclass, sizeof(d->stclass), "%s", word + 2);
    snprintf(d->stname, sizeof(d->stname), "%s", name);
    return 1;
}

/* PREFIX or PRE, on every panel: PREFIX name x y. Without a name all jobs
** are shown again; x and y take the place of * and %. PREFIX ? puts the
** setting on the command line. NULL if it is set.
*/
static const char *
prefix_cmd(DLG *d)
{
    char name[CMDLEN + 1], x[9], y[9], more[9];
    char any = '*', one = '%';

    cmd_word(d, 1, name, sizeof(name));
    cmd_word(d, 2, x, sizeof(x));
    cmd_word(d, 3, y, sizeof(y));
    cmd_word(d, 4, more, sizeof(more));
    if (more[0] != '\0')
        return " TOO MANY PARMS";
    if (strcmp(name, "?") == 0 && x[0] == '\0') {
        char line[CMDLEN + 1];
        int n;

        /* none set reads as *, as in IBM's SDSF V1R2 */
        n = snprintf(line, sizeof(line), "PREFIX %s %c %c",
                     d->prefix[0] ? d->prefix : "*", d->pany, d->pone);
        memset(d->cmd, ' ', CMDLEN);
        memcpy(d->cmd, line, (size_t)n);
        return NULL;
    }
    if (strlen(name) > 8)
        return " PARM INVALID";
    if (strlen(x) > 1 || strlen(y) > 1)
        return "INVALID SYNTAX";
    if (x[0] != '\0')
        any = x[0];
    if (y[0] != '\0')
        one = y[0];
    if (any == one || any == '?' || one == '?' || any == '&' || one == '&')
        return "INVALID SYNTAX";
    snprintf(d->prefix, sizeof(d->prefix), "%s", name);
    d->pany = any;
    d->pone = one;
    snprintf(d->pfxv, sizeof(d->pfxv), "%-8s%c%c", d->prefix, any, one);
    profile(d, "VPUT", "ISFPFX");
    memset(d->cmd, ' ', CMDLEN);
    return NULL;
}

/* A destination name as JES2 4.1 knows it, in the form the lists show:
** LOCAL (also ANYLOCAL), Rn for R, RM or RMT and a number, Un as it is.
** 0 if it is none.
*/
static int
dest_name(const char *w, char *out, size_t size)
{
    const char *num = NULL;

    if (strcmp(w, "LOCAL") == 0 || strcmp(w, "ANYLOCAL") == 0) {
        snprintf(out, size, "LOCAL");
        return 1;
    }
    if (strncmp(w, "RMT", 3) == 0)
        num = w + 3;
    else if (strncmp(w, "RM", 2) == 0)
        num = w + 2;
    else if (w[0] == 'R' || w[0] == 'U')
        num = w + 1;
    if (num == NULL || *num == '\0' || strlen(num) > 4 || strspn(num, "0123456789") != strlen(num))
        return 0;
    snprintf(out, size, "%c%d", w[0] == 'U' ? 'U' : 'R', atoi(num));
    return 1;
}

static void
dest_put(DLG *d)
{
    int i;

    memset(d->dstv, ' ', sizeof(d->dstv));
    for (i = 0; i < d->ndest; i++)
        memcpy(d->dstv + 9 * i, d->dest[i], strlen(d->dest[i]));
    profile(d, "VPUT", "ISFDST");
}

/* DEST, on every panel, as in IBM's SDSF V1R2: DEST name ... (four at
** most) limits the lists to jobs with one of these destinations, DEST alone
** shows all again, DEST ? puts the setting on the command line. NULL if
** it is set.
*/
static const char *
dest_cmd(DLG *d)
{
    char w[5][CMDLEN + 1], norm[4][9];
    int i, n = 0;

    for (i = 0; i < 5; i++)
        cmd_word(d, i + 1, w[i], sizeof(w[i]));
    if (w[4][0] != '\0')
        return " TOO MANY PARMS";
    if (strcmp(w[0], "?") == 0 && w[1][0] == '\0') {
        char line[CMDLEN + 1];
        int len = snprintf(line, sizeof(line), "DEST");

        for (i = 0; i < d->ndest; i++)
            len += snprintf(line + len, sizeof(line) - (size_t)len, " %s", d->dest[i]);
        memset(d->cmd, ' ', CMDLEN);
        memcpy(d->cmd, line, (size_t)len);
        /* the cursor after DEST, on the first name if there is one (IBM's SDSF V1R2) */
        d->cmdpos = d->ndest > 0 ? 5 : 4;
        return NULL;
    }
    for (i = 0; i < 4 && w[i][0] != '\0'; i++) {
        if (!dest_name(w[i], norm[n], sizeof(norm[n]))) {
            size_t wl = strlen(w[i]);
            int k;

            /* the cursor on the name (the line has no end mark) */
            d->cmdpos = 0;
            for (k = 0; k + (int)wl <= CMDLEN; k++)
                if (memcmp(d->cmd + k, w[i], wl) == 0
                    && (k == 0 || d->cmd[k - 1] == ' ')) {
                    d->cmdpos = k;
                    break;
                }
            return "INVALID DESTINATION NAME";
        }
        n++;
    }
    for (i = 0; i < n; i++)
        snprintf(d->dest[i], sizeof(d->dest[i]), "%s", norm[i]);
    d->ndest = n;
    dest_put(d);
    memset(d->cmd, ' ', CMDLEN);
    return NULL;
}

/* The job is to be shown under DEST */
static int
dest_match(const DLG *d, const ISFROW *j)
{
    int i;

    if (d->ndest == 0)
        return 1;
    for (i = 0; i < d->ndest; i++)
        if (strcmp(d->dest[i], j->dest) == 0)
            return 1;
    return 0;
}

/* ---- PRINT ---- */

/* Where word n of the command line begins, for the cursor */
static int
word_pos(const DLG *d, int which)
{
    int i = 0;

    for (;;) {
        while (i < CMDLEN && d->cmd[i] == ' ')
            i++;
        if (which-- == 0)
            return i < CMDLEN ? i : 0;
        while (i < CMDLEN && d->cmd[i] != ' ' && d->cmd[i] != '\0')
            i++;
    }
}

/* A text unit of our own for dynalloc: key, one value of n bytes */
static char *
print_tu(unsigned char *tu, unsigned key, const void *v, unsigned n)
{
    tu[0] = (unsigned char)(key >> 8);
    tu[1] = (unsigned char)key;
    tu[2] = 0;
    tu[3] = 1;
    tu[4] = 0;
    tu[5] = (unsigned char)n;
    memcpy(tu + 6, v, n);
    return (char *)tu;
}

/* The print file: SYSOUT of class c ('\0' the default) with copies and
** forms, or the data set dsn (vol NULL: cataloged) with disp OLD, SHR or
** MOD. 0 if it is open.
*/
static int
print_open(DLG *d, char c, int copies, const char *forms, const char *dsn,
           const char *vol, const char *disp)
{
    __dyn_t dy;
    unsigned char tu[2][16];
    char *misc[3];
    char dd[9] = "????????", name[45], volser[7];
    int n = 0;

    dyninit(&dy);
    dy.__ddname = dd;
    if (dsn == NULL) {
        unsigned char cp = (unsigned char)copies;

        dy.__sysout = c ? c : __DEF_CLASS;
        if (copies > 1)
            misc[n++] = print_tu(tu[0], 0x001D, &cp, 1);         /* DALCOPYS */
        if (forms != NULL && forms[0] != '\0')
            misc[n++] = print_tu(tu[1], 0x001A, forms, (unsigned)strlen(forms));
        if (n > 0) {
            misc[n - 1] = (char *)((unsigned)misc[n - 1] | 0x80000000u);
            misc[n] = NULL;
            dy.__miscitems = misc;
        }
        dy.__recfm = _FB_ + _A_;
        dy.__lrecl = 133;
        dy.__blksize = 1330;
    } else {
        snprintf(name, sizeof(name), "%s", dsn);
        dy.__dsname = name;
        if (vol != NULL) {
            snprintf(volser, sizeof(volser), "%s", vol);
            dy.__volser = volser;
        }
        dy.__status = strcmp(disp, "SHR") == 0 ? __DISP_SHR
                    : strcmp(disp, "MOD") == 0 ? __DISP_MOD : __DISP_OLD;
    }
    if (dynalloc(&dy) != 0)
        return -1;
    {
        char spec[16];

        snprintf(spec, sizeof(spec), "DD:%s", dd);
        d->prf = fopen(spec, dsn != NULL && strcmp(disp, "MOD") == 0 ? "a" : "w");
    }
    if (d->prf == NULL) {
        dyninit(&dy);
        dy.__ddname = dd;
        dynfree(&dy);
        return -1;
    }
    snprintf(d->prdd, sizeof(d->prdd), "%s", dd);
    d->prsysout = dsn == NULL;
    d->prn = 0;
    d->prpage = 0;
    return 0;
}

/* Close the print file; its SYSOUT goes to be printed when it is freed */
static int
print_close(DLG *d)
{
    __dyn_t dy;
    int n = d->prn;

    if (d->prf == NULL)
        return -1;
    fclose(d->prf);
    d->prf = NULL;
    dyninit(&dy);
    dy.__ddname = d->prdd;
    dynfree(&dy);
    d->prn = 0;
    return n;
}

/* The heading of a page of the log in the print file, as in
** IBM's SDSF V1R2: where it has the SYSLOG's job and data set, ours says MTT
*/
static void
print_head(DLG *d, int line)
{
    char sysid[5], date[9], jul[7];
    time_t now = time(NULL);
    struct tm *tm = localtime(&now);

    st_sysid(sysid);
    strftime(date, sizeof(date), "%m/%d/%y", tm);
    snprintf(jul, sizeof(jul), "%02d.%03d", tm->tm_year % 100, tm->tm_yday + 1);
    fprintf(d->prf, "1          SDSF  SYSLOG  PRINT   %-24sSYSTEM ID %-4s  DATE %s   %s"
            "   LINE%8d  PAGE%8d\n", "MTT", d->sysid[0] ? d->sysid : sysid, date, jul,
            line, ++d->prpage);
}

/* Lines first to last (from 1) of the Output panel into the print file.
** A job's lines with their own ASA character (a blank for a record with
** none, or with a machine code); the log's in pages of 60 under a heading,
** each PRINT on a new page (IBM's SDSF V1R2).
*/
#define PRINT_PAGE 60
static int
print_lines(DLG *d, int first, int last, int *pages)
{
    const ISFOUT *o = d->pout;
    int i, n = 0;

    *pages = 0;
    for (i = first; i <= last && i <= o->n; i++) {
        const char *t = o->line[i - 1];
        int len = o->len[i - 1], rc;

        if (d->pjob) {
            char cc = t[-1];

            if (cc != ' ' && cc != '0' && cc != '-' && cc != '+' && cc != '1')
                cc = ' ';
            rc = fprintf(d->prf, "%c%.*s\n", cc, len > 132 ? 132 : len, t);
        } else {
            if (n % PRINT_PAGE == 0) {
                print_head(d, i);
                ++*pages;
            }
            rc = fprintf(d->prf, " %.*s\n", len > 132 ? 132 : len, t);
        }
        if (rc < 0)
            break;
        n++;
    }
    d->prn += n;
    return n;
}

/* PRINT, as SDSF V1R2's help gives it: OPEN [class] [copies]
** [form], ODSN data-set [vol-ser|*] [OLD|SHR|MOD], CLOSE, and on the
** Output panel and the log first-line last-line, or nothing for all of it.
** The first PRINT of lines opens a SYSOUT file if none is open.
*/
static void
print_cmd(DLG *d, const char **msg)
{
    static char text[40];
    char w[5][CMDLEN + 1];
    int i, bad = 0;

    for (i = 0; i < 5; i++)
        cmd_word(d, i + 1, w[i], sizeof(w[i]));
    *msg = NULL;
    if (strcmp(w[0], "CLOSE") == 0) {
        int n;

        if (w[1][0] != '\0') {
            *msg = " TOO MANY PARMS";
            return;
        }
        if ((n = print_close(d)) < 0) {
            *msg = "PRINT NOT OPENED";
            d->cmdpos = word_pos(d, 1);
            return;
        }
        snprintf(text, sizeof(text), "PRINT CLOSED %6d LINE", n);
        *msg = text;
    } else if (strcmp(w[0], "OPEN") == 0) {
        int copies = 1;

        if (w[4][0] != '\0') {
            *msg = " TOO MANY PARMS";
            return;
        }
        if (w[1][0] != '\0' && (strlen(w[1]) != 1 || !isalnum((unsigned char)w[1][0])))
            bad = 2;
        else if (w[2][0] != '\0' && (strspn(w[2], "0123456789") != strlen(w[2])
                                     || (copies = atoi(w[2])) < 1 || copies > 255))
            bad = 3;
        else if (strlen(w[3]) > 4)
            bad = 4;
        if (!bad && d->prf != NULL) {
            *msg = "PRINT ALREADY OPEN";
            d->cmdpos = word_pos(d, 1);
            return;
        }
        if (!bad)
            *msg = print_open(d, w[1][0], copies, w[3], NULL, NULL, NULL) == 0
                 ? " PRINT OPENED" : "PRINT OPEN ERROR";
    } else if (strcmp(w[0], "ODSN") == 0) {
        char dsn[CMDLEN + 1];
        const char *disp = w[3][0] ? w[3] : "OLD";
        size_t n = strlen(w[1]);

        if (w[4][0] != '\0') {
            *msg = " TOO MANY PARMS";
            return;
        }
        if (n == 0) {
            *msg = " TOO FEW PARMS";
            return;
        }
        /* quoted, or as typed: SDSF adds no prefix */
        if (w[1][0] == '\'' && n > 2 && w[1][n - 1] == '\'')
            snprintf(dsn, sizeof(dsn), "%.*s", (int)n - 2, w[1] + 1);
        else
            snprintf(dsn, sizeof(dsn), "%s", w[1]);
        if (strlen(dsn) > 44)
            bad = 2;
        else if (strlen(w[2]) > 6)
            bad = 3;
        else if (strcmp(disp, "OLD") != 0 && strcmp(disp, "SHR") != 0
                 && strcmp(disp, "MOD") != 0)
            bad = 4;
        if (!bad && d->prf != NULL) {
            *msg = "PRINT ALREADY OPEN";
            d->cmdpos = word_pos(d, 1);
            return;
        }
        if (!bad)
            *msg = print_open(d, 0, 1, NULL, dsn,
                              w[2][0] == '\0' || strcmp(w[2], "*") == 0 ? NULL : w[2],
                              disp) == 0 ? " PRINT OPENED" : "PRINT OPEN ERROR";
    } else if (w[0][0] == '\0' && (d->pout == NULL || !d->pjob)) {
        /* PRINT alone on the log and the lists: it opens the file, if
        ** none is open (as in IBM's SDSF V1R2)
        */
        if (d->prf == NULL)
            *msg = print_open(d, 0, 1, NULL, NULL, NULL, NULL) == 0
                 ? " PRINT OPENED" : "PRINT OPEN ERROR";
    } else if (d->pout == NULL) {
        /* a range of lines on a list: IBM's SDSF V1R2 refuses the first word */
        bad = 1;
    } else {
        int first = 1, last = d->pout->n, n, pages;

        if (w[0][0] != '\0' && (strspn(w[0], "0123456789") != strlen(w[0])
                                || strlen(w[0]) > 8))
            bad = 1;
        else if (w[0][0] != '\0' && w[1][0] == '\0') {
            *msg = " TOO FEW PARMS";
            return;
        } else if (w[2][0] != '\0') {
            *msg = " TOO MANY PARMS";
            return;
        } else if (w[1][0] != '\0' && (strspn(w[1], "0123456789") != strlen(w[1])
                                       || strlen(w[1]) > 8))
            bad = 2;
        if (!bad && w[0][0] != '\0') {
            first = atoi(w[0]) < 1 ? 1 : atoi(w[0]);
            /* IBM's SDSF V1R2: a last line before the first prints the first */
            last = atoi(w[1]) < first ? first : atoi(w[1]);
        }
        if (!bad) {
            if (d->prf == NULL && print_open(d, 0, 1, NULL, NULL, NULL, NULL) != 0) {
                *msg = "PRINT OPEN ERROR";
                return;
            }
            n = print_lines(d, first, last, &pages);
            if (d->pjob) {
                snprintf(text, sizeof(text), "%10d LINES PRINTED", n);
            } else {
                snprintf(text, sizeof(text), "%10d PAGES PRINTED", pages);
                /* the log shows the first line printed (IBM's SDSF V1R2) */
                if (w[0][0] != '\0')
                    scroll_to(d, first);
            }
            *msg = text;
        }
    }
    if (bad) {
        d->cmdpos = word_pos(d, bad);
        *msg = " PARM INVALID";
        return;
    }
    memset(d->cmd, ' ', CMDLEN);
}

/* INPUT ON|OFF, SET HEX [ON|OFF], FINDLIM n|?, WHO: settings, good on
** every panel as in IBM's SDSF V1R2. 0 if the word is none of them, else 1 and *msg (NULL
** when it is done).
*/
static int
setting_cmd(DLG *d, const char *word, const char **msg)
{
    char a[CMDLEN + 1], b[CMDLEN + 1], c[CMDLEN + 1];
    const char *bad = NULL;

    if (strcmp(word, "PRINT") == 0) {
        print_cmd(d, msg);
        return 1;
    }
    if (strcmp(word, "INPUT") != 0 && strcmp(word, "SET") != 0
        && strcmp(word, "FINDLIM") != 0 && strcmp(word, "WHO") != 0
        && strcmp(word, "SYSID") != 0)
        return 0;
    cmd_word(d, 1, a, sizeof(a));
    cmd_word(d, 2, b, sizeof(b));
    cmd_word(d, 3, c, sizeof(c));
    *msg = NULL;
    if (word[1] == 'Y') {
        /* SYSID name: the system whose log LOG shows, as in IBM's SDSF V1R2; with
        ** one system and the master trace table only ours has one
        */
        char own[5];

        st_sysid(own);
        if (a[0] == '\0') {
            *msg = " TOO FEW PARMS";
        } else if (b[0] != '\0') {
            *msg = " TOO MANY PARMS";
        } else if (strcmp(a, "?") == 0) {
            int n = snprintf(c, sizeof(c), "SYSID %s", d->sysid[0] ? d->sysid : own);

            memset(d->cmd, ' ', CMDLEN);
            memcpy(d->cmd, c, (size_t)n);
            d->cmdpos = 6;
        } else if (strlen(a) > 4) {
            *msg = " PARM INVALID";
            d->cmdpos = 6;
        } else {
            snprintf(d->sysid, sizeof(d->sysid), "%s", strcmp(a, own) == 0 ? "" : a);
            memset(d->cmd, ' ', CMDLEN);
        }
        return 1;
    }
    if (word[0] == 'W') {
        /* WHO: the user's line over the first row, for one display */
        if (a[0] != '\0') {
            *msg = " TOO MANY PARMS";
        } else {
            d->who = 1;
            memset(d->cmd, ' ', CMDLEN);
        }
        return 1;
    }
    if (a[0] == '\0') {
        *msg = " TOO FEW PARMS";
        return 1;
    }
    if (word[0] == 'I') {
        if (b[0] != '\0')
            *msg = " TOO MANY PARMS";
        else if (strcmp(a, "ON") == 0 || strcmp(a, "OFF") == 0)
            d->input = a[1] == 'N';
        else
            bad = a;
    } else if (word[0] == 'S') {
        if (c[0] != '\0')
            *msg = " TOO MANY PARMS";
        else if (strcmp(a, "HEX") != 0)
            bad = a;
        else if (b[0] == '\0' || strcmp(b, "ON") == 0 || strcmp(b, "OFF") == 0)
            d->hex = b[1] != 'F';
        else
            bad = b;
    } else if (b[0] != '\0') {
        *msg = " TOO MANY PARMS";
    } else if (strcmp(a, "?") == 0) {
        /* the setting on the command line, the cursor after FINDLIM */
        char line[CMDLEN + 1];
        int n = snprintf(line, sizeof(line), "FINDLIM %d", d->findlim);

        memset(d->cmd, ' ', CMDLEN);
        memcpy(d->cmd, line, (size_t)n);
        d->cmdpos = 8;
        return 1;
    } else if (strspn(a, "0123456789") != strlen(a) || strlen(a) > 7
               || atoi(a) < 1000) {
        bad = a;
    } else {
        d->findlim = atoi(a);
    }
    if (bad != NULL) {
        const char *p = strstr(d->cmd + strlen(word), bad);

        d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
        *msg = " PARM INVALID";
    }
    if (*msg == NULL)
        memset(d->cmd, ' ', CMDLEN);
    return 1;
}

/* The types and positions of DA, as bits */
#define DT_JOB  1
#define DT_TSU  2
#define DT_STC  4
#define DT_INIT 8
#define DT_ALL  15
#define DT_DEF  (DT_JOB | DT_TSU | DT_STC)
#define DP_IN   1       /* swapped in; nonswappable counts as in */
#define DP_OUT  2
#define DP_TRANS 4      /* not told apart on MVS 3.8j yet: none */
#define DP_READY 8
#define DP_ALL  15

/* DA and its parameters, as SDSF V1R2 has them: types (JOB TSU STC INIT)
** and positions (IN OUT TRANS READY) are added; with O in front they are
** the only ones, with NO in front they are left out; ALL, ALLT and ALLP
** take all of both, of the types, of the positions, and stand alone. At
** most four. 0 if the words are no DA command, 1 if they are one and it is
** set, 2 if not: then *msg says why.
*/
static int
da_parse(DLG *d, const char *word, const char **msg)
{
    static const struct {
        const char *name;
        int type, pos;
    } kw[] = {
        { "JOB", DT_JOB, 0 }, { "TSU", DT_TSU, 0 }, { "STC", DT_STC, 0 },
        { "INIT", DT_INIT, 0 }, { "IN", 0, DP_IN }, { "OUT", 0, DP_OUT },
        { "TRANS", 0, DP_TRANS }, { "READY", 0, DP_READY }, { NULL, 0, 0 }
    };
    char w[9];
    int type = DT_DEF, pos = DP_ALL, addt = 0, addp = 0, only = 0, all = 0, n = 0, i, k;

    if (strcmp(word, "DA") != 0)
        return 0;
    cmd_word(d, 5, w, sizeof(w));
    if (w[0] != '\0') {
        *msg = " TOO MANY PARMS";
        return 2;
    }
    for (i = 1; i <= 4; i++) {
        const char *base = w;
        int kind = 0;           /* 0 add, 1 only, 2 no */

        cmd_word(d, i, w, sizeof(w));
        if (w[0] == '\0')
            break;
        n++;
        if (strcmp(w, "ALL") == 0 || strcmp(w, "ALLT") == 0 || strcmp(w, "ALLP") == 0) {
            all = w[3] == 'T' ? 1 : w[3] == 'P' ? 2 : 3;
            continue;
        }
        if (w[0] == 'O' && w[1] != 'U') {
            kind = 1;
            base = w + 1;
        } else if (w[0] == 'N' && w[1] == 'O') {
            kind = 2;
            base = w + 2;
        }
        for (k = 0; kw[k].name != NULL && strcmp(kw[k].name, base) != 0; k++)
            ;
        if (kw[k].name == NULL) {
            const char *p = strstr(d->cmd, w);

            d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
            *msg = " PARM INVALID";
            return 2;
        }
        if (kind == 1 && only++) {
            *msg = " PARM INVALID";
            return 2;
        }
        if (kw[k].type) {
            if (kind == 1)
                type = kw[k].type;
            else if (kind == 2)
                type &= ~kw[k].type;
            else
                addt |= kw[k].type;
        } else {
            if (kind == 1)
                pos = kw[k].pos;
            else if (kind == 2)
                pos &= ~kw[k].pos;
            else
                addp |= kw[k].pos;
        }
    }
    if (all && n > 1) {
        *msg = " PARM INVALID";
        return 2;
    }
    type |= addt;
    if (addp)
        pos = addp;
    if (all & 1)
        type = DT_ALL;
    if (all & 2)
        pos = DP_ALL;
    d->datype = type;
    d->dapos = pos;
    return 1;
}

/* Classes after the letters of a command: up to max of A-Z, 0-9 and, if
** extra, $ and #. 0 if the rest of the word is not that.
*/
static int
classes(const char *rest, int max, int extra)
{
    int n = 0;

    for (; *rest != '\0'; rest++, n++)
        if (!((*rest >= 'A' && *rest <= 'Z') || (*rest >= '0' && *rest <= '9')
              || (extra && (*rest == '$' || *rest == '#'))))
            return 0;
    return n <= max;
}

/* I, O, H, PR and INIT with their parameters, as in SDSF V1R2:
**   Iclasses [H|NH]    the input queue; $ is TSO users, # started tasks
**   Oclasses [forms]   output not held
**   Hclasses [ALL|name] held output; without ALL the user's jobs only
**   PR [up to four of: number, n-m, Rnumber, LCL, RMT]
**   INIT
** 0 if the words are none of them, 1 if they are one and it is set (the
** kind in d->pkind), 2 if not: then *msg says why.
*/
static int
pan_parse(DLG *d, const char *word, const char **msg)
{
    char w[2][CMDLEN + 1];
    int kind, i, nw;

    if (first_long(d))
        return 0;
    if (strcmp(word, "INIT") == 0)
        kind = PK_INIT;
    else if (strcmp(word, "PR") == 0)
        kind = PK_PR;
    else if (word[0] == 'I' && classes(word + 1, 8, 1))
        kind = PK_I;
    else if (word[0] == 'O' && classes(word + 1, 8, 0))
        kind = PK_O;
    else if (word[0] == 'H' && classes(word + 1, 8, 0))
        kind = PK_H;
    else
        return 0;
    /* printers and initiators are the system's: SDSF.OPER */
    if ((kind == PK_PR || kind == PK_INIT) && !auth_oper(0)) {
        *msg = "COMMAND NOT AUTHORIZED";
        return 2;
    }
    cmd_word(d, 1, w[0], sizeof(w[0]));
    cmd_word(d, 2, w[1], sizeof(w[1]));
    nw = w[0][0] == '\0' ? 0 : w[1][0] == '\0' ? 1 : 2;
    if (kind == PK_PR) {
        char more[9];

        cmd_word(d, 5, more, sizeof(more));
        if (more[0] != '\0') {
            *msg = " TOO MANY PARMS";
            return 2;
        }
        d->nprsel = 0;
        for (i = 1; i <= 4; i++) {
            char a[CMDLEN + 1];
            const char *dash;
            int ok;

            cmd_word(d, i, a, sizeof(a));
            if (a[0] == '\0')
                break;
            dash = strchr(a, '-');
            ok = strcmp(a, "LCL") == 0 || strcmp(a, "RMT") == 0;
            if (!ok && a[0] == 'R' && a[1] != '\0')
                ok = (int)strspn(a + 1, "0123456789") == (int)strlen(a + 1);
            /* a range low to high: 2-1 is refused on IBM's SDSF V1R2 */
            if (!ok && dash != NULL)
                ok = dash > a && dash[1] != '\0'
                     && (int)strspn(a, "0123456789") == (int)(dash - a)
                     && strspn(dash + 1, "0123456789") == strlen(dash + 1)
                     && atoi(a) <= atoi(dash + 1);
            if (!ok)
                ok = a[0] != '\0' && strspn(a, "0123456789") == strlen(a);
            if (!ok || strlen(a) > 8) {
                const char *p = strstr(d->cmd, a);

                d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
                *msg = " PARM INVALID";
                return 2;
            }
            snprintf(d->prsel[d->nprsel++], sizeof(d->prsel[0]), "%s", a);
        }
    } else if ((kind == PK_INIT && nw > 0) || nw > 1) {
        *msg = " TOO MANY PARMS";
        return 2;
    } else if (strlen(w[0]) > 8) {
        *msg = " PARM INVALID";
        return 2;
    } else if (kind == PK_I) {
        if (nw == 1 && strcmp(w[0], "H") != 0 && strcmp(w[0], "NH") != 0) {
            /* the cursor on it, as in IBM's SDSF V1R2 (I $: classes go after I) */
            const char *p = strstr(d->cmd + 1, w[0]);

            d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
            *msg = " PARM INVALID";
            return 2;
        }
        snprintf(d->iclass, sizeof(d->iclass), "%s", word + 1);
        d->iheld = nw == 0 ? 0 : w[0][0] == 'H' ? 1 : 2;
    } else if (kind == PK_O) {
        snprintf(d->oclass, sizeof(d->oclass), "%s", word + 1);
        snprintf(d->oforms, sizeof(d->oforms), "%s", w[0]);
    } else if (kind == PK_H) {
        snprintf(d->hclass, sizeof(d->hclass), "%s", word + 1);
        d->hall = strcmp(w[0], "ALL") == 0;
        snprintf(d->hname, sizeof(d->hname), "%s", d->hall ? "" : w[0]);
    }
    d->pkind = kind;
    return 1;
}

/* What a panel under a list hands back */
#define P_BACK  0       /* END: to the panel before */
#define P_ST    1       /* the ST command: to a fresh list */
#define P_ERROR 2       /* ISPF failed */
#define P_LOG   3       /* the LOG command */
#define P_DA    4       /* the DA command */
#define P_PAN   5       /* I, O, H, PR or INIT: d->pkind says which */

/* A panel code that leads to another list */
#define TO_LIST(p) ((p) == P_ST || (p) == P_LOG || (p) == P_DA || (p) == P_PAN)

/* A line number as IBM's SDSF V1R2 shows it: with commas between the thousands */
static const char *
line_no(char *buf, size_t size, int n)
{
    char digits[16];
    int len, i, k = 0;

    len = snprintf(digits, sizeof(digits), "%d", n);
    for (i = 0; i < len && (size_t)k < size - 1; i++) {
        if (i > 0 && (len - i) % 3 == 0)
            buf[k++] = ',';
        buf[k++] = digits[i];
    }
    buf[k] = '\0';
    return buf;
}

/* Where a message starts on the title of the log and of output: column 57
** of the screen; the attribute of the line takes the first one.
*/
#define T_MSG   55

/* The lines of data on the Output panel: one row each, four with SET HEX
** (the text, the zone and the numeric digits, a line of dashes), less the
** scale of COLS
*/
static void
out_shown(DLG *d)
{
    int rows = d->rows - (d->cols ? 1 : 0);

    d->shown = d->hex ? rows / 4 : rows;
    if (d->shown < 1)
        d->shown = 1;
}

/* The data area of the Output panel from line at on, as IBM's SDSF V1R2 shows it */
static void
out_fill(DLG *d, const ISFOUT *o, int at, int total)
{
    static const char top[] = " TOP OF DATA ";
    static const char bot[] = " BOTTOM OF DATA ";
    static const char digit[] = "0123456789ABCDEF";
    int per = d->hex ? 4 : 1, first = d->cols ? 1 : 0, k, r, w = d->width;

    memset(d->buf, ' ', (size_t)(w * d->rows));
    if (d->cols) {
        /* the scale: the columns of the record, a digit every tenth */
        for (k = 0; k < w; k++) {
            int c = d->left + d->fbase + k;

            d->buf[k] = c % 10 == 0 ? (char)('0' + c / 10 % 10) : c % 5 == 0 ? '+' : '-';
        }
    }
    for (r = 0; at + r < total && first + r * per < d->rows; r++) {
        int y = first + r * per;
        char *row = d->buf + y * w;
        int i = at + r;
        const char *t = NULL;
        int len = 0;

        if (i == 0 || i == total - 1) {
            const char *s = i == 0 ? top : bot;
            size_t l = strlen(s);

            memset(row, '*', (size_t)w);
            memcpy(row + ((size_t)w - l) / 2, s, l);
        } else {
            t = o->line[i - 1];
            len = o->len[i - 1];
            if (len > d->left) {
                int l = len - d->left;

                memcpy(row, t + d->left, (size_t)(l < w ? l : w));
            }
        }
        if (!d->hex)
            continue;
        for (k = 0; t != NULL && k < w; k++) {
            unsigned char b = d->left + k < len ? (unsigned char)t[d->left + k] : 0x40;

            /* what the screen cannot show as a character */
            if (b < 0x40)
                row[k] = '.';
            if (y + 1 < d->rows)
                row[w + k] = digit[b >> 4];
            if (y + 2 < d->rows)
                row[2 * w + k] = digit[b & 15];
        }
        if (y + 3 < d->rows)
            memset(row + 3 * w + 1, '-', (size_t)(w - 2));
    }
    /* The replies at the end of the log stand out in high intensity.
    ** IBM's SDSF V1R2 shows them white, but Wally ISPF gives every row of the
    ** area its colour; an attribute in the last column of the row
    ** before (of the command row above the first row of data) takes
    ** that column's character and keeps the intensity across rows.
    */
    for (r = 0; at + r < total && first + r * per < d->rows; r++) {
        int i = at + r, y = first + r * per;
        int reply = i >= 1 && i <= o->n && o->dsid[i - 1] == REPLY_DSID;
        int before = i >= 2 && i - 1 <= o->n && o->dsid[i - 2] == REPLY_DSID;

        if (reply == before)
            continue;
        if (y == 0)
            d->cmdend = reply ? 0x07 : 0x05;
        else
            d->buf[y * w - 1] = reply ? 0x07 : 0x05;
    }
}

/* FIND on a list panel: the string in its rows as they are on the screen
** (on IBM's SDSF V1R2 F ZSOUT on ST puts ZSOUT's row at the top, the cursor in its
** NP column). From the row at the top on, or after it if that is the last
** hit; at the end the next one starts at the other end.
*/
static const char *
list_find(DLG *d, int *bad)
{
    char str[CMDLEN];
    int len, how, k;
    FOPT f;
    const char *m = find_parse(d, str, &len, &how, &f);

    *bad = m != NULL;
    if (m != NULL)
        return m;
    for (k = 0; k < len; k++)
        str[k] = f.exact ? str[k] : (char)toupper((unsigned char)str[k]);
    if (len != d->flen || memcmp(str, d->find, (size_t)len) != 0)
        d->fline = -1;
    memcpy(d->find, str, (size_t)len);
    d->flen = len;
    d->fexact = f.exact;
    d->fkind = K_CHARS;
    if (how != F_NONE)
        d->fback = how == F_PREV || how == F_LAST;
    return list_search(d, how, f.all);
}

/* Search the rows for d->find, as in IBM's SDSF V1R2: from the row after
** the cursor's when it was on one, else from the top row (NEXT) or the one
** before it (PREV); FIRST, LAST, ALL and a search after the end start at
** an end. ALL counts the rows that have it and goes to the first.
*/
static const char *
list_search(DLG *d, int how, int all)
{
    char row[LINELEN];
    int i, k, n = d->njobs, start, step, from_top = 0, hits = 0, first = -1;
    int len = d->flen;
    const char *str = d->find;

    step = d->fback ? -1 : 1;
    if (all) {
        step = 1;
        start = 0;
        from_top = 1;
    } else if (how == F_FIRST || how == F_LAST || d->fwrap) {
        start = d->fback ? n - 1 : 0;
        from_top = 1;
    } else if (d->crow >= 0 && d->crow < n) {
        start = d->crow + step;
    } else {
        start = d->fback ? d->top - 1 : d->top;
        from_top = d->fback ? start >= n - 1 : start <= 0;
    }
    d->fwrap = 0;
    for (i = start; i >= 0 && i < n; i += step) {
        d->rowtext(d, i, row);
        for (k = 0; k + len <= d->width; k++) {
            int c = 0;

            while (c < len && (d->fexact ? row[k + c] == str[c]
                               : toupper((unsigned char)row[k + c]) == str[c]))
                c++;
            if (c == len)
                break;
        }
        if (k + len <= d->width) {
            if (!all)
                break;
            if (first < 0)
                first = i;
            hits++;
        }
    }
    if (all)
        i = first;
    memset(d->cmd, ' ', CMDLEN);
    if (i < 0 || i >= n) {
        d->fline = -1;
        if (from_top)
            return find_msg(d, kind_none[K_CHARS], " FOUND");
        d->fwrap = 1;
        return d->fback ? " * TOP OF DATA REACHED *" : "*BOTTOM OF DATA REACHED*";
    }
    scroll_to(d, i);
    d->fline = d->top;
    memcpy(d->csr, "ISFBUF  ", 8);
    snprintf(d->csrpos, sizeof(d->csrpos), "%-8d", 2 * d->width + 2);
    if (all) {
        char count[12];
        const char *m;

        snprintf(count, sizeof(count), "%d", hits);
        m = find_msg(d, " CHARS ", " FOUND");
        memmove(d->fmsg + strlen(count), m, strlen(m) + 1 < sizeof(d->fmsg) - strlen(count)
                ? strlen(m) + 1 : sizeof(d->fmsg) - strlen(count) - 1);
        memcpy(d->fmsg, count, strlen(count));
        d->fmsg[sizeof(d->fmsg) - 1] = '\0';
        return d->fmsg;
    }
    return find_msg(d, " CHARS ", " FOUND");
}

/* The rows of the list panels, for list_find */
static void
rt_st(void *v, int i, char *row)
{
    DLG *d = v;

    memset(row, ' ', (size_t)d->width);
    st_row(&d->jobs[i], row, d->width);
}

static void
rt_da(void *v, int i, char *row)
{
    DLG *d = v;

    memset(row, ' ', (size_t)d->width);
    da_row(&d->das[i], row, d->width, 0);
}

static void
rt_pan(void *v, int i, char *row)
{
    DLG *d = v;

    pan_line(&d->pan, i, row, d->width, 0);
}

static void
rt_jds(void *v, int i, char *row)
{
    DLG *d = v;

    memset(row, ' ', (size_t)d->width);
    jds_row(d->curjds, i, row, d->width, 0);
}

/* RIGHT and LEFT on the Output panel by an amount, or as far as it goes */
static void
out_sideways(DLG *d, int right, const char *amt, int max)
{
    int n = max ? 255
          : memcmp(amt, "PAGE", SCRLEN) == 0 ? d->width
          : memcmp(amt, "HALF", SCRLEN) == 0 ? d->width / 2
          : memcmp(amt, "DATA", SCRLEN) == 0 ? d->width - 1
          : memcmp(amt, "CSR ", SCRLEN) == 0 ? d->width
          : atoi(amt);

    d->left += right ? n : -n;
    if (d->left > 255 - d->width)
        d->left = 255 - d->width;
    if (d->left < 0)
        d->left = 0;
}

/* LOCATE n (L n): line n to the top, on output the nth of the data set at
** the top; on the log also LOCATE hh.mm.ss, the first line of that time or
** later. NULL if done.
*/
static const char *
locate_cmd(DLG *d, const ISFOUT *o, int job)
{
    char a[CMDLEN + 1], b[CMDLEN + 1];
    size_t n;
    int target;

    cmd_word(d, 1, a, sizeof(a));
    cmd_word(d, 2, b, sizeof(b));
    if (a[0] == '\0')
        return " TOO FEW PARMS";
    if (b[0] != '\0')
        return " TOO MANY PARMS";
    n = strlen(a);
    if (n <= 8 && strspn(a, "0123456789") == n) {
        target = atoi(a);
        if (job && d->top >= 1 && d->top <= o->n) {
            int f = d->top - 1;

            while (f > 0 && o->dsid[f - 1] == o->dsid[d->top - 1])
                f--;
            target += f;
        }
    } else if (!job && n == 8 && a[2] == '.' && a[5] == '.'
               && isdigit((unsigned char)a[0]) && isdigit((unsigned char)a[1])
               && isdigit((unsigned char)a[3]) && isdigit((unsigned char)a[4])
               && isdigit((unsigned char)a[6]) && isdigit((unsigned char)a[7])) {
        int i;

        /* the time of a line of the log stands in columns 6 to 13 */
        for (i = 0; i < o->n; i++) {
            const char *t = o->line[i];

            if (o->len[i] >= 13 && t[7] == '.' && t[10] == '.'
                && isdigit((unsigned char)t[5]) && memcmp(t + 5, a, 8) >= 0)
                break;
        }
        target = i + 1;
    } else {
        const char *p = strstr(d->cmd, a);

        d->cmdpos = p != NULL ? (int)(p - d->cmd) : 0;
        return " PARM INVALID";
    }
    if (target > o->n)
        target = o->n;
    d->fline = -1;
    scroll_to(d, target);
    memset(d->cmd, ' ', CMDLEN);
    return NULL;
}

/* The Output Data Set panel: the lines in storage, one column offset for all */
static int
out_panel2(DLG *d, const ISFROW *job, ISFOUT *o, const char *first);

/* The Output panel, its lines there for PRINT while it is shown */
static int
out_panel(DLG *d, const ISFROW *job, ISFOUT *o, const char *first)
{
    const ISFOUT *was = d->pout;
    int wasjob = d->pjob, rc;

    d->pout = o;
    d->pjob = job != NULL;
    rc = out_panel2(d, job, o, first);
    d->pout = was;
    d->pjob = wasjob;
    return rc;
}

static int
out_panel2(DLG *d, const ISFROW *job, ISFOUT *o, const char *first)
{
    char word[9], arg[9], verb[9];
    const char *msg = first != NULL ? first : o->full ? "NOT ENOUGH STORAGE" : NULL;
    int total = o->n + 2;   /* the two lines of stars */
    int rc, sc, r;

    d->left = 0;
    d->cols = 0;
    d->fbase = job != NULL ? 2 : 1;     /* see the title's COLUMNS */
    d->fline = -1;
    d->fwrap = 0;
    d->njobs = total;
    out_shown(d);
    d->tail = 0;
    d->top = 0;
    /* The log opens at its end, the newest lines */
    if (job == NULL)
        scroll_to(d, total - d->shown);
    memset(d->cmd, ' ', CMDLEN);
    cursor_to(d, "ISFCMD");
    for (;;) {
        d->rowtext = NULL;
        int at, dsid;
        char head[80], num[16];

        out_shown(d);
        at = d->top;
        dsid = at > 0 && at <= o->n ? o->dsid[at - 1]
                 : o->n > 0 ? o->dsid[at == 0 ? 0 : o->n - 1] : 0;

        if (job != NULL) {
            /* The columns are those of the record: the first holds its
            ** carriage control on the spool and is never shown.
            */
            /* as in IBM's SDSF V1R2, LINE counts within the data set */
            int rel = at;

            if (at >= 1 && at <= o->n) {
                int first = at - 1;

                while (first > 0 && o->dsid[first - 1] == o->dsid[at - 1])
                    first--;
                rel = at - first;
            }
            snprintf(head, sizeof(head),
                     "SDSF OUTPUT DISPLAY %-8s %s%6d DSID%6d LINE%8s COLUMNS  %02d-%4d",
                     job->name, job->type, job->number, dsid,
                     line_no(num, sizeof(num), rel),
                     d->left + 2, d->left + d->width + 1);
        } else {
            char sysid[5], date[9];
            time_t now = time(NULL);
            struct tm *tm = localtime(&now);

            st_sysid(sysid);
            strftime(date, sizeof(date), "%m/%d/%y", tm);
            snprintf(head, sizeof(head),
                     "SDSF SYSLOG   %-8s %-4s DATE %s LINE%8s  COLUMNS %3d %3d",
                     d->sysid[0] ? "   0.000" : "MTT", d->sysid[0] ? d->sysid : sysid,
                     date, line_no(num, sizeof(num), d->sysid[0] ? 0 : at),
                     d->left + 1, d->left + d->width);
        }
        memset(d->line, ' ', LINELEN);
        memcpy(d->line, head, strlen(head));
        if (msg != NULL) {
            /* as in IBM's SDSF V1R2: the message starts in column 57 of the screen,
            ** over whatever stands there, and is cut at the right edge
            */
            int len = (int)strlen(msg);

            memset(d->line + T_MSG, ' ', (size_t)(LINELEN - T_MSG));
            if (len > d->width - 1 - T_MSG)
                len = d->width - 1 - T_MSG;
            memcpy(d->line + T_MSG, msg, (size_t)len);
            msg = NULL;
        }
        out_fill(d, o, at, total);
        d->help = job != NULL ? "ISFHOD" : "ISFHLG";
        rc = list_display(d);
        if (rc != 0 && rc != 8)
            return P_ERROR;
        system_var(d, "ZVERB", verb, sizeof(verb));
        sc = scroll_check(d);
        if (sc == SCROLL_BAD) {
            if (rc == 8)
                return P_BACK;
            cursor_to(d, "ISFS");
            msg = "INVALID SCROLL AMOUNT";
            continue;
        }
        if (rc == 8)
            return P_BACK;
        if (memcmp(verb, "DOWN", 4) == 0 || memcmp(verb, "UP", 2) == 0) {
            /* PF8 at the end of the log looks for new lines, as Enter does */
            if (job == NULL && verb[0] == 'D' && d->top + d->shown >= total) {
                msg = log_read(d, o);
                total = o->n + 2;
                d->njobs = total;
                scroll_to(d, total - d->shown);
                memset(d->cmd, ' ', CMDLEN);
            } else {
                msg = scroll_key(d, verb, sc);
            }
            cursor_to(d, "ISFCMD");
            continue;
        }
        if (memcmp(verb, "RIGHT", 5) == 0 || memcmp(verb, "LEFT", 4) == 0) {
            char amt[SCRLEN];
            int max;

            if (!key_amount(d, sc, amt, &max))
                msg = "INVALID SCROLL AMOUNT";
            else
                out_sideways(d, verb[0] == 'R', amt, max);
            cursor_to(d, "ISFCMD");
            continue;
        }
        cursor_to(d, "ISFCMD");
        /* the Repeat-FIND key; with something on the command line that
        ** runs instead, as in IBM's SDSF V1R2
        */
        cmd_word(d, 0, word, sizeof(word));
        if (memcmp(verb, "RFIND", 5) == 0 && word[0] == '\0') {
            if (d->flen > 0)
                msg = find_do(d, o, d->find, d->flen, F_NONE, NULL);
            continue;
        }
        if (slash_cmd(d, &msg)) {
            /* on the log, the answer is wanted: a moment for it, then the
            ** log is read again; who stood at its end stays there
            */
            if (job == NULL && msg != NULL && strcmp(msg, "COMMAND ISSUED") == 0) {
                int at_end = d->top + d->shown >= total;

                sleep(1);
                {
                    const char *m = log_read(d, o);

                    if (m != NULL)
                        msg = m;
                }
                total = o->n + 2;
                d->njobs = total;
                scroll_to(d, at_end ? total - d->shown : d->top);
            }
            continue;
        }
        cmd_word(d, 0, word, sizeof(word));
        cmd_word(d, 1, arg, sizeof(arg));
        if (strcmp(word, "END") == 0)
            return P_BACK;
        if (strcmp(word, "FIND") == 0 || strcmp(word, "F") == 0) {
            char str[CMDLEN];
            int len, how;
            FOPT f;

            msg = find_parse(d, str, &len, &how, &f);
            if (msg == NULL) {
                msg = find_do(d, o, str, len, how, &f);
                memset(d->cmd, ' ', CMDLEN);
            }
            continue;
        }
        if (strcmp(word, "NEXT") == 0 || strcmp(word, "N") == 0
            || strcmp(word, "PREV") == 0 || strcmp(word, "P") == 0) {
            /* on the log they do nothing and say nothing, as in IBM's SDSF V1R2 */
            msg = job != NULL ? next_prev(d, o, word[0] == 'P', arg) : NULL;
            if (msg == NULL)
                memset(d->cmd, ' ', CMDLEN);
            continue;
        }
        if (strcmp(word, "RFIND") == 0) {
            /* typed, as the key: the last string again (isfkfind) */
            if (d->flen > 0)
                msg = find_do(d, o, d->find, d->flen, F_NONE, NULL);
            memset(d->cmd, ' ', CMDLEN);
            continue;
        }
        if (strcmp(word, "LOCATE") == 0 || strcmp(word, "L") == 0) {
            msg = locate_cmd(d, o, job != NULL);
            continue;
        }
        if (strcmp(word, "RIGHT") == 0 || strcmp(word, "LEFT") == 0) {
            /* as the keys, with the amount after the word (IBM's SDSF V1R2) */
            char amt[SCRLEN], more[9];
            size_t l = strlen(arg);

            cmd_word(d, 2, more, sizeof(more));
            memcpy(amt, d->scr, SCRLEN);
            if (l > 0) {
                memset(amt, ' ', SCRLEN);
                memcpy(amt, arg, l < SCRLEN ? l : SCRLEN);
            }
            if (more[0] != '\0') {
                msg = " TOO MANY PARMS";
            } else if (strcmp(arg, "MAX") == 0 || strcmp(arg, "M") == 0) {
                out_sideways(d, word[0] == 'R', amt, 1);
                memset(d->cmd, ' ', CMDLEN);
            } else if (l > SCRLEN || !scroll_valid(amt)) {
                msg = "INVALID SCROLL AMOUNT";
            } else {
                out_sideways(d, word[0] == 'R', amt, 0);
                memset(d->cmd, ' ', CMDLEN);
            }
            continue;
        }
        if ((strcmp(word, "COLS") == 0 || strcmp(word, "RESET") == 0)
            && arg[0] == '\0') {
            d->cols = word[0] == 'C';
            memset(d->cmd, ' ', CMDLEN);
            continue;
        }
        if (word[0] == '\0' && job == NULL) {
            /* Enter reads the log again; who stood at its end stays there */
            int at_end = d->top + d->shown >= total;

            msg = log_read(d, o);
            total = o->n + 2;
            d->njobs = total;
            scroll_to(d, at_end ? total - d->shown : d->top);
            continue;
        }
        if (word[0] == '\0')
            continue;
        r = scroll_command(d, word, arg, &msg);
        if (r == 2)
            continue;
        if (r == 0 && strcmp(word, "ACTION") == 0) {
            msg = action_cmd(d);
            /* on the log the replies follow at once; the screen stays */
            if (job == NULL && memcmp(d->cmd, "ACTION", 6) != 0) {
                const char *m = log_read(d, o);

                if (m != NULL)
                    msg = m;
                total = o->n + 2;
                d->njobs = total;
                scroll_to(d, d->top);
            }
            continue;
        }
        if (r == 0 && job == NULL && strcmp(word, "SYSID") == 0
            && setting_cmd(d, word, &msg)) {
            /* the log of the system now chosen, at once (IBM's SDSF V1R2) */
            if (msg == NULL && d->cmd[0] == ' ') {
                msg = log_read(d, o);
                total = o->n + 2;
                d->njobs = total;
                scroll_to(d, 0);
            }
            continue;
        }
        if (r == 0 && setting_cmd(d, word, &msg))
            continue;
        if (r == 0 && strcmp(word, "DEST") == 0) {
            msg = dest_cmd(d);
            continue;
        }
        if (r == 0 && (strcmp(word, "PREFIX") == 0 || strcmp(word, "PRE") == 0)) {
            msg = prefix_cmd(d);
            continue;
        }
        if (r == 0) {
            int st = st_parse(d, word, &msg), da;

            if (st == 1) {
                d->ds_shown = job != NULL;
                return P_ST;
            }
            if (st == 2)
                continue;
            if ((da = da_parse(d, word, &msg)) == 1)
                return P_DA;
            if (da == 2)
                continue;
            if ((da = pan_parse(d, word, &msg)) == 1)
                return P_PAN;
            if (da == 2)
                continue;
            if (strcmp(word, "LOG") == 0 && arg[0] == '\0' && !auth_oper(0)) {
                memset(d->cmd, ' ', CMDLEN);
                msg = "COMMAND NOT AUTHORIZED";
                continue;
            }
            if (strcmp(word, "LOG") == 0 && arg[0] == '\0') {
                if (job != NULL)
                    return P_LOG;
                memset(d->cmd, ' ', CMDLEN);
                continue;
            }
            if (strcmp(word, "ST") == 0) {
                memset(d->cmd, ' ', CMDLEN);
                msg = "NOT AVAILABLE YET";
            } else {
                msg = " INVALID COMMAND";
            }
            continue;
        }
        memset(d->cmd, ' ', CMDLEN);
    }
}

/* The Job Data Set panel */
static int
jds_panel(DLG *d, const ISFROW *job)
{
    char text[60];
    char word[9], arg[9], verb[9];
    const char *msg = NULL;
    ISFJDS j;
    int rc, sc, r, top = 0, shift = 0, result = P_BACK;

    if (!jds_open(&j, job, d->input))
        return P_BACK + 100;
    snprintf(text, sizeof(text), "SDSF JOB DATA SET DISPLAY - %s %-8s (%c%-7d)",
             job->type, job->name, job->type[0], job->number);
    memset(d->cmd, ' ', CMDLEN);
    cursor_to(d, "ISFCMD");
    for (;;) {
        d->rowtext = rt_jds;
        d->curjds = &j;
        d->top = top;
        d->njobs = j.ndd;
        d->shown = d->rows - 1;
        d->tail = 0;
        list_title(d, text, msg);
        msg = NULL;
        memset(d->buf, ' ', (size_t)(d->width * d->rows));
        jds_heading(d->buf, d->width, shift);
        for (r = 1; r < d->rows && top + r - 1 < j.ndd; r++)
            jds_row(&j, top + r - 1, d->buf + r * d->width, d->width, shift);
        d->help = "ISFHJD";
        rc = list_display(d);
        if (rc != 0 && rc != 8) {
            result = P_ERROR;
            break;
        }
        system_var(d, "ZVERB", verb, sizeof(verb));
        sc = scroll_check(d);
        if (sc == SCROLL_BAD) {
            if (rc == 8)
                break;
            cursor_to(d, "ISFS");
            msg = "INVALID SCROLL AMOUNT";
            continue;
        }
        if (rc == 8)
            break;
        {
            int which[MAXROWS];
            char action[MAXROWS][NPMAX];
            int n = np_typed(d, which, action, 2), i;

            for (i = 0; i < n && result == P_BACK; i++) {
                ISFOUT o;

                if (strcmp(action[i], "S ") != 0) {
                    msg = "ACTION NOT AVAILABLE YET";
                    continue;
                }
                memset(&o, 0, sizeof(o));
                if (out_load(&o, &j, j.dd[top + which[i]]->dsid) != 0) {
                    msg = "OUTPUT NOT READABLE";
                } else {
                    result = out_panel(d, job, &o, NULL);
                }
                out_free(&o);
            }
            if (result != P_BACK)
                break;
            if (n > 0) {
                memset(d->cmd, ' ', CMDLEN);
                cursor_to(d, "ISFCMD");
                continue;
            }
        }
        d->top = top;
        d->njobs = j.ndd;
        d->shown = d->rows - 1;
        d->tail = 0;
        if (memcmp(verb, "DOWN", 4) == 0 || memcmp(verb, "UP", 2) == 0) {
            msg = scroll_key(d, verb, sc);
            top = d->top;
            cursor_to(d, "ISFCMD");
            continue;
        }
        if (memcmp(verb, "RIGHT", 5) == 0 || memcmp(verb, "LEFT", 4) == 0) {
            /* The columns right of DDNAME; the last one stops at the edge.
            ** On IBM's SDSF V1R2 a page of them moves by one less than it shows.
            */
            int w = d->width - 12;
            int most = JDS_VIRTUAL - d->width;
            char amt[SCRLEN];
            int max, n;

            if (!key_amount(d, sc, amt, &max)) {
                msg = "INVALID SCROLL AMOUNT";
                cursor_to(d, "ISFCMD");
                continue;
            }
            n = max ? most
              : memcmp(amt, "HALF", SCRLEN) == 0 ? w / 2
              : memcmp(amt, "PAGE", SCRLEN) == 0 ? w - 1
              : memcmp(amt, "DATA", SCRLEN) == 0 ? w - 1
              : memcmp(amt, "CSR ", SCRLEN) == 0 ? w - 1
              : atoi(amt);

            shift += verb[0] == 'R' ? n : -n;
            if (shift > most)
                shift = most;
            if (shift < 0)
                shift = 0;
            cursor_to(d, "ISFCMD");
            continue;
        }
        cursor_to(d, "ISFCMD");
        if (slash_cmd(d, &msg))
            continue;
        cmd_word(d, 0, word, sizeof(word));
        cmd_word(d, 1, arg, sizeof(arg));
        if (strcmp(word, "END") == 0)
            break;
        if (word[0] == '\0')
            continue;
        r = scroll_command(d, word, arg, &msg);
        top = d->top;
        if (r == 2)
            continue;
        if (r == 0 && strcmp(word, "ACTION") == 0) {
            msg = action_cmd(d);
            continue;
        }
        if (r == 0 && setting_cmd(d, word, &msg))
            continue;
        if (r == 0 && strcmp(word, "DEST") == 0) {
            msg = dest_cmd(d);
            continue;
        }
        if (r == 0 && (strcmp(word, "PREFIX") == 0 || strcmp(word, "PRE") == 0)) {
            msg = prefix_cmd(d);
            continue;
        }
        if (r == 0) {
            int st = st_parse(d, word, &msg), da;

            if (st == 1) {
                result = P_ST;
                break;
            }
            if (st == 2)
                continue;
            if ((da = da_parse(d, word, &msg)) == 1) {
                result = P_DA;
                break;
            }
            if (da == 2)
                continue;
            if ((da = pan_parse(d, word, &msg)) == 1) {
                result = P_PAN;
                break;
            }
            if (da == 2)
                continue;
            if (strcmp(word, "LOG") == 0 && arg[0] == '\0') {
                if (!auth_oper(0)) {
                    memset(d->cmd, ' ', CMDLEN);
                    msg = "COMMAND NOT AUTHORIZED";
                    continue;
                }
                result = P_LOG;
                break;
            }
            if (strcmp(word, "ST") == 0) {
                memset(d->cmd, ' ', CMDLEN);
                msg = "NOT AVAILABLE YET";
            } else {
                msg = " INVALID COMMAND";
            }
            continue;
        }
        memset(d->cmd, ' ', CMDLEN);
    }
    jds_close(&j);
    return result;
}

/* S on a job: all its data sets one after the other */
static int
job_output(DLG *d, const ISFROW *job)
{
    ISFJDS j;
    ISFOUT o;
    int rc, result;

    if (!jds_open(&j, job, d->input))
        return P_BACK + 100;
    memset(&o, 0, sizeof(o));
    rc = out_load(&o, &j, 0);
    jds_close(&j);
    result = rc != 0 && o.n == 0 ? P_BACK + 100 : out_panel(d, job, &o, NULL);
    out_free(&o);
    return result;
}

static void
st_load(DLG *d)
{
    st_free(d->jobs);
    d->jobs = NULL;
    d->njobs = st_read(&d->jobs);
    /* the classes and the name of ST, and PREFIX */
    if (d->njobs > 0 && (d->stclass[0] || d->prefix[0] || d->stname[0] || d->ndest)) {
        int i, k = 0;

        /* as in IBM's SDSF V1R2: PREFIX and the name of ST both apply,
        ** and classes take no job from the print queue
        */
        for (i = 0; i < d->njobs; i++) {
            const ISFROW *j = &d->jobs[i];

            if (d->stclass[0] && (j->jclass == ' '
                                  || strcmp(j->queue, "PRINT") == 0
                                  || strchr(d->stclass, j->jclass) == NULL))
                continue;
            if (d->prefix[0] && !name_match(d->prefix, j->name, d->pany, d->pone))
                continue;
            if (d->stname[0] && !name_match(d->stname, j->name, d->pany, d->pone))
                continue;
            if (!dest_match(d, j))
                continue;
            d->jobs[k++] = *j;
        }
        d->njobs = k;
    }
    scroll_to(d, d->top);
}

/* The Status panel, until END */
static int
st_panel(DLG *d)
{
    char text[48];
    char word[9], arg[9], verb[9];
    const char *msg = NULL;
    int rc, sc, r, top = 0;

    st_load(d);
    if (d->ds_shown)
        msg = " DATA SET DISPLAYED";
    d->ds_shown = 0;
    if (d->njobs < 0) {
        msg = d->njobs == ST_NOSTORAGE ? "NOT ENOUGH STORAGE" : "JES2 NOT READABLE";
        d->njobs = 0;
    }
    memset(d->cmd, ' ', CMDLEN);
    cursor_to(d, "ISFCMD");
    for (;;) {
        d->rowtext = rt_st;
        int count = d->njobs;

        d->top = top;
        d->shown = d->rows - 1;
        d->tail = 0;
        if (d->stclass[0])
            snprintf(text, sizeof(text), "SDSF STATUS DISPLAY CLASS %s",
                     d->stclass);
        else
            snprintf(text, sizeof(text), "SDSF STATUS DISPLAY ALL CLASSES");
        list_title(d, text, msg);
        msg = NULL;
        st_fill(d);
        d->help = "ISFHST";
        rc = list_display(d);
        if (rc != 0 && rc != 8)
            return rc;
        system_var(d, "ZVERB", verb, sizeof(verb));
        sc = scroll_check(d);
        if (sc == SCROLL_BAD) {
            if (rc == 8)
                return 0;
            cursor_to(d, "ISFS");
            msg = "INVALID SCROLL AMOUNT";
            continue;
        }
        if (rc == 8)        /* the End key: to the menu */
            return 0;
        {
            /* PRTY and DEST overtyped: a command each; the rows stay */
            const char *ov = ov_jobs(d, ov_st, d->jobs, d->njobs);

            if (ov != NULL) {
                msg = ov;
                if (d->nov == 0)
                    cursor_to(d, "ISFCMD");
                continue;
            }
        }
        {
            int which[MAXROWS];
            char action[MAXROWS][NPMAX];
            int n = np_typed(d, which, action, 2), i, fresh = 0;

            for (i = 0; i < n; i++) {
                const ISFROW *job = &d->jobs[top + which[i]];
                int p;

                if (strcmp(action[i], "P ") == 0 && !auth_job(job, 1)) {
                    msg = "NOT AUTHORIZED FOR JOB";
                    continue;
                }
                if (strcmp(action[i], "P ") == 0) {
                    const char *why = st_purge(job);

                    if (why != NULL)
                        msg = why;
                    fresh = 2;
                    continue;
                }
                if (strcmp(action[i], "? ") == 0) {
                    p = jds_panel(d, job);
                } else if (strcmp(action[i], "S ") == 0) {
                    p = job_output(d, job);
                } else {
                    /* the others go to JES2 as commands; O is not
                    ** on DA, P is the purge above
                    */
                    char cmd[24];

                    if (job_command(job->type, job->number, action[i], cmd, sizeof(cmd)))
                        /* D and L only show; the others change the job */
                        msg = !auth_job(job, action[i][0] != 'D' && action[i][0] != 'L')
                            ? "NOT AUTHORIZED FOR JOB" : action_issue(cmd);
                    else {
                        np_keep(d, which[i] + 1, action[i]);
                        msg = "INVALID COMMAND";
                    }
                    continue;
                }
                d->njobs = count;
                if (p == P_ERROR)
                    return 8;
                if (p == P_LOG || p == P_DA || p == P_PAN)
                    return p;
                if (p == P_ST) {
                    /* ST from the output, as in IBM's SDSF V1R2 */
                    if (d->ds_shown)
                        msg = " DATA SET DISPLAYED";
                    d->ds_shown = 0;
                    fresh = 1;
                    break;
                }
                if (p != P_BACK)
                    msg = "JOB NOT FOUND";
            }
            d->top = top;
            d->shown = d->rows - 1;
            d->tail = 0;
            if (fresh) {
                if (fresh == 1)
                    top = 0;
                d->top = top;
                st_load(d);
                if (d->njobs < 0)
                    d->njobs = 0;
                top = d->top;
            }
            if (n > 0) {
                memset(d->cmd, ' ', CMDLEN);
                cursor_to(d, "ISFCMD");
                continue;
            }
        }
        if (memcmp(verb, "DOWN", 4) == 0 || memcmp(verb, "UP", 2) == 0) {
            msg = scroll_key(d, verb, sc);
            top = d->top;
            cursor_to(d, "ISFCMD");
            continue;
        }
        if (d->stalt && (memcmp(verb, "RIGHT", 5) == 0 || memcmp(verb, "LEFT", 4) == 0)) {
            /* only with ?: without it the line fits (IBM's SDSF V1R2) */
            if (verb[0] == 'R'
                && line_shift(ST_ALT_LEN, 12, 1, d->width, d->stpage + 1) >= 0)
                d->stpage++;
            else if (verb[0] == 'L' && d->stpage > 0)
                d->stpage--;
            memset(d->cmd, ' ', CMDLEN);
            cursor_to(d, "ISFCMD");
            continue;
        }
        cursor_to(d, "ISFCMD");
        if (slash_cmd(d, &msg))
            continue;
        cmd_word(d, 0, word, sizeof(word));
        cmd_word(d, 1, arg, sizeof(arg));
        if (strcmp(word, "END") == 0)
            return 0;
        if (strcmp(word, "?") == 0 && arg[0] == '\0') {
            /* ? : the further columns of the jobs, and back (IBM's SDSF V1R2) */
            d->stalt = !d->stalt;
            d->stpage = 0;
            memset(d->cmd, ' ', CMDLEN);
            continue;
        }
        if (word[0] == '\0') {
            st_load(d);
            if (d->njobs < 0) {
                msg = d->njobs == ST_NOSTORAGE ? "NOT ENOUGH STORAGE" : "JES2 NOT READABLE";
                d->njobs = 0;
            }
            top = d->top;
            continue;
        }
        r = scroll_command(d, word, arg, &msg);
        top = d->top;
        if (r == 2)
            continue;
        if (r == 0 && strcmp(word, "ACTION") == 0) {
            msg = action_cmd(d);
            continue;
        }
        if (r == 0 && setting_cmd(d, word, &msg))
            continue;
        if (r == 0 && strcmp(word, "DEST") == 0) {
            msg = dest_cmd(d);
            if (msg == NULL)
                st_load(d);   /* the list with the new limit */
            continue;
        }
        if (r == 0 && (strcmp(word, "PREFIX") == 0 || strcmp(word, "PRE") == 0)) {
            msg = prefix_cmd(d);
            if (msg == NULL && memcmp(d->cmd, "PREFIX", 6) != 0) {
                top = 0;
                d->top = 0;
                st_load(d);
            }
            continue;
        }
        if (r == 0) {
            int st = st_parse(d, word, &msg), da;

            if (st == 2)
                continue;
            if ((da = da_parse(d, word, &msg)) == 1)
                return P_DA;
            if (da == 2)
                continue;
            if ((da = pan_parse(d, word, &msg)) == 1)
                return P_PAN;
            if (da == 2)
                continue;
            if (st == 1) {
                top = 0;
                d->top = 0;
                st_load(d);
            } else if (strcmp(word, "LOG") == 0 && arg[0] == '\0') {
                if (auth_oper(0))
                    return P_LOG;
                memset(d->cmd, ' ', CMDLEN);
                msg = "COMMAND NOT AUTHORIZED";
            } else {
                msg = " INVALID COMMAND";
                continue;
            }
        }
        memset(d->cmd, ' ', CMDLEN);
    }
}

/* The SYSLOG panel: the master trace table, on the output panel */
static int
log_panel(DLG *d)
{
    ISFOUT o;
    int result;

    memset(&o, 0, sizeof(o));
    result = out_panel(d, NULL, &o, log_read(d, &o));
    out_free(&o);
    return result;
}

/* The address spaces of DA, those it shows */
/* The job of an address space among the jobs the user may see (st_read
** leaves out the others): 1 and the row in *out if it is there.
*/
static int
da_job(const ISFDA *x, const ISFROW *jobs, int n, ISFROW *out)
{
    const char *type = strcmp(x->type, "INIT") == 0 ? "JOB" : x->type;
    int i;

    if (x->number == 0)
        return 0;
    for (i = 0; i < n; i++)
        if (jobs[i].number == x->number && strcmp(jobs[i].type, type) == 0) {
            if (out != NULL)
                *out = jobs[i];
            return 1;
        }
    return 0;
}

static void
da_load(DLG *d, const char **msg)
{
    ISFDA *a = NULL;
    int n = da_read(&a), i, k = 0;
    unsigned now[2];
    double secs = 0;

    free(d->das);
    d->das = NULL;
    d->njobs = 0;
    if (n < 0) {
        *msg = n == ST_NOSTORAGE ? "NOT ENOUGH STORAGE" : "JES2 NOT READABLE";
        free(a);
        return;
    }
    /* The rates over the interval since the last display, as in IBM's SDSF V1R2:
    ** the first display shows 0.00. An address space counts only against
    ** itself (same ASID and name) at that display.
    */
    __getclk(now);
    if (d->daprev != NULL)
        secs = ((double)(now[0] - d->dalast[0]) * 1048576.0
                + ((double)now[1] - (double)d->dalast[1]) / 4096.0) / 1000000.0;
    d->dacpu = d->dasio = 0;
    for (i = 0; secs > 0.01 && i < n; i++) {
        int j;

        for (j = 0; j < d->ndaprev; j++) {
            const ISFDA *p = &d->daprev[j];
            double dc, de;

            if (p->asid != a[i].asid || strcmp(p->name, a[i].name) != 0)
                continue;
            dc = a[i].cpu > p->cpu ? a[i].cpu - p->cpu : 0;
            de = a[i].excp > p->excp ? (double)(a[i].excp - p->excp) : 0;
            a[i].cpupct = dc / secs * 100.0;
            a[i].sio = de / secs;
            d->dacpu += dc / secs * 100.0;
            d->dasio += de / secs;
            break;
        }
    }
    free(d->daprev);
    d->daprev = malloc((size_t)(n > 0 ? n : 1) * sizeof(*a));
    d->ndaprev = 0;
    if (d->daprev != NULL) {
        memcpy(d->daprev, a, (size_t)n * sizeof(*a));
        d->ndaprev = n;
    }
    d->dalast[0] = now[0];
    d->dalast[1] = now[1];
    {
        /* who may see what: an address space with a job if the job may be
        ** seen, the others (MASTER, JES2, an idle initiator) with SDSF.OPER
        */
        ISFROW *jobs = NULL;
        int nj = st_read(&jobs), oper = auth_oper(0);

        for (i = 0; i < n; i++) {
            const ISFDA *x = &a[i];
            int t = strcmp(x->type, "JOB") == 0 ? DT_JOB : strcmp(x->type, "TSU") == 0 ? DT_TSU
                  : strcmp(x->type, "STC") == 0 ? DT_STC : DT_INIT;
            int p = strcmp(x->pos, "OUT") == 0 ? DP_OUT : DP_IN;
            int seen = x->number == 0 ? oper : da_job(x, jobs, nj > 0 ? nj : 0, NULL);

            if ((d->datype & t) && (d->dapos & p) && seen)
                a[k++] = a[i];
        }
        st_free(jobs);
    }
    d->das = a;
    d->njobs = k;
    scroll_to(d, d->top);
}

/* The Display Active Users panel, until END. As on IBM's SDSF V1R2: the address
** spaces by ASID; without ALL no idle initiator.
*/
static int
da_panel(DLG *d)
{
    char text[64], sysid[5];
    char word[9], arg[9], verb[9];
    const char *msg = NULL;
    int rc, sc, r, shift = 0;

    st_sysid(sysid);
    d->top = 0;
    da_load(d, &msg);
    memset(d->cmd, ' ', CMDLEN);
    cursor_to(d, "ISFCMD");
    for (;;) {
        d->rowtext = rt_da;
        d->shown = d->rows - 1;
        d->tail = 0;
        /* the system's paging rate is still to come */
        snprintf(text, sizeof(text), "SDSF DA %-4s PAGING %6.2f SIO %7.2f CPU %6.2f%%",
                 sysid, 0.0, d->dasio, d->dacpu);
        list_title(d, text, msg);
        msg = NULL;
        memset(d->buf, ' ', (size_t)(d->width * d->rows));
        da_heading(d->buf, d->width, shift);
        for (r = 1; r < d->rows && d->top + r - 1 < d->njobs; r++)
            da_row(&d->das[d->top + r - 1], d->buf + r * d->width, d->width, shift);
        d->help = "ISFHDA";
        rc = list_display(d);
        if (rc != 0 && rc != 8)
            return rc;
        system_var(d, "ZVERB", verb, sizeof(verb));
        sc = scroll_check(d);
        if (sc == SCROLL_BAD) {
            if (rc == 8)
                return 0;
            cursor_to(d, "ISFS");
            msg = "INVALID SCROLL AMOUNT";
            continue;
        }
        if (rc == 8)        /* the End key: to the menu */
            return 0;
        {
            /* PGN overtyped: a RESET of the address space */
            OVF pgn[2] = { { 0, 3, 'G' }, { 0, 0, 0 } };
            const char *ov;

            pgn[0].col = da_pgn();
            ov = ov_area(d, pgn, DA_FIXED, shift, d->njobs, ov_build_da);
            if (ov != NULL) {
                msg = ov;
                if (d->nov == 0)
                    cursor_to(d, "ISFCMD");
                continue;
            }
        }
        {
            /* ? and S, as on ST, for an address space with a JES2 job; the
            ** actions that change a job wait for the authorization
            */
            int which[MAXROWS];
            char action[MAXROWS][NPMAX];
            int n = np_typed(d, which, action, 2), i;

            for (i = 0; i < n; i++) {
                const ISFDA *a = &d->das[d->top + which[i]];
                ISFROW job;
                int p;

                if (strcmp(action[i], "? ") != 0 && strcmp(action[i], "S ") != 0) {
                    char cmd[24];

                    if (strcmp(action[i], "O ") == 0     /* not on DA (SDSF's help) */
                        || !job_command(a->type, a->number, action[i], cmd, sizeof(cmd))) {
                        np_keep(d, which[i] + 1, action[i]);
                        msg = "INVALID COMMAND";
                    } else if (a->number == 0) {
                        msg = "JOB NOT FOUND";
                    } else {
                        ISFROW *jobs = NULL;
                        int nj = st_read(&jobs);
                        ISFROW job;

                        /* D and L only show; the others change the job */
                        if (!da_job(a, jobs, nj > 0 ? nj : 0, &job))
                            msg = "JOB NOT FOUND";
                        else if (!auth_job(&job, action[i][0] != 'D' && action[i][0] != 'L'))
                            msg = "NOT AUTHORIZED FOR JOB";
                        else
                            msg = action_issue(cmd);
                        st_free(jobs);
                    }
                    continue;
                }
                if (a->number == 0) {
                    msg = "JOB NOT FOUND";
                    continue;
                }
                memset(&job, 0, sizeof(job));
                snprintf(job.name, sizeof(job.name), "%-8s", a->name);
                snprintf(job.type, sizeof(job.type), "%s",
                         strcmp(a->type, "INIT") == 0 ? "JOB" : a->type);
                job.number = a->number;
                job.active = 1;
                job.jclass = a->jclass;
                p = action[i][0] == '?' ? jds_panel(d, &job) : job_output(d, &job);
                if (p == P_ERROR)
                    return 8;
                if (TO_LIST(p))
                    return p;
                if (p != P_BACK)
                    msg = "JOB NOT FOUND";
            }
            if (n > 0) {
                d->shown = d->rows - 1;
                d->tail = 0;
                da_load(d, &msg);
                memset(d->cmd, ' ', CMDLEN);
                cursor_to(d, "ISFCMD");
                continue;
            }
        }
        if (memcmp(verb, "DOWN", 4) == 0 || memcmp(verb, "UP", 2) == 0) {
            msg = scroll_key(d, verb, sc);
            cursor_to(d, "ISFCMD");
            continue;
        }
        if (memcmp(verb, "RIGHT", 5) == 0 || memcmp(verb, "LEFT", 4) == 0) {
            /* as in IBM's SDSF V1R2: one step to the right part and back; on a
            ** screen that holds the whole line nothing moves
            */
            shift = verb[0] == 'R' && d->width < da_vlen() ? da_vlen() - d->width : 0;
            memset(d->cmd, ' ', CMDLEN);
            cursor_to(d, "ISFCMD");
            continue;
        }
        cursor_to(d, "ISFCMD");
        if (slash_cmd(d, &msg))
            continue;
        cmd_word(d, 0, word, sizeof(word));
        cmd_word(d, 1, arg, sizeof(arg));
        if (strcmp(word, "END") == 0)
            return 0;
        if (word[0] == '\0') {
            da_load(d, &msg);
            continue;
        }
        r = scroll_command(d, word, arg, &msg);
        if (r == 2)
            continue;
        if (r == 0 && strcmp(word, "ACTION") == 0) {
            msg = action_cmd(d);
            continue;
        }
        if (r == 0 && setting_cmd(d, word, &msg))
            continue;
        if (r == 0 && strcmp(word, "DEST") == 0) {
            msg = dest_cmd(d);
            continue;
        }
        if (r == 0 && (strcmp(word, "PREFIX") == 0 || strcmp(word, "PRE") == 0)) {
            msg = prefix_cmd(d);
            continue;
        }
        if (r == 0 && strcmp(word, "?") == 0 && arg[0] == '\0') {
            /* ? : the columns in the other order, and back (IBM's SDSF V1R2) */
            d->daalt = !d->daalt;
            da_set_alt(d->daalt);
            shift = 0;
            memset(d->cmd, ' ', CMDLEN);
            continue;
        }
        if (r == 0) {
            int st = st_parse(d, word, &msg), da;

            if (st == 1)
                return P_ST;
            if (st == 2)
                continue;
            if ((da = da_parse(d, word, &msg)) == 2)
                continue;
            if (da == 0 && (da = pan_parse(d, word, &msg)) != 0) {
                if (da == 1)
                    return P_PAN;
                continue;
            }
            if (da == 1) {
                d->top = 0;
                da_load(d, &msg);
            } else if (strcmp(word, "LOG") == 0 && arg[0] == '\0') {
                if (auth_oper(0))
                    return P_LOG;
                memset(d->cmd, ' ', CMDLEN);
                msg = "COMMAND NOT AUTHORIZED";
            } else {
                msg = " INVALID COMMAND";
                continue;
            }
        }
        memset(d->cmd, ' ', CMDLEN);
    }
}

/* What I, O, H and PR keep of the rows read; see pan_parse */
static int
pan_keep(const ISFROW *r, void *arg)
{
    DLG *d = arg;
    int i;

    switch (d->pkind) {
    case PK_I:
        if (d->iclass[0] == '\0') {
            if (strcmp(r->type, "JOB") != 0)
                return 0;
        } else if (strcmp(r->type, "TSU") == 0) {
            if (strchr(d->iclass, '$') == NULL)
                return 0;
        } else if (strcmp(r->type, "STC") == 0) {
            if (strchr(d->iclass, '#') == NULL)
                return 0;
        } else if (r->jclass == ' ' || strchr(d->iclass, r->jclass) == NULL) {
            return 0;
        }
        if ((d->iheld == 1 && !r->hold) || (d->iheld == 2 && r->hold))
            return 0;
        break;
    case PK_H:
        if (d->hclass[0] && strchr(d->hclass, r->jclass) == NULL)
            return 0;
        /* without ALL, a name or PREFIX: the jobs whose name starts with
        ** the user id. PREFIX takes the place of that rule (as in
        ** IBM's SDSF V1R2: PREFIX ZS* then H lists the ZS jobs of others)
        */
        if (!d->hall && d->hname[0] == '\0' && d->prefix[0] == '\0'
            && strncmp(r->name, d->user, strlen(d->user)) != 0)
            return 0;
        if (d->hname[0] && !name_match(d->hname, r->name, d->pany, d->pone))
            return 0;
        break;
    case PK_O:
        if (d->oclass[0] && strchr(d->oclass, r->jclass) == NULL)
            return 0;
        if (d->oforms[0] && !name_match(d->oforms, r->forms, d->pany, d->pone))
            return 0;
        break;
    case PK_PR:
        if (d->nprsel == 0)
            return 1;
        for (i = 0; i < d->nprsel; i++) {
            const char *a = d->prsel[i], *dash = strchr(a, '-');

            if (strcmp(a, "LCL") == 0)
                return 1;
            if (a[0] >= '0' && a[0] <= '9') {
                int lo = atoi(a), hi = dash != NULL ? atoi(dash + 1) : lo;

                if (r->number >= lo && r->number <= hi)
                    return 1;
            }
            /* remote printers are not in the answer of $DU,PRTS */
        }
        return 0;
    default:
        return 1;
    }
    if (d->prefix[0] && !name_match(d->prefix, r->name, d->pany, d->pone))
        return 0;
    return dest_match(d, r);
}

static void
pan_load(DLG *d, const char **msg)
{
    int n;

    pan_free(&d->pan);
    n = pan_read(&d->pan, d->pkind, d->pkind == PK_I && d->ialt, pan_keep, d);
    d->njobs = n > 0 ? n : 0;
    if (n < 0)
        *msg = n == ST_NOSTORAGE ? "NOT ENOUGH STORAGE"
             : n == ST_NOCMD ? "COMMAND NOT AUTHORIZED"
             : n == ST_NOANSWER ? "NO ANSWER FROM JES2" : "JES2 NOT READABLE";
    scroll_to(d, d->top);
}

/* The title of I, O, H, PR and INIT */
static void
pan_title(DLG *d, char *text, size_t size)
{
    char cls[24], num[16], fm[16];

    switch (d->pkind) {
    case PK_I:
        if (d->iclass[0])
            snprintf(text, size, "SDSF INPUT QUEUE DISPLAY CLASS %s", d->iclass);
        else
            snprintf(text, size, "SDSF INPUT QUEUE DISPLAY ALL CLASSES");
        break;
    case PK_H:
        /* the lines of the rows, on the right up to column 48 */
        if (d->hclass[0])
            snprintf(cls, sizeof(cls), "CLASS %s", d->hclass);
        else
            snprintf(cls, sizeof(cls), "ALL CLASSES");
        snprintf(text, size, "SDSF HELD OUTPUT DISPLAY %-11s %11s LINES",
                 cls, line_no(num, sizeof(num), (int)d->pan.lines));
        break;
    case PK_O:
        if (d->oclass[0])
            snprintf(cls, sizeof(cls), "CLASS %s", d->oclass);
        else
            snprintf(cls, sizeof(cls), "ALL CLASSES");
        /* SDSF OUTPUT CLASS X       FORM STD  LINES 0, as in IBM's SDSF V1R2 */
        if (d->oforms[0])
            snprintf(fm, sizeof(fm), "FORM %-4s", d->oforms);
        else
            snprintf(fm, sizeof(fm), "ALL FORMS");
        snprintf(text, size, "SDSF OUTPUT %-11s   %s LINES %s", cls, fm,
                 line_no(num, sizeof(num), (int)d->pan.lines));
        break;
    case PK_PR:
        snprintf(text, size, "SDSF PRINTER DISPLAY");
        break;
    default:
        snprintf(text, size, "SDSF INITIATOR DISPLAY");
        break;
    }
}

/* I, O, H, PR and INIT, until END: a list as DA is one */
static int
pan_panel(DLG *d)
{
    char hdest[MAXROWS][40];    /* H: the $R of a row released with a new DEST */
    char text[80];
    char word[9], arg[9], verb[9];
    const char *msg = NULL;
    int rc, sc, r, page = 0;

    d->top = 0;
    pan_load(d, &msg);
    memset(d->cmd, ' ', CMDLEN);
    cursor_to(d, "ISFCMD");
    for (;;) {
        d->rowtext = rt_pan;
        int shift = pan_shift(&d->pan, d->width, page);

        if (shift < 0)
            shift = page = 0;
        d->shown = d->rows - 1;
        d->tail = 0;
        pan_title(d, text, sizeof(text));
        list_title(d, text, msg);
        msg = NULL;
        memset(d->buf, ' ', (size_t)(d->width * d->rows));
        pan_line(&d->pan, -1, d->buf, d->width, shift);
        for (r = 1; r < d->rows && d->top + r - 1 < d->njobs; r++)
            pan_line(&d->pan, d->top + r - 1, d->buf + r * d->width, d->width, shift);
        d->help = pan_help(d->pkind);
        rc = list_display(d);
        if (rc != 0 && rc != 8)
            return rc;
        system_var(d, "ZVERB", verb, sizeof(verb));
        sc = scroll_check(d);
        if (sc == SCROLL_BAD) {
            if (rc == 8)
                return 0;
            cursor_to(d, "ISFS");
            msg = "INVALID SCROLL AMOUNT";
            continue;
        }
        if (rc == 8)        /* the End key: to the menu */
            return 0;
        if (d->pkind == PK_I || d->pkind == PK_PR || d->pkind == PK_INIT) {
            /* the fields overtyped: a command each; the rows stay */
            const char *ov = d->pkind == PK_I ? ov_jobs(d, ov_i, d->pan.job, d->njobs)
                : ov_area(d, d->pkind == PK_PR ? ov_pr : ov_init, d->pan.fixedh + 1,
                          shift, d->njobs, ov_build_pan);

            if (ov != NULL) {
                msg = ov;
                if (d->nov == 0)
                    cursor_to(d, "ISFCMD");
                continue;
            }
        }
        memset(hdest, 0, sizeof(hdest));
        if ((d->pkind == PK_O || d->pkind == PK_H) && shift == 0) {
            /* DEST, on the first page only: further right it is not there */
            const char *ov = d->pkind == PK_O ? ov_jobs(d, ov_o, d->pan.job, d->njobs)
                                              : ov_held(d, hdest);

            if (ov != NULL) {
                msg = ov;
                if (d->nov == 0)
                    cursor_to(d, "ISFCMD");
                continue;
            }
        }
        {
            /* ? and S for a row with a job; the actions that change one
            ** wait for the authorization
            */
            int which[MAXROWS];
            char action[MAXROWS][NPMAX];
            int n = np_typed(d, which, action, d->pkind == PK_PR ? 4 : 2), i;

            for (i = 0; i < n; i++) {
                ISFROW job;
                int p;

                if (d->top + which[i] >= d->njobs)
                    continue;
                job = d->pan.job[d->top + which[i]];
                if (d->pkind == PK_PR || d->pkind == PK_INIT) {
                    char cmd[24];
                    int ok = d->pkind == PK_PR
                        ? pr_command(&d->pan, d->top + which[i], action[i], cmd, sizeof(cmd))
                        : init_command(&d->pan, d->top + which[i], action[i], cmd, sizeof(cmd));

                    /* D only shows; the rest changes the device */
                    if (ok && !auth_oper(action[i][0] != 'D'))
                        msg = d->pkind == PK_PR ? "NOT AUTHORIZED FOR PRT"
                                                : "NOT AUTHORIZED FOR INIT";
                    else if (ok) {
                        msg = action_issue(cmd);
                    } else {
                        np_keep(d, which[i] + 1, action[i]);
                        msg = "INVALID COMMAND";
                    }
                    continue;
                }
                if (d->pkind == PK_H && strcmp(action[i], "O ") == 0) {
                    /* O on H: the held output released ($O), with the new
                    ** DEST first if one was typed (IBM's SDSF V1R2)
                    */
                    char cmd[24];

                    if (job.number == 0)
                        msg = "JOB NOT FOUND";
                    else if (!auth_job(&job, 1))
                        msg = "NOT AUTHORIZED FOR JOB";
                    else {
                        if (hdest[which[i]][0] != '\0')
                            msg = action_issue(hdest[which[i]]);
                        if (job_command(job.type, job.number, "O ", cmd, sizeof(cmd)))
                            msg = action_issue(cmd);
                    }
                    continue;
                }
                if (strcmp(action[i], "? ") != 0 && strcmp(action[i], "S ") != 0) {
                    msg = "ACTION NOT AVAILABLE YET";
                    continue;
                }
                if (job.number == 0) {
                    msg = "JOB NOT FOUND";
                    continue;
                }
                p = action[i][0] == '?' ? jds_panel(d, &job) : job_output(d, &job);
                if (p == P_ERROR)
                    return 8;
                if (TO_LIST(p))
                    return p;
                if (p != P_BACK)
                    msg = "JOB NOT FOUND";
            }
            if (n > 0) {
                /* the rows stay as they were after a command (IBM's SDSF V1R2) */
                if (d->pkind != PK_PR && d->pkind != PK_INIT)
                    pan_load(d, &msg);
                memset(d->cmd, ' ', CMDLEN);
                cursor_to(d, "ISFCMD");
                continue;
            }
        }
        if (memcmp(verb, "DOWN", 4) == 0 || memcmp(verb, "UP", 2) == 0) {
            msg = scroll_key(d, verb, sc);
            cursor_to(d, "ISFCMD");
            continue;
        }
        if (memcmp(verb, "RIGHT", 5) == 0 || memcmp(verb, "LEFT", 4) == 0) {
            if (verb[0] == 'R' && pan_shift(&d->pan, d->width, page + 1) >= 0)
                page++;
            else if (verb[0] == 'L' && page > 0)
                page--;
            memset(d->cmd, ' ', CMDLEN);
            cursor_to(d, "ISFCMD");
            continue;
        }
        cursor_to(d, "ISFCMD");
        if (slash_cmd(d, &msg))
            continue;
        cmd_word(d, 0, word, sizeof(word));
        cmd_word(d, 1, arg, sizeof(arg));
        if (strcmp(word, "END") == 0)
            return 0;
        if (word[0] == '\0') {
            pan_load(d, &msg);
            continue;
        }
        r = scroll_command(d, word, arg, &msg);
        if (r == 2)
            continue;
        if (r == 0 && strcmp(word, "?") == 0 && arg[0] == '\0'
            && (d->pkind == PK_I || d->pkind == PK_H)) {
            /* ? : on I the further columns, and back; on H IBM's SDSF V1R2 shows
            ** the same columns either way
            */
            if (d->pkind == PK_I) {
                d->ialt = !d->ialt;
                page = 0;
                pan_load(d, &msg);
            }
            memset(d->cmd, ' ', CMDLEN);
            continue;
        }
        if (r == 0 && strcmp(word, "ACTION") == 0) {
            msg = action_cmd(d);
            continue;
        }
        if (r == 0 && setting_cmd(d, word, &msg))
            continue;
        if (r == 0 && strcmp(word, "DEST") == 0) {
            msg = dest_cmd(d);
            if (msg == NULL)
                pan_load(d, &msg);   /* the list with the new limit */
            continue;
        }
        if (r == 0 && (strcmp(word, "PREFIX") == 0 || strcmp(word, "PRE") == 0)) {
            msg = prefix_cmd(d);
            if (msg == NULL)
                pan_load(d, &msg);
            continue;
        }
        if (r == 0) {
            int st = st_parse(d, word, &msg), da, pk;

            if (st == 1)
                return P_ST;
            if (st == 2)
                continue;
            if ((da = da_parse(d, word, &msg)) == 1)
                return P_DA;
            if (da == 2)
                continue;
            if ((pk = pan_parse(d, word, &msg)) == 2)
                continue;
            if (pk == 1) {
                d->top = 0;
                page = 0;
                pan_load(d, &msg);
            } else if (strcmp(word, "LOG") == 0 && arg[0] == '\0') {
                if (auth_oper(0))
                    return P_LOG;
                memset(d->cmd, ' ', CMDLEN);
                msg = "COMMAND NOT AUTHORIZED";
            } else {
                msg = " INVALID COMMAND";
                continue;
            }
        }
        memset(d->cmd, ' ', CMDLEN);
    }
}

/* ST and LOG lead to each other; END of either goes back to the menu */
static int
lists(DLG *d, int which)
{
    int r = which;

    while (TO_LIST(r))
        r = r == P_ST ? st_panel(d) : r == P_LOG ? log_panel(d)
          : r == P_DA ? da_panel(d) : pan_panel(d);
    return r;
}

int
main(void)
{
    static const char menu[] = "SDSF PRIMARY OPTION MENU";
    DLG *d;
    char word[9], arg[9];
    const char *stmsg;
    int st, da, pk = 0;
    int rc;

    if ((d = calloc(1, sizeof(*d))) == NULL)
        return 8;
    d->isplink = __load(NULL, "ISPLINK", NULL, NULL);
    if (d->isplink == NULL
        || vdefine(d, "ISFCMD", d->cmd, CMDLEN) != 0
        || vdefine(d, "ISFS", d->scr, SCRLEN) != 0
        || vdefine(d, "ISFCSR", d->csr, (int)sizeof(d->csr)) != 0
        || vdefine(d, "ISFCSRP", d->csrpos, 8) != 0
        || vdefine(d, "ISFACT", d->actv, 4) != 0
        || vdefine(d, "ISFPFX", d->pfxv, 10) != 0
        || vdefine(d, "ISFDST", d->dstv, 36) != 0
        || vdefine(d, "ISFFND", d->fndv, 60) != 0
        || vdefine(d, "ISFLN1", d->line, LINELEN) != 0
        || vdefine(d, "ISFPFK", d->pfk, (int)sizeof(d->pfk)) != 0) {
        FILE *out = fopen("*PUTLINE", "w");

        fprintf(out ? out : stdout,
                "ISF001E ISFISP RUNS UNDER ISPF: SELECT PGM(ISFISP)\n");
        if (out)
            fclose(out);
        free(d);
        return 8;
    }

    screen_size(d);
    system_var(d, "ZUSER", d->user, sizeof(d->user));
    auth_init(d->user);
    {
        char *b = strchr(d->user, ' ');

        if (b != NULL)
            *b = '\0';
    }
    if ((d->area = malloc((size_t)(d->width * (d->rows + 1)))) == NULL
        || (d->shadow = malloc((size_t)(d->width * d->rows))) == NULL
        || vdefine(d, "ISFBUF", d->area, d->width * (d->rows + 1)) != 0) {
        free(d->area);
        free(d->shadow);
        free(d);
        return 8;
    }
    d->buf = d->area + d->width;
    memset(d->cmd, ' ', CMDLEN);
    memset(d->scr, ' ', SCRLEN);
    if (profile(d, "VGET", "ISFS") != 0 || !scroll_valid(d->scr))
        memcpy(d->scr, "PAGE", SCRLEN);
    memcpy(d->saved, d->scr, SCRLEN);
    /* ACTION as the user left it; OFF if the profile has none */
    memset(d->actv, ' ', 4);
    if (profile(d, "VGET", "ISFACT") == 0) {
        char hex[5];

        memcpy(hex, d->actv, 4);
        hex[4] = '\0';
        d->action = (unsigned short)strtoul(hex, NULL, 16);
    }
    /* the last FIND, as the user left it */
    memset(d->fndv, ' ', 60);
    if (profile(d, "VGET", "ISFFND") == 0
        && (d->fndv[0] == 'N' || d->fndv[0] == 'P')
        && isdigit((unsigned char)d->fndv[1]) && isdigit((unsigned char)d->fndv[2])) {
        int n = (d->fndv[1] - '0') * 10 + (d->fndv[2] - '0');

        if (n > 0 && n <= 57) {
            memcpy(d->find, d->fndv + 3, (size_t)n);
            d->flen = n;
            d->fback = d->fndv[0] == 'P';
        }
    }
    /* PREFIX as the user left it */
    d->findlim = 5000;      /* as in IBM's SDSF V1R2 */
    d->pany = '*';
    d->pone = '%';
    memset(d->pfxv, ' ', 10);
    if (profile(d, "VGET", "ISFPFX") == 0) {
        int i;

        for (i = 0; i < 8 && d->pfxv[i] != ' '; i++)
            d->prefix[i] = d->pfxv[i];
        d->prefix[i] = '\0';
        if (d->pfxv[8] != ' ' && d->pfxv[9] != ' ' && d->pfxv[8] != d->pfxv[9]) {
            d->pany = d->pfxv[8];
            d->pone = d->pfxv[9];
        }
    }
    memset(d->dstv, ' ', sizeof(d->dstv));
    if (profile(d, "VGET", "ISFDST") == 0) {
        int i, k;

        for (i = 0; i < 4 && d->dstv[9 * i] != ' '; i++) {
            for (k = 0; k < 8 && d->dstv[9 * i + k] != ' '; k++)
                d->dest[i][k] = d->dstv[9 * i + k];
            d->dest[i][k] = '\0';
        }
        d->ndest = i;
    }
    cursor_to(d, "ISFCMD");
    title(d, menu, NULL);
    for (;;) {
        retr_before(d);
        d->help = "ISFHMN";
        rc = display(d, "ISFMENU");
        if (rc != 0 && rc != 8)
            break;
        if (rc == 0) {
            const char *hm;

            if (help_cmd(d, &hm)) {
                cursor_to(d, "ISFCMD");
                title(d, menu, hm);
                continue;
            }
        }
        if (rc == 0 && retr_after(d)) {
            d->cmdpos = 0;
            continue;
        }
        cursor_to(d, "ISFCMD");
        if (scroll_check(d) == SCROLL_BAD) {
            if (rc == 8)    /* leaving: the profile keeps the last good one */
                break;
            cursor_to(d, "ISFS");
            title(d, menu, "INVALID SCROLL AMOUNT");
            continue;
        }
        if (rc == 8)        /* the End key */
            break;
        {
            const char *m;

            if (slash_cmd(d, &m)) {
                d->cmdpos = 0;  /* the menu panel sets no position */
                title(d, menu, m);
                continue;
            }
        }
        cmd_word(d, 0, word, sizeof(word));
        cmd_word(d, 1, arg, sizeof(arg));
        pk = 0;
        if (strcmp(word, "END") == 0)
            break;
        if (word[0] == '\0') {
            title(d, menu, NULL);
        } else if (strcmp(word, "ACTION") == 0) {
            const char *m = action_cmd(d);

            d->cmdpos = 0;      /* the menu panel sets no cursor position */
            title(d, menu, m);
        } else if (strcmp(word, "PREFIX") == 0 || strcmp(word, "PRE") == 0) {
            title(d, menu, prefix_cmd(d));
        } else if (strcmp(word, "DEST") == 0) {
            title(d, menu, dest_cmd(d));
        } else if (setting_cmd(d, word, &stmsg)) {
            d->cmdpos = 0;
            d->who = 0;
            title(d, menu, stmsg);
        } else if ((st = st_parse(d, word, &stmsg)) == 2) {
            title(d, menu, stmsg);
        } else if ((da = da_parse(d, word, &stmsg)) != 0
                   || (pk = pan_parse(d, word, &stmsg)) != 0) {
            if (da == 2 || pk == 2) {
                title(d, menu, stmsg);
            } else {
                rc = lists(d, da == 1 ? P_DA : P_PAN);
                if (rc != 0)
                    break;
                memset(d->cmd, ' ', CMDLEN);
                cursor_to(d, "ISFCMD");
                title(d, menu, NULL);
            }
        } else if (st != 1 && strcmp(word, "LOG") == 0 && arg[0] == '\0'
                   && !auth_oper(0)) {
            memset(d->cmd, ' ', CMDLEN);
            title(d, menu, "COMMAND NOT AUTHORIZED");
        } else if (st == 1 || (strcmp(word, "LOG") == 0 && arg[0] == '\0')) {
            rc = lists(d, st == 1 ? P_ST : P_LOG);
            if (rc != 0)
                break;
            memset(d->cmd, ' ', CMDLEN);
            cursor_to(d, "ISFCMD");
            title(d, menu, NULL);
        } else if (strcmp(word, "ST") == 0 || strcmp(word, "LOG") == 0) {
            memset(d->cmd, ' ', CMDLEN);
            title(d, menu, "NOT AVAILABLE YET");
        } else {
            /* the command stays on the line, for correcting it */
            title(d, menu, "INVALID COMMAND");
        }
    }
    st_free(d->jobs);
    pan_free(&d->pan);
    free(d->das);
    free(d->daprev);
    /* a print file still open goes to be printed */
    print_close(d);
    free(d->area);
    free(d->shadow);
    free(d);
    return rc > 8 ? rc : 0;
}
