Disposable = require '../src/disposable'

describe "Disposable", ->
  it "does not try to execute disposalAction when it is not a function", ->
    disposalAction = {}
    disposable = new Disposable(disposalAction)
    expect(disposable.disposalAction).toBe disposalAction

    disposable.dispose()
    expect(disposable.disposalAction).toBe null

  it "dereferences the disposalAction once dispose() is invoked", ->
    disposalAction = jasmine.createSpy("dummy")
    disposable = new Disposable(disposalAction)
    expect(disposable.disposalAction).toBe disposalAction

    disposable.dispose()
    expect(disposalAction.callCount).toBe 1
    expect(disposable.disposalAction).toBe null

    disposable.dispose()
    expect(disposalAction.callCount).toBe 1
