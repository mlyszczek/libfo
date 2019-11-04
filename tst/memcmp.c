/* ==========================================================================
    Licensed under BSD 2clause license See LICENSE file for more information
    Author: Michał Łyszczek <michal.lyszczek@bofc.pl>
   ========================================================================== */

#include <stdio.h>
#include <string.h>

int main(void)
{
    int i;

    for (i = 0; i != 3; ++i)
        if (memcmp("a", "a", 2) == 0)
            printf("s");
        else
            printf("e");

    return 0;
}
