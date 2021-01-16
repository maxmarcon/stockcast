#!/usr/bin/env python
import argparse
from time import time

import tensorflow.keras.models as kmodels

import utils


def train(model, epochs, batch_size, x_train, y_train, x_val, y_val, **kwargs):
    model.compile(optimizer='adam', loss='mean_squared_error')
    return model.fit(x_train, y_train, shuffle=True, validation_data=(x_val, y_val), epochs=epochs,
                     batch_size=batch_size)


def tune(model_name, datafile, input_length, output_length, training_size, validation_size):
    total_models = len(feature_columns) * len(dropout_rates) * len(layer_sizes) * len(nof_hidden_layers)

    print("{} models to train".format(total_models))

    tuning_state_filename = utils.tuning_state_filename(model_name)
    print("storing tuning state in: {}".format(tuning_state_filename))
    dataframe = utils.load_tuning_state(tuning_state_filename)
    if dataframe is not None:
        print("resuming interrupted tuning session with {} trained models".format(len(dataframe)))

    try:
        for features in feature_columns:
            for dropout_rate in dropout_rates:
                for layer_size in layer_sizes:
                    for hidden_layers in nof_hidden_layers:
                        parameters = {
                            'features': features,
                            'dropout_rate': dropout_rate,
                            'layer_size': layer_size,
                            'hidden_layers': hidden_layers
                        }
                        if utils.contains_tuning_state(dataframe, parameters):
                            print("skipping parameters: {}".format(parameters))
                        else:
                            print("validating model with parameters {}".format(parameters))

                            data = utils.prepare_data(datafile, parameters['features'], input_length, output_length,
                                                      training_size, validation_size)
                            model = utils.make_model(input_length, len(parameters['features']), output_length,
                                                     **parameters)
                            start = time()
                            history = train(model, epochs, batch_size, **data)
                            training_time = time() - start
                            try:
                                pass
                            except KeyboardInterrupt:
                                print("received interrupt from keyboard, saving tuning state first")
                                raise
                            finally:
                                dataframe = utils.save_tuning_state(dataframe, parameters,
                                                                    {'loss': history.history['loss'][-1],
                                                                     'val_loss': history.history['val_loss'][-1]},
                                                                    training_time,
                                                                    model_name)
        print("tuning completed, results stored in: {}".format(tuning_state_filename))
    except KeyboardInterrupt:
        print("tuning interrupted by user, tuning state saved in: {}".format(tuning_state_filename))


def evaluate(model, x_test, y_test, dates_test, rescaler, **kwargs):
    metric_results = model.evaluate(x_test, y_test)
    if type(metric_results) != list:
        metric_results = [metric_results]
    for r in map(lambda a, b: a + ": " + str(b), model.metrics_names, metric_results):
        print(r)
    utils.plot_results(dates_test, rescaler.inverse_transform(model.predict(x_test)),
                       rescaler.inverse_transform(y_test))


if __name__ == '__main__':

    training_size = 0.7
    validation_size = 0.15
    epochs = 30
    batch_size = 30
    input_length = 60
    output_length = 5

    ## tuning_state
    feature_columns = [
        ['close_scaled', 'day_of_week'],
        ['close_scaled'],
        ['close_scaled', *['dow_{}'.format(i) for i in range(0, 6)]]
    ]
    dropout_rates = [0.0, 0.1, 0.2]
    optimizer = ['adam']
    loss = ['mean_squared_error']
    layer_sizes = [10, 20, 30, 40, 50, 100]
    nof_hidden_layers = [1, 2, 3, 4, 5]

    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('command', choices=('tune', 'train', 'evaluate', 'save'))
    arg_parser.add_argument('datafile')
    arg_parser.add_argument('--model', '-m', required=True)

    # subparsers = arg_parser.add_subparsers(dest="command", required=True)
    # 
    # parser_load = subparsers.add_parser('evaluate')
    # parser_load.add_argument('datafile')
    # # parser_load.add_argument('--model', '-m', required=True)
    # 
    # parser_train = subparsers.add_parser('train')
    # parser_train.add_argument('datafile')
    # # parser_load.add_argument('--model', '-m', required=True)
    # 
    # parser_train = subparsers.add_parser('tune')
    # parser_train.add_argument('datafile')
    # # parser_load.add_argument('--model', '-m', required=True)
    # 
    # parser_save = subparsers.add_parser('save')
    # parser_save.add_argument('datafile')
    # # parser_save.add_argument('--model', '-m', required=True)

    args = arg_parser.parse_args()

    print("Loading data...")

    data = utils.prepare_data(
        args.datafile, feature_columns[0], input_length, output_length, training_size, validation_size)

    print("Training set has size {}, validation set has size {}, test set has size {}".format(len(data['x_train']),
                                                                                              len(data['x_val']),
                                                                                              len(data['x_test'])))
    if args.command == 'evaluate':
        print('loading model from {}'.format(args.model))
        model = kmodels.load_model(args.model)
        evaluate(kmodels.load_model(args.model), **data)
    elif args.command == 'train':
        model = utils.make_model(len(feature_columns), output_length, 50, 5)
        train(model, epochs, batch_size, **data)
        model.save(args.model)
    elif args.command == 'tune':
        tune(args.model, args.datafile, input_length, output_length, training_size, validation_size)
    else:
        raise RuntimeError("Unimplemented command {}".format(args.command))
