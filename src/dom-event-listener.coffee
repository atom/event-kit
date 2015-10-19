Disposable = require './disposable'

module.exports = class DOMEventListener
  constructor: (el, type, cb, {useCapture, delegationTarget, once}={}) ->
    unless el instanceof EventTarget
      throw new TypeError('Failed to create DOMEventListener: parameter 1 is not of type EventTarget')

    wrapper = (event) =>
      if delegationTarget
        {target} = event
        while !target.matches(delegationTarget) && target != el
          target = target.parentNode
        if target != el
          @dispose() if once
          cb.call(target, event)
      else
        @dispose() if once
        cb.call(el, event)

    el.addEventListener(type, wrapper, useCapture)
    @disposable = new Disposable ->
      el.removeEventListener(type, wrapper, useCapture)

  dispose: ->
    @disposable.dispose()
    return
