const Disposable = require("./disposable")
const CompositeDisposable = require("./composite-disposable")

// Essential: Utility class to be used when implementing event-based APIs that
// allows for handlers registered via `::on` to be invoked with calls to
// `::emit`. Instances of this class are intended to be used internally by
// classes that expose an event-based API.
//
// For example:
//
// ```js
// class User {
//   constructor() {
//     this.emitter = new Emitter()
//   }
//
//   onDidChangeName(callback) {
//     this.emitter.on('did-change-name', callback)
//   }
//
//   setName(name) {
//     if (name !== this.name) {
//       this.name = name
//       this.emitter.emit('did-change-name', name)
//     }
//
//     return this.name
//   }
// }
// ```
class Emitter {
  static onEventHandlerException(exceptionHandler) {
    if (this.exceptionHandlers.length === 0) {
      this.dispatch = this.exceptionHandlingDispatch
    }

    this.exceptionHandlers.push(exceptionHandler)

    return new Disposable(() => {
      this.exceptionHandlers.splice(
        this.exceptionHandlers.indexOf(exceptionHandler),
        1
      )
      if (this.exceptionHandlers.length === 0) {
        return (this.dispatch = this.simpleDispatch)
      }
    })
  }

  static simpleDispatch(handler, value) {
    return handler(value)
  }

  static exceptionHandlingDispatch(handler, value) {
    try {
      return handler(value)
    } catch (exception) {
      return this.exceptionHandlers.map(exceptionHandler =>
        exceptionHandler(exception)
      )
    }
  }

  /*
  Section: Construction and Destruction
  */

  // Public: Construct an emitter.
  //
  // ```js
  // this.emitter = new Emitter()
  // ```
  constructor() {
    this.disposed = false;
    this.clear();
  }

  // Public: Clear out any existing subscribers.
  clear() {
    if (this.subscriptions != null) {
      this.subscriptions.dispose()
    }
    this.subscriptions = new CompositeDisposable()
    this.handlersByEventName = {}
  }

  // Public: Unsubscribe all handlers.
  dispose() {
    this.subscriptions.dispose()
    this.handlersByEventName = null
    this.disposed = true
  }

  /*
   * Section: Event Subscription
   */

  // Public: Register the given handler function to be invoked whenever events by
  // the given name are emitted via {::emit}.
  //
  // * `eventName` {String} naming the event that you want to invoke the handler
  //   when emitted.
  // * `handler` {Function} to invoke when {::emit} is called with the given
  //   event name.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  on(eventName, handler, unshift) {
    if (unshift == null) {
      unshift = false
    }

    if (this.disposed) {
      throw new Error("Emitter has been disposed")
    }

    if (typeof handler !== "function") {
      throw new Error("Handler must be a function")
    }

    const currentHandlers = this.handlersByEventName[eventName]
    if (currentHandlers) {
      if (unshift) {
        this.handlersByEventName[eventName].unshift(handler)
      } else {
        this.handlersByEventName[eventName].push(handler)
      }
    } else {
      this.handlersByEventName[eventName] = [handler]
    }

    // When the emitter is disposed, we want to dispose of all subscriptions.
    // However, we also need to stop tracking disposables when they're disposed
    // from outside, otherwise this class will hold references to all the
    // disposables it created (instead of just the active ones).
    const cleanup = new Disposable(() => {
      this.subscriptions.remove(cleanup)
      return this.off(eventName, handler)
    })
    this.subscriptions.add(cleanup)
    return cleanup
  }

  // Public: Register the given handler function to be invoked the next time an
  // events with the given name is emitted via {::emit}.
  //
  // * `eventName` {String} naming the event that you want to invoke the handler
  //   when emitted.
  // * `handler` {Function} to invoke when {::emit} is called with the given
  //   event name.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  once(eventName, handler, unshift) {
    if (unshift == null) {
      unshift = false
    }

    const wrapped = function(value) {
      disposable.dispose()
      return handler(value)
    }

    const disposable = this.on(eventName, wrapped, unshift)
    return disposable
  }

  // Public: Register the given handler function to be invoked *before* all
  // other handlers existing at the time of subscription whenever events by the
  // given name are emitted via {::emit}.
  //
  // Use this method when you need to be the first to handle a given event. This
  // could be required when a data structure in a parent object needs to be
  // updated before third-party event handlers registered on a child object via a
  // public API are invoked. Your handler could itself be preempted via
  // subsequent calls to this method, but this can be controlled by keeping
  // methods based on `::preempt` private.
  //
  // * `eventName` {String} naming the event that you want to invoke the handler
  //   when emitted.
  // * `handler` {Function} to invoke when {::emit} is called with the given
  //   event name.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  preempt(eventName, handler) {
    return this.on(eventName, handler, true)
  }

  // Private: Used by the disposable.
  off(eventName, handlerToRemove) {
    if (this.disposed) {
      return
    }

    const handlers = this.handlersByEventName[eventName]
    if (handlers) {
      const handlerIndex = handlers.indexOf(handlerToRemove)
      if (handlerIndex >= 0) {
        handlers.splice(handlerIndex, 1)
      }
      if (handlers.length === 0) {
        delete this.handlersByEventName[eventName]
      }
    }
  }

  /*
   * Section: Event Emission
   */

  // Public: Invoke handlers registered via {::on} for the given event name.
  //
  // * `eventName` The name of the event to emit. Handlers registered with {::on}
  //   for the same name will be invoked.
  // * `value` Callbacks will be invoked with this value as an argument.
  emit(eventName, value) {
    const handlers =
      this.handlersByEventName && this.handlersByEventName[eventName]
    if (handlers) {
      // create a copy of `handlers` so that if any handler mutates `handlers`
      // (e.g. by calling `on` on this same emitter), this does not result in
      // changing the handlers being called during this same `emit`.
      const handlersCopy = handlers.slice()
      for (let i = 0; i < handlersCopy.length; i++) {
        this.constructor.dispatch(handlersCopy[i], value)
      }
    }
  }

  emitAsync(eventName, value) {
    const handlers =
      this.handlersByEventName && this.handlersByEventName[eventName]
    if (handlers) {
      const promises = handlers.map(handler =>
        this.constructor.dispatch(handler, value)
      )
      return Promise.all(promises).then(() => {})
    }
    return Promise.resolve()
  }

  getEventNames() {
    return Object.keys(this.handlersByEventName)
  }

  listenerCountForEventName(eventName) {
    const handlers = this.handlersByEventName[eventName]
    return handlers == null ? 0 : handlers.length
  }

  getTotalListenerCount() {
    let result = 0
    for (let eventName of Object.keys(this.handlersByEventName)) {
      result += this.handlersByEventName[eventName].length
    }
    return result
  }
}

Emitter.dispatch = Emitter.simpleDispatch
Emitter.exceptionHandlers = []
module.exports = Emitter
