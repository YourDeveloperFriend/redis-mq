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
			lpushed = []
			published = []
			promise = new (events.EventEmitter)
			ids = 0
			db = {}
			unread = {}
			mq = new RedisMQ
				client:
					lpush: (key, id, callback)->
						setTimeout ->
							lpushed.push
								user_key: key
								message_id: id
							callback()
						, 100
					publish: (channel, id, callback)->
						setTimeout ->
							published.push
								channel: channel
								message_id: id
							callback()
						, 100
					incr: (key, callback)->
						setTimeout ->
							ids++
							other = ids
							callback null, other
						, 100
					set: (key, value, callback)->
						db[key] = value
						setTimeout ->
							callback null, value
						, 100
					sadd: (key, value, callback)->
						setTimeout ->
							unread[key] = {} unless unread[key]?
							unread[key][value] = true
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
					lpushed: lpushed
					published: published
					errors: errors
					successes: successes
					db: db
					unread: unread
			promise
		"The messages were added to the unread set": (result)->
			expected = [
				unread_key: "ddd|54321|mmm|unread"
				message_id: 1
			,
				user_key: "ddd|123|mmm|unread"
				message_id: 2
			,
				user_key: "ddd|54321|mmm|unread"
				message_id: 3
			]
			for pushed, key in result.unread
				assert.equal expected[key].user_key, pushed.user_key
				assert.equal expected[key].message_id, pushed.message_id
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
			for pushed, key in result.lpushed
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
		"All of the messages were set": (result)->
			expected = [
				userid: "54321"
				data:
					test1: "a"
					test2: "b"
					test3: "c"
			,
				userid: "123"
				data:
					test1: "9"
					test2: "8"
					test3: "7"
			,
				userid: "54321"
				data:
					test1: "1"
					test2: "2"
					test3: "3"
			]
			messageid = 0
			for message_info in expected
				messageid++
				userid = message_info.userid
				for key, value of message_info.data
					assert.equal result.db[["ddd", userid, "mmm", messageid, key].join("|")], value
		"There were no errors": (result)->
			assert.equal false, err for err in result.errors
		"There were all successes": (result)->
			assert.equal true, success for success in result.successes
	"Testing get message":
		topic: ->
			promise = new (events.EventEmitter)
			craft_db =
				message1:
					toid: true
					subject: false
					message: true
					message2: true
					type: "TWO"
				message2:
					toid: true
					subject: true
					message: false
					message2: false
					type: "THREE"
			db = {}
			for id, object of craft_db
				for key, value of object
					db[["users", "54", "messages", id, key].join "|"] = value
			mq = new RedisMQ
				client:
					get: (key, callback)->
						setTimeout ->
							callback null, db[key]
						, 100
				channelManager: "G"
			
			keys =
				toid: false
				type: (type)->
					switch type
						when "TWO"
							return ["message", "message2"]
						when "THREE"
							return ["subject"]
			messages = []
			mq.getMessage "54", "message1", keys, (message)->
				messages.push message
				mq.getMessage "54", "message2", keys, (message)->
					messages.push message
					promise.emit "success", messages
			promise
		"The first message arrived": (messages)->
			message = messages[0]
			assert.equal Object.keys(message).length, 4
			assert.equal "TWO", message["type"]
			assert.equal value, true for key, value of message when key isnt "type"
		"The second message arrived": (messages)->
			message = messages[1]
			assert.equal Object.keys(message).length, 3
			assert.equal "THREE", message["type"]
			assert.equal value, true for key, value of message when key isnt "type"
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
	"Testing Get Page":
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
						setTimeout ->
							callback null, db.length
						, 100
					lrange: (key, start, number, callback)->
						setTimeout ->
							result.start = start
							result.number = number
							to_send = db.slice start, start + number
							callback null, to_send
						, 100
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
	"Test Read":
		topic: ->
			promise = new (events.EventEmitter)
			users =
				"54321": ["414", "123", "222"]
				"123": ["111", "333", "2", "5"]
				"4141": ["44", "3", "8888"]
			db = {}
			for userid, messages of users
				user_key = "users|" + userid + "|messages|unread"
				db[user_key] = {}
				db[user_key][messageid] = true for messageid in messages
					
			mq = new RedisMQ
				client:
					on: ->
						
					srem: (key, value, callback)->
						setTimeout ->
							db[key][value] = false
							callback null, 1
						, 100
				channelManager: "G"
			s = true
			append_success = (success)=>
				s |= success
			mq.setRead "54321", "123", append_success
			mq.setRead "54321", "222", append_success
			mq.setRead "123", "2", append_success
			mq.setRead "123", "111", append_success
			mq.setRead "4141", "8888", (success)=>
				append_success(success)
				promise.emit "success",
					success: s
					db: db
			promise
		"Was successful": (result)->
			assert.equal true, result.success
		"The right messages were removed": (result)->
			removed =
				"54321": ["123", "222"]
				"123": ["2", "111"]
				"4141": ["8888"]
			for userid, messages  of removed
				assert.equal false, result.db["users|" + userid + "|messages|unread"][messageid] for messageid in messages
			not_removed =
				"54321": ["414"]
				"123": ["333", "5"]
				"4141": ["44", "3"]
			for userid, messages of not_removed
				assert.equal true, result.db["users|" + userid + "|messages|unread"][messageid] for messageid in messages
).run();