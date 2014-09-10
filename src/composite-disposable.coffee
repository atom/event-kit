# Public: An object that aggregates multiple {Disposable} instances together
# into a single disposable, so they can all be disposed as a group.
module.exports =
class CompositeDisposable
  disposed: false

  # Public: Construct an instance, optionally with one or more
  constructor: ->
    @disposables = []
    @add(disposable) for disposable in arguments

  # Public: Add a disposable to be disposed when the composite is disposed.
  #
  # If this object has already been disposed, this method has no effect.
  #
  # * `disposable` {Disposable} instance or any object with a `.dispose()`
  #   method.
  add: (disposable) ->
    unless @disposed
      @disposables.push(disposable)

  # Public: Remove a previously added disposable.
  #
  # * `disposable` {Disposable} instance or any object with a `.dispose()`
  #   method.
  remove: (disposable) ->
    index = @disposables.indexOf(disposable)
    @disposables.splice(index, 1) if index isnt -1

  # Public: Dispose all disposables added to this composite disposable.
  #
  # If this object has already been disposed, this method has no effect.
  dispose: ->
    unless @disposed
      @disposed = true
      disposable.dispose() for disposable in @disposables
      @clear()

  # Public: Clear all disposables. They will not be disposed by the next call
  # to dispose.
  clear: ->
    @disposables.length = 0
