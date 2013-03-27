assert = require('assert')
vows = require('vows')
RedisMQ = require("../lib/redis-mq/RedisMQ").RedisMQ
events = require("events")

vows.describe("Redis MQ Test").addBatch(
	"Testing Constructor":
		topic: ()->
			mq = new RedisMQ
				client:
					test: "b"
				delimiter: "B"
				channelManager: "G"
		"The client was initialized": (result)->
			assert.equal result.client.test, "b"
		"The delimiter was initialized": (result)->
			assert.equal result.delimiter, "B"
		"The channel manager was initialized": (result)->
			assert.equal result.channelManager, "G"
	"Testing Send Payload":
		topic: ()->
			rpushed = []
			published = []
			promise = new (events.EventEmitter)
			ids = 0
			objects = {}
			mq = new RedisMQ
				client:
					rpush: (key, id, callback)->
						rpushed.push
							user_key: key
							message_id: id
						setTimeout ->
							callback()
						, 100
					publish: (channel, id, callback)->
						published.push
							channel: channel
							message_id: id
						setTimeout ->
							callback()
						, 100
					incr: (key, callback)->
						ids++
						other = ids
						setTimeout ->
							callback null, other
						, 100
					set: (key, value, callback)->
						objects[key] = value
						setTimeout ->
							callback null, value
						, 100
				channelManager: "G"
				message_key: "mmm"
				user_key: "ddd"
				channel_key: "lll"
			errors = []
			successes = []
			mq.sendPayload "54321",
				test1: "a"
				test2: "b"
				test3: "c"
			, (err, success)->
				errors.push err
				successes.push success
			mq.sendPayload "123",
				test1: "9"
				test2: "8"
				test3: "7"
			, (err, success)->
				errors.push err
				successes.push success
			mq.sendPayload "54321",
				test1: "1"
				test2: "2"
				test3: "3"
			, (err, success)->
				errors.push err
				successes.push success
				promise.emit "success",
					rpushed: rpushed
					published: published
					errors: errors
					successes: successes
			promise
		"The messages were pushed onto the user": (result)->
			expected = [
				user_key: "ddd|54321|mmm"
				message_id: 1
			,
				user_key: "ddd|123|mmm"
				message_id: 2
			,
				user_key: "ddd|54321|mmm"
				message_id: 3
			]
			for pushed, key in result.rpushed
				assert.equal expected[key].user_key, pushed.user_key
				assert.equal expected[key].message_id, pushed.message_id
		"The messages were published": (result)->
			expected = [
				channel: "lll|54321"
				message_id: 1
			,
				channel: "lll|123"
				message_id: 2
			,
				channel: "lll|54321"
				message_id: 3
			]
			for published, key in result.published
				assert.equal expected[key].channel, published.channel
				assert.equal expected[key].message_id, published.message_id
		"There were no errors": (result)->
			assert.equal false, err for err in result.errors
		"There were no errors": (result)->
			assert.equal true, success for success in result.successes
	"Testing message count":
		topic: ->
			mq = new RedisMQ
				client: "B"
				channelManager: "G"
			result =
				start0: mq.getMessagesStart(125, 30, 1),
				start1: mq.getMessagesStart(125, 15, 4),
				start2: mq.getMessagesStart(125, 30, 5),
				start3: mq.getMessagesStart(125, 30, 20),
				start4: mq.getMessagesStart(125, 130, 2),
		"All the starts were valid": (result)->
			expected =
				start0: 0
				start1: 45
				start2: 120
				start3: 120
				start4: 0
			for key, value of expected
				assert.equal value, result[key]
	"Testing Send Payload":
		topic: ->
			promise = new (events.EventEmitter)
			result =
				start: null
				number: null	
			db = []
			for i in [0..130]
				db.push "message" + i
			mq = new RedisMQ
				client:
					on: ->
						
					llen: (key, callback)->
						callback null, db.length
					lrange: (key, start, number, callback)->
						result.start = start
						result.number = number
						to_send = db.slice start, start + number
						callback null, to_send
				channelManager: "G"
			
			mq.getPage "54321", 3, 20, (messages)->
				result.messages = messages
				promise.emit "success", result
			promise
		"The correct start and number were calculated": (result)->
			assert.equal 40, result.start
			assert.equal 20, result.number
		"The correct messages were grabbed": (result)->
			for i in [40..59]
				assert.notEqual -1, result.messages.indexOf "message" + i
).run();