Emitter = require '../src/emitter'

describe "Emitter", ->
  it "invokes the observer when the named event is emitted until disposed", ->
    emitter = new Emitter

    fooEvents = []
    barEvents = []

    sub1 = emitter.on 'foo', (value) -> fooEvents.push(['a', value])
    sub2 = emitter.on 'bar', (value) -> barEvents.push(['b', value])
    sub3 = emitter.preempt 'bar', (value) -> barEvents.push(['c', value])

    emitter.emit 'foo', 1
    emitter.emit 'foo', 2
    emitter.emit 'bar', 3

    sub1.dispose()

    emitter.emit 'foo', 4
    emitter.emit 'bar', 5

    sub2.dispose()

    emitter.emit 'bar', 6

    expect(fooEvents).toEqual [['a', 1], ['a', 2]]
    expect(barEvents).toEqual [['c', 3], ['b', 3], ['c', 5], ['b', 5], ['c', 6]]

  it "throws an exception when subscribing with a callback that isn't a function", ->
    emitter = new Emitter
    expect(-> emitter.on('foo', null)).toThrow()
    expect(-> emitter.on('foo', 'a')).toThrow()

  it "allows all subsribers to be cleared out at once", ->
    emitter = new Emitter
    events = []

    emitter.on 'foo', (value) -> events.push(['a', value])
    emitter.preempt 'foo', (value) -> events.push(['b', value])
    emitter.clear()

    emitter.emit 'foo', 1
    emitter.emit 'foo', 2
    expect(events).toEqual []

  describe "when a handler throws an exception", ->
    describe "when no exception handlers are registered on Emitter", ->
      it "throws exceptions as normal, stopping subsequent handlers from firing", ->
        emitter = new Emitter
        handler2Fired = false

        emitter.on 'foo', -> throw new Error()
        emitter.on 'foo', -> handler2Fired = true

        expect(-> emitter.emit 'foo').toThrow()
        expect(handler2Fired).toBe false

    describe "when exception handlers are registered on Emitter", ->
      it "invokes the exception handlers in the order they were registered and continues to fire subsequent event handlers", ->
        emitter = new Emitter
        handler2Fired = false

        emitter.on 'foo', -> throw new Error('bar')
        emitter.on 'foo', -> handler2Fired = true

        errorHandlerInvocations = []
        disposable1 = Emitter.onEventHandlerException (error) ->
          expect(error.message).toBe 'bar'
          errorHandlerInvocations.push(1)

        disposable2 = Emitter.onEventHandlerException (error) ->
          expect(error.message).toBe 'bar'
          errorHandlerInvocations.push(2)

        emitter.emit 'foo'

        expect(errorHandlerInvocations).toEqual [1, 2]
        expect(handler2Fired).toBe true

        errorHandlerInvocations = []
        handler2Fired = false

        disposable1.dispose()
        emitter.emit 'foo'
        expect(errorHandlerInvocations).toEqual [2]
        expect(handler2Fired).toBe true

        errorHandlerInvocations = []
        handler2Fired = false

        disposable2.dispose()
        expect(-> emitter.emit 'foo').toThrow()
        expect(errorHandlerInvocations).toEqual []
        expect(handler2Fired).toBe false
