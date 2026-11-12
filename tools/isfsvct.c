/* isfsvct.c -- a test tool for SDSF's SVC (IGX00011, SVC 109 code 11):
** turns the authorization on and off and says what the SVC answered and
** what TESTAUTH says after each step. Its name begins with ISF, so the
** SVC takes it for SDSF when it is loaded as authorized; as XSFSVCT it
** must be refused (return code 12).
**
** Output: one line per step on SYSPRINT (or the terminal), e.g.
**   ISFSVCT ESR11=1 ON RC=0 TESTAUTH=0 OFF RC=0 TESTAUTH=4
*/
#include <stdio.h>

static int
testauth(void)
{
    int rc;

    __asm__("TESTAUTH FCTN=1\n\tST 15,%0" : "=m"(rc) : : "0", "1", "14", "15", "memory");
    return rc;
}

static int
esr11(void)
{
    unsigned cvt = *(unsigned *)0x10 & 0xFFFFFF;
    unsigned scvt = *(unsigned *)(cvt + 0xC8) & 0xFFFFFF;
    unsigned svct = *(unsigned *)(scvt + 0x84) & 0xFFFFFF;
    unsigned esr = *(unsigned *)(svct + 109 * 8) & 0xFFFFFF;

    return esr != 0 && (*(unsigned *)(esr + 11 * 8) & 0xFFFFFF)
                       != (*(unsigned *)esr & 0xFFFFFF);
}

static int
svc(int r0, int on)
{
    int rc;

    __asm__("L 0,%1\n\t"
            "L 1,%2\n\t"
            "LA 15,11\n\t"
            "SVC 109\n\t"
            "ST 15,%0"
            : "=m"(rc) : "m"(r0), "m"(on) : "0", "1", "14", "15", "memory");
    return rc;
}

int
main(void)
{
    int installed = esr11(), on, a1, off, a2, bad;

    if (!installed) {
        printf("ISFSVCT ESR11=0 TESTAUTH=%d (code 11 not installed)\n", testauth());
        return 8;
    }
    bad = svc(5, 1);            /* R0 not 0: 4 */
    on = svc(0, 1);
    a1 = testauth();
    off = svc(0, 0);
    a2 = testauth();
    printf("ISFSVCT ESR11=1 BADR0 RC=%d ON RC=%d TESTAUTH=%d OFF RC=%d TESTAUTH=%d\n",
           bad, on, a1, off, a2);
    return on;
}
