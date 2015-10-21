Disposable = require './disposable'

module.exports = class DOMEventListener extends Disposable
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
    super ->
      el.removeEventListener(type, wrapper, useCapture)
