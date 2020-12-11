#!/usr/bin/env python
import argparse

import numpy as np
import pandas as pd
import tensorflow.keras.models as kmodels

import utils

arg_parser = argparse.ArgumentParser()
arg_parser.add_argument('--model', '-m', action='store')
arg_parser.add_argument('command', choices=('train', 'load', 'save'))
arg_parser.add_argument('datafile')

arguments = arg_parser.parse_args()

training_size = 0.7
validation_size = 0.15
epochs = 30
batch_size = 30
feature_columns = ['close_scaled']
dropout = 0.0


def prepare_data(datafile):
    global close_rescaler
    global x_train, x_val, x_test
    global y_train, y_val, y_test
    global dates_train, dates_val, dates_test

    input_length = 60
    output_length = 5

    data = pd.read_csv(datafile)
    close_rescaler = utils.preprocess(data)

    feature_data = data[feature_columns]

    features, labels, dates = [], [], []

    for i in range(0, feature_data.shape[0] - (input_length + output_length) + 1):
        features.append(feature_data[i:i + input_length].values)

    for i in range(0, data.shape[0] - (input_length + output_length) + 1):
        dates.append(data[i + input_length:i + input_length + output_length]['date'])
        labels.append(data[i + input_length:i + input_length + output_length]['close_scaled'])

    print("Feature set has size {}".format(len(features)))

    features, labels, dates = np.array(features, np.float), np.array(labels, np.float), np.array(dates)

    x_train, x_val, x_test = utils.make_sets(features, training_size, validation_size)
    y_train, y_val, y_test = utils.make_sets(labels, training_size, validation_size)
    dates_train, dates_val, dates_test = utils.make_sets(dates, training_size, validation_size)


prepare_data(arguments.datafile)

print("Training set has size {}, validation set has size {}, test set has size {}".format(len(x_train), len(x_val),
                                                                                          len(x_test)))


def train(model, x_train, y_train, x_val, y_val, epochs, batch_size):
    model.compile(optimizer='adam', loss='mean_squared_error')
    training_history = model.fit(x_train, y_train, shuffle=True, validation_data=(x_val, y_val), epochs=epochs,
                                 batch_size=batch_size)


def require_model_name():
    if arguments.model is None:
        raise RuntimeError("You need to specify a model with --model")


if arguments.command == 'load':
    require_model_name()
    print('loading model from {}'.format(arguments.model))
    model = kmodels.load_model(arguments.model)
elif arguments.command == 'train':
    require_model_name()
    model = utils.make_model(len(feature_columns), output_length, 50, 5)
    train(model, x_test, y_test, x_val, y_val, epochs, batch_size)
    model.save(arguments.model)
else:
    raise RuntimeError("Unimplemented command {}".format(arguments.command))

metric_results = model.evaluate(x_test, y_test)

if type(metric_results) != list:
    metric_results = [metric_results]

for r in map(lambda a, b: a + ": " + str(b), model.metrics_names, metric_results):
    print(r)

utils.plot_results(dates_test, close_rescaler.inverse_transform(model.predict(x_test)),
                   close_rescaler.inverse_transform(y_test))
