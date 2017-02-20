(function () {
'use strict';

var Disposable$1;

Disposable$1 = (function() {
  Disposable.prototype.disposed = false;

  Disposable.isDisposable = function(object) {
    return typeof (object != null ? object.dispose : void 0) === "function";
  };


  /*
  Section: Construction and Destruction
   */

  function Disposable(disposalAction) {
    this.disposalAction = disposalAction;
  }

  Disposable.prototype.dispose = function() {
    if (!this.disposed) {
      this.disposed = true;
      if (typeof this.disposalAction === "function") {
        this.disposalAction();
      }
      this.disposalAction = null;
    }
  };

  return Disposable;

})();

var Emitter$1;

Emitter$1 = (function() {
  Emitter.exceptionHandlers = [];

  Emitter.onEventHandlerException = function(exceptionHandler) {
    if (this.exceptionHandlers.length === 0) {
      this.dispatch = this.exceptionHandlingDispatch;
    }
    this.exceptionHandlers.push(exceptionHandler);
    return new Disposable((function(_this) {
      return function() {
        _this.exceptionHandlers.splice(_this.exceptionHandlers.indexOf(exceptionHandler), 1);
        if (_this.exceptionHandlers.length === 0) {
          return _this.dispatch = _this.simpleDispatch;
        }
      };
    })(this));
  };

  Emitter.simpleDispatch = function(handler, value) {
    return handler(value);
  };

  Emitter.exceptionHandlingDispatch = function(handler, value) {
    var exception, exceptionHandler, i, len, ref, results;
    try {
      return handler(value);
    } catch (error) {
      exception = error;
      ref = this.exceptionHandlers;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        exceptionHandler = ref[i];
        results.push(exceptionHandler(exception));
      }
      return results;
    }
  };

  Emitter.dispatch = Emitter.simpleDispatch;

  Emitter.prototype.disposed = false;


  /*
  Section: Construction and Destruction
   */

  function Emitter() {
    this.clear();
  }

  Emitter.prototype.clear = function() {
    return this.handlersByEventName = {};
  };

  Emitter.prototype.dispose = function() {
    this.handlersByEventName = null;
    return this.disposed = true;
  };


  /*
  Section: Event Subscription
   */

  Emitter.prototype.on = function(eventName, handler, unshift) {
    var currentHandlers;
    if (unshift == null) {
      unshift = false;
    }
    if (this.disposed) {
      throw new Error("Emitter has been disposed");
    }
    if (typeof handler !== 'function') {
      throw new Error("Handler must be a function");
    }
    if (currentHandlers = this.handlersByEventName[eventName]) {
      if (unshift) {
        this.handlersByEventName[eventName] = [handler].concat(currentHandlers);
      } else {
        this.handlersByEventName[eventName] = currentHandlers.concat(handler);
      }
    } else {
      this.handlersByEventName[eventName] = [handler];
    }
    return new Disposable(this.off.bind(this, eventName, handler));
  };

  Emitter.prototype.preempt = function(eventName, handler) {
    return this.on(eventName, handler, true);
  };

  Emitter.prototype.off = function(eventName, handlerToRemove) {
    var handler, i, len, newHandlers, oldHandlers;
    if (this.disposed) {
      return;
    }
    if (oldHandlers = this.handlersByEventName[eventName]) {
      newHandlers = [];
      for (i = 0, len = oldHandlers.length; i < len; i++) {
        handler = oldHandlers[i];
        if (handler !== handlerToRemove) {
          newHandlers.push(handler);
        }
      }
      if (newHandlers.length > 0) {
        this.handlersByEventName[eventName] = newHandlers;
      } else {
        delete this.handlersByEventName[eventName];
      }
    }
  };


  /*
  Section: Event Emission
   */

  Emitter.prototype.emit = function(eventName, value) {
    var handler, handlers, i, len, ref;
    if (handlers = (ref = this.handlersByEventName) != null ? ref[eventName] : void 0) {
      for (i = 0, len = handlers.length; i < len; i++) {
        handler = handlers[i];
        this.constructor.dispatch(handler, value);
      }
    }
  };

  Emitter.prototype.getEventNames = function() {
    return Object.keys(this.handlersByEventName);
  };

  Emitter.prototype.listenerCountForEventName = function(eventName) {
    var ref, ref1;
    return (ref = (ref1 = this.handlersByEventName[eventName]) != null ? ref1.length : void 0) != null ? ref : 0;
  };

  Emitter.prototype.getTotalListenerCount = function() {
    var eventName, i, len, ref, result;
    result = 0;
    ref = Object.keys(this.handlersByEventName);
    for (i = 0, len = ref.length; i < len; i++) {
      eventName = ref[i];
      result += this.handlersByEventName[eventName].length;
    }
    return result;
  };

  return Emitter;

})();

window.Emitter = Emitter;

}());