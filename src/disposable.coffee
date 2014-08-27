module.exports =
class Disposable
  isDisposed: false

  constructor: (@onDisposed) ->

  dispose: ->
    unless @isDisposed
      @isDisposed = true
      @onDisposed?()
