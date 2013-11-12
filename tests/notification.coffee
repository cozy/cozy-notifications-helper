should = require('chai').should()
Client = require('request-json').JsonClient
clientDS = new Client "http://localhost:9101/"

helpers = require './helpers'

NotificationManager = require '../src/notification-manager'

describe "Notification Manager", ->

    # Allow notification retrieval to make assertions
    before (done) ->
        map = """
            function (doc) {
                if (doc.docType.toLowerCase() === "notification") {
                    return emit(doc._id, doc);
                }
            }
        """
        clientDS.put 'request/notification/all/', map: map, (err, res, body) ->
            should.not.exist err
            should.exist body
            done()

    describe "Creation", ->

        describe "When a temporary notification without a resource is created", ->

            before helpers.cleanDb

            before (done) ->
                @notif = text: "test notification"
                NotificationManager.manage @notif, 'temporary', (err) =>
                    @err = err
                    done()

            it "There shouldn't be an error", ->
                should.not.exist @err

            it "And there should be the notification in the database", (done) ->
                clientDS.post 'request/notification/all/', {}, (err, res, body) =>
                    should.not.exist err
                    should.exist body
                    body.length.should.equal 1
                    notif = body[0].value
                    helpers.validateNotificationFormat notif
                    notif.text.should.equal @notif.text
                    notif.type.should.equal 'temporary'
                    should.not.exist notif.resource.app
                    notif.resource.url.should.equal '/'
                    done()

        describe "When a temporary notification with a resource is created", ->

            before helpers.cleanDb

            before (done) ->
                @notif =
                    text: "test notification"
                    resource:
                        app: 'randomapp'
                        url: '/randomurl'

                NotificationManager.manage @notif, 'temporary', (err) =>
                    @err = err
                    done()

            it "There shouldn't be an error", ->
                should.not.exist @err

            it "And there should be the notification in the database", (done) ->
                clientDS.post 'request/notification/all/', {}, (err, res, body) =>
                    should.not.exist err
                    should.exist body
                    body.length.should.equal 1
                    notif = body[0].value
                    helpers.validateNotificationFormat notif
                    notif.text.should.equal @notif.text
                    notif.type.should.equal 'temporary'
                    notif.resource.app.should.equal @notif.resource.app
                    notif.resource.url.should.equal @notif.resource.url
                    done()

        describe "When a permanent notification is created", ->

            before helpers.cleanDb

            before (done) ->
                @notif =
                    text: "test notification"
                    app: 'randomapp'
                    ref: 'randomref'
                NotificationManager.manage @notif, 'persistent', (err) =>
                    @err = err
                    done()

            it "There shouldn't be error", ->
                should.not.exist @err

            it "And the notification should be in the database", (done) ->
                clientDS.post 'request/notification/all/', {}, (err, res, body) =>
                    should.not.exist err
                    should.exist body
                    body.length.should.equal 1
                    notif = body[0].value
                    helpers.validateNotificationFormat notif
                    notif.text.should.equal @notif.text
                    notif.type.should.equal 'persistent'
                    notif.app.should.equal @notif.app
                    notif.ref.should.equal @notif.ref
                    done()

        describe "When the same notification is updated", ->

            before (done) ->
                @notif.text = "new text"
                NotificationManager.manage @notif, 'persistent', (err) =>
                    @err = err
                    done()

            it "There shouldn't be an error", ->
                should.not.exist @err

            it "And the notification should have its text changed", (done) ->
                clientDS.post 'request/notification/all/', {}, (err, res, body) =>
                    should.not.exist err
                    should.exist body
                    body.length.should.equal 1
                    notif = body[0].value
                    helpers.validateNotificationFormat notif
                    notif.text.should.equal @notif.text
                    notif.type.should.equal 'persistent'
                    notif.app.should.equal @notif.app
                    notif.ref.should.equal @notif.ref
                    done()

    describe "Validation", ->

        describe "When a temporary notification with all fields is validated", ->
            it "There shouldn't be any error", ->
                notification =
                    text: "random text"
                    type: 'temporary'
                    resource:
                        app: 'randomapp'
                        url: '/'
                    publishDate: Date.now()
                issues = NotificationManager.validate notification
                issues.length.should.equal 0

        describe "When a persistent notification with all fields is validated", ->
            it "There shouldn't be any error", ->
                notification =
                    text: "random text"
                    type: 'persistent'
                    resource:
                        app: 'randomapp'
                        url: '/'
                    publishDate: Date.now()
                    app: 'randomapp'
                    ref: 'random ref'
                issues = NotificationManager.validate notification
                issues.length.should.equal 0

        describe "When a notification with an empty text field or without text field is validated", ->
            it "There should be an error", ->
                notification =
                    text: ""
                    type: 'temporary'
                    resource:
                        app: 'randomapp'
                        url: '/'
                    publishDate: Date.now()
                issues = NotificationManager.validate notification
                issues.length.should.equal 1
                issues[0].should.equal 'text'

                notification =
                    type: 'temporary'
                    resource:
                        app: 'randomapp'
                        url: '/'
                    publishDate: Date.now()
                issues = NotificationManager.validate notification
                issues.length.should.equal 1
                issues[0].should.equal 'text'

        describe "When a notification with a wrong type is validated", ->
            it "There should be an error", ->
                notification =
                    text: "random text"
                    type: 'random type'
                    resource:
                        app: 'randomapp'
                        url: '/'
                    publishDate: Date.now()
                issues = NotificationManager.validate notification
                issues.length.should.equal 1
                issues[0].should.equal 'type'

        describe "When a notification without a publishDate field is validated", ->
            it "There should be an error", ->
                notification =
                    text: "random text"
                    type: 'temporary'
                    resource:
                        app: 'randomapp'
                        url: '/'
                issues = NotificationManager.validate notification
                issues[0].should.equal 'publishDate'

        describe "When a notification without a resource field is validated", ->
            it "There should be an error", ->
                notification =
                    text: "random text"
                    type: 'temporary'
                    publishDate: Date.now()
                issues = NotificationManager.validate notification
                issues.length.should.equal 1
                issues[0].should.equal 'resource'

        describe "When a notification without a resource.url field is validated", ->
            it "There should be an error", ->
                notification =
                    text: "random text"
                    type: 'temporary'
                    publishDate: Date.now()
                    resource:
                        app: 'randomapp'
                issues = NotificationManager.validate notification
                issues.length.should.equal 1
                issues[0].should.equal 'resource.url'

        describe "When a persistent notification without a app field is validated", ->
            it "There should be an error", ->
                notification =
                    text: "random text"
                    type: 'persistent'
                    resource:
                        app: 'randomapp'
                        url: '/'
                    publishDate: Date.now()
                    ref: 'random ref'
                issues = NotificationManager.validate notification
                issues.length.should.equal 1
                issues[0].should.equal 'app (persistent)'

        describe "When a persistent notification without a ref field is validated", ->
            it "There should be an error", ->
                notification =
                    text: "random text"
                    type: 'persistent'
                    resource:
                        app: 'randomapp'
                        url: '/'
                    publishDate: Date.now()
                    app: 'randomapp'
                issues = NotificationManager.validate notification
                issues.length.should.equal 1
                issues[0].should.equal 'ref (persistent)'

    describe "Normalization", ->
        describe "When a notification without a publishDate field is normalized", ->
            it "It should have one after normzalization", ->
                notification =
                    text: "random text"
                    type: 'temporary'
                    resource:
                        app: 'randomapp'
                        url: '/'
                notification = NotificationManager.normalize notification
                notification.should.have.property 'publishDate'

        describe "When a notification without a resource field is normalized", ->
            it "It should have one after normzalization", ->
                notification =
                    text: "random text"
                    type: 'temporary'
                    publishDate: Date.now()

                notification = NotificationManager.normalize notification
                notification.should.have.property 'resource'
                notification.resource.should.have.property('url').equal '/'


