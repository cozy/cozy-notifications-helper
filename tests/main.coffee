NotificationsHelper = require '../src/main.coffee'
should = require('chai').should()

helpers = require './helpers'

describe 'Notifications Helper (interface)', ->

    it 'should not throw when instanciated', ->
        @nh = new NotificationsHelper 'appname'

    describe 'Create temporary notification', (done) ->

        before helpers.cleanDb
        after helpers.cleanDb

        it 'should allow creation of temporary notifications', (done) ->
            @nh.createTemporary
                text: 'test'
                resource: {app: 'appname'}
            , (err) ->
                should.not.exist err
                done()

    describe 'Create persistent notification', (done) ->

        before helpers.cleanDb
        after helpers.cleanDb

        it 'should allow creation of persistent notifications', (done) ->
            @nh.createOrUpdatePersistent 'notifname',
                text: 'test2'
                resource: {app: 'appname'}
            , (err) ->
                should.not.exist err
                done()

    describe 'Destroy notification', (done) ->

        before helpers.cleanDb
        before (done) ->
            @nh.createOrUpdatePersistent 'notifnameother',
                text: 'test2'
                resource: {app: 'appname'}
            , done
        after helpers.cleanDb

        it 'should allow deletion of peristent notifications', (done) ->
            @nh.destroy 'notifnameother', (err) ->
                should.not.exist err
                done()