import operator
from functools import reduce

import numpy as np
import pandas
import tensorflow.keras as keras
import tensorflow.keras.layers as layers
from colors import *
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import OneHotEncoder

COLUMNS_TO_RESCALE = ['open', 'high', 'low', 'close', 'volume', 'change', 'changePercent']


def make_model(input_len, feature_size, output_len, layer_size, nof_hidden_layers, dropout_rate=0.0, **kwargs):
    model = keras.Sequential([
        layers.Input((input_len, feature_size))
    ])
    for _ in range(0, nof_hidden_layers - 1):
        model.add(layers.LSTM(layer_size, return_sequences=True, dropout=dropout_rate))
    model.add(layers.LSTM(layer_size, return_sequences=False, dropout=dropout_rate))
    model.add(layers.Dense(output_len))
    return model


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
    close_scaler = None
    for column in COLUMNS_TO_RESCALE:
        if column in data:
            scaler = MinMaxScaler()
            values = data[column].to_numpy().reshape(-1, 1)
            scaler.fit(values)
            data[f'{column}_scaled'] = scaler.transform(values)
            if column == 'close':
                close_scaler = scaler

    dow_onehot = OneHotEncoder(sparse=False).fit_transform(dow)
    for i in range(0, dow_onehot.shape[1]):
        data['dow_{}'.format(i)] = dow_onehot[:, i]

    return close_scaler


def plot_results(ax, title, dates, predicted_labels, labels, show_xticks=True):
    sections = sorted(
        map(lambda el: dict(dates=el[0], labels=el[1], predicted=el[2]), zip(dates, labels, predicted_labels)),
        key=lambda el: el['dates'][0])
    ax.set_title(title)

    xticks, xtick_labels = [], []
    last_right = 0
    for i, section in enumerate(sections):
        left = 0 if i == 0 else i * len(sections[i - 1]['dates'])
        right = (i + 1) * len(sections[i]['dates'])
        last_right = right
        xticks.append(left)
        xtick_labels.append(sections[i]['dates'][0])
        l1, = ax.plot(range(left, right), sections[i]['labels'], 'b.-')
        l2, = ax.plot(range(left, right), sections[i]['predicted'], 'r.-')
        if i == 0:
            l1.set_label('Real value')
            l2.set_label('Predicted value')

    if show_xticks:
        ax.set_xticks(xticks)
        ax.set_xticklabels(xtick_labels)
    ax.legend()
    ax.set_xlim(0, last_right - 1)
    ax.yaxis.grid(True)
    ax.xaxis.grid(True)
    for t in ax.xaxis.get_ticklabels():
        t.set_horizontalalignment('right')
        t.set_rotation(30)
        t.set_fontsize('small')


def load_data(datafile, feature_columns, input_length, output_length, training_size, random_state, shuffle_data,
              labels_starting_on_weekday=None):
    ok(f"Reading data from {datafile}")
    warn(f"Data shuffling is {'ON' if shuffle_data else 'OFF'}")
    data = pandas.read_csv(datafile)
    close_rescaler = preprocess(data)

    features, labels, label_dates = [], [], []

    for i in range(input_length, len(data) - output_length + 1):
        if labels_starting_on_weekday is None or data.iloc[i]['day_of_week'] == labels_starting_on_weekday + 1:
            features.append(data[i - input_length:i][feature_columns].values)
            label_dates.append(data[i:i + output_length]['date'])
            labels.append(data[i:i + output_length]['close_scaled'])

    features, labels, label_dates = np.array(features, np.float), np.array(labels, np.float), np.array(label_dates)

    x_train, x_test, y_train, y_test, dates_train, dates_test = train_test_split(features, labels, label_dates,
                                                                                 random_state=random_state,
                                                                                 train_size=training_size,
                                                                                 shuffle=shuffle_data)

    return {
        'x_train': x_train,
        'y_train': y_train,
        'x_test': x_test,
        'y_test': y_test,
        'dates_train': dates_train,
        'dates_test': dates_test,
        'rescaler': close_rescaler
    }


def ok(msg):
    print(color(msg, fg='green'))


def error(msg):
    print(color(msg, fg='red'))


def warn(msg):
    print(color(msg, fg='yellow'))
