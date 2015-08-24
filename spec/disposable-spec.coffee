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

  describe ".isDisposable(object)", ->
    it "returns true if the object implements the ::dispose function", ->
      expect(Disposable.isDisposable(new Disposable(->))).toBe(true)
      expect(Disposable.isDisposable({dispose: ->})).toBe(true)

      expect(Disposable.isDisposable(null)).toBe(false)
      expect(Disposable.isDisposable(undefined)).toBe(false)
      expect(Disposable.isDisposable({foo: ->})).toBe(false)
      expect(Disposable.isDisposable({dispose: 1})).toBe(false)
