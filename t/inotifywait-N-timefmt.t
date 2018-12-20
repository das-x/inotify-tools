#!/bin/sh
# Test the various permutations of the "%N" time format place holder for
# correctness.  The only values tested are nanoseconds with hour, minute, 
# seconds, and/or the various timezone outputs but the full set of possible
# strftime values which it could be tested against is as follows:
#   aAbBcCdDeEFghIjklmMnpPrStuUVwxXyYzZ+%
#set -x

DIG_2=[[:digit:]]{2}

DIG_HRS=$DIG_2
DIG_MIN=$DIG_2
DIG_SEC=$DIG_2
DIG_NNO=[[:digit:]]{9}
DIG_HMS=$DIG_HRS:$DIG_MIN:$DIG_SEC
DIG_HMSN=$DIG_HRS:$DIG_MIN:$DIG_SEC\.$DIG_NNO
TMZ_OFF=[+-][[:digit:]]{4}
TMZ_NM=[[:alpha:]]{3,}

# The various hour, minute, second, timezone, and nanosecond formats to test.
# NOTE: A '_' is used in-place of a space.
TSTFMTS="%N|$DIG_NNO \
        %H_%N|${DIG_HRS}_${DIG_NNO} \
        %N_%H|${DIG_NNO}_${DIG_HRS} \
        %H:%N|$DIG_HRS:$DIG_NNO \
        %N:%H|$DIG_NNO:$DIG_HRS \
        %N_%N|${DIG_NNO}_${DIG_NNO} \
        %N%N|$DIG_NNO$DIG_NNO \
        %N%N%N|$DIG_NNO$DIG_NNO$DIG_NNO \
        %N%N%N%N|$DIG_NNO$DIG_NNO$DIG_NNO$DIG_NNO \
        %N_%H:%M:%S.%N|${DIG_NNO}_${DIG_HMSN}\
        %H%N:%M:%S|$DIG_HRS$DIG_NNO:$DIG_MIN:$DIG_SEC \
        %N%H:%M:%S|$DIG_NNO$DIG_HRS:$DIG_MIN:$DIG_SEC \
        %H:%N%M:%S|$DIG_HRS:$DIG_NNO$DIG_MIN:$DIG_SEC \
        %H:%M%N:%S|$DIG_HRS:$DIG_MIN$DIG_NNO:$DIG_SEC \
        %H:%M:%S%N|$DIG_HRS:$DIG_MIN:$DIG_SEC$DIG_NNO \
        %H:%M:%N%S|$DIG_HRS:$DIG_MIN:$DIG_NNO$DIG_SEC \
        %H:%M:%S.%N_%z|${DIG_HMSN}_$TMZ_OFF \
        %H:%M:%S.%N%z|${DIG_HMSN}$TMZ_OFF \
        %H:%M:%S_%z_%N|${DIG_HMS}_${TMZ_OFF}_$DIG_NNO \
        %H:%M:%S%z_%N|${DIG_HMS}${TMZ_OFF}_$DIG_NNO \
        %H:%M:%S%z%N|${DIG_HMS}${TMZ_OFF}$DIG_NNO \
        %H:%M:%S.%N_%Z|${DIG_HMSN}_$TMZ_NM \
        %H:%M:%S.%N%Z|${DIG_HMSN}$TMZ_NM \
        %H:%M:%S_%Z_%N|${DIG_HMS}_${TMZ_NM}_$DIG_NNO \
        %H:%M:%S%Z_%N|${DIG_HMS}${TMZ_NM}_$DIG_NNO \
        %H:%M:%S%Z%N|${DIG_HMS}${TMZ_NM}$DIG_NNO \
        %H:%M:%S.%N|$DIG_HMSN
        other_%H:%M:%S.%N_end|other_${DIG_HMSN}_end
        %N_other_%H:%M:%S.%N_end|${DIG_NNO}_other_${DIG_HMSN}_end
        %N_other_%H:%M:%S.%N_end_%N|${DIG_NNO}_other_${DIG_HMSN}_end_${DIG_NNO}"

[ -d test_dir ] && rm -rf test_dir
mkdir test_dir

runInotifywait () {
    TST_TMFMT=`echo $1 | tr _ ' '`
    EXP_OUTPUT=`echo $2 | tr _ ' '`

    echo -n "Testing time format "$TST_TMFMT" ... "

    RTN_CHK=`../src/inotifywait -t 2 -q --format "%T" --timefmt "$TST_TMFMT" test_dir`

    echo $RTN_CHK | grep -qE "^${EXP_OUTPUT}$" && echo "$RTN_CHK is good" || echo "$RTN_CHK failed '$EXP_OUTPUT'"
}

for TSTFMT in $TSTFMTS; do

    runInotifywait `echo $TSTFMT | tr '|' ' '` &

    touch test_dir/a.txt

    sleep 1

    rm test_dir/a.txt

done

sleep 1

rmdir test_dir
set -
