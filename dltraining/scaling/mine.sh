for i in $(cat fact.log | grep invoked | awk '{print $(NF)}')
do
    wsk -i activation result $i | grep CANARY-RESULT | awk '{print $(NF)}' >> act.logs
done
