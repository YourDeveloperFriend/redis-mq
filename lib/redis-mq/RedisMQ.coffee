RedisSetter = require('./RedisSetter').RedisSetter
RedisGetter = require('./RedisGetter').RedisGetter
RedisHelper = require('./RedisBase').RedisHelper
_ = require("underscore")

class RedisMQ
	constructor: (options)->
		defaults =
			delimiter: '|'
			client: null
			channelManager: null
			user_key: 'users'
			message_key: 'messages'
			channel_key: 'messages'
		options = _.extend({}, defaults, options)
		for key, value of options
			if value
				@[key] = value
			else
				throw "Expected " + key + " for redis mq"

	sendPayload: (toid, payload, callback)->
		messages_key = @buildMessagesKey toid
		redisSetter = new RedisSetter
			delimiter: @delimiter
			client: @client
			redis_base: messages_key
		redisSetter.saveObject payload, (id)=>
			@client.lpush messages_key, id, (err, reply)=>
				
			@client.publish @channel_key + '|' + toid, id, (err, reply)=>
			
			@client.sadd messages_key, id, (err, reply)=>
				
			callback false, true
			
	getMessage: (userid, messageid, keys, callback)->
		builder = new RedisGetter
			delimiter: @delimiter
			client: @client
			redis_base: @buildMessagesKey(userid)
			id: messageid
		builder.onDone (message)=>
			callback message
		for key, value of keys
			if value
				builder.loadKey key, (response)=>
					otherkeys = value response
					if otherkeys
						builder.loadKey otherkey for otherkey in otherkeys
			else
				builder.loadKey key
	buildMessagesKey: (userid)->
		RedisHelper.buildKey @delimiter, [@user_key, userid, @message_key]
	buildUnreadKey: (userid)->
		RedisHelper.buildKey @delimiter, [@user_key, userid, @message_key, 'unread']
	getNextMessage: (userid, uniq, callback)->
		@channelManager.getNextMessage userid, uniq, callback
	getMessagesStart: (messages_count, messages_per_page, page)->
		start = Math.min (page - 1) * messages_per_page, messages_count - (messages_count % messages_per_page)
			
	getPage: (userid, page, messages_per_page, callback)->
		user_messages_key = @buildMessagesKey(userid)
		@client.llen user_messages_key, (err, messages_count)=>
				messages_count = parseInt messages_count
				messages_start = @getMessagesStart(messages_count, messages_per_page, page)
				@client.lrange user_messages_key, messages_start, messages_per_page, (err, messages)=>
						callback messages
	getUnread: (userid, callback)->
		@client.smembers @buildUnreadKey(userid), (err, messages)=>
			callback if err then [] else messages
	setRead: (userid, messageid, callback)->
		@client.srem @buildUnreadKey(userid), messageid, (err, removed)=>
			callback if err then false else removed > 0
exports.RedisMQ = RedisMQ