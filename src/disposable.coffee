Grim = require 'grim'

module.exports =
class Disposable
  isDisposed: false

  constructor: (@onDisposed) ->

  dispose: ->
    unless @isDisposed
      @isDisposed = true
      @onDisposed?()

  off: ->
    Grim.deprecate("Use ::dispose to cancel subscriptions instead of ::off")
    @dispose()
