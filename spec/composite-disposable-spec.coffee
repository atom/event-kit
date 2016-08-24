CompositeDisposable = require '../src/composite-disposable'
Disposable = require '../src/disposable'

describe "CompositeDisposable", ->
  [disposable1, disposable2, disposable3, destroyable1, destroyable2, destroyable3] = []

  beforeEach ->
    disposable1 = new Disposable
    disposable2 = new Disposable
    disposable3 = new Disposable
    destroyable = class
      constructor: ->
        @disposed = false
      destroy: ->
        @disposed = true

    destroyable1 = new destroyable()
    destroyable2 = new destroyable()
    destroyable3 = new destroyable()

  it "can be constructed with multiple disposables", ->
    composite = new CompositeDisposable(disposable1, disposable2)
    composite.dispose()

    expect(composite.disposed).toBe true
    expect(disposable1.disposed).toBe true
    expect(disposable2.disposed).toBe true

  it "tolerates falsy things", ->
    composite = new CompositeDisposable(null, null, undefined, undefined)
    composite.dispose()

    expect(composite.disposed).toBe true

  it "allows disposables to be added and removed", ->
    composite = new CompositeDisposable
    composite.add(disposable1)
    composite.add(disposable2, disposable3)
    composite.remove(disposable2)

    composite.dispose()

    expect(composite.disposed).toBe true
    expect(disposable1.disposed).toBe true
    expect(disposable2.disposed).toBe false
    expect(disposable3.disposed).toBe true

  it "can be constructed with multiple destroyables", ->
    composite = new CompositeDisposable(destroyable1, destroyable2)
    composite.dispose()

    expect(composite.disposed).toBe true
    expect(destroyable1.disposed).toBe true
    expect(destroyable2.disposed).toBe true

  it "allows destroyables to be added and removed", ->
    composite = new CompositeDisposable
    composite.add(destroyable1)
    composite.add(destroyable2, destroyable3)
    composite.remove(destroyable2)

    composite.dispose()

    expect(composite.disposed).toBe true
    expect(destroyable1.disposed).toBe true
    expect(destroyable2.disposed).toBe false
    expect(destroyable3.disposed).toBe true

  it "can be constructed with destroyables and disposables", ->
    composite = new CompositeDisposable(destroyable1, destroyable2, disposable1, disposable2)
    composite.dispose()

    expect(composite.disposed).toBe true
    expect(destroyable1.disposed).toBe true
    expect(destroyable2.disposed).toBe true
    expect(disposable1.disposed).toBe true
    expect(disposable2.disposed).toBe true
