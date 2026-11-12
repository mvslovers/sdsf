/* isfwait.c - a batch job that stays in execution for a while, to see a
** running job on the Status panel. PARM is the seconds, 60 if none.
*/
#include <stdlib.h>
#include <unistd.h>

int
main(int argc, char **argv)
{
    sleep((unsigned)(argc > 1 ? atoi(argv[1]) : 60));
    return 0;
}
