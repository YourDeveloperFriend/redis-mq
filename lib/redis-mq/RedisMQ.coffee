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

	sendMessage: (fromid, toid, subject, message, callback)->
		console.log 'sending message in mq'
		@sendPayload toid,
			toid: toid
			subject: subject
			message: message
			fromid: fromid
			read: false
			type: "PersonalMessage"
			date: new Date().toISOString()
		, callback

	sendPayload: (toid, payload, callback)->
		redisSetter = new RedisSetter
			delimiter: @delimiter
			client: @client
			redis_base: @message_key
		redisSetter.saveObject payload, (id)=>
			@client.rpush RedisHelper.buildKey(@delimiter, [@user_key, toid, @message_key]), id, (err, reply)=>
				
			@client.publish @channel_key + '|' + toid, id, (err, reply)=>
				
			callback false, true
			
	getMessage: (messageid, callback)->
		builder = new RedisGetter
			delimiter: @delimiter
			client: @client
			redis_key: @message_key
			id: messageid
		builder.onDone (message)=>
			callback message
		builder.loadKey 'toid'
		builder.loadKey 'subject'
		builder.loadKey 'message'
		builder.loadKey 'unread'
		builder.loadKey 'type', (type)=>
			switch type
				when "PersonalMessage" then builder.loadKey 'fromid'
	
	listen: (userid)->
		@channelManager.listen userid
		
	getNextMessage: (userid, uniq, callback)->
		console.log "getting next message"
		@channelManager.getNextMessage userid, uniq, callback
	getMessagesStart: (messages_count, messages_per_page, page)->
		start = messages_count
		while messages_count - messages_per_page > 0 && page > 0
			start -= messages_per_page
			page--
		start
	getPage: (userid, page, messages_per_page, callback)->
		user_messages_key = RedisHelper.buildKey @delimiter, [@user_key, userid, @message_key]
		console.log "finding " + user_messages_key
		@client.llen user_messages_key, (err, messages_count)=>
			console.log "Counted"
			console.log err
			console.log messages_count
			messages_count = parseInt messages_count
			messages_start = getMessagesStart(messages_count, messages_per_page, page)
			@client.lrange user_messages_key, messages_start, messages_per_page, (err, messages)=>
				console.log "found messages"
				console.log err
				console.log messages
				
				callback messages

exports.RedisMQ = RedisMQ