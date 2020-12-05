import numpy as np
import pandas as pd
import tensorflow.keras as keras
import tensorflow.keras.layers as layers

import utils

data = pd.read_csv('prices-AMZ-GY-2016-01-01-2020-12-03.csv')
close_rescaler = utils.preprocess(data)

feature_columns = ['close_scaled']
label_columns = ['close_scaled']
input_length = 60
output_length = 5
training_size = 0.7
validation_size = 0.15
epochs = 1
batch_size = 30
dropout = 0.0

feature_data = data[feature_columns].values
label_data = data[label_columns].values

model = keras.Sequential([
    layers.Input((None, len(feature_columns))),
    layers.LSTM(50, return_sequences=True, dropout=dropout),
    # needs to feed sequences and not only the last output to the next layer
    layers.LSTM(50, return_sequences=True, dropout=dropout),
    layers.LSTM(50, return_sequences=True, dropout=dropout),
    layers.LSTM(50, return_sequences=True, dropout=dropout),
    layers.LSTM(50, dropout=dropout),
    # next five days
    layers.Dense(output_length)
])

features, labels = [], []

for i in range(0, feature_data.shape[0] - (input_length + output_length) + 1):
    features.append(feature_data[i:i + input_length])

for i in range(0, label_data.shape[0] - (input_length + output_length) + 1):
    labels.append(label_data[i + input_length:i + input_length + output_length, 0])

print("Feature set has size {}".format(len(features)))

features, labels = np.array(features), np.array(labels)

x_train, x_val, x_test = utils.make_sets(features, training_size, validation_size)
y_train, y_val, y_test = utils.make_sets(labels, training_size, validation_size)

print("Training set has size {}, validation set has size {}, test set has size {}".format(len(x_train), len(x_val),
                                                                                          len(x_test)))

model.compile(optimizer='adam', loss='mean_squared_error')

training_history = model.fit(x_train, y_train, validation_data=(x_val, y_val), epochs=epochs, batch_size=batch_size)

metric_results = model.evaluate(x_test, y_test)

if type(metric_results) != list:
    metric_results = [metric_results]

for r in map(lambda a, b: a + ": " + str(b), model.metrics_names, metric_results):
    print(r)

utils.plot_results(model, x_test, y_test)
