let CompositeDisposable
let Disposable

// Essential: An object that aggregates multiple {Disposable} instances together
// into a single disposable, so they can all be disposed as a group.
//
// These are very useful when subscribing to multiple events.
//
// ## Examples
//
// ```js
// const {CompositeDisposable} = require('atom')
//
// class Something {
//   constructor() {
//     this.disposables = new CompositeDisposable()
//     const editor = atom.workspace.getActiveTextEditor()
//     this.disposables.add(editor.onDidChange(() => {})
//     this.disposables.add(editor.onDidChangePath(() => {})
//   }
//
//   destroy() {
//     this.disposables.dispose();
//   }
// }
// ```
module.exports = class CompositeDisposable {
  /*
   * Section: Construction and Destruction
   */

  // Public: Construct an instance, optionally with one or more disposables
  constructor() {
    this.disposed = false
    this.disposables = new Set()
    for (let disposable of arguments) {
      this.add(disposable)
    }
  }

  // Public: Dispose all disposables added to this composite disposable.
  //
  // If this object has already been disposed, this method has no effect.
  dispose() {
    if (!this.disposed) {
      this.disposed = true
      this.disposables.forEach(disposable => disposable.dispose())
      this.disposables = null
    }
  }

  /*
   * Section: Managing Disposables
   */

  // Public: Add disposables to be disposed when the composite is disposed.
  //
  // If this object has already been disposed, this method has no effect.
  //
  // * `...disposables` {Disposable} instances or any objects with `.dispose()`
  //   methods.
  add() {
    if (!this.disposed) {
      for (const disposable of arguments) {
        assertDisposable(disposable)
        this.disposables.add(disposable)
      }
    }
  }

  // Public: Remove a previously added disposable.
  //
  // * `disposable` {Disposable} instance or any object with a `.dispose()`
  //   method.
  remove(disposable) {
    if (!this.disposed) {
      this.disposables.delete(disposable)
    }
  }

  // Public: Alias to {CompositeDisposable::remove}
  delete(disposable) {
    this.remove(disposable)
  }

  // Public: Clear all disposables. They will not be disposed by the next call
  // to dispose.
  clear() {
    if (!this.disposed) {
      this.disposables.clear()
    }
  }
}

function assertDisposable(disposable) {
  if (Disposable == null) {
    Disposable = require("./disposable")
  }

  if (!Disposable.isDisposable(disposable)) {
    throw new TypeError(
      "Arguments to CompositeDisposable.add must have a .dispose() method"
    )
  }
}
