export const percentage = (value) => {
  value = value*100
  return `${(value >= 0 ? '+' : '')}${value.toFixed(2)}%`
}

