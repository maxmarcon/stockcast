#!/usr/bin/env python
import argparse
import os.path
import shutil
from contextlib import nullcontext
from datetime import timedelta
from time import time

import matplotlib.pyplot as pyplot
import tensorflow.keras as keras
import yaml
from matplotlib.backends.backend_pdf import PdfPages

import utils
from utils import ok, warn, error


def fit(model, epochs, batch_size, loss_function, optimizer, validation_split, x_train, y_train, **kwargs):
    model.compile(optimizer=optimizer, loss=loss_function)
    return model.fit(x_train, y_train, shuffle=True, validation_split=validation_split, epochs=epochs,
                     batch_size=batch_size)


def tune(prefix, datafile, hyperparameter_space, input_length, output_length, training_size, validation_split,
         random_state, shuffle_data):
    total_models = utils.parameter_space_size(hyperparameter_space)
    trained_models = 0

    ok("{} models to train".format(total_models))

    tuning_state_filename = f'{prefix}.tuning'
    ok(f"Storing tuning state in: {tuning_state_filename}")
    tuning_state = utils.load_tuning_state(tuning_state_filename)
    if tuning_state is not None:
        warn(f'Resuming interrupted tuning session with {len(tuning_state)} trained models')

    try:
        for hyperparameters in utils.enumerate_parameter_space(hyperparameter_space):
            if utils.contains_tuning_state(tuning_state, hyperparameters):
                warn("Skipping parameters: {}".format(hyperparameters))
            else:
                ok("Training and validating model with parameters {}".format(hyperparameters))
                ok(f"{total_models - trained_models} models left to go")
                if tuning_state is not None:
                    time_left = timedelta(seconds=tuning_state.mean()['time'] * (total_models - trained_models))
                    ok(f"Approx. {time_left} left")

                model, history, training_time = train(datafile, hyperparameters, input_length, output_length,
                                                      training_size,
                                                      validation_split, random_state, shuffle_data, silent=True)
                try:
                    pass
                except KeyboardInterrupt:
                    warn("Received interrupt from keyboard, saving tuning state first")
                    raise
                finally:
                    tuning_state = utils.save_tuning_state(tuning_state, hyperparameters,
                                                           {'loss': history.history['loss'][-1],
                                                            'val_loss': history.history['val_loss'][-1]},
                                                           training_time,
                                                           tuning_state_filename)
            trained_models = trained_models + 1
        warn("Tuning completed, results stored in: {}".format(tuning_state_filename))
    except KeyboardInterrupt:
        warn("Tuning interrupted by user, tuning state saved in: {}".format(tuning_state_filename))


def train(datafile, hyperparameters, input_length, output_length, training_size, validation_split, random_state,
          shuffle_data, silent=False, **kwargs):
    feature_columns = hyperparameters['feature_columns']
    data = utils.load_data(datafile, feature_columns, input_length,
                           output_length,
                           training_size, random_state, shuffle_data)
    model = utils.make_model(input_length, len(feature_columns), output_length,
                             **hyperparameters)
    start = time()
    if not silent:
        ok(f"training and validating model with parameters:\n\n{hyperparameters}")

    history = fit(model, **hyperparameters, **data, validation_split=validation_split)
    training_time = time() - start
    return model, history, training_time


def evaluate(model, datafile, output_file, feature_columns, input_length, output_length, training_size, random_state,
             shuffle_data, pdf=False, **kwargs):
    data = utils.load_data(datafile, feature_columns, input_length,
                           output_length,
                           training_size, random_state, shuffle_data=shuffle_data)
    metric_results = model.evaluate(data['x_test'], data['y_test'])
    if type(metric_results) != list:
        metric_results = [metric_results]

    metric_summary = ', '.join(map(lambda a, b: a + f"={b:.4f}", model.metrics_names, metric_results))
    print(metric_summary)

    data = utils.load_data(datafile, feature_columns, input_length,
                           output_length,
                           training_size, random_state, labels_starting_on_weekday=0, shuffle_data=shuffle_data)

    with PdfPages(output_file) if pdf else nullcontext() as pdf_file:
        if not pdf:
            fig, axes = pyplot.subplots(2, 1)
            fig.suptitle(metric_summary)
            fig.set_tight_layout(True)

        for (plot_num, (title, dates, x, y)) in enumerate(zip(('Training set', 'Test set'),
                                                              ('dates_train', 'dates_test'),
                                                              ('x_train', 'x_test'),
                                                              ('y_train', 'y_test'))):

            if pdf:
                fig, axes = pyplot.subplots()
                fig.suptitle(metric_summary)

            utils.plot_results(axes if pdf else axes[plot_num], title, data[dates],
                               data['rescaler'].inverse_transform(model.predict(data[x])),
                               data['rescaler'].inverse_transform(data[y]), show_xticks=(x == 'x_test'))

            if pdf:
                pdf_file.savefig(fig)

        if not pdf:
            pyplot.show()


def add_common_args(arg_parser, which=('datafile', 'configfile', 'no-shuffle')):
    if 'datafile' in which:
        arg_parser.add_argument('datafile',
                                help="Input data file")
    if 'configfile' in which:
        arg_parser.add_argument('configfile', help="The config file (yaml)")


def evaluate_command(model_name, pdf=False, shuffle_data=True):
    ok(f"Loading model from {model_name}")
    model = keras.models.load_model(model_name)
    assets_folder = os.path.join(model_name, "assets")
    datafile = os.path.join(assets_folder, "data.csv")
    config_file = os.path.join(assets_folder, 'config.yaml')
    config, _ = load_config(config_file)
    if shuffle_data != config['shuffle_data']:
        config['shuffle_data'] = shuffle_data
    output_file = os.path.join(assets_folder, 'results.pdf')
    ok(f"Features are: {config['feature_columns']}")
    evaluate(model, datafile, output_file, **config, pdf=pdf)


def train_command(configfile, datafile, hp_index, model_prefix_override=None):
    config, prefix = load_config(configfile)

    model_name = model_prefix_override if model_prefix_override else prefix
    model_name = f'{model_name}-{hp_index}' if hp_index is not None else model_name

    if os.path.exists(model_name):
        error(f'Model {model_name} already exists!')
        exit(1)

    tuning_file = f'{prefix}.tuning'

    ok(f'Reading tuning state from {tuning_file}')
    if hp_index is None:
        hp_index = utils.load_optimal_hyperparameters_index(tuning_file)
        ok(f'Loading hyperparameters that minimize val_loss (found at position {hp_index})')
    ok(f'Loading hyperparameters at position {hp_index}')
    hyperparameters = utils.load_hyperparameters(tuning_file, hp_index)
    hyperparameters['feature_columns'] = hyperparameters['feature_columns'].split(',')
    model, *_ = train(datafile, hyperparameters, **config)
    model.save(model_name)
    model.summary()
    ok(f"Model saved to folder: {model_name}")
    asset_folder = os.path.join(model_name, 'assets')
    shutil.copy(datafile, os.path.join(asset_folder, 'data.csv'))
    shutil.copy(tuning_file, os.path.join(asset_folder, 'tuning.csv'))
    config['hp_index'] = int(hp_index)
    config['feature_columns'] = hyperparameters['feature_columns']
    with open(os.path.join(asset_folder, 'config.yaml'), 'w') as fd:
        yaml.dump(config, fd)
    ok(f"Data, tuning and config files copied to {asset_folder}")


def tune_command(configfile, datafile):
    config, prefix = load_config(configfile)

    tune(prefix, datafile, **config)


def load_config(configfile):
    ok(f"Loading config from {configfile}")
    with open(configfile, 'r') as fd:
        return yaml.safe_load(fd), os.path.splitext(configfile)[0]


if __name__ == '__main__':

    arg_parser = argparse.ArgumentParser()
    subparsers = arg_parser.add_subparsers(dest='command', required=True)
    tune_parser = subparsers.add_parser('tune', help="Tune hyperparameters")
    add_common_args(tune_parser)

    train_parser = subparsers.add_parser('train', help="Train a model")
    add_common_args(train_parser)
    train_parser.add_argument('--hp-index', '-hp',
                              help="Hyperparameters index - if not provided, the optimal hyperparameters will be used",
                              type=int)
    train_parser.add_argument('--model-prefix', '-mp', help="Model prefix to use - defaults to config filename prefix")

    evaluate_parser = subparsers.add_parser('evaluate', aliases=('eval',), help='Evaluate a model')
    evaluate_parser.add_argument('model', help='Model to evaluate')
    evaluate_parser.add_argument('--pdf', action='store_true', help='Store results as pdf')
    evaluate_parser.add_argument('--no-shuffle', action='store_true')

    args = arg_parser.parse_args()

    if args.command in ('evaluate', 'eval'):
        evaluate_command(args.model, pdf=args.pdf, shuffle_data=not args.no_shuffle)
    elif args.command == 'train':
        train_command(args.configfile, args.datafile, args.hp_index, args.model_prefix)
    elif args.command == 'tune':
        tune_command(args.configfile, args.datafile)
