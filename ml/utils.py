import os.path

import matplotlib.pyplot as pyplot
import numpy as np
import pandas
import tensorflow.keras as keras
import tensorflow.keras.layers as layers
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import OneHotEncoder


def make_model(input_len, output_len, layer_size, nof_hidden_layers, dropout=0.0):
    model = keras.Sequential([
        layers.Input((None, input_len))
    ])
    for _ in range(0, nof_hidden_layers - 1):
        model.add(layers.LSTM(layer_size, return_sequences=True, dropout=dropout))
    model.add(layers.LSTM(layer_size, return_sequences=False, dropout=dropout))
    model.add(layers.Dense(output_len))
    return model


def make_sets(array, training, validation):
    array_size = len(array)
    return np.split(array, (int(array_size * training), int(array_size * (training + validation))))


def __get_hyperparameter_filename(file):
    (stem, _) = os.path.splitext(file)
    return stem + ".hp"


def load_hyperparameters(file):
    try:
        return pandas.read_csv(__get_hyperparameter_filename(file))
    except FileNotFoundError:
        return None


def save_hyperparameters(dataframe, parameters, metrics, time, file):
    row = {k: [v] for k, v in {**parameters, **metrics, 'time': time}.items()}

    if dataframe is None:
        dataframe = pandas.DataFrame.from_dict(row)
    else:
        dataframe = dataframe.append(row)

    dataframe.to_csv(__get_hyperparameter_filename(file))


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


def prepare_data(datafile, feature_columns, input_length, output_length, training_size, validation_size):
    data = pandas.read_csv(datafile)
    close_rescaler = preprocess(data)

    feature_data = data[feature_columns]

    features, labels, dates = [], [], []

    for i in range(0, feature_data.shape[0] - (input_length + output_length) + 1):
        features.append(feature_data[i:i + input_length].values)

    for i in range(0, data.shape[0] - (input_length + output_length) + 1):
        dates.append(data[i + input_length:i + input_length + output_length]['date'])
        labels.append(data[i + input_length:i + input_length + output_length]['close_scaled'])

    features, labels, dates = np.array(features, np.float), np.array(labels, np.float), np.array(dates)

    x_train, x_val, x_test = make_sets(features, training_size, validation_size)
    y_train, y_val, y_test = make_sets(labels, training_size, validation_size)
    dates_train, dates_val, dates_test = make_sets(dates, training_size, validation_size)

    return {
        'x_train': x_train,
        'y_train': y_train,
        'x_val': x_val,
        'y_val': y_val,
        'x_test': x_test,
        'y_test': y_test,
        'dates_train': dates_train,
        'dates_val': dates_val,
        'dates_test': dates_test,
        'rescaler': close_rescaler
    }
