assert = require('assert')
RedisBase = require("../lib/redis-mq/RedisBase").RedisBase
RedisHelper = require("../lib/redis-mq/RedisBase").RedisHelper

var options = {
	delimiter: {test: "a"},
	client: {test: "b"},
	redis_base: {test: "c"},
	id: {test: "d"}
}
exports.options = options;
exports.build_test = function(constructor){
	return {
		"Testing Constructor": {
			topic: function() {
				return new (constructor)(options);
			},
			"The delimiter saved": function(base) {
				assert.equal("a", base.delimiter.test);
			},
			"The client saved": function(base) {
				assert.equal("b", base.client.test);
			},
			"The base saved": function(base) {
				assert.equal("c", base.redis_base.test);
			},
			"The id saved": function(base) {
				assert.equal("d", base.id.test);
			},
			"Exception Thrown": function(base) {
				assert.throws(function() {new (constructor)()}, "No value found for required key client in RedisBase.");
			}
		},
		"Testing onDone": {
			topic: function() {
				base = new (constructor)(options);
				base.onDone(function() {
					return 5;
				});
				return base.listener();
			},
			'The function should have ran': function(topic) {
				assert.equal(5, topic);
			}
		},
		"Testing build key": {
			topic: function() {
				var options = {
					delimiter: "::",
					client: {},
					redis_base: "basebase",
					id: 54321
				}
				base = new (constructor)(options);
				return base.buildKey("thiskey");
			},
			"Got a key": function(topic) {
				assert.equal("basebase::54321::thiskey", topic);
			}
		}
	}
}