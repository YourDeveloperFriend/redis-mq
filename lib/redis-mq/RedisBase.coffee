_ = require ("underscore")
class RedisHelper
	@buildKey: (delimiter, parts)->
		parts.join delimiter

class RedisBase
	constructor: (options)->
		defaults =
			delimiter: "|"
			client: null
			id: null
			redis_base: null
		options = _.extend {}, defaults, options
		for key, value of options
			if value
				@[key] = value
			else
				throw "No value found for required key " + key + " in RedisBase."
		@keys_waiting = 0
	onDone: (callback)->
		@listener = callback
	buildKey: (key)->
		RedisHelper.buildKey @delimiter, [@redis_base, @id, key]
	isDone: ->
		@keys_waiting == 0

exports.RedisBase = RedisBase
exports.RedisHelper = RedisHelper