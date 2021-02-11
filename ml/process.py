#!/usr/bin/env python
import argparse
import json
import os.path
import shutil
from contextlib import nullcontext
from datetime import timedelta
from time import time

import matplotlib.pyplot as pyplot
import tensorflow.keras as keras
from matplotlib.backends.backend_pdf import PdfPages

import config
import utils
from utils import ok, warn, error


def fit(model, epochs, batch_size, loss_function, optimizer, x_train, y_train, x_val, y_val, **kwargs):
    model.compile(optimizer=optimizer, loss=loss_function)
    return model.fit(x_train, y_train, shuffle=True, validation_data=(x_val, y_val), epochs=epochs,
                     batch_size=batch_size)


def tune(model_name, datafile, hyperparameter_space, input_length, output_length, training_size, validation_size):
    total_models = utils.parameter_space_size(hyperparameter_space)
    trained_models = 0

    ok("{} models to train".format(total_models))

    tuning_state_filename = utils.generate_tuning_state_filename(model_name, datafile)
    ok("Storing tuning state in: {}".format(tuning_state_filename))
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
                                                      validation_size, silent=True)
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

    history = fit(model, **hyperparameters, **data)
    training_time = time() - start
    return model, history, training_time


def evaluate(model, datafile, output_file, feature_columns, input_length, output_length, training_size,
             validation_size, pdf=False):
    data = utils.prepare_data(datafile, feature_columns, input_length,
                              output_length,
                              training_size, validation_size)
    metric_results = model.evaluate(data['x_test'], data['y_test'])
    if type(metric_results) != list:
        metric_results = [metric_results]

    metric_summary = ', '.join(map(lambda a, b: a + f"={b:.4f}", model.metrics_names, metric_results))
    print(metric_summary)

    data = utils.prepare_data(datafile, feature_columns, input_length,
                              output_length,
                              training_size, validation_size, labels_starting_on_weekday=0)

    with PdfPages(output_file) if pdf else nullcontext() as pdf_file:
        if not pdf:
            fig, axes = pyplot.subplots(3, 1)
            fig.suptitle(metric_summary)
            fig.set_tight_layout(True)

        for (plot_num, (title, dates, x, y)) in enumerate(zip(('Training set', 'Validation set', 'Test set'),
                                                              ('dates_train', 'dates_val', 'dates_test'),
                                                              ('x_train', 'x_val', 'x_test'),
                                                              ('y_train', 'y_val', 'y_test'))):

            if pdf:
                fig, axes = pyplot.subplots()
                fig.suptitle(metric_summary)

            utils.plot_results(axes if pdf else axes[plot_num], title, data[dates],
                               data['rescaler'].inverse_transform(model.predict(data[x])),
                               data['rescaler'].inverse_transform(data[y]), minor_xtics=(x != 'x_train'))

            if pdf:
                pdf_file.savefig(fig)

        if not pdf:
            pyplot.show()


def add_common_args(arg_parser, which=('datafile', 'model')):
    if 'datafile' in which:
        arg_parser.add_argument('datafile',
                                help="Input data file")
    if 'model' in which:
        arg_parser.add_argument('model', help="The model name")


def evaluate_command(model_name, pdf=False):
    ok(f"Loading model from {model_name}")
    model = keras.models.load_model(model_name)
    assets_folder = os.path.join(model_name, "assets")
    datafile = os.path.join(assets_folder, "data")
    metadata_file = os.path.join(assets_folder, 'metadata.json')
    output_file = os.path.join(assets_folder, 'results.pdf')
    with open(metadata_file, 'r') as fd:
        metadata = json.load(fd)
    ok(f"Features are: {metadata['feature_columns']}")
    evaluate(model, datafile, output_file, metadata['feature_columns'], metadata['input_length'],
             metadata['output_length'],
             metadata['training_size'], metadata['validation_size'], pdf=pdf)


def train_command(model_name, datafile, tuning_file, hp_index):
    if os.path.exists(model_name):
        error(f'{model_name} already exists. Please delete it or use a different name')
        exit(1)

    ok(f'Loading tuning state from {tuning_file}')
    if hp_index is None:
        hp_index = utils.load_optimal_hyperparameters_index(tuning_file)
        ok(f'Loading hyperparameters that minimize val_loss (found at position {hp_index})')
    ok(f'Loading hyperparameters at position {hp_index}')
    ok(f"Loading data from {datafile}")
    hyperparameters = utils.load_hyperparameters(tuning_file, hp_index)
    model, *rest = train(datafile, hyperparameters, config.input_length, config.output_length,
                         config.training_size,
                         config.validation_size)
    model.save(model_name)
    model.summary()
    ok(f"Model saved to folder: {model_name}")
    asset_folder = os.path.join(model_name, 'assets')
    datafile = shutil.copy(datafile, asset_folder)
    os.symlink(os.path.basename(datafile), os.path.join(os.path.dirname(datafile), 'data'))
    tuning_file = shutil.copy(tuning_file, asset_folder)
    os.symlink(os.path.basename(tuning_file), os.path.join(os.path.dirname(tuning_file), 'tuning'))
    with open(os.path.join(asset_folder, "metadata.json"), 'w') as fd:
        metadata = dict(
            input_length=config.input_length,
            output_length=config.output_length,
            training_size=config.training_size,
            validation_size=config.validation_size,
            feature_columns=hyperparameters['feature_columns'].split(','),
            hp_index=int(hp_index)
        )
        json.dump(metadata, fd)
    ok(f"Datafile, tuning file and metadata copied to {asset_folder}")


def tune_command(model_name, datafile):
    ok(f"Loading data from {datafile}")
    tune(model_name, datafile, config.hyperparameter_space, config.input_length, config.output_length,
         config.training_size,
         config.validation_size)


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
    train_parser.add_argument('tuning_file', help='File keeping tuning state')

    evaluate_parser = subparsers.add_parser('evaluate', aliases=('eval',), help='Evaluate a model')
    add_common_args(evaluate_parser, ('model',))
    evaluate_parser.add_argument('--pdf', action='store_true', help='Store results as pdf')

    args = arg_parser.parse_args()

    if args.command in ('evaluate', 'eval'):
        evaluate_command(args.model, pdf=args.pdf)
    elif args.command == 'train':
        train_command(args.model, args.datafile, args.tuning_file, args.hp_index)
    elif args.command == 'tune':
        tune_command(args.model, args.datafile)
