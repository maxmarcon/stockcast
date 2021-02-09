import operator
import os.path
from functools import reduce

import matplotlib.pyplot as pyplot
import numpy as np
import pandas
import tensorflow.keras as keras
import tensorflow.keras.layers as layers
from colors import *
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import OneHotEncoder


def make_model(input_len, feature_size, output_len, layer_size, nof_hidden_layers, dropout_rate=0.0, **kwargs):
    model = keras.Sequential([
        layers.Input((input_len, feature_size))
    ])
    for _ in range(0, nof_hidden_layers - 1):
        model.add(layers.LSTM(layer_size, return_sequences=True, dropout=dropout_rate))
    model.add(layers.LSTM(layer_size, return_sequences=False, dropout=dropout_rate))
    model.add(layers.Dense(output_len))
    return model


def make_sets(array, training, validation):
    array_size = len(array)
    return np.split(array, (int(array_size * training), int(array_size * (training + validation))))


def generate_tuning_state_filename(file, datafile):
    (stem, _) = os.path.splitext(file)
    if datafile is not None:
        (datafile_stem, _) = os.path.splitext(datafile)
        prefix = f'{stem}-{datafile_stem}'
    else:
        prefix = stem

    return f'{prefix}.tuning'


def load_tuning_state(filename, dontfail=True):
    try:
        return pandas.read_csv(filename)
    except FileNotFoundError:
        if not dontfail:
            error(f"Could not open file {filename} - maybe you should tune first?")
            exit(1)
        return None


def enumerate_parameter_space(parameter_space):
    key, values = parameter_space.popitem()
    if len(parameter_space) == 0:
        for v in values:
            yield {key: v}
    else:
        for rest in enumerate_parameter_space(parameter_space):
            for v in values:
                yield {key: v, **rest}


def parameter_space_size(parameter_space):
    return reduce(operator.mul, (len(values) for values in parameter_space.values()))


def paramaters_for_lookup(parameters):
    return dict(
        (param_key, ','.join(sorted(param_value)) if type(param_value) is list else param_value) for
        (param_key, param_value) in
        parameters.items()
    )


def contains_tuning_state(dataframe, parameters):
    if dataframe is None:
        return False

    selector = reduce(lambda l, r: operator.and_(l, r),
                      (dataframe[param_key] == param_value for (param_key, param_value) in
                       paramaters_for_lookup(parameters).items()))
    return not dataframe[selector].empty


def save_tuning_state(dataframe, parameters, metrics, time, filename):
    row_dict = {**paramaters_for_lookup(parameters), **metrics, 'time': time}

    if dataframe is None:
        dataframe = pandas.DataFrame.from_dict({k: [v] for k, v in row_dict.items()})
    else:
        dataframe = dataframe.append(row_dict, ignore_index=True)

    dataframe.to_csv(filename, index=False)
    return dataframe


def load_hyperparameters(tuning_file, hp_index):
    tuning_state = load_tuning_state(tuning_file, False)
    if hp_index >= len(tuning_state):
        error(f"Index {hp_index} exceed max index {len(tuning_state) - 1}")
        exit(1)

    return tuning_state.loc[hp_index]


def load_optimal_hyperparameters_index(tuning_file, column='val_loss'):
    tuning_state = load_tuning_state(tuning_file, False)
    return tuning_state[tuning_state['val_loss'] == tuning_state.min()['val_loss']].index[0]


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


def plot_results(title, dates, predicted_labels, labels, max_labels=10, pdf=None):
    prediction_length = predicted_labels.shape[1]
    predicted_labels_nonoverlapping = predicted_labels[::prediction_length].reshape(-1)
    labels_nonoverlapping = labels[::prediction_length].reshape(-1)
    labels_nonoverlapping_first_ones = labels_nonoverlapping[::prediction_length]
    dates_nonoverlapping = dates[::prediction_length].reshape(-1)
    dates_nonoverlapping_first_ones = dates_nonoverlapping[::prediction_length]

    pyplot.title(title)
    pyplot.plot(dates_nonoverlapping, labels_nonoverlapping, 'b-', label='Real value')
    pyplot.plot(dates_nonoverlapping, predicted_labels_nonoverlapping, 'r-', label='Predicted')
    pyplot.plot(dates_nonoverlapping_first_ones, labels_nonoverlapping_first_ones, 'gx')
    max_labels = max_labels if max_labels < dates_nonoverlapping.size else dates_nonoverlapping.size
    pyplot.xticks(np.arange(0, dates_nonoverlapping.size, dates_nonoverlapping.size / max_labels), rotation=-30,
                  fontsize='x-small')
    pyplot.ylim(bottom=0)
    pyplot.legend()
    pyplot.grid(True)
    if pdf:
        pdf.savefig()
        pyplot.close()


def prepare_data(datafile, feature_columns, input_length, output_length, training_size, validation_size):
    data = pandas.read_csv(datafile)
    close_rescaler = preprocess(data)

    features, labels, label_dates = [], [], []

    for i in range(0, len(data) - (input_length + output_length) + 1):
        features.append(data[i:i + input_length][feature_columns].values)

    for i in range(0, len(data) - (input_length + output_length) + 1):
        label_dates.append(data[i + input_length:i + input_length + output_length]['date'])
        labels.append(data[i + input_length:i + input_length + output_length]['close_scaled'])

    features, labels, label_dates = np.array(features, np.float), np.array(labels, np.float), np.array(label_dates)

    x_train, x_val, x_test = make_sets(features, training_size, validation_size)
    y_train, y_val, y_test = make_sets(labels, training_size, validation_size)
    dates_train, dates_val, dates_test = make_sets(label_dates, training_size, validation_size)

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


def ok(msg):
    print(color(msg, fg='green'))


def error(msg):
    print(color(msg, fg='red'))


def warn(msg):
    print(color(msg, fg='yellow'))
