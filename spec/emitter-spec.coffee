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

  it "Does throw when an observer throws and no ensureHandlerInvoke", ->
    emitter = new Emitter
    hadThrow = false

    sub = emitter.on 'bar', (value) -> throw new Error()
    try
      emitter.emit 'bar', 1
    catch error
      hadThrow = true
    sub.dispose()

    expect(hadThrow).toBe true

  it "isEnsureHandlerInvoke", ->
    expect(Emitter.isEnsureHandlerInvoke()).toBe(false)
    Emitter.setEnsureHandlerInvoke(true)
    expect(Emitter.isEnsureHandlerInvoke()).toBe(true)
    Emitter.setEnsureHandlerInvoke(false)
    expect(Emitter.isEnsureHandlerInvoke()).toBe(false)

  it "Does not throw when an observer throws and ensureHandlerInvoke", ->
    Emitter.setEnsureHandlerInvoke(true)
    emitter = new Emitter
    hadThrow = false

    sub = emitter.on 'bar', (value) -> throw new Error()
    try
      emitter.emit 'bar', 1
    catch error
      hadThrow = true
    sub.dispose()

    expect(hadThrow).toBe false
    Emitter.setEnsureHandlerInvoke(false)

  it "Invokes onHandlerException when a handler throws", ->
    emitter = new Emitter
    hadUncaughtException = false

    Emitter.setEnsureHandlerInvoke(true)
    uncaughtException = (error) -> hadUncaughtException = true
    subUncaught = Emitter.onHandlerException(uncaughtException)

    sub = emitter.on 'bar', (value) -> throw new Error()
    emitter.emit 'bar', 1

    sub.dispose()
    subUncaught.dispose()
    Emitter.setEnsureHandlerInvoke(false)
    expect(hadUncaughtException).toBe true

  it "invokes all observers even when one observer throws", ->
    emitter = new Emitter
    barEvents = []

    Emitter.setEnsureHandlerInvoke(true)
    sub1 = emitter.on 'bar', (value) -> barEvents.push(value)
    sub2 = emitter.on 'bar', (value) -> throw new Error()
    sub3 = emitter.on 'bar', (value) -> barEvents.push(value * value)

    emitter.emit 'bar', 1
    emitter.emit 'bar', 2
    emitter.emit 'bar', 3

    sub1.dispose()
    sub2.dispose()
    sub3.dispose()
    Emitter.setEnsureHandlerInvoke(false)

    expect(barEvents).toEqual [1, 1, 2, 4, 3, 9]

  it "throw from uncaughtHandler handler terminates", ->
    Emitter.setEnsureHandlerInvoke(true)
    uncaughtException = (value) -> throw new Error()
    subUncaught = Emitter.onHandlerException(uncaughtException)

    emitter = new Emitter
    sub = emitter.on 'bar', (value) -> throw new Error()
    emitter.emit 'bar', 1

    sub.dispose()
    subUncaught.dispose()
    Emitter.setEnsureHandlerInvoke(false)
