#!/usr/bin/env python
import argparse
from datetime import timedelta
from time import time

import utils
from utils import ok, warn, error


def _train(model, epochs, batch_size, loss_function, optimizer, x_train, y_train, x_val, y_val, **kwargs):
    model.compile(optimizer=optimizer, loss=loss_function)
    return model.fit(x_train, y_train, shuffle=True, validation_data=(x_val, y_val), epochs=epochs,
                     batch_size=batch_size)


def tune(model_name, datafile, hyperparameter_space, input_length, output_length, training_size, validation_size):
    total_models = utils.parameter_space_size(hyperparameter_space)
    trained_models = 0

    ok("{} models to train".format(total_models))

    tuning_state_filename = utils.tuning_state_filename(model_name)
    ok("storing tuning state in: {}".format(tuning_state_filename))
    tuning_state = utils.load_tuning_state(tuning_state_filename)
    if tuning_state is not None:
        warn("resuming interrupted tuning session with {} trained models".format(len(tuning_state)))

    try:
        for hyperparameters in utils.enumerate_parameter_space(hyperparameter_space):
            if utils.contains_tuning_state(tuning_state, hyperparameters):
                warn("skipping parameters: {}".format(hyperparameters))
            else:
                ok("training and validating model with parameters {}".format(hyperparameters))
                ok(f"{total_models - trained_models} models left to go")
                if tuning_state is not None:
                    time_left = timedelta(seconds=tuning_state.mean()['time'] * (total_models - trained_models))
                    ok(f"approx. {time_left} left")

                model, history, training_time = train(datafile, hyperparameters, input_length, output_length,
                                                      training_size,
                                                      validation_size, silent=True)
                try:
                    pass
                except KeyboardInterrupt:
                    warn("received interrupt from keyboard, saving tuning state first")
                    raise
                finally:
                    tuning_state = utils.save_tuning_state(tuning_state, hyperparameters,
                                                           {'loss': history.history['loss'][-1],
                                                            'val_loss': history.history['val_loss'][-1]},
                                                           training_time,
                                                           model_name)
            trained_models = trained_models + 1
        warn("tuning completed, results stored in: {}".format(tuning_state_filename))
    except KeyboardInterrupt:
        warn("tuning interrupted by user, tuning state saved in: {}".format(tuning_state_filename))


def train(datafile, hyperparameters, input_length, output_length, training_size, validation_size, silent=False):
    feature_columns = hyperparameters['feature_columns']
    if type(feature_columns) is not list:
        feature_columns = feature_columns.split(',')
    data = utils.prepare_data(datafile, feature_columns, input_length,
                              output_length,
                              training_size, validation_size)
    model = utils.make_model(input_length, len(feature_columns), output_length,
                             **hyperparameters)
    start = time()
    if not silent:
        ok("training and validating model with parameters:\n{}".format(hyperparameters))

    history = _train(model, **hyperparameters, **data)
    training_time = time() - start
    return model, history, training_time


def evaluate(model, x_test, y_test, dates_test, rescaler, **kwargs):
    metric_results = model.evaluate(x_test, y_test)
    if type(metric_results) != list:
        metric_results = [metric_results]
    for r in map(lambda a, b: a + ": " + str(b), model.metrics_names, metric_results):
        print(r)
    utils.plot_results(dates_test, rescaler.inverse_transform(model.predict(x_test)),
                       rescaler.inverse_transform(y_test))


def load_hyperparameters(model_name, index):
    tuning_state_filename = utils.tuning_state_filename(model_name)
    ok("Rading stuning state from: {}".format(tuning_state_filename))
    tuning_state = utils.load_tuning_state(tuning_state_filename)
    if tuning_state is None:
        error(f"Could not open file {tuning_state_filename} - maybe you should tune first?")
        exit(1)
    if tuning_state.loc[index].empty:
        error(f"No row at index {index}")
        exit(1)

    return tuning_state.loc[index]


training_size = 0.7
validation_size = 0.15
input_length = 60
output_length = 5

hyperparameter_space = dict(
    feature_columns=[
        ['close_scaled', 'day_of_week'],
        ['close_scaled'],
        ['close_scaled', *[f'dow_{i}' for i in range(0, 5)]]
    ],
    dropout_rate=[0.0, 0.1, 0.2],
    optimizer=['adam', 'sgd'],
    loss_function=['mean_squared_error'],
    layer_size=[10, 20, 30, 40, 50, 100],
    nof_hidden_layers=[1, 2, 3, 4, 5],
    epochs=[30],
    batch_size=[32]
)

if __name__ == '__main__':

    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('datafile', help="Input data file")
    arg_parser.add_argument('--model', '-m', required=True, help="The model name")
    subparsers = arg_parser.add_subparsers(dest='command', required=True)
    tune_parser = subparsers.add_parser('tune', help="Tune hyperparameters")

    train_parser = subparsers.add_parser('train', help="Train a model")
    train_parser.add_argument('--index', '-i', help="Hyperparameters index", required=True, type=int)

    args = arg_parser.parse_args()
    datafile = args.datafile

    ok(f"Loading data from {datafile}...")
    model_name = args.model

    if args.command == 'evaluate':
        raise RuntimeError("not implemented yet")
    elif args.command == 'train':
        index = args.index
        hyperparameters = load_hyperparameters(model_name, index)
        model, *rest = train(datafile, hyperparameters, input_length, output_length, training_size,
                             validation_size)
        model.save(model_name)
        ok(f"Model saved in folder: {model_name}")
    elif args.command == 'tune':
        tune(args.model, datafile, hyperparameter_space, input_length, output_length, training_size,
             validation_size)
