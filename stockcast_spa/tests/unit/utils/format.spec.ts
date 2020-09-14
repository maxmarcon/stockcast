import {percentage} from "@/utils/format";

describe('percentage', () => {

  it('should format correctly', () => {

    expect(percentage(0)).toBe("+0.00%")
    expect(percentage(0.1234)).toBe("+12.34%")
    expect(percentage(0.126)).toBe("+12.60%")

    expect(percentage(-0.1234)).toBe("-12.34%")
    expect(percentage(-0.126)).toBe("-12.60%")

    expect(percentage("0")).toBe("+0.00%")
    expect(percentage("0.1234")).toBe("+12.34%")
    expect(percentage("0.126")).toBe("+12.60%")

    expect(percentage("-0.1234")).toBe("-12.34%")
    expect(percentage("-0.126")).toBe("-12.60%")
  })
})
