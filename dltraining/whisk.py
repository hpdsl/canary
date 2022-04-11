import argparse
import subprocess
import sys, time
import json
from pathlib import Path

initTime = time.time()

def main():
    # Read commands parsed by users
    parser = argparse.ArgumentParser(
        prog='whisk', description='All in One action deep learning')
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
    epochs = 50 if params['epoch'] is None else params['epoch']
    metadata = json.dumps({"model": file_content['model']['name'], "dataset": dataset,
                           "batch": batch_size, "epochs": epochs, "features": params["features"]})
    #import pdb
    # pdb.set_trace()

    # Create package and action
    package_code = "wsk -i package update deep --param meta '{0}'".format(
        metadata)
    post(package_code)

    action_code = "wsk -i action update deep/learning $HOME/examples/learning.py --docker {img} --memory 10240 --timeout 540000".format(img=image)
    post(action_code)

    # Invoke action
    answer = post("wsk -i action invoke deep/learning")
    print("MAKESPAN ::> Container Launched -> Time = {0}.s".format(time.time()-initTime))
    activation = answer.split(" ")[-1]
    print("Retrieve results with activation code {act}".format(act=activation))


def post(command):
    print('Running ({0})....'.format(command))
    reply = subprocess.run(['/bin/bash', '-c', command], stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT).stdout.decode().strip()
    if "error" in reply:
        # print('Error:', reply)
        pass
    else:
        print('Result:', reply)
    return reply


if __name__ == '__main__':
    main()

