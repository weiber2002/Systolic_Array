// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

void  hsG_0__0 (struct dummyq_struct * I1360, EBLK  * I1355, U  I707);
void  hsG_0__0 (struct dummyq_struct * I1360, EBLK  * I1355, U  I707)
{
    U  I1621;
    U  I1622;
    U  I1623;
    struct futq * I1624;
    struct dummyq_struct * pQ = I1360;
    I1621 = ((U )vcs_clocks) + I707;
    I1623 = I1621 & ((1 << fHashTableSize) - 1);
    I1355->I752 = (EBLK  *)(-1);
    I1355->I753 = I1621;
    if (0 && rmaProfEvtProp) {
        vcs_simpSetEBlkEvtID(I1355);
    }
    if (I1621 < (U )vcs_clocks) {
        I1622 = ((U  *)&vcs_clocks)[1];
        sched_millenium(pQ, I1355, I1622 + 1, I1621);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I707 == 1)) {
        I1355->I755 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I752 = I1355;
        peblkFutQ1Tail = I1355;
    }
    else if ((I1624 = pQ->I1263[I1623].I775)) {
        I1355->I755 = (struct eblk *)I1624->I773;
        I1624->I773->I752 = (RP )I1355;
        I1624->I773 = (RmaEblk  *)I1355;
    }
    else {
        sched_hsopt(pQ, I1355, I1621);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
