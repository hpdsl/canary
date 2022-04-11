#!/bin/bash

NUMBEROFFUNCTION=$1

for (( i=1; i<=$NUMBEROFFUNCTION; i++ ))
do
   wsk -i action update deep/learning-$i $HOME/examples/scaling/learning.py --docker hpdsl/dlserverless:latest --memory 12288 --timeout 540000 &
done

wait

for (( i=1; i<=$NUMBEROFFUNCTION; i++ ))
do
   wsk -i action invoke deep/learning-$i
done

