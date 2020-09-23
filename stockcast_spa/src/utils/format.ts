export const percentage = (value: number | string): string => {
  if (typeof (value) === 'string') {
    value = parseFloat(value)
  }
  value *= 100
  return `${(value >= 0 ? '+' : '')}${value.toFixed(2)}%`
}
