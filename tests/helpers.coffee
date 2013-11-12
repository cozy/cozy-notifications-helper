Client = require('request-json').JsonClient
client = new Client "http://localhost:9101/"

should = require('chai').should()

helpers = {}

helpers.cleanDb = (done) ->
    client.put 'request/notification/all/destroy/', {}, (err, res, body) ->
        done()

helpers.validateNotificationFormat = (notif) ->
    notif.should.have.property 'text'
    notif.should.have.property 'resource'
    notif.should.have.property 'type'
    notif.should.have.property 'publishDate'
    notif.resource.should.have.property 'app'
    notif.resource.should.have.property 'url'

module.exports = helpers