import numpy as np
import pandas as pd
from tensorflow.keras.layers.experimental.preprocessing import Normalization

data = pd.read_csv('../prices-AMZ-GY-2020-01-01-2020-11-21.csv')
nparray = np.array(data[['day_of_week', 'close']])

normalization_layer = Normalization()
normalization_layer.adapt(nparray)
print(normalization_layer(nparray))
