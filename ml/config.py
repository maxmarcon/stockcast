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
