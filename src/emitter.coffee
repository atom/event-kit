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
  @exceptionHandlers: []

  @onEventHandlerException: (exceptionHandler) ->
    if @exceptionHandlers.length is 0
      @dispatch = @exceptionHandlingDispatch

    @exceptionHandlers.push(exceptionHandler)

    new Disposable =>
      @exceptionHandlers.splice(@exceptionHandlers.indexOf(exceptionHandler), 1)
      if @exceptionHandlers.length is 0
        @dispatch = @simpleDispatch

  @simpleDispatch: (handler, value) ->
    handler(value)

  @exceptionHandlingDispatch: (handler, value) ->
    try
      handler(value)
    catch exception
      for exceptionHandler in @exceptionHandlers
        exceptionHandler(exception)

  @dispatch: @simpleDispatch

  disposed: false

  ###
  Section: Construction and Destruction
  ###

  # Public: Construct an emitter.
  #
  # ```coffee
  # @emitter = new Emitter()
  # ```
  constructor: ->
    @clear()

  # Public: Clear out any existing subscribers.
  clear: ->
    @handlersByEventName = {}

  # Public: Unsubscribe all handlers.
  dispose: ->
    @handlersByEventName = null
    @disposed = true

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
    if @disposed
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

  # Public: Register the given handler function to be invoked only once whenever
  # the next by the given name are emitted via {::emit}. After being invoked,
  # will automatically be unsubscribed.
  #
  # * `eventName` {String} naming the event that you want to invoke the handler
  #   when emitted.
  # * `handler` {Function} to invoke when {::emit} is called with the given
  #   event name.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  once: (eventName, handler, unshift=false) ->
    if typeof handler isnt 'function'
      throw new Error("Handler must be a function")

    subscription = null
    wrappedHandler = (value) ->
      handler(value)
      subscription.dispose()

    subscription = @on(eventName, wrappedHandler, unshift)

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

  # Public: Register the given handler function to be invoked *before* all
  # other handlers existing at the time of subscription only once the next time
  # events by the given name are emitted via {::emit}. After being invoked, it
  # will automatically be unsubscribed.
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
  preemptOnce: (eventName, handler) ->
    @once(eventName, handler, true)

  # Private: Used by the disposable.
  off: (eventName, handlerToRemove) ->
    return if @disposed

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
      for handler in handlers
        @constructor.dispatch(handler, value)
    return
