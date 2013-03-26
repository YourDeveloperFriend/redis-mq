RedisHelper = require('./RedisBase').RedisHelper
_ = require("underscore")
class ChannelManager
	constructor: (options)->
		defaults =
			delimiter: "|"
			client: null
			cleanup: 120000
			base: 'messages'
		options = _.extend {}, defaults, options
		for key, value of options
			if value
				@[key] = value
			else
				throw "Expected " + key + " for channel manager"
				
		@channels = {}
		@client.on 'message', @gotMessage

	extractChannelKey: (channel)=>
		return channel.split(@delimiter)[1]
	
	gotMessage: (channel, message)=>
		userid = @extractChannelKey channel
		if @channels[userid]?
			for uniq, subscriber of @channels[userid].subscribers
				if not subscriber.callback? or not subscriber.callback [message]
					subscriber.messages.push message
				
	getNextMessage: (userid, uniq, callback)->
		if @channels[userid]?.subscribers[uniq]
			clearTimeout @channels[userid].subscribers[uniq].cleanupTimeout
			@channels[userid].subscribers[uniq].cleanupTimeout = @setCleanup userid, uniq
			if @channels[userid].subscribers[uniq].messages.length > 0
				if callback @channels[userid].subscribers[uniq].messages
					@channels[userid].subscribers[uniq].messages = []
			else
				@channels[userid].subscribers[uniq].callback = callback
		else
			throw "SubscriptionLost"

	listen: (userid)->
		unless @channels[userid]
			@channels[userid] =
				uniq: 0
				subscribers: {}
			@client.subscribe @buildChannelKey userid
		uniq = @channels[userid].uniq++
		@channels[userid].subscribers[uniq] =
			messages: []
			callback: null
			cleanupTimeout: @setCleanup userid, uniq
		uniq
	buildChannelKey: (userid)->
		RedisHelper.buildKey @delimiter, [@base, userid]
	setCleanup: (userid, uniq)->
		return setTimeout ()=>
			console.log "cleaning up " + userid + ":" + uniq
			if @channels[userid]?
				if @channels[userid].subscribers[uniq]?
					delete @channels[userid].subscribers[uniq]
				unless Object.keys(@channels[userid].subscribers).length > 0
					@client.unsubscribe @buildChannelKey userid
					delete @channels[userid]
		, @cleanup

exports.ChannelManager = ChannelManager