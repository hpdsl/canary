# This code is adapted from
# https://www.geeksforgeeks.org/python-program-for-program-for-fibonacci-numbers-2/

import time

def main(args):

    initTime = time.time()
    max = int(args.get("max", 10000))
    number_a = 0
    number_b = 1
    numbers_array = []

    if max < 0:
        print("Invalid number!")
    elif max == 0:
        numbers_array.append(0)
    elif max == 1:
        numbers_array.append(1)
    else:
        index = 1
        while index <= max:
            batch = []
            for curr in range(1000):
                number_found = getNumberAt(index)
                batch.append(number_found)
                index += 1
            numbers_array.append(batch)
            print("MAKESPAN ::> State {0} -> Time = {1}.s".format(len(numbers_array), time.time()-initTime))

    complete_time = time.time()-initTime
    return {"CANARY-RESULT": "Found of {0} first numbers in Fibonacci sequence in {1}sec". format(max, complete_time)}


def getNumberAt(position):
    number_a = 0
    number_b = 1
    for i in range(1, position):
        result = number_a + number_b
        number_a = number_b
        number_b = result
    return number_b
