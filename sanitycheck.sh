#!/bin/bash

#  Copyright 2009 Bjorn Fahller <bjorn@fahller.se>
#  All rights reserved
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.

#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
#  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#  SUCH DAMAGE.

AWK=$1
DIR=$2

R=67
RN=69
F=40
[ "$3" == "gmock" ] && {
  R=78
  RN=80
  F=47
}
tests=(
    "           asserts"       "run=25 failed=14"
    "-v         asserts"       "run=25 failed=14 verbose=1"
    "-c 8       asserts"       "run=25 failed=14"
    "-c 8 -v    asserts"       "run=25 failed=14 verbose=1"

    "-n         asserts"       "run=25 failed=14 nodeps=1"
    "-n -v      asserts"       "run=25 failed=14 nodeps=1 verbose=1"
    "-n -c 8    asserts"       "run=25 failed=14 nodens=1"
    "-n -c 8 -v asserts"       "run=25 failed=14 nodeps=1 verbose=1"

    "           asserts death" "run=41 failed=26"
    "-v         asserts death" "run=41 failed=26 verbose=1"
    "-c 8       asserts death" "run=41 failed=26"
    "-c 8 -v    asserts death" "run=41 failed=26 verbose=1"

    "-n         asserts death" "run=41 failed=26 nodeps=1"
    "-n -v      asserts death" "run=41 failed=26 nodeps=1 verbose=1"
    "-n -c 8    asserts death" "run=41 failed=26 nodeps=1"
    "-n -c 8 -v asserts death" "run=41 failed=26 nodeps=1 verbose=1"

    ""                         "run=$R failed=$F blocked=2"
    "-v"                       "run=$R failed=$F blocked=2 verbose=1 "
    "-c 8"                     "run=$R failed=$F blocked=2"
    "-c 8 -v"                  "run=$R failed=$F blocked=2 verbose=1"

    "-n"                       "run=$RN failed=$F blocked=0 nodeps=1"
    "-n -v"                    "run=$RN failed=$F blocked=0 nodeps=1 verbose=1"
    "-n -c 8"                  "run=$RN failed=$F blocked=0 nodeps=1"
    "-n -c 8 -v"               "run=$RN failed=$F blocked=0 nodeps=1 verbose=1"
    )
echo "sanity check takes about 30 seconds to complete"
n=0
while [ $n -lt ${#tests[*]} ]
do
    param="${tests[$n]}"
    expect="${tests[$(($n+1))]}"
    printf "./test/testprog -x %-34s: " "$param"
    filename=/tmp/crpcut_sanity$$_$(($n/2+1)).xml
    reportfile=/tmp/crpcut_sanity_report$$_$(($n/2+1))
    ./test/testprog -x $param > $filename
    rv=$?
    xmllint --noout --schema $DIR/crpcut.xsd $filename 2> /dev/null || {
        echo "$filename violates crpcut.xsd XML Schema"
        exit 1
    }
    r=()
    lineno=0
    $AWK -f $DIR/filter.awk -- registered=$RN rv=$rv $expect < $filename > $reportfile
    [ $? == 0 ] || {
        echo FAILED
        cat $reportfile
        rm $reportfile
        echo "The test report is in $filename"
        exit 1
    }
    echo "OK"
    rm $filename
    rm $reportfile
    n=$(($n+2))
done
