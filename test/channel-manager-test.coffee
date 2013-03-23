assert = require('assert')
vows = require('vows')
ChannelManager = require("../lib/redis-mq/ChannelManager").ChannelManager
_ = require("underscore")
events = require("events")

initial_options =
	on: ()->
		

vows.describe("Channel Manager Test").addBatch(
	"Testing Constructor":
		topic: ()->
			test_on = (on_what, callack)->
				# Do nothing
			new ChannelManager 
				client: {test: "b", on: test_on}
				delimiter: "B"
		"The client was initialized": (result)->
			assert.equal result.client.test, "b"
		"The delimiter was initialize": (result)->
			assert.equal result.delimiter, "B"
	"build and extract channel key":
		topic: ->
			cm = new ChannelManager
				client: 
					on: ()->
						
			extracted = cm.extractChannelKey 'kennels|BBhkey'
			cm = new ChannelManager
				client:
					on:->
						
				base: 'hoohoo'
				delimiter: '()'
			built = cm.buildChannelKey 2323
			return {
				extracted: extracted
				built: built
			}
		"The extracted key was exact": (key)->
			assert.equal "BBhkey", key.extracted
		"The built key was exact": (key)->
			assert.equal "hoohoo()2323", key.built
	"setCleanup":
		topic: ->
			promise = new (events.EventEmitter)
			channels = []
			cm = new ChannelManager
				client:
					on: ->
						
					unsubscribe: (channel)->
						channels.push channel
				cleanup: 100
			cm.channels[323] =
				subscribers:
					12345: "blah"
					54321: "blah"
			cm.channels[111] =
				subscribers:
					123: "boo"
			cm.setCleanup(323, 12345)
			cm.setCleanup(111, 123)
			setTimeout ->
				promise.emit 'success',
					cm: cm
					channels: channels
			, 500
			promise
		"Cleaned up the key": (result)->
			assert.equal typeof(result.cm.channels[323].subscribers[12345]), "undefined"
		"Didn't destroy the other key": (result)->
			assert.equal "blah", result.cm.channels[323].subscribers[54321]
		"Deleted the entire channel": (result)->
			assert.equal "undefined", typeof(result.cm.channels[111])
			assert.equal 1, result.channels.length
			assert.equal 'messages|111', result.channels[0]
	"got message":
		topic: ->
			message_callback = null
			client = 
				on: ->
					
			cm = new ChannelManager
				client:
					on: (channel, callback)->
						message_callback = callback
			
			results = 0
			cm.channels[2323] =
				subscribers: 
					123:
						messages: []
						callback: (messages)->
							results += 100
							false
					454:
						callback: (messages)->
							results += 10
							true
					515:
						callback: (messages)->
							results += 1
							true
			cm.channels[2324] =
				subscribers: 
					123:
						callback: (messages)->
							results += 1000
							true
			
			message_callback "messages|2323", "This is a message"
			return {
				results: results
				cm: cm
			}
		"All the right callbacks were called": (result)->
			assert.equal 111, result.results
		"The one dead callback stored the messages.": (result)->
			assert.equal 'This is a message', result.cm.channels[2323].subscribers[123].messages[0]
			assert.equal 1, result.cm.channels[2323].subscribers[123].messages.length
	"Listening":
		topic: ->
			promise = new (events.EventEmitter)
			
			channels_subscribed = []
			channels_unsubscribed = []
			cm = new ChannelManager
				client:
					on: ->
						
					subscribe: (channel)->
						channels_subscribed.push channel
					unsubscribe: (channel)->
						channels_unsubscribed.push channel
				cleanup: 500
			uniq1 = cm.listen 12345
			uniq2 = cm.listen 12345
			uniq3 = cm.listen 12345
			uniq4 = cm.listen 432
			
			channels_before = []
			for userid, subscribers of cm.channels
				for uniq, subscriber of subscribers.subscribers
					channels_before.push(userid + ":" + uniq)
			setTimeout ->
				promise.emit 'success',
					uniqs: [
						uniq1
						uniq2
						uniq3
						uniq4
					]
					cm: cm
					channels_subscribed: channels_subscribed
					channels_unsubscribed: channels_unsubscribed
					channels_before: channels_before
			, 550
			promise
		"The uniqs are all unique": (result)->
			for i, uniq in result.uniqs when i isnt 3
				for j, uniq2 in result.uniqs when i isnt j and j isnt 3
					assert.notEqual uniq, uniq2
		"The channels were all subscribed": (result)->
			assert.equal 2, result.channels_subscribed.length
			assert.notEqual -1, result.channels_subscribed.indexOf("messages|432")
			assert.notEqual -1, result.channels_subscribed.indexOf("messages|12345")
		"The channels were inserted into the object": (result)->
			assert.notEqual -1, result.channels_before.indexOf("12345:" + result.uniqs[0])
			assert.notEqual -1, result.channels_before.indexOf("12345:" + result.uniqs[1])
			assert.notEqual -1, result.channels_before.indexOf("12345:" + result.uniqs[2])
			assert.notEqual -1, result.channels_before.indexOf("432:" + result.uniqs[3])
		"The channels were appropriately unsubscribed": (result)->
			assert.equal 0, Object.keys(result.cm.channels).length
			assert.notEqual -1, result.channels_unsubscribed.indexOf("messages|432")
			assert.notEqual -1, result.channels_unsubscribed.indexOf("messages|12345")
).run();