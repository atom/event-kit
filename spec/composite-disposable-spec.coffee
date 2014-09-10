CompositeDisposable = require '../src/composite-disposable'
Disposable = require '../src/disposable'

describe "CompositeDisposable", ->
  [disposable1, disposable2, disposable3] = []

  beforeEach ->
    disposable1 = new Disposable
    disposable2 = new Disposable
    disposable3 = new Disposable

  it "can be constructed with multiple disposables", ->
    composite = new CompositeDisposable(disposable1, disposable2)
    composite.dispose()

    expect(composite.disposed).toBe true
    expect(disposable1.disposed).toBe true
    expect(disposable2.disposed).toBe true

  it "allows disposables to be added and removed", ->
    composite = new CompositeDisposable
    composite.add(disposable1)
    composite.add(disposable2)
    composite.add(disposable3)
    composite.remove(disposable2)

    composite.dispose()

    expect(composite.disposed).toBe true
    expect(disposable1.disposed).toBe true
    expect(disposable2.disposed).toBe false
    expect(disposable3.disposed).toBe true
