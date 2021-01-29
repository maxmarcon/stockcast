#!/usr/bin/env python
import argparse
from datetime import timedelta
from time import time

import tensorflow.keras.models as kmodels

import utils
from utils import ok, warn


def train(model, epochs, batch_size, loss_function, optimizer, x_train, y_train, x_val, y_val, **kwargs):
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
        for hyeperparameters in utils.enumerate_parameter_space(hyperparameter_space):
            if utils.contains_tuning_state(tuning_state, hyeperparameters):
                warn("skipping parameters: {}".format(hyeperparameters))
            else:
                ok("training and validating model with parameters {}".format(hyeperparameters))
                ok(f"{total_models - trained_models} models left to go")
                if tuning_state is not None:
                    time_left = timedelta(seconds=tuning_state.mean()['time'] * (total_models - trained_models))
                    ok(f"approx. {time_left} left")

                data = utils.prepare_data(datafile, hyeperparameters['feature_columns'], input_length,
                                          output_length,
                                          training_size, validation_size)
                model = utils.make_model(input_length, len(hyeperparameters['feature_columns']), output_length,
                                         **hyeperparameters)
                start = time()
                history = train(model, **hyeperparameters, **data)
                training_time = time() - start
                try:
                    pass
                except KeyboardInterrupt:
                    warn("received interrupt from keyboard, saving tuning state first")
                    raise
                finally:
                    tuning_state = utils.save_tuning_state(tuning_state, hyeperparameters,
                                                           {'loss': history.history['loss'][-1],
                                                            'val_loss': history.history['val_loss'][-1]},
                                                           training_time,
                                                           model_name)
            trained_models = trained_models + 1
        warn("tuning completed, results stored in: {}".format(tuning_state_filename))
    except KeyboardInterrupt:
        warn("tuning interrupted by user, tuning state saved in: {}".format(tuning_state_filename))


def evaluate(model, x_test, y_test, dates_test, rescaler, **kwargs):
    metric_results = model.evaluate(x_test, y_test)
    if type(metric_results) != list:
        metric_results = [metric_results]
    for r in map(lambda a, b: a + ": " + str(b), model.metrics_names, metric_results):
        print(r)
    utils.plot_results(dates_test, rescaler.inverse_transform(model.predict(x_test)),
                       rescaler.inverse_transform(y_test))


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
    subparsers = arg_parser.add_subparsers(dest='command')
    tune = subparsers.add_parser('tune', help="Tune hyperparameters")
    
    train = subparsers.add_parser('train', help="Train a model")
    train.add_argument('--index', '-i', help="Hyperparameters index")


    args = arg_parser.parse_args()
    ok(f"Loading data from {args.datafile}...")

    feature_columns = hyperparameter_space['feature_columns']

    data = utils.prepare_data(
        args.datafile, feature_columns[0], input_length, output_length, training_size, validation_size)

    ok(f"Training set has size {len(data['x_train'])}, validation set has size {len(data['x_val'])}, test set has size {len(data['x_test'])}")

    if args.command == 'evaluate':
        model = kmodels.load_model(args.model)
        evaluate(kmodels.load_model(args.model), **data)
    elif args.command == 'train':
        model = utils.make_model(len(feature_columns), output_length, 50, 5)
        train(model, hyperparameter_space['epochs'][0], hyperparameter_space['batch_size'][0], **data)
        model.save(args.model)
    elif args.command == 'tune':
        tune(args.model, args.datafile, hyperparameter_space, input_length, output_length, training_size,
             validation_size)
    else:
        raise RuntimeError("Unimplemented command {}".format(args.command))
