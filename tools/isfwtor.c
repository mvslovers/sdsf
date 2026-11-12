/* isfwtor.c - a batch job that asks the operator and waits for the reply,
** to see an outstanding WTOR on the SYSLOG panel. PARM is the text of the
** question; the job ends when it is answered.
*/
#include <stdio.h>
#include <string.h>

#include <mvs/wto.h>

int
main(int argc, char **argv)
{
    char reply[120], text[101];
    int i, at = 0;

    /* the runtime hands the PARM over in words */
    text[0] = '\0';
    for (i = 1; i < argc; i++)
        at += snprintf(text + at, sizeof(text) - (size_t)at, "%s%s",
                       i > 1 ? " " : "", argv[i]);
    memset(reply, 0, sizeof(reply));
    wtorf(reply, sizeof(reply) - 1, "ISFWTOR %s",
          argc > 1 ? text : "REPLY TO END THIS TEST JOB");
    printf("ISFWTOR REPLY '%s'\n", reply);
    return 0;
}
