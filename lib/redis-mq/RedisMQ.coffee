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
		options = _.extend({}, defaults, options)
		throw "RedisMQ requires a redis client (parameter: client)" unless options.client
		throw "RedisMQ requires a channel manager(parameter: channelManager)" unless options.channelManager
		@client = client
		@channelManager = channelManager
		@delimiter = delimiter

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
		console.log 'sending payload'
		redisSetter = new RedisSetter @delimiter, @client, 'messages'
		redisSetter.saveObject payload, (id)=>
			console.log 'payload sent ' + id
			@client.rpush RedisHelper.buildKey(['users', toid, 'messages']), id, (err, reply)=>
				console.log 'pushed into queue'
				console.log err
				console.log reply
			@client.publish 'messages|' + toid, id, (err, reply)=>
				console.log 'published!'
				console.log err
				console.log reply
			callback false, true
			
	getMessage: (messageid, callback)->
		builder = new RedisGetter @delimiter, @client, 'messages', messageid
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
		user_messages_key = RedisHelper.buildKey ['users', userid, 'messages']
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