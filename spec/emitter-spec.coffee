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

  it "allows the listeners to be inspected", ->
    emitter = new Emitter

    disposable1 = emitter.on 'foo', ->
    expect(emitter.getEventNames()).toEqual ['foo']
    expect(emitter.listenerCountForEventName('foo')).toBe(1)
    expect(emitter.listenerCountForEventName('bar')).toBe(0)
    expect(emitter.getTotalListenerCount()).toBe(1)

    disposable2 = emitter.on 'bar', ->
    expect(emitter.getEventNames()).toEqual ['foo', 'bar']
    expect(emitter.listenerCountForEventName('foo')).toBe(1)
    expect(emitter.listenerCountForEventName('bar')).toBe(1)
    expect(emitter.getTotalListenerCount()).toBe(2)

    emitter.preempt 'foo', ->
    expect(emitter.getEventNames()).toEqual ['foo', 'bar']
    expect(emitter.listenerCountForEventName('foo')).toBe(2)
    expect(emitter.listenerCountForEventName('bar')).toBe(1)
    expect(emitter.getTotalListenerCount()).toBe(3)

    disposable1.dispose()
    expect(emitter.getEventNames()).toEqual ['foo', 'bar']
    expect(emitter.listenerCountForEventName('foo')).toBe(1)
    expect(emitter.listenerCountForEventName('bar')).toBe(1)
    expect(emitter.getTotalListenerCount()).toBe(2)

    disposable2.dispose()
    expect(emitter.getEventNames()).toEqual ['foo']
    expect(emitter.listenerCountForEventName('foo')).toBe(1)
    expect(emitter.listenerCountForEventName('bar')).toBe(0)
    expect(emitter.getTotalListenerCount()).toBe(1)

    emitter.clear()
    expect(emitter.getTotalListenerCount()).toBe(0)

  describe "::once", ->
    it "only invokes the handler once", ->
      emitter = new Emitter
      firedCount = 0
      emitter.once 'foo', -> firedCount += 1
      emitter.emit 'foo'
      emitter.emit 'foo'
      expect(firedCount).toBe 1

    it "invokes the handler with the emitted value", ->
      emitter = new Emitter
      emittedValue = null
      emitter.once 'foo', (value) -> emittedValue = value
      emitter.emit 'foo', 'bar'
      expect(emittedValue).toBe 'bar'

  describe "dispose", ->
    it "disposes of all listeners", ->
      emitter = new Emitter
      disposable1 = emitter.on 'foo', ->
      disposable2 = emitter.once 'foo', ->
      emitter.dispose()
      expect(disposable1.disposed).toBe true
      expect(disposable2.disposed).toBe true

    it "doesn't keep track of disposed disposables", ->
      emitter = new Emitter
      disposable = emitter.on 'foo', ->
      expect(emitter.subscriptions.disposables.size).toBe 1
      disposable.dispose()
      expect(emitter.subscriptions.disposables.size).toBe 0

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

  describe "::emitAsync", ->
    it "resolves when all of the promises returned by handlers have resolved", ->
      emitter = new Emitter

      resolveHandler1 = null
      resolveHandler3 = null
      disposable1 = emitter.on 'foo', -> new Promise((resolve) -> resolveHandler1 = resolve)
      disposable2 = emitter.on 'foo', -> return
      disposable3 = emitter.on 'foo', -> new Promise((resolve) -> resolveHandler3 = resolve)

      result = emitter.emitAsync 'foo'

      waitsFor (done) ->
        resolveHandler3()
        resolveHandler1()
        result.then (result) ->
          expect(result).toBeUndefined()
          done()

    it "rejects when any of the promises returned by handlers reject", ->
      emitter = new Emitter

      rejectHandler1 = null
      disposable1 = emitter.on 'foo', -> new Promise((resolve, reject) -> rejectHandler1 = reject)
      disposable2 = emitter.on 'foo', -> return
      disposable3 = emitter.on 'foo', -> new Promise((resolve) ->)

      result = emitter.emitAsync 'foo'

      waitsFor (done) ->
        rejectHandler1(new Error('Something bad happened'))
        result.catch (error) ->
          expect(error.message).toBe('Something bad happened')
          done()
