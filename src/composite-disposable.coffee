Disposable = null

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
        disposable.dispose()
      @disposables = null
    return

  ###
  Section: Managing Disposables
  ###

  # Public: Add disposables to be disposed when the composite is disposed.
  #
  # If this object has already been disposed, this method has no effect.
  #
  # * `...disposables` {Disposable} instances or any objects with `.dispose()`
  #   methods.
  add: ->
    unless @disposed
      for disposable in arguments by 1
        assertDisposable(disposable)
        @disposables.add(disposable)
    return

  # Public: Remove a previously added disposable.
  #
  # * `disposable` {Disposable} instance or any object with a `.dispose()`
  #   method.
  remove: (disposable) ->
    @disposables.delete(disposable) unless @disposed
    return

  # Public: Alias to remove
  delete: (disposable) ->
    @remove(disposable)
    return

  # Public: Clear all disposables. They will not be disposed by the next call
  # to dispose.
  clear: ->
    @disposables.clear() unless @disposed
    return

assertDisposable = (disposable) ->
  Disposable ?= require './disposable'
  unless Disposable.isDisposable(disposable)
    throw new TypeError('Arguments to CompositeDisposable.add must have a .dispose() method')
  return
