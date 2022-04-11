#!/bin/bash

NUMBEROFFUNCTION=$1

#TARGET=$2

for (( i=1; i<=$NUMBEROFFUNCTION; i++ ))
do
   wsk -i action update fibonacci-$i $HOME/examples/scaling/fibonacci.py --memory 128 --timeout 540000 --docker openwhisk/python3action &
   sleep 0.01
done

wait

for (( i=1; i<=$NUMBEROFFUNCTION; i++ ))
do
   wsk -i action invoke fibonacci-$i
   sleep 0.01
done

