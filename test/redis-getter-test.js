// Generated by CoffeeScript 1.4.0
(function() {
  var RedisGetter, assert, base_test, events, new_options, options, values, vows, _;

  assert = require('assert');

  vows = require('vows');

  RedisGetter = require("../lib/redis-mq/RedisGetter").RedisGetter;

  base_test = require("./base-test");

  options = require("./base-test").options;

  _ = require("underscore");

  events = require("events");

  vows.describe("Creating a Redis Getter").addBatch(base_test.build_test(RedisGetter)).run();

  values = {
    "base:54321:KEY": "VALUE",
    "base:54321:key1": "value1",
    "base:54321:key2": "value2",
    "base:54321:key3": "value3"
  };

  new_options = _.extend({}, options, {
    client: {
      get: function(key, callback) {
        return setTimeout(function() {
          return callback(null, values[key]);
        }, 500);
      }
    },
    redis_base: "base",
    delimiter: ":",
    id: "54321"
  });

  vows.describe("Redis Getter functions").addBatch({
    "Testing Set": {
      topic: function() {
        var getter, ran;
        getter = new RedisGetter(new_options);
        getter.keys_waiting = 5;
        ran = false;
        getter.onDone(function(redis_object) {
          return ran = true;
        });
        getter.set('KEY', 'VALUE');
        return {
          ran: ran,
          object: getter.redis_object,
          keys_waiting: getter.keys_waiting
        };
      },
      "The onDone wasn't run": function(result) {
        return assert.equal(false, result.ran);
      },
      "The key set": function(result) {
        return assert.equal("VALUE", result.object.KEY);
      },
      "The keys_waiting decreased": function(result) {
        return assert.equal(4, result.keys_waiting);
      }
    },
    "Testing Set onDone": {
      topic: function() {
        var getter, loadkey_callback_result, promise, result_object, _this;
        promise = new events.EventEmitter;
        getter = new RedisGetter(new_options);
        result_object = null;
        loadkey_callback_result = null;
        _this = this;
        getter.onDone(function(redis_object) {
          return promise.emit('success', {
            object: redis_object,
            loadkey_callback_result: loadkey_callback_result
          });
        });
        getter.loadKey("KEY");
        getter.loadKey("key1");
        getter.loadKey("key2");
        getter.loadKey("key3", function(value) {
          return loadkey_callback_result = value;
        });
        return promise;
      },
      "All the keys were loaded": function(result) {
        var expected, key, value, _ref, _results;
        expected = {
          'KEY': 'VALUE',
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3'
        };
        _ref = result.object;
        _results = [];
        for (key in _ref) {
          value = _ref[key];
          _results.push(assert.equal(value, expected[key]));
        }
        return _results;
      },
      "The loadkey callback was called": function(result) {
        return assert.equal(result.loadkey_callback_result, "value3");
      }
    }
  }).run();

}).call(this);
