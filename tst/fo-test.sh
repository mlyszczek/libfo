#!/bin/sh
## ==========================================================================
#   Licensed under BSD 2clause license See LICENSE file for more information
#   Author: Michał Łyszczek <michal.lyszczek@bofc.pl>
## ==========================================================================

. ./mtest.sh

## ==========================================================================
#                           __               __
#                          / /_ ___   _____ / /_ _____
#                         / __// _ \ / ___// __// ___/
#                        / /_ /  __/(__  )/ /_ (__  )
#                        \__/ \___//____/ \__//____/
#
## ==========================================================================


## ==========================================================================
## ==========================================================================


ok_no_env()
{
    o=$(LD_PRELOAD=./libfo.so ./memcmp)
    mt_fail "[ ${o} = sss ]"
}

## ==========================================================================
## ==========================================================================


ok_env()
{
    echo "fread, 0, 0, EINVAL" > fo-init
    o=$(LIBFO_INIT_FILE=fo-init LD_PRELOAD=./libfo.so ./memcmp)
    mt_fail "[ ${o} = sss ]"
}


## ==========================================================================
## ==========================================================================


fail_first()
{
    echo "memcmp, 1, 1, 0" > fo-init
    o=$(LIBFO_INIT_FILE=fo-init LD_PRELOAD=./libfo.so ./memcmp)
    mt_fail "[ ${o} = ess ]"
}


## ==========================================================================
## ==========================================================================


fail_second()
{
    echo "memcmp, 2, 1, 0" > fo-init
    o=$(LIBFO_INIT_FILE=fo-init LD_PRELOAD=./libfo.so ./memcmp)
    mt_fail "[ ${o} = ses ]"
}


## ==========================================================================
#                                 __                __
#                          _____ / /_ ____ _ _____ / /_
#                         / ___// __// __ `// ___// __/
#                        (__  )/ /_ / /_/ // /   / /_
#                       /____/ \__/ \__,_//_/    \__/
#
## ==========================================================================


mt_run ok_no_env
mt_run ok_env
mt_run fail_first
mt_run fail_second

rm fo-init

mt_return
