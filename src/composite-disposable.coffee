module.exports =
class CompositeDisposable
  isDisposed: false

  constructor: ->
    @disposables = []

  add: (disposable) ->
    unless @isDisposed
      @disposables.push(disposable)

  remove: (disposable) ->
    index = @dispoables.indexOf(disposable)
    @disposables.splice(index, 1) if index isnt -1

  dispose: ->
    unless @isDisposed
      disposable.dispose() for disposable in @disposables
      @clear()

  clear: ->
    @disposables.length = 0
