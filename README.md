# event-kit [![Build Status](https://travis-ci.org/atom/event-kit.svg?branch=master)](https://travis-ci.org/atom/event-kit)

This is a simple library for implementing event subscription APIs.

## Implementing Event Subscription APIs

```coffee
{Emitter} = require 'event-kit'

class User
  constructor: ->
     @emitter = new Emitter

  onDidChangeName: (callback) ->
     @emitter.on 'did-change-name', callback

  setName: (name) ->
     if name isnt @name
       @name = name
       @emitter.emit 'did-change-name', name
     @name

  destroy: ->
    @emitter.dispose()
```

In the example above, we implement `::onDidChangeName` on the user object, which
will register callbacks to be invoked whenever the user's name changes. To do
so, we make use of an internal `Emitter` instance. We use `::on` to subscribe
the given callback in `::onDidChangeName`, and `::emit` in `::setName` to notify
subscribers. Finally, when the `User` instance is destroyed we call `::dispose`
on the emitter to unsubscribe all subscribers.

## Consuming Event Subscription APIs

`Emitter::on` returns a `Disposable` instance, which has a `::dispose` method.
To unsubscribe, simply call dispose on the returned object.

```coffee
subscription = user.onDidChangeName (name) -> console.log("My name is #{name}")
# Later, to unsubscribe...
subscription.dispose()
```

You can also use `CompositeDisposable` to combine disposable instances together.

```coffee
{CompositeDisposable} = require 'event-kit'

subscriptions = new CompositeDisposable
subscriptions.add user1.onDidChangeName (name) -> console.log("User 1: #{name}")
subscriptions.add user2.onDidChangeName (name) -> console.log("User 2: #{name}")

# Later, to unsubscribe from *both*...
subscriptions.dispose()
```

## Working with DOM Events

Event kit provides the `DOMEventListener` class to integrate with the DOM Event
API. `DOMEventListener` instances are disposables that will remove the event
listener on disposal.

```coffee
{DOMEventListener} = require 'event-kit'

subscription = new DOMEventListener document.body, 'click', ->
  console.log 'body was clicked'
,
  # initiate capture for this event
  useCapture: true
  # delegate event to elements that match the delegationTarget selector
  delegationTarget: '.delegation-target'
  # immediately dispose of the event listener when it is triggered for the first time
  once: true
```

## Creating Your Own Disposables

Disposables are convenient ways to represent a resource you will no longer
need at some point. You can instantiate a disposable with an action to take when
no longer needed.

```coffee
{Disposable} = require 'event-kit'

disposable = new Disposable => @destroyResource()
```
