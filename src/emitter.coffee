Disposable = require './disposable'

# Essential: Utility class to be used when implementing event-based APIs that
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

  ###
  Section: Construction and Destruction
  ###

  # Public: Construct an emitter.
  #
  # ```coffee
  # @emitter = new Emitter()
  # ```
  constructor: ->
    @handlersByEventName = {}

  # Public: Unsubscribe all handlers.
  dispose: ->
    @handlersByEventName = null
    @isDisposed = true

  ###
  Section: Event Subscription
  ###

  # Public: Register the given handler function to be invoked whenever events by
  # the given name are emitted via {::emit}.
  #
  # * `eventName` {String} naming the event that you want to invoke the handler
  #   when emitted.
  # * `handler` {Function} to invoke when {::emit} is called with the given
  #   event name.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  on: (eventName, handler, unshift=false) ->
    if @isDisposed
      throw new Error("Emitter has been disposed")

    if typeof handler isnt 'function'
      throw new Error("Handler must be a function")

    if currentHandlers = @handlersByEventName[eventName]
      if unshift
        @handlersByEventName[eventName] = [handler].concat(currentHandlers)
      else
        @handlersByEventName[eventName] = currentHandlers.concat(handler)
    else
      @handlersByEventName[eventName] = [handler]

    new Disposable(@off.bind(this, eventName, handler))

  # Public: Register the given handler function to be invoked *before* all
  # other handlers existing at the time of subscription whenever events by the
  # given name are emitted via {::emit}.
  #
  # Use this method when you need to be the first to handle a given event. This
  # could be required when a data structure in a parent object needs to be
  # updated before third-party event handlers registered on a child object via a
  # public API are invoked. Your handler could itself be preempted via
  # subsequent calls to this method, but this can be controlled by keeping
  # methods based on `::preempt` private.
  #
  # * `eventName` {String} naming the event that you want to invoke the handler
  #   when emitted.
  # * `handler` {Function} to invoke when {::emit} is called with the given
  #   event name.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  preempt: (eventName, handler) ->
    @on(eventName, handler, true)

  # Private: Used by the disposable.
  off: (eventName, handlerToRemove) ->
    return if @isDisposed

    if oldHandlers = @handlersByEventName[eventName]
      newHandlers = []
      for handler in oldHandlers when handler isnt handlerToRemove
        newHandlers.push(handler)
      @handlersByEventName[eventName] = newHandlers
    return

  ###
  Section: Event Emission
  ###

  # Public: Invoke handlers registered via {::on} for the given event name.
  #
  # * `eventName` The name of the event to emit. Handlers registered with {::on}
  #   for the same name will be invoked.
  # * `value` Callbacks will be invoked with this value as an argument.
  emit: (eventName, value) ->
    if handlers = @handlersByEventName?[eventName]
      handler(value) for handler in handlers
    return
