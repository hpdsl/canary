import subprocess
import time

def main(args):
    initTime = time.time()
    invocation = "java -jar /USCensus.jar US_diversity_index"
    __post(invocation)
    print("INFO ::> Job Completed @ {0} seconds".format(time.time()-initTime))
    return {"Status": "Job completed"}


def __post(command):
    response = subprocess.run(['/bin/bash', '-c', command], stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT).stdout.decode().strip()
    print('Result:', response)


