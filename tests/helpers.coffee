should = require('chai').should()
helpers = {}

request = require('request-json-light')
helpers.client = request.newClient "http://localhost:9101/"

# Data System authentification
authentifiedEnvs = ['test', 'production']
if process.env.NODE_ENV in authentifiedEnvs
    helpers.client.setBasicAuth process.env.NAME, process.env.TOKEN

helpers.cleanDb = (done) ->
    helpers.client.put 'request/notification/all/destroy/', {}, (err, res, body) ->
        done()

helpers.validateNotificationFormat = (notif) ->
    notif.should.have.property 'text'
    notif.should.have.property 'resource'
    notif.should.have.property 'type'
    notif.should.have.property 'publishDate'
    notif.resource.should.have.property 'app'
    notif.resource.should.have.property 'url'

module.exports = helpers
