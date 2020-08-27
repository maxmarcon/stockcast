export const percentage = (value) => {
  value = parseFloat(value) * 100
  return `${(value >= 0 ? '+' : '')}${value.toFixed(2)}%`
}

