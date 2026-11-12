/* isfhelp.c - the help and tutorial panels of SDSF
**
** Wally ISPF's HELP shows the one panel named in .HELP and goes back on the
** next key: it follows none of ZSEL, ZCONT or ZUP (measured).
** So SDSF shows its help and tutorial panels itself, as ISPF's tutorial
** does on IBM's SDSF V1R2. The panels (ISFH*, ISFK*, ISFX*, ISFT* in ispplib/) set,
** in their )PROC:
**
**   &ISFHPFK = .PFKEY           the key that ended the display
**   &ZSEL    = TRANS(&ISFHCMD ...)  the panel of a topic number, ? if none
**   &ZCONT   = name             the panel Enter goes on to
**   &ZUP     = name             the panel the Up key goes to
**
** and show &ISFHMSG on their first line. The command field is ISFHCMD, not
** ZCMD: ISPF takes HELP typed into ZCMD for itself. A tutorial panel that
** shows an SDSF panel may have a field HN, two wide, in its NP column: what
** is typed there counts as typed on the command line.
**
** Enter goes on (ZCONT), a topic number goes there (ZSEL), the Up key goes
** up (ZUP), the Left key back to the panel before, T to the table of
** contents, I to the index, HELP to the panel on using help, and the End
** key (or END) back to the SDSF panel.
*/
#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include <mvs/link.h>

#include "isf.h"

#define HCMDLEN 60
#define DEPTH   32      /* the panels the Left key goes back through */

static void *ispl;
static char sel[8], cont[8], up[8], hcmd[HCMDLEN], pfk[4], hmsg[30], hn[2];

static int
vdefine(const char *name, char *buf, int len)
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
    return __call(ispl, plist);
}

static void
vdelete(void)
{
    char service[9] = "VDELETE ";
    char list[] = "(ZSEL ZCONT ZUP ISFHCMD ISFHPFK ISFHMSG HN)";
    unsigned plist[2];

    plist[0] = (unsigned)service;
    plist[1] = (unsigned)list | 0x80000000;
    __call(ispl, plist);
}

/* CONTROL ERRORS RETURN or CANCEL: with RETURN a panel not found comes
** back as DISPLAY RC 12; with CANCEL, ISPF's default, ISPF shows its
** service error panel and ends the dialog
*/
static void
errors(const char *how)
{
    char service[9] = "CONTROL ";
    char what[9] = "ERRORS  ";
    char mode[9];
    unsigned plist[3];

    snprintf(mode, sizeof(mode), "%-8s", how);
    plist[0] = (unsigned)service;
    plist[1] = (unsigned)what;
    plist[2] = (unsigned)mode | 0x80000000;
    __call(ispl, plist);
}

static int
show(const char *panel)
{
    char service[9] = "DISPLAY ";
    char name[9];
    unsigned plist[2];

    snprintf(name, sizeof(name), "%-8s", panel);
    plist[0] = (unsigned)service;
    plist[1] = (unsigned)name | 0x80000000;
    return __call(ispl, plist);
}

/* A variable of a buffer, without the blanks after it */
static void
take(const char *buf, int len, char *out, int size)
{
    int n = len < size - 1 ? len : size - 1;

    memcpy(out, buf, (size_t)n);
    while (n > 0 && (out[n - 1] == ' ' || out[n - 1] == '\0'))
        n--;
    out[n] = '\0';
}

/* What the key PFnn does, from the user's keys (ZPFnn) where VCOPY gives
** them; else the ISPF defaults. Not measured which of the two Wally ISPF
** answers: the defaults gave the same on the systems tested.
*/
static void
key_command(const char *key, char *cmd, int size)
{
    static const char *const dflt[12] = {
        "HELP", "SPLIT", "END", "RETURN", "RFIND", "RCHANGE",
        "UP", "DOWN", "SWAP", "LEFT", "RIGHT", "RETRIEVE"
    };
    char service[9] = "VCOPY   ";
    char name[9], value[9];
    char mode[9] = "MOVE    ";
    int len = 8, n;
    unsigned plist[5];

    cmd[0] = '\0';
    if (key[0] != 'P' || key[1] != 'F')
        return;
    n = (key[2] - '0') * 10 + (key[3] - '0');
    if (n < 1 || n > 24)
        return;
    snprintf(name, sizeof(name), "ZPF%02d   ", n);
    memset(value, 0, sizeof(value));
    plist[0] = (unsigned)service;
    plist[1] = (unsigned)name;
    plist[2] = (unsigned)&len;
    plist[3] = (unsigned)value;
    plist[4] = (unsigned)mode | 0x80000000;
    if (__call(ispl, plist) == 0 && value[0] != '\0' && value[0] != ' ')
        take(value, 8, cmd, size);
    else
        snprintf(cmd, (size_t)size, "%s", dflt[(n - 1) % 12]);
}

/* 1 if the key that ended a display of an SDSF panel ("PF01", from .PFKEY)
** carries the HELP command
*/
int
help_key(void *isplink, const char *key)
{
    char cmd[9];

    ispl = isplink;
    key_command(key, cmd, sizeof(cmd));
    return strcmp(cmd, "HELP") == 0;
}

#define S_GO    0       /* to the panel in next */
#define S_STAY  1       /* the panel again, with the message if any */
#define S_BACK  2       /* to the panel before */
#define S_LEAVE 3       /* out of the help */

/* What the word typed (or the key's command, "" for Enter) does on the
** panel just shown, with its ZSEL, ZCONT and ZUP
*/
static int
step(const char *word, char *next, int size)
{
    next[0] = '\0';
    /* what the panel makes of a typed word comes first: an index panel
    ** takes the letters T and I
    */
    if (word[0] != '\0') {
        take(sel, sizeof(sel), next, size);
        if (next[0] != '\0' && next[0] != '?')
            return S_GO;
        next[0] = '\0';
    }
    if (word[0] == '\0' || strcmp(word, "RIGHT") == 0 || strcmp(word, "DOWN") == 0) {
        take(cont, sizeof(cont), next, size);
        if (next[0] == '\0')
            take(up, sizeof(up), next, size);
        if (next[0] != '\0')
            return S_GO;
        memcpy(hmsg, "END OF TOPIC", 12);
        return S_STAY;
    }
    if (strcmp(word, "UP") == 0) {
        take(up, sizeof(up), next, size);
        return next[0] != '\0' ? S_GO : S_STAY;
    }
    if (strcmp(word, "LEFT") == 0 || strcmp(word, "BACK") == 0)
        return S_BACK;
    if (strcmp(word, "END") == 0 || strcmp(word, "RETURN") == 0)
        return S_LEAVE;
    if (strcmp(word, "T") == 0 || strcmp(word, "TOP") == 0)
        snprintf(next, (size_t)size, "%s", ISF_HELP_TOC);
    else if (strcmp(word, "I") == 0 || strcmp(word, "INDEX") == 0)
        snprintf(next, (size_t)size, "%s", ISF_HELP_INDEX);
    else if (strcmp(word, "HELP") == 0)
        snprintf(next, (size_t)size, "%s", ISF_HELP_HELP);
    else {
        /* SDSF's own commands are no good here (IBM's SDSF V1R2) */
        memcpy(hmsg, "INVALID OPTION", 14);
        return S_STAY;
    }
    return S_GO;
}

int
isf_help(void *isplink, const char *start)
{
    char back[DEPTH][9], cur[9], next[9], word[HCMDLEN + 1], key[9];
    int nback = 0, rc, i;

    ispl = isplink;
    if (vdefine("ZSEL", sel, sizeof(sel)) != 0
        || vdefine("ZCONT", cont, sizeof(cont)) != 0
        || vdefine("ZUP", up, sizeof(up)) != 0
        || vdefine("ISFHCMD", hcmd, sizeof(hcmd)) != 0
        || vdefine("ISFHPFK", pfk, sizeof(pfk)) != 0
        || vdefine("ISFHMSG", hmsg, sizeof(hmsg)) != 0
        || vdefine("HN", hn, sizeof(hn)) != 0) {
        vdelete();
        return 20;
    }
    snprintf(cur, sizeof(cur), "%s", start);
    memset(hmsg, ' ', sizeof(hmsg));
    memset(hcmd, ' ', sizeof(hcmd));
    for (;;) {
        /* a panel that sets none of them must not inherit the last one's */
        memset(sel, ' ', sizeof(sel));
        memset(cont, ' ', sizeof(cont));
        memset(up, ' ', sizeof(up));
        memset(pfk, ' ', sizeof(pfk));
        memset(hn, ' ', sizeof(hn));
        errors("RETURN");
        rc = show(cur);
        errors("CANCEL");
        memset(hmsg, ' ', sizeof(hmsg));
        if (rc == 8)            /* the End key, or END */
            break;
        if (rc != 0) {
            /* a panel not found: the one before stays, with a message;
            ** a display whose help is not written yet gets the contents
            */
            if (nback == 0 && strcmp(cur, ISF_HELP_TOC) != 0) {
                snprintf(cur, sizeof(cur), "%s", ISF_HELP_TOC);
                memcpy(hmsg, "NO HELP FOR THIS PANEL YET", 26);
                continue;
            }
            if (nback == 0)
                break;
            snprintf(cur, sizeof(cur), "%s", back[--nback]);
            memcpy(hmsg, "PANEL NOT FOUND", 15);
            continue;
        }
        take(hcmd, HCMDLEN, word, sizeof(word));
        if (word[0] == '\0')
            take(hn, sizeof(hn), word, sizeof(word));
        for (i = 0; word[i] != '\0'; i++)
            word[i] = (char)toupper((unsigned char)word[i]);
        memset(hcmd, ' ', sizeof(hcmd));
        take(pfk, sizeof(pfk), key, sizeof(key));
        if (word[0] == '\0' && strcmp(key, "PF00") != 0 && key[0] != '\0')
            key_command(key, word, sizeof(word));
        i = step(word, next, sizeof(next));
        if (i == S_LEAVE)
            break;
        if (i == S_BACK && nback > 0)
            snprintf(cur, sizeof(cur), "%s", back[--nback]);
        if (i != S_GO)
            continue;
        if (strcmp(next, cur) == 0)
            continue;
        if (nback == DEPTH) {
            memmove(back[0], back[1], sizeof(back[0]) * (DEPTH - 1));
            nback--;
        }
        snprintf(back[nback++], sizeof(back[0]), "%s", cur);
        snprintf(cur, sizeof(cur), "%s", next);
    }
    vdelete();
    return rc == 8 || rc == 0 ? 0 : rc;
}
