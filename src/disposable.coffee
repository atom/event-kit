# Essential: A handle to a resource that can be disposed. For example,
# {Emitter::on} returns disposables representing subscriptions.
module.exports =
class Disposable
  disposed: false

  # Public: Ensure that `object` correctly implements the `Disposable`
  # contract.
  #
  # * `object` An {Object} you want to perform the check against.
  #
  # Returns a {Boolean} indicating whether `object` is a valid `Disposable`.
  @isDisposable: (object) ->
    typeof object?.dispose is "function"

  ###
  Section: Construction and Destruction
  ###

  # Public: Construct a Disposable
  #
  # * `disposalAction` A {Function} to call when {::dispose} is called for the
  #   first time.
  constructor: (@disposalAction) ->

  # Public: Perform the disposal action, indicating that the resource associated
  # with this disposable is no longer needed.
  #
  # You can call this method more than once, but the disposal action will only
  # be performed the first time.
  dispose: ->
    unless @disposed
      @disposed = true
      @disposalAction?()
      @disposalAction = null
    return
