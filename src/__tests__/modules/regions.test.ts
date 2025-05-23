import Regions from '../../model/regions'

describe('Regions', () => {
  it('should add #1', async () => {
    let r = new Regions()
    r.add(1, 2)
    r.add(2, 1)
    expect(r.current).toEqual([1, 2])
  })

  it('should add #2', async () => {
    let r = new Regions()
    r.add(3, 4)
    r.add(1, 5)
    expect(r.current).toEqual([1, 5])
  })

  it('should add #3', async () => {
    let r = new Regions()
    r.add(2, 3)
    r.add(1, 2)
    expect(r.current).toEqual([1, 3])
  })

  it('should add #4', async () => {
    let r = new Regions()
    r.add(2, 5)
    r.add(3, 4)
    expect(r.current).toEqual([2, 5])
  })

  it('should add #5', async () => {
    let r = new Regions()
    r.add(3, 4)
    r.add(1, 5)
    expect(r.current).toEqual([1, 5])
  })

  it('should add #6', async () => {
    let r = new Regions()
    r.add(1, 2)
    r.add(3, 5)
    expect(r.current).toEqual([1, 5])
    r.add(1, 8)
    expect(r.current).toEqual([1, 8])
  })

  it('should add #7', async () => {
    let r = new Regions()
    r.add(1, 2)
    r.add(1, 5)
    expect(r.current).toEqual([1, 5])
    r.add(9, 10)
    r.add(5, 6)
    expect(r.current).toEqual([1, 6, 9, 10])
  })

  it('should check range', async () => {
    let r = new Regions()
    r.add(1, 2)
    r.add(1, 5)
    expect(r.has(3, 5)).toBe(true)
    expect(r.has(3, 6)).toBe(false)
    r.add(6, 8)
    expect(r.has(1, 8)).toBe(true)
  })

  it('should get range', async () => {
    let r = new Regions()
    r.add(1, 2)
    r.add(1, 5)
    expect(r.isEmpty).toBe(false)
    expect(r.getRange(8)).toBeUndefined()
    expect(r.getRange(9)).toBeUndefined()
    expect(r.getRange(1)).toEqual([1, 5])
    expect(r.getRange(5)).toEqual([1, 5])
  })

  it('should get uncovered range', async () => {
    let r = new Regions()
    expect(r.toUncoveredSpan([1, 2], 3, 10)).toEqual([0, 5])
    r.add(0, 5)
    expect(r.toUncoveredSpan([1, 2], 3, 10)).toBeUndefined()
    r.add(8, 10)
    expect(r.toUncoveredSpan([4, 6], 3, 20)).toEqual([5, 8])
  })

  it('should merge spans', async () => {
    expect(Regions.mergeSpans([[0, 1], [1, 2]])).toEqual([[0, 2]])
    expect(Regions.mergeSpans([[0, 1], [2, 3]])).toEqual([[0, 1], [2, 3]])
    expect(Regions.mergeSpans([[2, 3], [0, 1]])).toEqual([[2, 3], [0, 1]])
    expect(Regions.mergeSpans([[1, 4], [0, 5]])).toEqual([[0, 5]])
    expect(Regions.mergeSpans([[1, 4], [2, 3]])).toEqual([[1, 4]])
    expect(Regions.mergeSpans([[1, 2], [2, 3], [3, 4]])).toEqual([[1, 4]])
  })
})
