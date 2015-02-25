Grim = require 'grim'

# Essential: A handle to a resource that can be disposed. For example,
# {Emitter::on} returns disposables representing subscriptions.
module.exports =
class Disposable
  disposed: false

  ###
  Section: Construction and Destruction
  ###

  # Public: Construct a Disposable
  #
  # * `disposalAction` An action to perform when {::dispose} is called for the
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

  off: ->
    Grim.deprecate("Use ::dispose to cancel subscriptions instead of ::off")
    @dispose()
