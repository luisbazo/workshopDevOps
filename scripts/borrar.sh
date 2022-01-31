#!/bin/sh


#for i in (1..17)
for (( i=11 ;i<=11; i++ ))
do
   echo "user$i"
   pkill -u user$i
   userdel -r user$i 
   rm -rf /home/user$i
   oc delete project ns$i
   for e in dev qa staging production; do
     oc delete project project${i}-${e}
  done
done
