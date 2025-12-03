#!/bin/sh -l

set -eu
month=`date "-d +1 month" +%B`
yyyy=`date +%Y`
if [[ $month == "January" ]]
then
   mese=gennaio
elif [[ $month == "February" ]]
then
   mese=febbraio
elif [[ $month == "March" ]]
then
   mese=marzo
elif [[ $month == "April" ]]
then
   mese=aprile
elif [[ $month == "May" ]]
then
   mese=maggio
elif [[ $month == "June" ]]
then
   mese=giugno
elif [[ $month == "July" ]]
then
   mese=luglio
elif [[ $month == "August" ]]
then
   mese=agosto
elif [[ $month == "September" ]]
then
   mese=settembre
elif [[ $month == "October" ]]
then
   mese=ottobre
elif [[ $month == "November" ]]
then
   mese=novembre
elif [[ $month == "December" ]]
then
   mese=dicembre
fi


body="Buongiorno \n
\n
\n
    
       Con la presente chiediamo l'attivazione della reservation di 165 nodi, h24, dal primo al 6 $mese 
\n
\n

\n
\n



Grazie della preziosa collaborazione \n
\n


CMCC-SPS Staff

"

echo -e $body|mailx -r "CMCC-SPS <scc-noreply@cmcc.it>" -s "CMCC-SPS reservation $mese $yyyy - richiesta di attivazione" -b a.bocchinfuso@cineca.it -b superc@cineca.it sp1@cmcc.it
#echo -e $body|mailx -r "CMCC-SPS <scc-noreply@cmcc.it>" -s "CMCC_2025 reservation $mese $yyyy - richiesta di attivazione" -b antonella.sanna@cmcc.it sp1@cmcc.it
