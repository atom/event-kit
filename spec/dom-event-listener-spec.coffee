DOMEventListener = require '../src/dom-event-listener'

dispatchEvent = (target=document.body) ->
  target.dispatchEvent new MouseEvent 'click', {bubbles: true}

describe "DOMEventListener", ->
  listener = null
  counter = 0

  beforeEach ->
    listener?.dispose?()
    counter = 0

  it "should throw a TypeError when the provided target is not an instance of EventTarget", ->
    error = null
    try
      listener = new DOMEventListener {}, 'click', ->
        counter++
    catch e
      error = e
    expect(error instanceof TypeError).toBeTruthy()

  describe "when no options are provided", ->
    beforeEach ->
      listener = new DOMEventListener document.body, 'click', ->
        counter++

    it "registers an event listener with a DOM element", ->
      dispatchEvent()
      expect(counter).toEqual(1)

    it "removes the event listener when the dispose method is called", ->
      listener.dispose()
      dispatchEvent()
      expect(counter).toEqual(0)

  describe "when the once option is enabled", ->
    beforeEach ->
      listener = new DOMEventListener document.body, 'click', ->
        counter++
      , once: true

    it "will dispose itself the first time the event is triggered", ->
      dispatchEvent()
      dispatchEvent()
      expect(counter).toEqual(1)

  describe "when a delegationTarget is provided", ->
    delegationTarget = null

    beforeEach ->
      delegationTarget = document.createElement('div')
      delegationTarget.classList.add('delegation-target')
      document.body.appendChild(delegationTarget)
      window.listener = listener = new DOMEventListener document.body, 'click', ->
        counter++
      , delegationTarget: '.delegation-target'

    it "should call the callback only when the event is triggered on the delegation target", ->
      dispatchEvent()
      dispatchEvent(delegationTarget)
      expect(counter).toEqual(1)
