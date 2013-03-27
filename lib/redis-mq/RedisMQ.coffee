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
		redisSetter = new RedisSetter
			delimiter: @delimiter
			client: @client
			redis_base: @message_key
		redisSetter.saveObject payload, (id)=>
			@client.rpush RedisHelper.buildKey(@delimiter, [@user_key, toid, @message_key]), id, (err, reply)=>
				
			@client.publish @channel_key + '|' + toid, id, (err, reply)=>
				
			callback false, true
			
	getMessage: (messageid, keys, callback)->
		builder = new RedisGetter
			delimiter: @delimiter
			client: @client
			redis_key: @message_key
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
	
	listen: (userid)->
		@channelManager.listen userid
		
	getNextMessage: (userid, uniq, callback)->
		@channelManager.getNextMessage userid, uniq, callback
	getMessagesStart: (messages_count, messages_per_page, page)->
		start = Math.min (page - 1) * messages_per_page, messages_count - (messages_count % messages_per_page)
	getPage: (userid, page, messages_per_page, callback)->
		user_messages_key = RedisHelper.buildKey @delimiter, [@user_key, userid, @message_key]
		@client.llen user_messages_key, (err, messages_count)=>
			messages_count = parseInt messages_count
			messages_start = @getMessagesStart(messages_count, messages_per_page, page)
			@client.lrange user_messages_key, messages_start, messages_per_page, (err, messages)=>
				callback messages

exports.RedisMQ = RedisMQ