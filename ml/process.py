import matplotlib.pyplot as pyplot
import numpy as np
import pandas as pd
import tensorflow.keras as keras
import tensorflow.keras.layers as layers


def make_sets(array, training, validation):
    array_size = len(array)
    return np.split(array, (int(array_size * training), int(array_size * (training + validation))))


feature_columns = ['close', 'day_of_week']
input_length = 60
output_length = 1
training_size = 0.7
validation_size = 0.15
epochs = 100
plot_results_for_test_sample = 1

data = pd.read_csv('prices-AMZ-GY-2020-01-01-2020-11-21.csv')
label_columns = ['close']
feature_data = np.array(data[feature_columns])
label_data = np.array(data[label_columns])

model = keras.Sequential([
    layers.Input((None, len(feature_columns))),
    # needs to feed sequences and not only the last output to the next layer
    layers.BatchNormalization(),
    layers.LSTM(50, return_sequences=True),
    layers.LSTM(50, return_sequences=True),
    layers.LSTM(50, return_sequences=True),
    layers.LSTM(50),
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

x_train, x_val, x_test = make_sets(features, training_size, validation_size)
y_train, y_val, y_test = make_sets(labels, training_size, validation_size)

print("Training set has size {}, validation set has size {}, test set has size {}".format(len(x_train), len(x_val),
                                                                                          len(x_test)))

model.compile(optimizer='adam', loss='mean_squared_error', metrics=['mean_squared_error'])

model.fit(x_train, y_train, validation_data=(x_val, y_val), epochs=epochs, batch_size=x_train.shape[0])

for r in map(lambda a, b: a + ": " + str(b), model.metrics_names, model.test_on_batch(x_test, y_test)):
    print(r)

predicted = model.predict(x_test[plot_results_for_test_sample].reshape(1, input_length, len(feature_columns)))

pyplot.plot(range(0, x_test.shape[1]), x_test[plot_results_for_test_sample, :, feature_columns.index('close')],
            color='blue', marker='.',
            label='Real prices')
pyplot.plot(range(x_test.shape[1], x_test.shape[1] + output_length), y_test[plot_results_for_test_sample], color='blue',
            marker='.')
pyplot.plot(range(x_test.shape[1], x_test.shape[1] + output_length), predicted[0], color='red',
            label='Predicted prices', marker='.')
pyplot.legend()
pyplot.show()
