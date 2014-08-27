module.exports =
class CompositeDisposable
  isDisposed: false

  constructor: ->
    @disposables = []

  add: (disposable) ->
    unless @isDisposed
      @disposables.push(disposable)

  dispose: ->
    unless @isDisposed
      disposable.dispose() for disposable in @disposables
      @clear()

  clear: ->
    @disposables.length = 0
