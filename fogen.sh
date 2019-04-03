#!/bin/sh
## ==========================================================================
#   Licensed under BSD 2clause license See LICENSE file for more information
#   Author: Michał Łyszczek <michal.lyszczek@bofc.pl>
## ==========================================================================

print_usage()
{
    echo "usage: ${0} (-df | -l) [-o]"
    echo ""
    echo "where:"
    echo "    -d<file>      database with function information"
    echo "    -f<file>      file with list of function to generate code for"
    echo "    -l<file>      csv function information to generate code for"
    echo "    -o<file>      name of output file (without extension)"
    #echo ""
    #echo "check fogen(1) for details and better description"
}

fdb=
flist=
fl=
outc=
outh=

while getopts ":d:f:l:o:hv" opt
do
    case "${opt}" in
        d)
            ###
            # database with all functions possible to override
            #

            fdb="${OPTARG}"
            ;;

        f)
            ###
            # list with functions to gen code for
            #

            flist="${OPTARG}"
            ;;

        l)
            ###
            # function list, csv file with functions to generate,
            # it's different from flist in that, that flist contains
            # only function names, and fl is fdb with only entries
            # to generate code for
            #
            # if this is not passed, fl is generated from fdb and flist
            #

            fl="${OPTARG}"
            ;;

        o)
            ###
            # generated output name without extendion
            #

            outc="${OPTARG}.c"
            outh="${OPTARG}.h"
            ;;

        h)
            print_usage
            exit 0
            ;;

        v)
            echo "fogen v0.1.0"
            echo "by Michał Łyszczek <michal.lyszczek@bofc.pl>"
            exit 0
            ;;

        *)
            echo "invalid argument"
            print_usage
            exit 1
            ;;
    esac
done

if [ -z "${fdb}" ] && [ -z "${flist}" ] && [ -z "${fl}" ]
then
    echo "no data to generate code from, use -d -f or -l"
    echo ""
    print_usage
    exit 1
fi

if [ -z "${outc}" ]
then
    outc="fo.c"
    outh="fo.h"
fi

if [ -n "${fdb}" ]
then
    if [ ! -f "${fdb}" ]
    then
        echo "function database ${fdb} does not exist"
        exit 1
    fi

    if [ ! -f "${flist}" ]
    then
        echo "function list ${flist} does not exist"
        exit 1
    fi
fi

echo "function database....: ${fdb}"
echo "function list........: ${flist}"
echo "out file.............: ${outc}"

###
# if user didn't passe fl then generate csv with function to
# generate
#

if [ -z "${fl}" ]
then
    fl="$(mktemp)"
    to_remove="${fl}"
    while read -r function
    do
        if ! grep "${function}" "${fdb}" >> "${fl}"
        then
            ###
            # function was not found in database, emit error so
            # user can add it
            #

            echo "f/function: ${function} is not present in db file: ${fdb}"
            rm "${fl}"
            exit 1
        fi
    done < "${flist}"
else
    ###
    # fl is passed, so we need to generate flist
    #

    flist="$(mktemp)"
    to_remove="${flist}"
    while read -r line
    do
        echo "${line}" | cut -f3 -d, >> "${flist}"
    done < "${fl}"
fi

cat > "${outc}" << EOF
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


#ifndef _GNU_SOURCE
#define _GNU_SOURCE 1
#endif

#include "$(basename "${outh}")"

EOF

include_list="$(mktemp)"
echo "errno.h" > "${include_list}"
echo "stdio.h" >> "${include_list}"
echo "stdlib.h" >> "${include_list}"
echo "dlfcn.h" >> "${include_list}"
while read -r line
do
    includes="$(echo "${line}" | cut -f1 -d,)"
    IFS=";"

    for include in ${includes}
    do
        echo "${include}" >> "${include_list}"
    done
done < "${fl}"

unique_include="$(mktemp)"
cat "${include_list}" | sort | uniq > "${unique_include}"
rm "${include_list}"

while read -r include
do
    echo "#include <${include}>" >> "${outc}"
done < "${unique_include}"
rm "${unique_include}"

cat >> "${outc}" << EOF


/* ==========================================================================
          __             __                     __   _
     ____/ /___   _____ / /____ _ _____ ____ _ / /_ (_)____   ____   _____
    / __  // _ \ / ___// // __ \`// ___// __ \`// __// // __ \ / __ \ / ___/
   / /_/ //  __// /__ / // /_/ // /   / /_/ // /_ / // /_/ // / / /(__  )
   \__,_/ \___/ \___//_/ \__,_//_/    \__,_/ \__//_/ \____//_/ /_//____/

   ========================================================================== */


/* struct holding information about single function override
 */

struct fo_info
{
    /* when set and reaches 0, fo will call spoofed function to
     * trigger error condition. Check description of fo_fail()
     * function for more details
     */

    int    countdown;

    /* value to return when spoofed function is called
     */

    int    ret;

    /* errno to set when spoofed function is called
     */

    int    errn;

    /* pointer to original function
     */

    void  *original;
};

/* array of all functions information
 */

static struct fo_info fo_info[fo_f_max];


/* ==========================================================================
                       __     __ _          ____
        ____   __  __ / /_   / /(_)_____   / __/__  __ ____   _____ _____
       / __ \ / / / // __ \ / // // ___/  / /_ / / / // __ \ / ___// ___/
      / /_/ // /_/ // /_/ // // // /__   / __// /_/ // / / // /__ (__  )
     / .___/ \__,_//_.___//_//_/ \___/  /_/   \__,_//_/ /_/ \___//____/
    /_/
   ========================================================================== */


/* ==========================================================================
    Initializes function override object. Should be called at least once
    before any call to overrided function or else it will behave undefined,
    and will probably trigger segfault (or much worse). It's best to call it
    as first function in you test code - just right after main() {.

    It can be called twice and more, in such case object's state will be
    reseted and any configured failing points won't work after this is
    called again (original function will be called, not overriden one).

    Function does not return anything, when error occurs, exit() is called,
    since it's pointless to continue execution when original function we
    are overriding does not exist.
   ========================================================================== */


void fo_init
(
    void
)
{
    #define FO_INIT(F) \\
        fo_info[fo_ ## F].countdown = -1; \\
        fo_info[fo_ ## F].ret = 0; \\
        fo_info[fo_ ## F].errn = 0; \\
        fo_info[fo_ ## F].original = dlsym(RTLD_NEXT, #F); \\
        if (fo_info[fo_ ## F].original == NULL) \\
        { \\
            fprintf(stderr, "f/dlsym(RTLD_NEXT, %s): %s\n", #F, dlerror()); \\
            exit(1); \\
        }

EOF

while read -r function
do
    echo "    FO_INIT(${function});" >> "${outc}"
done < "${flist}"

cat >> "${outc}" << EOF
}


/* ==========================================================================
    Configures point of failure for specified function.

    (doc assumes posix function write() has been overriden)

    params
        function
            Must be taken from 'enum fo_f' as this is used as array index.
            Those enum values are in format fo_function-name. So to install
            write() failure, you'd use fo_write as function argument.

        countdown
            Each time you call overriden function (like write()), your
            program will actually call write() defined in this file. If you
            just initialized fo, then countdown will be '-1' and our write()
            will call real posix write() function. You can use this function
            to trigger error on posix call function. To do so, you need to
            set countdown to value 1 or bigger. Each time our write() is
            called, countdown will get decremented and once it reaches 0,
            our write() will return value ret and set errno to value errn.

            So to make write() to fail on first call (after fo_fail() call),
            you need to set countdown to 1. When you set countdown to -
            let's say 3 - then first and second write() will call real posix
            write() but 3rd call to write() will return ret value with errno
            set to errn.

        ret
            this value will be returned when countdown reaches 0 and fo will
            trigger error condition.

        errn
            this value will be stored to errno when countdown reaches 0 and
            fo will trigger error condition.

    errno
        ENOENT
            function does not exist in the list of overriden functions

        EINVAL
            countdown is less than 0
   ========================================================================== */


int fo_fail
(
    int  function,    /* function to override */
    int  countdown,   /* after how many calls trigger error */
    int  ret,         /* value to return upon error */
    int  errn         /* errno to be set upon error */
)
{
    if (function >= fo_f_max)
    {
        errno = ENOENT;
        return -1;
    }

    if (countdown < 0)
    {
        errno = EINVAL;
        return -1;
    }

    fo_info[function].countdown = countdown;
    fo_info[function].ret = ret;
    fo_info[function].errn = errn;
    return 0;
}


/* ==========================================================================
                                              _      __
              ____  _   __ ___   _____ _____ (_)____/ /___   _____
             / __ \| | / // _ \ / ___// ___// // __  // _ \ / ___/
            / /_/ /| |/ //  __// /   / /   / // /_/ //  __/(__  )
            \____/ |___/ \___//_/   /_/   /_/ \__,_/ \___//____/

   ========================================================================== */
EOF

while read -r line
do
    rett="$(echo "${line}" | cut -f2  -d,)"
    func="$(echo "${line}" | cut -f3  -d,)"
    types="$(echo "${line}" | cut -f4- -d,)"
    max_type_len=0
    argc=0
    curr_argc=0

    ###
    # print function prototype
    #
    # print type and name
    #

    echo "" >> "${outc}"
    echo "" >> "${outc}"
    printf "${rett} ${func}\n(\n" >> "${outc}"

    ###
    # print arguments
    #

    IFS=","
    for atype in ${types}
    do
        argc=$((argc + 1))

        if [ ${#atype} -gt ${max_type_len} ]
        then
            max_type_len=${#atype}
        fi
    done

    for atype in ${types}
    do
        curr_argc=$((curr_argc + 1))

        printf "    %-*s  arg%d" ${max_type_len} "${atype}" "${curr_argc}" \
            >> "${outc}"

        if [ ${curr_argc} -ne ${argc} ]
        then
            ###
            # this is not last argument on the list, append
            # last ","
            #

            printf ",\n" >> "${outc}"
        fi
    done

    printf "\n)\n{\n" >> "${outc}"

    ###
    # print body of the function
    #
    cat >> "${outc}" << EOF
    if (fo_info[fo_${func}].countdown == -1 ||
        --(fo_info[fo_${func}].countdown) != 0)
    {
        /* fail countdown is negative or it didn't yet reach
         * value 0, in that case we call original function
         */

EOF
    printf "        ${rett} (*original)(" >> "${outc}"

    curr_argc=0
    for atype in ${types}
    do
        curr_argc=$((curr_argc + 1))
        printf "${atype}" >> "${outc}"

        if [ ${curr_argc} -ne ${argc} ]
        then
            printf ", " >> "${outc}"
        fi
    done

    printf ");\n" >> "${outc}"
    printf "        original = fo_info[fo_${func}].original;\n" >> "${outc}"
    printf "        return original(" >> "${outc}"

    curr_argc=0
    for atype in ${types}
    do
        curr_argc=$((curr_argc + 1))
        printf "arg%d" ${curr_argc} >> "${outc}"

        if [ ${curr_argc} -ne ${argc} ]
        then
            printf ", " >> "${outc}"
        fi
    done

    printf ");\n" >> "${outc}"

    cat >> "${outc}" << EOF
    }

    /* countdown is 0, return error and don't execute original
     * function
     */

    errno = fo_info[fo_${func}].errn;
    return fo_info[fo_${func}].ret;
}
EOF
done < "${fl}"

###
# generate header file
#

cat > "${outh}" << EOF
/* ==========================================================================
    Licensed under BSD 2clause license See LICENSE file for more information
    Author: Michał Łyszczek <michal.lyszczek@bofc.pl>
   ========================================================================== */

#ifndef BOFC_FO_H
#define BOFC_FO_H 1

enum fo_f
{
EOF
while read -r function
do
    echo "    fo_${function}," >> "${outh}"
done < "${flist}"

cat >> "${outh}" << EOF

    fo_f_max
};

void fo_init(void);
int fo_fail(int function, int countdown, int ret, int errn);

#endif
EOF

rm -f -- ${to_remove}
