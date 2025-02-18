#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -evxu

lista_spike_cases="sps4_199311_012 sps4_199311_029 sps4_199611_002 sps4_199611_017 sps4_199611_018 sps4_199611_024 sps4_199811_007 sps4_199811_009 sps4_199811_010 sps4_199911_027 sps4_200111_012 sps4_200211_002 sps4_200211_027 sps4_200511_025 sps4_200511_027 sps4_200611_024 sps4_200611_026 sps4_200811_009 sps4_201011_018 sps4_201211_008 sps4_201211_026 sps4_201211_028 sps4_201411_020 sps4_201411_029 sps4_201411_030 sps4_201511_026 sps4_201611_029 sps4_201711_023 sps4_201711_026 sps4_201711_027 sps4_201711_028 sps4_201811_014 sps4_201811_015 sps4_201811_016 sps4_201911_004 sps4_201911_010 sps4_202011_006 sps4_202111_003 sps4_202111_018 sps4_202111_024 sps4_202111_030 sps4_202211_017 sps4_202211_023 sps4_202211_028 sps4_202211_029 sps4_199511_004 sps4_199711_014 sps4_200311_014 sps4_200311_017 sps4_200711_005 sps4_200711_009 sps4_202111_028 sps4_199711_008 sps4_200011_005 sps4_200311_010 sps4_201111_015 sps4_201611_001 sps4_199911_023 sps4_199511_025"

cd $DIR_ARCHIVE
refdate=20241005

case4transfer=()
for caso in ${lista_spike_cases}
do
    if [[ -f $DIR_TEMP/$caso.copy4spike_started ]]
    then
        continue
    fi
    if [[ -f $DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE ]]
    then
       is_new=`find ${DIR_ARCHIVE}/$caso -type d -newermt $refdate |wc -w`
       if [[ ${is_new} -eq 0 ]] ; then
          #  tochange+=("${elem}")
          case4transfer+=("$caso")
       else
          continue
       fi
    else
         case4transfer+=("$caso") 
    fi

done
#echo ${ensemble[@]}
echo ${case4transfer[@]}


CHUNK_SIZE=9

index=0
while [[ $index -lt ${#case4transfer[@]} ]]; do
    lista_chunk="${case4transfer[@]:$index:$CHUNK_SIZE}"
    lista_input=""
    for cc  in ${lista_chunk[@]}  ; do
      lista_input+="$cc "
    done
    ${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -q s_download -j copy_SPS4DMO_from_Leonardo_spike -l ${DIR_LOG}/leonardo_transfer/ -d ${DIR_UTIL} -s copy_SPS4DMO_from_Leonardo_spike.sh -i "'${lista_input}'"
    index=$((index + CHUNK_SIZE))
done


