#!/bin/bash
date +"%s"

for i in {1..10}
do
   wsk -i action update divindex-$i divindex.py --memory 1024 --timeout 900000 --docker kevinassogba/spark:usdiv &
done


for i in {1..5}
do
   wsk -i action update deep/learning-$i $HOME/examples/scaling/learning.py --docker hpdsl/dlserverless:latest --memory 10240 --timeout 900000 &
done

wait

for i in {1..5}
do
   wsk -i action invoke deep/learning-$i | tee logs.txt
done


for i in {1..10}
do
   wsk -i action invoke divindex-$i | tee divlogs.txt
done

