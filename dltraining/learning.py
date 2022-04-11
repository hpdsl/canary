import resource, time
init_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024
initTime = time.time()
print("MAKESPAN ::> Code deployed -> Time = {0}.s | Memory = {1}.MB".format(time.time()-initTime, resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024))
import numpy as np # linear algebra
import os, sys, logging
import tensorflow_datasets as tfds
from tensorflow.keras.utils import to_categorical
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D
from tensorflow.keras.layers import Dense, Flatten
from tensorflow.keras import models
from tensorflow.keras.models import Model
from tensorflow.keras import layers
from tensorflow.keras import optimizers
from tensorflow.keras import callbacks
from tensorflow.keras.utils import get_file
from tensorflow.keras.preprocessing.image import img_to_array, array_to_img

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
logging.getLogger("tensorflow").setLevel(logging.CRITICAL)
logging.getLogger("tensorflow_hub").setLevel(logging.CRITICAL)

class PrintLR(callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
        print("MAKESPAN ::> State {0} -> Time = {1}.s | Memory = {2}.MB".format(epoch, time.time()-initTime, resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024))

def main(args):
    params = args.get('meta')
    dataset = params['dataset']
    selected_model = params['model']
    BATCH_SIZE = int(params['batch'])
    NB_EPOCHS = int(params['epochs'])
    features = params['features']
    label = int(features['class'])
    example = int(features['sample'])
    shape = features['shape']

    train_ds = tfds.load(name=dataset, split=tfds.Split.TRAIN)
    train_ds = tfds.as_numpy(train_ds)
    train_X = np.asarray([im["image"] for im in train_ds])
    train_Y = np.asarray([im["label"] for im in train_ds])
    #train_X, train_Y = train_ds["image"], train_ds["label"]
    print("MAKESPAN ::> Data Loaded -> Time = {0}.s | Memory = {1}.MB".format(time.time()-initTime, resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024))

    classes = np.unique(train_Y)
    num_classes = len(classes)

    if shape[-1] < 3: #If is not RGB image
        train_X=np.dstack([train_X] * 3)
        # Reshape images as per the tensor format required by tensorflow
        train_X = train_X.reshape(-1, shape[0], shape[1], 3)

    # Resize the images 48*48 required by models for datasets having smaller sizes
    if shape[0] < 48:
         train_X = np.asarray([img_to_array(array_to_img(im, scale=False).resize((48,48))) for im in train_X])
    elif shape[0] > 56:
         train_X = np.asarray([img_to_array(array_to_img(im, scale=False).resize((56,56))) for im in train_X])

    # Normalise the data and change data type
    train_X = train_X / 255.
    train_X = train_X.astype('float32')

    # Converting Labels to one hot encoded format
    train_label = to_categorical(train_Y)

    #  Create base model
    if selected_model == 'vgg16':
        from tensorflow.keras.applications import vgg16
        train_X = vgg16.preprocess_input(train_X)
        conv_base = vgg16.VGG16(weights='imagenet',include_top=False,input_shape=(train_X.shape[1], train_X.shape[2], train_X.shape[3]))
    elif selected_model == 'resnet50':
        from tensorflow.keras.applications import ResNet50
        from tensorflow.keras.applications.resnet import preprocess_input
        train_X = preprocess_input(train_X)
        conv_base = ResNet50(input_shape=(train_X.shape[1], train_X.shape[2], train_X.shape[3]), include_top=False, weights='imagenet', pooling='max')
    elif selected_model == 'resnet152':
        from tensorflow.keras.applications import ResNet152
        from tensorflow.keras.applications.resnet import preprocess_input
        train_X = preprocess_input(train_X)
        conv_base = ResNet152(input_shape=(train_X.shape[1], train_X.shape[2], train_X.shape[3]), include_top=False, weights='imagenet', pooling='max')
    elif selected_model == 'mobilenet':
        from tensorflow.keras.applications import MobileNet
        from tensorflow.keras.applications.mobilenet import preprocess_input
        train_X = preprocess_input(train_X)
        conv_base = MobileNet(input_shape=(train_X.shape[1], train_X.shape[2], train_X.shape[3]), include_top=False, weights='imagenet', pooling='max')
    else:
        print('The requested model is currently not supported.')
        sys.exit(0)

    print("MAKESPAN ::> Data Processed -> Time = {0}.s | Memory = {1}.MB".format(time.time()-initTime, resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024))
    train_features = conv_base.predict(np.array(train_X), batch_size=BATCH_SIZE, verbose=2)
    for layer in conv_base.layers:
        layer.trainable = False

    # Saving the features so that they can be used for future
    np.savez("train_features", train_features, train_label)

    # Flatten extracted features
    train_features_flat = np.reshape(train_features, (train_features.shape[0], 1*1*train_features.shape[-1]))

    model = models.Sequential()
    model.add(layers.Dense(64, activation='relu', input_dim=(1*1*train_features.shape[-1])))
    model.add(layers.Dense(label, activation='softmax'))

    # Define the checkpoint directory to store the checkpoints
    checkpoint_dir = './training_checkpoints'
    # Name of the checkpoint files
    checkpoint_prefix = os.path.join(checkpoint_dir, "ckpt_{epoch}")
    callback = [
        callbacks.TensorBoard(log_dir='./logs'),
        callbacks.ModelCheckpoint(filepath=checkpoint_prefix,
                                           save_weights_only=True),
        PrintLR()
    ]

    # Compile the model.
    model.compile(
        loss='categorical_crossentropy',
        optimizer=optimizers.Adam(),
        metrics=['acc'])

    print("MAKESPAN ::> Ready for Training -> Time = {0}.s | Memory = {1}.MB".format(time.time()-initTime, resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024))
    history = model.fit(
        train_features_flat,
        train_label,
        epochs=NB_EPOCHS,
        callbacks=callback
    )
    final_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024 - init_memory
    print("MAKESPAN ::> Function completion -> Time = {0}.s | Memory = {1}.MB".format(time.time()-initTime, final_memory))
    output = {'Response': 'FUNCTION COMPLETED SUCCESSFULLY (*_*)'}
    return output

