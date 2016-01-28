Client = require('request-json').JsonClient
client = new Client "http://localhost:9101/"

# Data System authentification
authentifiedEnvs = ['test', 'production']
if process.env.NODE_ENV in authentifiedEnvs
    client.setBasicAuth process.env.NAME, process.env.TOKEN

# Initialize the "all by app" request for persistent notification
# createOrUpdate operations must be queued while request is being created
queue = []
initialized = false

module.exports.initializeRequest = ->
    initialized = false
    map = """
        function (doc) {
            if (doc.docType.toLowerCase() === "notification") {
                if(doc.type === 'persistent') {
                    emit([doc.app, doc.ref], doc);
                }
            }
        }
    """
    client.put 'request/notification/byApps/', map: map, (err, res, body) ->
        if err?
            msg = "An error occurred while initializing notification module"
            console.log "#{msg} -- #{err}"
        else
            initialized = true
            # Process the waiting operations
            module.exports._emptyQueue()

module.exports.initializeRequest()

module.exports.manage = (notification, type, callback) ->
    notification.type = type
    notification = module.exports._normalize notification
    issues = module.exports._validate notification
    if issues.length > 0
        issues = issues.join " "
        msg = "Notification malformed (problem with fields #{issues})"
        callback new Error msg
    else
        if notification.type is 'temporary'
            module.exports._processCreation notification, callback
        else
            module.exports._createOrUpdate notification, callback

# For persistent notifications
module.exports._createOrUpdate = (notification, callback) ->
    if not initialized
        module.exports._queueOperation 'createOrUpdate', notification, callback
    else
        params = key: [notification.app, notification.ref]

        client.post 'request/notification/byApps/', params, (err, res, body) ->
            if err
                callback err
            else if body? and body.error? and res?.statusCode is 404
                # during tests, the request can be destroy
                module.exports._queueOperation 'createOrUpdate', notification, \
                                                callback
                module.exports.initializeRequest()
            else if not body? or body.length is 0
                module.exports._processCreation notification, callback
            else
                id = body[0].value._id
                module.exports._processUpdate id, notification, callback

# For persistent notifications
module.exports.destroy = (notification, callback) ->
    if not initialized
        module.exports._queueOperation 'destroy', notification, callback
    else
        params = key: [notification.app, notification.ref]

        client.post 'request/notification/byApps/', params, (err, res, body) ->
            if err
                callback err
            else if body? and body.error?
                callback body.error
            else if not body or body.length is 0
                callback()
            else
                id = body[0].value._id
                module.exports._processDestroy id, callback

# Add operations to the queue
module.exports._queueOperation = (action, notification, callback) ->
    queue.push
        action: action
        notification: notification
        callback: callback

# Empty the queue and process the operations
module.exports._emptyQueue = ->
    for action in queue
        if action.action is 'destroy'
            module.exports.destroy action.notification, action.callback
        else if action.action is 'createOrUpdate'
            module.exports._createOrUpdate action.notification, action.callback

# Call the data system to process the create
module.exports._processCreation = (notification, callback) ->
    client.post 'data/', notification, (err, res, body) ->
        err = body if res?.statusCode? and res.statusCode is 500
        callback err

# Call the data system to process the update
module.exports._processUpdate = (id, notification, callback) ->
    client.put "data/#{id}/", notification, (err, res, body) ->
        err = body if res?.statusCode? and res.statusCode is 500
        callback err

# Call the data system to process the delete
module.exports._processDestroy = (id, callback) ->
    client.del "data/#{id}/", (err, res, body) ->
        statusError = [404, 500]
        err = body if res?.statusCode? and res.statusCode in statusError
        callback err


# Set default values for non mandatory parameters
module.exports._normalize = (notification) ->

    notification.docType = "Notification"
    notification.publishDate = Date.now()

    if notification.resource?
        notification.resource =
            app: notification.resource?.app or null
            url: notification.resource?.url or '/'
    else
        notification.resource =
            app: null
            url: '/'

    return notification

# Returns a list of validation issues (empty array if none)
module.exports._validate = (notification) ->

    issues = []

    if not notification.text? or notification.text is ""
        issues.push 'text'

    if not notification.publishDate?
        issues.push 'publishDate'

    if not notification.resource?
        issues.push 'resource'
    else if not notification.resource.url?
        issues.push 'resource.url'

    allowedTypes = ['temporary', 'persistent']
    if not notification.type? or notification.type not in allowedTypes
        issues.push 'type'

    if notification.type is 'persistent'
        if not notification.app?
            issues.push 'app (persistent)'
        if not notification.ref?
            issues.push 'ref (persistent)'

    return issues
