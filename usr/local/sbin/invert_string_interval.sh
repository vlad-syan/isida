#!/bin/bash


if [ -z $1 ]
	then
	exit 0
fi

if [ -z $2 ]
	then
	exit 0
fi

source=`echo $1 | sed -e 's/,/ /g'`

for i in {1..32}
	do
	ports[$i]='0'
done

case $2 in
    10)	binX='0xFFC00000';;
    18)	binX='0xFFFFC000';;
    26)	binX='0xFFFFFFC0';;
    28)	binX='0xFFFFFFF0';;
    *)	exit 0;;
esac

function parse_interval {

interval=$1
result=''
start=`echo $interval | awk -F- '{print $1}'`
end=`echo $interval | awk -F- '{print $2}'`

if [ -z $end ]
	then
	end=$start
fi

result=''

for (( i = start; i <= end; i++ ))
	do
	result=$result"$i "
done

}

fin=''

for int in $source
	do
	parse_interval $int
	fin=$fin"$result"
done

for i in $fin
	do
ports[$i]='1'
done

bin='2#'`echo ${ports[@]} | sed -e 's/\ //g'` 
res=`echo "obase=2; ibase=10; $((bin ^ binX))" | bc`

x=`echo ${#res}`
y=$((32 - x))

d=''
for ((i = 1; i <= y; i++ ))
	do
	d=$d'0'
done

y=`echo $d$res | sed -e 's/0/0 /g' -e 's/1/1 /g'`

st=0
c=0
out=''

for i in $y
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

