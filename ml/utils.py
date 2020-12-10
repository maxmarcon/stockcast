import os.path

import matplotlib.pyplot as pyplot
import numpy as np
import pandas
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


def save_hyperparameters(datafile, parameters, metrics):
    (stem, _) = os.path.splitext(datafile)
    params_file = stem + ".hp"

    row = {k: [v] for k, v in {**parameters, **metrics}.items()}

    if os.path.exists(params_file):
        hp_data = pandas.read_csv(params_file)
        # append row
    else:
        hp_data = pandas.DataFrame.from_dict(row)

    # save

    return hp_data


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


def plot_results(dates, y_predicted, y_test, max_labels=10):
    prediction_length = y_predicted.shape[1]
    y_predicted_flat = y_predicted[::prediction_length].reshape(-1)
    y_test_flat = y_test[::prediction_length].reshape(-1)
    dates_flat = dates[::prediction_length].reshape(-1)

    pyplot.plot(dates_flat, y_test_flat, 'b-', dates_flat, y_predicted_flat, 'r-')
    max_labels = max_labels if max_labels < dates_flat.size else dates_flat.size
    pyplot.xticks(np.arange(0, dates_flat.size, dates_flat.size / max_labels), rotation=-30, fontsize='x-small')
    pyplot.ylim(bottom=0)
    pyplot.grid(True)
    pyplot.show()
