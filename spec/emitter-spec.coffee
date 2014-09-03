Emitter = require '../src/emitter'

describe "Emitter", ->
  it "invokes the observer when the named event is emitted until disposed", ->
    emitter = new Emitter

    fooEvents = []
    barEvents = []

    sub1 = emitter.on 'foo', (value) -> fooEvents.push(value)
    sub2 = emitter.on 'bar', (value) -> barEvents.push(value)

    emitter.emit 'foo', 1
    emitter.emit 'foo', 2
    emitter.emit 'bar', 3

    sub1.dispose()

    emitter.emit 'foo', 4
    emitter.emit 'bar', 5

    sub2.dispose()

    emitter.emit 'bar', 6

    expect(fooEvents).toEqual [1, 2]
    expect(barEvents).toEqual [3, 5]

  it "throws an exception when subscribing with a callback that isn't a function", ->
    emitter = new Emitter
    expect(-> emitter.on('foo', null)).toThrow()
    expect(-> emitter.on('foo', 'a')).toThrow()
