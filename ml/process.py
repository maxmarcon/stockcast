import numpy as np
import pandas as pd
import tensorflow.keras as keras
import tensorflow.keras.layers as layers


def make_sets(array, training, validation):
    array_size = len(array)
    return np.split(array, (int(array_size * training), int(array_size * (training + validation))))


data = pd.read_csv('prices-AMZ-GY-2020-01-01-2020-11-21.csv')
input_data = np.array(data[['day_of_week', 'close']])

output_size = 5
training_size = 0.7
validation_size = 0.15

model = keras.Sequential([
    layers.Input((None, 2)),
    # needs to feed sequences and not only the last output to the next layer
    layers.BatchNormalization(),
    layers.LSTM(10, return_sequences=True),
    layers.LSTM(10),
    # next five days
    layers.Dense(output_size)
])

features, labels = [], []
sequence_length = 60

for i in range(0, input_data.shape[0]-(sequence_length+output_size)+1):
    features.append(input_data[i:i+sequence_length])
    labels.append(input_data[i+sequence_length:i+sequence_length+output_size, 1])

print("Feature set has size {}".format(len(features)))

features, labels = np.array(features), np.array(labels)

x_train, x_val, x_test = make_sets(features, training_size, validation_size)
y_train, y_val, y_test = make_sets(labels, training_size, validation_size)
# check out model.fit validation_split option... maybe we don't need an explicit validation set

print("Training set has size {}, validation set has size {}, test set has size {}".format(len(x_train), len(x_val), len(x_test)))

model.compile(optimizer = 'sgd', loss = 'mean_squared_error')
