CompositeDisposable = require '../src/composite-disposable'
Disposable = require '../src/disposable'
MappedDisposable = require '../src/mapped-disposable'

describe 'MappedDisposable', ->
  it 'can be constructed with an iterable', ->
    disposable1 = new Disposable
    disposable2 = new Disposable
    disposable3 = new CompositeDisposable
    map = new MappedDisposable [
      [{name: 'foo'}, disposable1]
      [{name: 'bar'}, disposable2]
      [{name: 'baz'}, disposable3]
    ]
    map.dispose()
    expect(disposable1.disposed).toBe true
    expect(disposable2.disposed).toBe true
    expect(disposable3.disposed).toBe true

  it 'can be constructed without an iterable', ->
    map = new MappedDisposable
    expect(map.disposed).toBe false
    map.dispose()
    expect(map.disposed).toBe true

  it 'embeds ordinary disposables in CompositeDisposables', ->
    disposable1 = new Disposable
    disposable2 = new CompositeDisposable
    map = new MappedDisposable [
      ['foo', disposable1],
      ['bar', disposable2]
    ]
    expect(map.get('foo')).toBeInstanceOf CompositeDisposable
    expect(map.get('bar')).toBe disposable2

  it 'allows disposables to be added to keys', ->
    key = {}
    cd1 = new CompositeDisposable
    cd2 = new CompositeDisposable
    cd3 = new CompositeDisposable
    map = new MappedDisposable [[key, cd1]]
    expect(map.get(key)).toBe cd1
    map.add key, cd2
    expect(cd1.disposables.size).toBe 1
    map.add 'foo', cd3
    expect(map.size).toBe 2
    map.dispose()
    expect(map.disposed).toBe true
    expect(cd1.disposed).toBe true
    expect(cd2.disposed).toBe true

  it 'allows disposables to be used as keys', ->
    calledIt = false
    toldYou = false
    disposableKey = new Disposable -> calledIt = true
    disposableValue = new Disposable -> toldYou = true
    map = new MappedDisposable [[disposableKey, disposableValue]]

    expect(map.size).toBe 1
    expect(calledIt).toBe false
    expect(toldYou).toBe false
    expect(disposableKey.disposed).toBe false
    expect(disposableValue.disposed).toBe false

    map.dispose()
    expect(map.size).toBe 0
    expect(disposableKey.disposed).toBe true
    expect(disposableValue.disposed).toBe true
    expect(calledIt).toBe true
    expect(toldYou).toBe true

  it "calls a key's dispose() method when disposing it", ->
    foo = false
    bar = false
    fooDis = new Disposable -> foo = true
    barDat = new Disposable -> bar = true
    map = new MappedDisposable
    map.set 'foo', fooDis
    map.set 'bar', barDat

    expect(map.size).toBe 2
    expect(foo).toBe false
    expect(bar).toBe false
    expect(fooDis.disposed).toBe false
    expect(barDat.disposed).toBe false

    map.dispose 'foo'
    expect(map.size).toBe 1
    expect(foo).toBe true
    expect(bar).toBe false
    expect(fooDis.disposed).toBe true
    expect(barDat.disposed).toBe false
    expect(map.has('foo')).toBe false

  it 'allows disposables to be removed from keys', ->
    key = {}
    cd1 = new CompositeDisposable
    cd2 = new CompositeDisposable
    cd3 = new CompositeDisposable
    cd4 = new CompositeDisposable
    cd5 = new CompositeDisposable
    map = new MappedDisposable [[key, cd1]]
    map.add key, cd2, cd3, cd4, cd5
    expect(cd1.disposables.size).toBe 4
    map.remove key, cd3, cd5
    expect(cd1.disposables.size).toBe 2
    map.dispose()
    expect(map.disposed).toBe true
    expect(cd1.disposed).toBe true
    expect(cd2.disposed).toBe true
    expect(cd3.disposed).toBe false
    expect(cd4.disposed).toBe true
    expect(cd5.disposed).toBe false

  it 'allows other MappedDisposables to be added to keys', ->
    disposable = new Disposable
    map1 = new MappedDisposable [['foo', disposable]]
    map2 = new MappedDisposable [['bar', map1]]
    expect(map1.get('foo').disposables.has(disposable)).toBe true
    expect(map2.get('bar').disposables.has(map1)).toBe true
    map2.dispose()
    expect(disposable.disposed).toBe true
    expect(map1.disposed).toBe true
    expect(map2.disposed).toBe true
  
  it 'reports accurate entry count', ->
    map = new MappedDisposable
    expect(map.size).toBe 0
    map.add 'foo', new Disposable
    expect(map.size).toBe 1
    map.add 'foo', new Disposable
    map.add 'bar', new Disposable
    expect(map.size).toBe 2
    map.delete 'foo'
    expect(map.size).toBe 1
    map.dispose()
    expect(map.size).toBe 0
  
  it 'deletes keys when disposing them', ->
    key = {}
    cd1 = new CompositeDisposable
    map = new MappedDisposable [[key, cd1]]
    map.delete key
    expect(map.has(key)).toBe false
    expect(map.get(key)).toBe undefined
    map.dispose()
    expect(cd1.disposed).toBe false
  
  it 'deletes all keys when disposed', ->
    map = new MappedDisposable [
      ['foo', new Disposable]
      ['bar', new Disposable]
    ]
    expect(map.has('foo')).toBe true
    expect(map.has('bar')).toBe true
    map.dispose()
    expect(map.has('foo')).toBe false
    expect(map.has('bar')).toBe false
    expect(map.size).toBe 0

  it 'allows a disposable list to be replaced with another', ->
    cd1 = new CompositeDisposable
    cd2 = new CompositeDisposable
    key = {}
    map = new MappedDisposable [[key, cd1]]
    map.set key, cd2
    expect(map.get(key)).toBe cd2
    expect(map.get(key).disposables.has(cd1)).toBe false
    map.dispose()
    expect(cd1.disposed).toBe false
    expect(cd2.disposed).toBe true

  it 'throws an error when setting a value to a non-disposable', ->
    fn = ->
      key = {}
      map = new MappedDisposable [[key, new Disposable]]
      map.set key, {}
    expect(fn).toThrow()
