#!/bin/bash

NUMBEROFFUNCTION=$1

TARGET=$2

for (( i=1; i<=$NUMBEROFFUNCTION; i++ ))
do
   wsk -i action update factorial-$i $HOME/examples/scaling/factorial.py --memory 128 --timeout 540000 --docker openwhisk/python3action &
   sleep 0.01
done

wait

for (( i=1; i<=$NUMBEROFFUNCTION; i++ ))
do
   wsk -i action invoke factorial-$i
# --param target $TARGET
   sleep 0.01
done

