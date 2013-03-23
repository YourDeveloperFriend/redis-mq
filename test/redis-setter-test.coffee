assert = require('assert')
vows = require('vows')
RedisSetter = require("../lib/redis-mq/RedisSetter").RedisSetter
base_test = require("./base-test")
options = base_test.options
_ = require("underscore")
events = require("events")

setter_base_test = base_test.build_test(RedisSetter)

vows.describe("Creating a Redis Setter").addBatch(setter_base_test).run()

values =
	"base:54321:KEY": "VALUE"
	"base:54321:key1": "value1"
	"base:54321:key2": "value2"
	"base:54321:key3": "value3"
ids = 2431
set_keys = {}
new_options = _.extend {}, options,
	client:
		incr: (key, callback)->
			setTimeout ()->
				callback null, ids++
			, 500
		set: (key, value, callback) ->
			setTimeout ()->
				set_keys[key] = value
				callback null, values[key]
			, 500
	redis_base: "base"
	delimiter: ":"
	id: "54321"

vows.describe("Redis Setter functions").addBatch(
	"Testing finishedSave":
		topic: ()-> 
			setter = new RedisSetter new_options
			setter.keys_waiting = 2
			count = 0
			setter.onDone ->
				count++
			setter.finishedSave()
			setter.finishedSave()
			return {
				count: count
				keys_waiting: setter.keys_waiting
			}
		"The keys waiting depleted": (result)->
			assert.equal result.keys_waiting, 0
		"The callback called once": (result)->
			assert.equal result.count, 1
	"Testing saveKey":
		topic: ->
			promise = new (events.EventEmitter)
			new_options.id = 123
			setter = new RedisSetter new_options
			object_to_save =
				key1: "value1"
				key2: "value2"
				key3: "value3"
			count = 0
			setter.onDone (id)->
				promise.emit 'success',
					id: id
					count: count
			for key, value of object_to_save
				setter.saveKey key, value, (value)->
					count++
			promise
		"All the keys were saved": (result)->
			for key, value of {
				"base:123:key1": "value1"
				"base:123:key2": "value2"
				"base:123:key3": "value3"
			}
				assert.equal value, set_keys[key]
		"The callbacks were all called": (result)->
			assert.equal 3, result.count
		"The onDone returned the right id": (result)->
			assert.equal 123, result.id
).run();