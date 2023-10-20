#!/bin/sh -l
#d1=$(date -d "$1" +%j)
#d2=$(date -d "$2" +%j)
#echo $((10#$d1 - 10#$d2))    NON FUNZIONA NEL CAMBIO ANNO!!!!
d1=$(date -d "$1" +%s)
d2=$(date -d "$2" +%s)
#in case there is a non-DST to DST transition in the interval, one of the days will be only 23 hours long; you can compensate by adding ½ day to the sum ex 19930401 e 19930328 
echo $(( (d1 - d2 + 43200) / 86400 )) 
