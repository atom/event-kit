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
  # If a handler throws, then onHandlerException handlers are called.
  #
  # If a handler throws and setEnsureHandlerInvoke(true) has been called, then
  # the exception is considered handled, and any remaining handlers are invoked;
  # otherwise the caught exception is rethrown.
  #
  # * `eventName` The name of the event to emit. Handlers registered with {::on}
  #   for the same name will be invoked.
  # * `value` Callbacks will be invoked with this value as an argument.
  emit: (eventName, value) ->
    if handlers = @handlersByEventName?[eventName]
      Emitter.dispatch(handler, value) for handler in handlers
    return

  @emitter: new @()
  @ensureHandlerInvoke: false

  @simpleDispatch: (handler, value) ->
      handler(value)

  @complexDispatch: (handler, value) ->
    try
      handler(value)
    catch error
      Emitter.emitter.emit('handler-exception', error)
      if (not Emitter.ensureHandlerInvoke)
        throw error

  @dispatch: @simpleDispatch

  # Public: When set to true, all handlers will be invoked when emit is called.
  # When set to false, if a handler throws, then any remaining handlers are not
  # invoked and the exception is passed to the caller.
  #
  # Defaults to false.
  @setEnsureHandlerInvoke: (ensure) ->
    handlers = @emitter.handlersByEventName?['handler-exception']
    shouldUseComplexDispatch = ensure || (handlers && handlers.length > 0)
    @dispatch = if shouldUseComplexDispatch then @complexDispatch else @simpleDispatch
    Emitter.ensureHandlerInvoke = ensure

  # Public: Returns the current state of setEnsureHandlerInvoke.
  @isEnsureHandlerInvoke: -> Emitter.ensureHandlerInvoke

  # Public: Registers the given handler function to be invoked when any
  # invoked handler throws. This can be useful for debugging handlers.
  @onHandlerException: (handler) ->
    @dispatch = @complexDispatch
    @emitter.on('handler-exception', (error) ->
      try
        handler(error)
      catch error
        # Ensure we don't recurse on a buggy handler
    )
