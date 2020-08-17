import {percentage} from "@/utils/format";

describe('percentage', () => {

  it('should format correctly', () => {

    expect(percentage(0)).toBe("+0.00%")
    expect(percentage(0.1234)).toBe("+0.12%")
    expect(percentage(20.1234)).toBe("+20.12%")
    expect(percentage(0.126)).toBe("+0.13%")
    expect(percentage(200.12345)).toBe("+200.12%")

    expect(percentage(-0)).toBe("+0.00%")
    expect(percentage(-0.1234)).toBe("-0.12%")
    expect(percentage(-20.1234)).toBe("-20.12%")
    expect(percentage(-0.126)).toBe("-0.13%")
    expect(percentage(-200.12345)).toBe("-200.12%")
  })
})
