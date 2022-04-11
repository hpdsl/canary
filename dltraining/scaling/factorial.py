import time
def main(args):
    initTime = time.time()
    target = int(args.get("target", 1000000000))
    factorial_value = 1
    for current in range(1, target+1):
        factorial_value = factorial_value * current

    complete_time = time.time()-initTime
    return {"CANARY-RESULT": "Factorial of {0} ({1}) found in {2}sec".format(target, factorial_value, complete_time)}

