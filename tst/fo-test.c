/* ==========================================================================
    Licensed under BSD 2clause license See LICENSE file for more information
    Author: Michał Łyszczek <michal.lyszczek@bofc.pl>
   ==========================================================================
          _               __            __         ____ _  __
         (_)____   _____ / /__  __ ____/ /___     / __/(_)/ /___   _____
        / // __ \ / ___// // / / // __  // _ \   / /_ / // // _ \ / ___/
       / // / / // /__ / // /_/ // /_/ //  __/  / __// // //  __/(__  )
      /_//_/ /_/ \___//_/ \__,_/ \__,_/ \___/  /_/  /_//_/ \___//____/

   ========================================================================== */


#include "mtest.h"
#include "fo.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>


/* ==========================================================================
          __             __                     __   _
     ____/ /___   _____ / /____ _ _____ ____ _ / /_ (_)____   ____   _____
    / __  // _ \ / ___// // __ `// ___// __ `// __// // __ \ / __ \ / ___/
   / /_/ //  __// /__ / // /_/ // /   / /_/ // /_ / // /_/ // / / /(__  )
   \__,_/ \___/ \___//_/ \__,_//_/    \__,_/ \__//_/ \____//_/ /_//____/

   ========================================================================== */


mt_defs();
#define TEST_FILE    "/tmp/fo-test-file"
#define TEST_STR     "test-str"
#define TEST_STRLEN  8


/* ==========================================================================
                           __               __
                          / /_ ___   _____ / /_ _____
                         / __// _ \ / ___// __// ___/
                        / /_ /  __/(__  )/ /_ (__  )
                        \__/ \___//____/ \__//____/

   ========================================================================== */


/* ==========================================================================
   ========================================================================== */


static void fo_test_original_after_init(void)
{
    int   fd;
    char  buf[16] = {0};
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


    mt_assert((fd = open(TEST_FILE, O_CREAT | O_TRUNC | O_RDWR, 0666)) >= 0);
    mt_fail(write(fd, TEST_STR, TEST_STRLEN) == TEST_STRLEN);
    mt_fok(lseek(fd, 0, SEEK_SET));
    mt_fail(read(fd, buf, sizeof(buf)) == TEST_STRLEN);
    mt_fail(strcmp(buf, TEST_STR) == 0);
    mt_fok(close(fd));
}


/* ==========================================================================
   ========================================================================== */


static void fo_write_fail(void)
{
    int fd;
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    mt_assert((fd = open(TEST_FILE, O_CREAT | O_TRUNC | O_RDWR, 0666)) >= 0);
    fo_fail(fo_write, 1, -1, EINVAL);
    mt_ferr(write(fd, TEST_STR, TEST_STRLEN), EINVAL);
    mt_fok(close(fd));
}


/* ==========================================================================
   ========================================================================== */


static void fo_write_fail_only_second_time(void)
{
    int fd;
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    mt_assert((fd = open(TEST_FILE, O_CREAT | O_TRUNC | O_RDWR, 0666)) >= 0);
    fo_fail(fo_write, 2, -1, EINVAL);
    mt_fail(write(fd, TEST_STR, TEST_STRLEN) == TEST_STRLEN);
    mt_ferr(write(fd, TEST_STR, TEST_STRLEN), EINVAL);
    mt_fail(write(fd, TEST_STR, TEST_STRLEN) == TEST_STRLEN);
    mt_fok(close(fd));
}


/* ==========================================================================
                                              _
                           ____ ___   ____ _ (_)____
                          / __ `__ \ / __ `// // __ \
                         / / / / / // /_/ // // / / /
                        /_/ /_/ /_/ \__,_//_//_/ /_/

   ========================================================================== */


int main(void)
{
    fo_init();

    mt_run(fo_test_original_after_init);
    mt_run(fo_write_fail);
    mt_run(fo_write_fail_only_second_time);

    mt_return();
}
