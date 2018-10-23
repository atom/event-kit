const Disposable = require("../dist/disposable")

describe("Disposable", function() {
  it("does not try to execute disposalAction when it is not a function", function() {
    const disposalAction = {}
    const disposable = new Disposable(disposalAction)
    expect(disposable.disposalAction).toBe(disposalAction)

    disposable.dispose()
    expect(disposable.disposalAction).toBe(null)
  })

  it("dereferences the disposalAction once dispose() is invoked", function() {
    const disposalAction = jasmine.createSpy("dummy")
    const disposable = new Disposable(disposalAction)
    expect(disposable.disposalAction).toBe(disposalAction)

    disposable.dispose()
    expect(disposalAction.callCount).toBe(1)
    expect(disposable.disposalAction).toBe(null)

    disposable.dispose()
    expect(disposalAction.callCount).toBe(1)
  })

  it('can be extended by ES5-style classes', () => {
    function MyDisposable () {
      // super
      Disposable.apply(this, arguments)
    }

    MyDisposable.prototype = new Disposable()

    let actionCalled = false
    const disposable = new MyDisposable(() => { actionCalled = true })
    disposable.dispose()
    expect(actionCalled).toBe(true)
  })

  describe(".isDisposable(object)", () => {
    it("true if the object implements the ::dispose function", function() {
      expect(Disposable.isDisposable(new Disposable(function() {}))).toBe(true)
      expect(Disposable.isDisposable({ dispose() {} })).toBe(true)

      expect(Disposable.isDisposable(null)).toBe(false)
      expect(Disposable.isDisposable(undefined)).toBe(false)
      expect(Disposable.isDisposable({ foo() {} })).toBe(false)
      expect(Disposable.isDisposable({ dispose: 1 })).toBe(false)
    })
  })
})
