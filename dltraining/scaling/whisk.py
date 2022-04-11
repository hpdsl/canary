import argparse
import subprocess
import sys, time
import json
from pathlib import Path
from multiprocessing import Process

initTime = time.time()

def main():
    # Read commands parsed by users
    parser = argparse.ArgumentParser(
        prog='canary', description='All in One action deep learning')
    parser.add_argument('model', type=str,
                        help='Target model for training job')
    parser.add_argument('dataset', type=str,
                        help='Target dataset (should be among tf.datasets)')
    parser.add_argument('-b', '--batch', type=int,
                        help='Size of data batch. \nDefault value is 64.')
    parser.add_argument('-e', '--epoch', type=int,
                        help='Number of epochs. \nDefault value is 100.')
    parser.add_argument('-j', '--job', type=int,
                        help='Batch or standalone computation')

    params = vars(parser.parse_args())
    print("MAKESPAN ::> Job Launched -> Time = {0}.s".format(0))
    home = str(Path.home())
    params['file'] = "{0}/examples/{1}/{2}.json".format(home,
        params['dataset'], params['model'])
    build(params)


def build(params):
    # get data and model info from file
    with open(params['file']) as file:
        file_content = json.load(file)

    image = "hpdsl/dlserverless:latest"
    # Get datasets parameters
    data_features = file_content['dataset']
    params['features'] = data_features
    size_attributes = data_features['size'].split(" ")
    size_value = int(float(size_attributes[0]))
    dataset = data_features['name']
    batch_size = 64 if params['batch'] is None else params['batch']
    workload = params['job']
    epochs = 50 if params['epoch'] is None else params['epoch']
    metadata = json.dumps({"model": file_content['model']['name'], "dataset": dataset, "batch": batch_size,
                            "epochs": epochs, "features": params["features"]})

    # Create package and action
    package_code = "wsk -i package update deep --param meta '{0}'".format(metadata)
    post(package_code)

    '''
    answers = []
    for current_job in range(workload):
        action_code = "wsk -i action update deep/learning-{0} $HOME/examples/scaling/learning.py --docker {1} --memory 9216 --timeout 540000".format(current_job, image)
        post(action_code)

        # Invoke action
        answer = post("wsk -i action invoke deep/learning-{0} --result".format(current_job))
        answers.append(answer)

    print("MAKESPAN ::> Containers Launched -> Time = {0}.s".format(time.time()-initTime), '\n')
    for answer in answers:
        print(answer)
        p = Process(target=poolActivations, args=(answer,))
        p.start()
    '''

def post(command):
    print('Running ({0})....'.format(command))
    reply = subprocess.run(['/bin/bash', '-c', command], stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT).stdout.decode().strip()
    if "error" not in reply:
        print('Result:', reply, '\n')
    return reply

def poolActivations(answer):
    try:
        activation = "random"
        if "CANARY-RESULT" in answer:
            print(answer, '\n')

        while "CANARY-RESULT" not in answer:
            if "error" in answer:
                if activation in answer:
                    answer = post("wsk -i activation result " + activation)
                elif "exceeds allowed threshold" in answer:
                    print("Status: Failed")
                    sys.exit(1)
            else:
                activation = answer.split(" ")[-1]
                act_code = "wsk -i activation result " + activation
                answer = post(act_code)

        if "CANARY-RESULT" not in answer:
            print("Failed with unexpected termination status")
            sys.exit(1)
    except:
        print('Error with answers')

if __name__ == '__main__':
    main()

