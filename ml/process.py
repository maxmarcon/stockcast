import numpy as np
import pandas as pd
import tensorflow.keras as keras
import tensorflow.keras.layers as layers
from tensorflow.keras.layers.experimental.preprocessing import Normalization

data = pd.read_csv('prices-AMZ-GY-2020-01-01-2020-11-21.csv')
input_data = np.array(data[['day_of_week', 'close']])

normalization_layer = Normalization()
normalization_layer.adapt(input_data)
print(normalization_layer(input_data))

model = keras.Sequential([
    layers.Input((None, 2)),
    layers.LSTM(10)
])

model(input_data)
