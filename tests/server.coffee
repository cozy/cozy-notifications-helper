NotificationsHelper = require '../src/server.coffee'
expect = require('chai').expect

console.log "START HOME BEFORE TESTS"

describe 'notifications helper', ->

    it 'should not throw when instanciated', ->
        @nh = new NotificationsHelper 'appname'

    describe 'createTemporary', (done) ->

        it 'should allow creation of temporary notifications', (done) ->
            @nh.createTemporary
                text: 'test'
                resource: {app: 'appname'}
            , (err, response, result) ->
                expect(result).to.have.property 'success'
                done()

    describe 'createPersistent', (done) ->

        it 'should allow creation of persistent notifications', (done) ->
            @nh.createOrUpdatePersistent 'notifname',
                text: 'test2'
                resource: {app: 'appname'}
            , (err, response, result) ->
                expect(result).to.have.property 'ref', 'notifname'
                expect(result).to.have.property 'app', 'appname'
                done()

    describe 'destroy', (done) ->

        it 'should allow deletion of peristent notifications', (done) ->
            @nh.destroy 'notifnameother', (err, response) ->
                expect(response).to.have.property 'statusCode', 204
                done()