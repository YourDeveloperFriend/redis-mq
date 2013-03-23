assert = require('assert')
vows = require('vows')
RedisGetter = require("../lib/redis-mq/RedisGetter").RedisGetter
base_test = require("./base-test")
options = require("./base-test").options
_ = require("underscore")
events = require("events")


vows.describe("Creating a Redis Getter").addBatch(base_test.build_test(RedisGetter)).run()

values =
	"base:54321:KEY": "VALUE"
	"base:54321:key1": "value1"
	"base:54321:key2": "value2"
	"base:54321:key3": "value3"
new_options = _.extend {}, options,
	client:
		get: (key, callback) ->
			setTimeout ()->
				callback null, values[key]
			, 500
	redis_base: "base"
	delimiter: ":"
	id: "54321"

vows.describe("Redis Getter functions").addBatch(
	"Testing Set":
		topic: ()-> 
			getter = new RedisGetter new_options
			getter.keys_waiting = 5
			ran = false
			getter.onDone (redis_object)->
				ran = true
			getter.set 'KEY', 'VALUE'
			return {
				ran: ran
				object: getter.redis_object
				keys_waiting: getter.keys_waiting
			}
		"The onDone wasn't run": (result)->
			assert.equal false, result.ran
		"The key set": (result)->
			assert.equal "VALUE", result.object.KEY
		"The keys_waiting decreased": (result)->
			assert.equal 4, result.keys_waiting
	"Testing Set onDone":
		topic: ()->
			promise = new (events.EventEmitter);
			getter = new RedisGetter new_options
			result_object = null
			loadkey_callback_result = null
			_this = this
			getter.onDone (redis_object)->
				promise.emit 'success', 
					object: redis_object
					loadkey_callback_result: loadkey_callback_result
			getter.loadKey "KEY"
			getter.loadKey "key1"
			getter.loadKey "key2"
			getter.loadKey "key3", (value)->
				loadkey_callback_result = value
			promise
		"All the keys were loaded": (result)->
			expected = 
				'KEY': 'VALUE'
				'key1': 'value1'
				'key2': 'value2'
				'key3': 'value3'
			for key, value of result.object
				assert.equal value, expected[key]
		"The loadkey callback was called": (result)->
			assert.equal result.loadkey_callback_result, "value3"
).run();