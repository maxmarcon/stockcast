import matplotlib.pyplot as pyplot
import numpy as np
import tensorflow.keras as keras
import tensorflow.keras.layers as layers
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import OneHotEncoder


def make_model(input_len, output_len, layer_size, layer_num, dropout=0.0):
    model = keras.Sequential([
        layers.Input((None, input_len))
    ])
    for _ in range(0, layer_num - 1):
        model.add(layers.LSTM(layer_size, return_sequences=True, dropout=dropout))
    model.add(layers.LSTM(layer_size, return_sequences=False, dropout=dropout))
    model.add(layers.Dense(output_len))
    return model


def make_sets(array, training, validation):
    array_size = len(array)
    # TODO: add random sampling!
    return np.split(array, (int(array_size * training), int(array_size * (training + validation))))


def preprocess(data):
    close, dow = data['close'].to_numpy().reshape(-1, 1), data['day_of_week'].to_numpy().reshape(-1, 1)
    close_scaler = MinMaxScaler()
    close_scaler.fit(close)
    close_scaled = close_scaler.transform(close)
    data['close_scaled'] = close_scaled

    dow_onehot = OneHotEncoder(sparse=False).fit_transform(dow)
    for i in range(0, dow_onehot.shape[1]):
        data['dow_{}'.format(i)] = dow_onehot[:, i]

    return close_scaler


def plot_results(dates, y_predicted, y_test, only_next_day=False, max_labels=10):
    if only_next_day:
        y_predicted_flat = y_predicted[:, 0]
        y_test_flat = y_test[:, 0]
    else:
        prediction_length = y_predicted.shape[1]
        y_predicted_flat = y_predicted[::prediction_length].reshape(-1)
        y_test_flat = y_test[::prediction_length].reshape(-1)

    x = dates[-y_test_flat.size:]
    pyplot.plot(x, y_test_flat, 'b-', x, y_predicted_flat, 'r-')
    pyplot.xticks(np.arange(0, y_test_flat.size, y_test_flat.size / max_labels), rotation=-30, fontsize='x-small')
    pyplot.grid(True)
    pyplot.show()
