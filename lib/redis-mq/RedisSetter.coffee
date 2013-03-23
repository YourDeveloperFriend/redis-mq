
RedisBase = require('./RedisBase').RedisBase

class RedisSetter extends RedisBase
	constructor: ->
		super
	saveObject: (redis_object, callback)->
		@listener = callback if callback
		@client.incr 'messageids', (err, reply) =>
			@id = reply
			@saveKey key, value for key, value of redis_object
	saveKey: (key, value, callback)->
		@keys_waiting++
		@client.set @buildKey(key), value, (err, value)=>
			callback value if callback
			@finishedSave()
	finishedSave: ->
		@keys_waiting--
		if @isDone()
			@listener @id if @listener

exports.RedisSetter = RedisSetter