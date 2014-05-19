#!/bin/bash

y=$@

st=0
c=0
out=''

for i in $y 0
        do
        text=''
        c=$((c + 1))
        if [ $i -eq 1 ]
                then
                if [ $st -eq 0 ]
                        then
                        st=1
                        start=$c
                fi
        else
                if [ $st -eq 1 ]
                        then
                        st=0
                        end=$((c - 1))
                        if [ "$start" = "$end" ]
                                then
                                text=$start
                                else
                                text="$start-$end"
                        fi
                fi

        fi
        if [ $text ]
                then
                if [ -z $out ]
                        then
                        out=$text
                else
                        out=$out",$text"
                fi
        fi
done

echo $out

