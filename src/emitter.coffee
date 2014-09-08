Disposable = require './disposable'

# Public: Utility class to be used when implementing event-based APIs that
# allows for handlers registered via `::on` to be invoked with calls to
# `::emit`. Instances of this class are intended to be used internally by
# classes that expose an event-based API.
#
# For example:
#
# ```coffee
# class User
#   constructor: ->
#     @emitter = new Emitter
#
#   onDidChangeName: (callback) ->
#     @emitter.on 'did-change-name', callback
#
#   setName: (name) ->
#     if name isnt @name
#       @name = name
#       @emitter.emit 'did-change-name', name
#     @name
# ```
module.exports =
class Emitter
  isDisposed: false

  constructor: ->
    @handlersByEventName = {}

  # Public: Register the given handler function to be invoked whenever events by
  # the given name are emitted via {::emit}.
  #
  # * `eventName` {String} naming the event that you want to invoke the handler
  #   when emitted.
  # * `handler` {Function} to invoke when {::emit} is called with the given
  #   event name.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  on: (eventName, handler) ->
    if @isDisposed
      throw new Error("Emitter has been disposed")

    if typeof handler isnt 'function'
      throw new Error("Handler must be a function")

    if currentHandlers = @handlersByEventName[eventName]
      @handlersByEventName[eventName] = currentHandlers.concat(handler)
    else
      @handlersByEventName[eventName] = [handler]

    new Disposable(@off.bind(this, eventName, handler))

  # Public: Invoke handlers registered via {::on} for the given event name.
  #
  # * `eventName` The name of the event to emit. Handlers registered with {::on}
  #   for the same name will be invoked.
  # * `value` Callbacks will be invoked with this value as an argument.
  emit: (eventName, value) ->
    if handlers = @handlersByEventName?[eventName]
      handler(value) for handler in handlers

  # Public: Unsubscribe all handlers.
  dispose: ->
    @handlersByEventName = null
    @isDisposed = true

  off: (eventName, handlerToRemove) ->
    return if @isDisposed

    if oldHandlers = @handlersByEventName[eventName]
      newHandlers = []
      for handler in oldHandlers when handler isnt handlerToRemove
        newHandlers.push(handler)
      @handlersByEventName[eventName] = newHandlers
