RedisBase = require('./RedisBase').RedisBase

class RedisGetter extends RedisBase
	constructor: ->
		super
		@redis_object = {}
	loadKey: (key, callback)->
		@keys_waiting++
		@client.get @buildKey(key), (err, value)=>
			callback value if callback
			@set key, value
	set: (key, value)->
		@keys_waiting--
		@redis_object[key] = value
		if @isDone()
			@listener @redis_object if @listener

exports.RedisGetter = RedisGetter