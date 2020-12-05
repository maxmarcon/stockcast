import matplotlib.pyplot as pyplot
import numpy as np
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import OneHotEncoder


def make_sets(array, training, validation):
    array_size = len(array)
    # TODO: add random sampling!
    return np.split(array, (int(array_size * training), int(array_size * (training + validation))))


def preprocess(data):
    close, dow = data['close'].to_numpy().reshape(-1, 1), data['day_of_week'].to_numpy().reshape(-1, 1)
    close_scaler = MinMaxScaler()
    close_scaler.fit(close)
    close_scaled = close_scaler.transform(close)
    data['close_scaled'] = close_scaled

    dow_onehot = OneHotEncoder(sparse=False).fit_transform(dow)
    for i in range(0, dow_onehot.shape[1]):
        data['dow_{}'.format(i)] = dow_onehot[:, i]

    return close_scaler


def plot_results(model, x_test, y_test, nof_samples=9):
    for i in range(0, nof_samples):
        pyplot.subplot(3, 3, i + 1, title='test sample {}'.format(i))

        predicted = model.predict(x_test[i].reshape(1, *x_test.shape[1:]))

        feature_x_range = range(0, x_test.shape[1])
        label_x_range = range(x_test.shape[1], x_test.shape[1] + y_test.shape[1])

        pyplot.plot(
            feature_x_range, x_test[i, :, 0], 'b.-',
            label_x_range, y_test[i], 'b.-',
            label_x_range, predicted[0], 'r.-'
        )
        pyplot.ylim(bottom=0)
        pyplot.grid(True)
    pyplot.show()
