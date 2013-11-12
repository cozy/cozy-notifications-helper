Client = require('request-json').JsonClient

NotificationManager = require './notification-manager'

module.exports = class NotificationsHelper

    constructor: (@app, port=9103) ->
        @client = new Client "http://localhost:#{port}/"

    createTemporary: (params, callback) ->
        callback ?= ->
        NotificationManager.manage params, 'temporary', callback

    createOrUpdatePersistent: (ref, params, callback) ->
        callback ?= ->
        params.ref = ref
        if params?.resource?.app?
            params.app = @app
        else if @app?
            params.app = params.resource.app

        NotificationManager.manage params, 'persistent', callback

    destroy: (ref, callback) ->
        callback ?= ->
        params =
            ref: ref
            app: @app if @app?
        NotificationManager.destroy params, callback

