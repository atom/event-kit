[CompositeDisposable, Disposable] = []

# Essential: Map-based equivalent of a {CompositeDisposable}.
#
# Helpful alternative to managing several CompositeDisposable
# instances, which can be referenced or disposed from the same
# object.
#
# ## Examples
#
# ```coffee
# {MappedDisposable} = require 'atom'
#
# class Something
#   constructor: ->
#     @disposables = new MappedDisposable
#     editor = atom.workspace.getActiveTextEditor()
#     @disposables.set "editor-changed", editor.onDidChange ->
#     @disposables.set "path-changed", editor.onDidChangePath ->
#
#     # CompositeDisposables work well with objects as keys:
#     onChangeText = editor.onDidChange ->
#     onChangePath = editor.onDidChangePath ->
#     @disposables.set editor, new CompositeDisposable(onChangeText, onChangePath)
#     @disposables.add editor, editor.onDidDestroy ->
#       @disposables.dispose editor
#
#   destroy: ->
#     @disposables.dispose()
# ```
module.exports =
class MappedDisposable
  disposed: false

  ###
  Section: Construction and Destruction
  ###

  # Public: Create a new instance, optionally with a list of keys and disposables.
  constructor: (iterable) ->
    @disposables = new Map()
    CompositeDisposable ?= require './composite-disposable'
    if iterable?
      for entry in iterable
        [key, value] = entry
        unless value instanceof CompositeDisposable
          value = new CompositeDisposable value
        @disposables.set key, value

  # Public: Delete keys and dispose of their values.
  #
  # * `...keys` Keys to dispose of. If none are passed, the method disposes of
  #             everything, rendering the instance completely inert.
  dispose: ->
    return if @disposed
    if arguments.length
      for key in arguments by 1
        disposable = @disposables.get key
        if typeof key?.dispose is 'function'
          key.dispose()
        if disposable
          disposable.dispose()
          @disposables.delete key
    else
      @disposed = true
      @disposables.forEach (value, key) ->
        value.dispose()
        if typeof key?.dispose is 'function'
          key.dispose()
      @disposables.clear()
      @disposables = null
    return


  ###
  Section: Managing Disposables
  ###

  # Public: Key one or more {Disposable} instances to an object.
  #
  # * `key`
  # * `...disposables`
  add: (key, disposables...) ->
    return if @disposed
    if keyDisposables = @disposables.get(key)
      for disposable in disposables
        keyDisposables.add(disposable)
    else
      @disposables.set key, new CompositeDisposable(disposables...)
    return

  # Public: Remove a {Disposable} from an object's disposables list.
  #
  # If no disposables are passed, the object itself is removed from the
  # MappedDisposable. Any disposables keyed to it are not disposed of.
  #
  # * `key`
  # * `...disposables`
  remove: (key, disposables...) ->
    return if @disposed

    if disposable = @disposables.get key
      # Remove specific disposables if any were provided
      if disposables.length
        for unwantedDisposable in disposables
          disposable.remove unwantedDisposable

      # Otherwise, remove the keyed object itself
      else @disposables.delete key

    return

  # Public: Alias of {MappedDisposable::remove}, included for parity with Map objects.
  delete: (key, disposables...) ->
    @remove(key, disposables...)

  # Public: Clear the MappedDisposable's contents. Disposables keyed to objects are not disposed of.
  clear: ->
    @disposables.clear() unless @disposed

  # Public: Number of entries (key/disposable pairs) stored in the instance.
  Object.defineProperty @::, 'size',
    get: -> if @disposed then 0 else @disposables.size

  # Public: Determine if an entry with the given key exists in the MappedDisposable.
  has: (key) ->
    return false if @disposed
    @disposables.has key

  # Public: Retrieve the disposables list keyed to an object.
  #
  # Returns a {CompositeDisposable} instance, or `undefined` if
  # the MappedDisposable has been disposed of.
  get: (key) ->
    return if @disposed
    @disposables.get key

  # Public: Replace the {Disposable} keyed to an object.
  #
  # Throws a TypeError if the object lacks a `dispose` method.
  set: (key, value) ->
    return if @disposed
    Disposable ?= require './disposable'
    unless Disposable.isDisposable value
      throw new TypeError('Value must have a .dispose() method')
    @disposables.set key, value
