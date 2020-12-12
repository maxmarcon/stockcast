#!/usr/bin/env python
import argparse

arg_parser = argparse.ArgumentParser()
subparsers = arg_parser.add_subparsers(dest="command", required=True)

parser_load = subparsers.add_parser('evaluate')
parser_load.add_argument('datafile')
parser_load.add_argument('--model', '-m', required=True)

parser_train = subparsers.add_parser('train')
parser_train.add_argument('datafile')

parser_save = subparsers.add_parser('save')
parser_save.add_argument('datafile')
parser_save.add_argument('--model', '-m', required=True)

args = arg_parser.parse_args()

import tensorflow.keras.models as kmodels

import utils

training_size = 0.7
validation_size = 0.15
epochs = 30
batch_size = 30
input_length = 60
output_length = 5

## Hyperparameters
feature_columns = [
    ['close_scaled'],
    ['close_scaled', 'day_of_the_week'],
    ['close_scaled', *['dow_{}'.format(i) for i in range(0, 6)]]
]
dropout = [0.0, 0.1, 0.2]
optimizer = ['adam']
loss = ['mean_squared_error']
layer_size = [10, 20, 30, 40, 50, 100]
nof_hidden_layers = [1, 2, 3, 4, 5]

data = utils.prepare_data(
    args.datafile, feature_columns[0], input_length, output_length, training_size, validation_size)

print("Training set has size {}, validation set has size {}, test set has size {}".format(len(data['x_train']),
                                                                                          len(data['x_val']),
                                                                                          len(data['x_test'])))


def train(model, epochs, batch_size, x_train, y_train, x_val, y_val, **kwargs):
    model.compile(optimizer='adam', loss='mean_squared_error')
    training_history = model.fit(x_train, y_train, shuffle=True, validation_data=(x_val, y_val), epochs=epochs,
                                 batch_size=batch_size)


def evaluate(model, x_test, y_test, dates_test, rescaler, **kwargs):
    metric_results = model.evaluate(x_test, y_test)
    if type(metric_results) != list:
        metric_results = [metric_results]
    for r in map(lambda a, b: a + ": " + str(b), model.metrics_names, metric_results):
        print(r)
    utils.plot_results(dates_test, rescaler.inverse_transform(model.predict(x_test)),
                       rescaler.inverse_transform(y_test))


if args.command == 'evaluate':
    print('loading model from {}'.format(args.model))
    model = kmodels.load_model(args.model)
    evaluate(kmodels.load_model(args.model), **data)
elif args.command == 'train':
    model = utils.make_model(len(feature_columns), output_length, 50, 5)
    train(model, epochs, batch_size, **data)
    model.save(args.model)
else:
    raise RuntimeError("Unimplemented command {}".format(args.command))
