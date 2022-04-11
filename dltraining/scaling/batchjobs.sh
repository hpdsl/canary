#!/bin/bash

for i in {1..50}
do
   wsk -i action update deep/learning-$i $HOME/examples/scaling/learning.py --docker hpdsl/dlserverless:latest --memory 9216 --timeout 540000 &
done

wait

for i in {1..50}
do
   wsk -i action invoke deep/learning-$i | tee logs.txt
done
