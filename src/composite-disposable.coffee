# Essential: An object that aggregates multiple {Disposable} instances together
# into a single disposable, so they can all be disposed as a group.
#
# These are very useful when subscribing to multiple events.
#
# ## Examples
#
# ```coffee
# {CompositeDisposable} = require 'atom'
#
# class Something
#   constructor: ->
#     @disposables = new CompositeDisposable
#     editor = atom.workspace.getActiveTextEditor()
#     @disposables.add editor.onDidChange ->
#     @disposables.add editor.onDidChangePath ->
#
#   destroy: ->
#     @disposables.dispose()
# ```
module.exports =
class CompositeDisposable
  disposed: false

  ###
  Section: Construction and Destruction
  ###

  # Public: Construct an instance, optionally with one or more disposables
  constructor: ->
    @disposables = new Set
    @add(disposable) for disposable in arguments

  # Public: Dispose all disposables added to this composite disposable.
  #
  # If this object has already been disposed, this method has no effect.
  dispose: ->
    unless @disposed
      @disposed = true
      @disposables.forEach (disposable) ->
        disposable.dispose() if disposable?
      @disposables = null
    return

  ###
  Section: Managing Disposables
  ###

  # Public: Add a disposable to be disposed when the composite is disposed.
  #
  # If this object has already been disposed, this method has no effect.
  #
  # * `disposable` {Disposable} instance or any object with a `.dispose()`
  #   method.
  add: (disposable) ->
    @disposables.add(disposable) unless @disposed
    return

  # Public: Remove a previously added disposable.
  #
  # * `disposable` {Disposable} instance or any object with a `.dispose()`
  #   method.
  remove: (disposable) ->
    @disposables.delete(disposable) unless @disposed
    return

  # Public: Clear all disposables. They will not be disposed by the next call
  # to dispose.
  clear: ->
    @disposables.clear() unless @disposed
    return
