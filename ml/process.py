#!/usr/bin/env python
import argparse
from datetime import timedelta
from time import time

import config
import utils
from utils import ok, warn
import tensorflow.keras as keras


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


def evaluate(model, feature_columns, input_length, output_length, training_size, validation_size):
    data = utils.prepare_data(datafile, feature_columns, input_length,
                              output_length,
                              training_size, validation_size)
    metric_results = model.evaluate(data['x_test'], data['y_test'])
    if type(metric_results) != list:
        metric_results = [metric_results]
    for r in map(lambda a, b: a + ": " + str(b), model.metrics_names, metric_results):
        print(r)
    utils.plot_results(data['dates_test'], data['rescaler'].inverse_transform(model.predict(data['x_test'])),
                       data['rescaler'].inverse_transform(data['y_test']))


if __name__ == '__main__':

    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('datafile', help="Input data file")
    arg_parser.add_argument('--model', '-m', required=True, help="The model name")
    subparsers = arg_parser.add_subparsers(dest='command', required=True)
    tune_parser = subparsers.add_parser('tune', help="Tune hyperparameters")

    train_parser = subparsers.add_parser('train', help="Train a model")
    train_parser.add_argument('--index', '-i', help="Hyperparameters index", required=False, type=int)

    evaluate_parser = subparsers.add_parser('evaluate', help='Evaluate a model')
    # evaluate_parser.add_argument('--index', '-i', help="Hyperparameters index", required=False, type=int)

    args = arg_parser.parse_args()
    datafile = args.datafile

    ok(f"Loading data from {datafile}...")
    model_name = f'{args.model}-{config.input_length}-{config.output_length}'

    if args.command == 'evaluate':
        model = keras.models.load_model(model_name)
        # fix this
        evaluate(model, ['close_scaled', 'day_of_week'], config.input_length, config.output_length, config.training_size, config.validation_size)
        raise RuntimeError("not implemented yet")
    elif args.command == 'train':
        index = args.index
        if index is None:
            ok(f'Loading hyperparameters that minimize val_loss')
            hyperparameters = utils.load_optimal_hyperparameters(model_name)
        else:
            ok(f'Loading hyperparameters at position {index}')
            hyperparameters = utils.load_hyperparameters(model_name, index)
        model, *rest = train(datafile, hyperparameters, config.input_length, config.output_length, config.training_size,
                             config.validation_size)
        model.save(model_name)
        ok(model.summary())
        ok(f"Model saved in folder: {model_name}")
    elif args.command == 'tune':
        tune(model_name, datafile, config.hyperparameter_space, config.input_length, config.output_length,
             config.training_size,
             config.validation_size)
