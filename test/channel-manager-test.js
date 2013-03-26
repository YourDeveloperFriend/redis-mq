// Generated by CoffeeScript 1.4.0
(function() {
  var ChannelManager, assert, events, initial_options, vows, _;

  assert = require('assert');

  vows = require('vows');

  ChannelManager = require("../lib/redis-mq/ChannelManager").ChannelManager;

  _ = require("underscore");

  events = require("events");

  initial_options = {
    on: function() {}
  };

  vows.describe("Channel Manager Test").addBatch({
    "Testing Constructor": {
      topic: function() {
        var test_on;
        test_on = function(on_what, callack) {};
        return new ChannelManager({
          client: {
            test: "b",
            on: test_on
          },
          delimiter: "B"
        });
      },
      "The client was initialized": function(result) {
        return assert.equal(result.client.test, "b");
      },
      "The delimiter was initialize": function(result) {
        return assert.equal(result.delimiter, "B");
      }
    },
    "build and extract channel key": {
      topic: function() {
        var built, cm, extracted;
        cm = new ChannelManager({
          client: {
            on: function() {}
          }
        });
        extracted = cm.extractChannelKey('kennels|BBhkey');
        cm = new ChannelManager({
          client: {
            on: function() {}
          },
          base: 'hoohoo',
          delimiter: '()'
        });
        built = cm.buildChannelKey(2323);
        return {
          extracted: extracted,
          built: built
        };
      },
      "The extracted key was exact": function(key) {
        return assert.equal("BBhkey", key.extracted);
      },
      "The built key was exact": function(key) {
        return assert.equal("hoohoo()2323", key.built);
      }
    },
    "setCleanup": {
      topic: function() {
        var channels, cm, promise;
        promise = new events.EventEmitter;
        channels = [];
        cm = new ChannelManager({
          client: {
            on: function() {},
            unsubscribe: function(channel) {
              return channels.push(channel);
            }
          },
          cleanup: 100
        });
        cm.channels[323] = {
          subscribers: {
            12345: "blah",
            54321: "blah"
          }
        };
        cm.channels[111] = {
          subscribers: {
            123: "boo"
          }
        };
        cm.setCleanup(323, 12345);
        cm.setCleanup(111, 123);
        setTimeout(function() {
          return promise.emit('success', {
            cm: cm,
            channels: channels
          });
        }, 500);
        return promise;
      },
      "Cleaned up the key": function(result) {
        return assert.equal(typeof result.cm.channels[323].subscribers[12345], "undefined");
      },
      "Didn't destroy the other key": function(result) {
        return assert.equal("blah", result.cm.channels[323].subscribers[54321]);
      },
      "Deleted the entire channel": function(result) {
        assert.equal("undefined", typeof result.cm.channels[111]);
        assert.equal(1, result.channels.length);
        return assert.equal('messages|111', result.channels[0]);
      }
    },
    "got message": {
      topic: function() {
        var client, cm, message_callback, results;
        message_callback = null;
        client = {
          on: function() {}
        };
        cm = new ChannelManager({
          client: {
            on: function(channel, callback) {
              return message_callback = callback;
            }
          }
        });
        results = 0;
        cm.channels[2323] = {
          subscribers: {
            123: {
              messages: [],
              callback: function(messages) {
                results += 100;
                return false;
              }
            },
            454: {
              callback: function(messages) {
                results += 10;
                return true;
              }
            },
            515: {
              callback: function(messages) {
                results += 1;
                return true;
              }
            }
          }
        };
        cm.channels[2324] = {
          subscribers: {
            123: {
              callback: function(messages) {
                results += 1000;
                return true;
              }
            }
          }
        };
        message_callback("messages|2323", "This is a message");
        return {
          results: results,
          cm: cm
        };
      },
      "All the right callbacks were called": function(result) {
        return assert.equal(111, result.results);
      },
      "The one dead callback stored the messages.": function(result) {
        assert.equal('This is a message', result.cm.channels[2323].subscribers[123].messages[0]);
        return assert.equal(1, result.cm.channels[2323].subscribers[123].messages.length);
      }
    },
    "Listening": {
      topic: function() {
        var channels_before, channels_subscribed, channels_unsubscribed, cm, promise, subscriber, subscribers, uniq, uniq1, uniq2, uniq3, uniq4, userid, _ref, _ref1;
        promise = new events.EventEmitter;
        channels_subscribed = [];
        channels_unsubscribed = [];
        cm = new ChannelManager({
          client: {
            on: function() {},
            subscribe: function(channel) {
              return channels_subscribed.push(channel);
            },
            unsubscribe: function(channel) {
              return channels_unsubscribed.push(channel);
            }
          },
          cleanup: 500
        });
        uniq1 = cm.listen(12345);
        uniq2 = cm.listen(12345);
        uniq3 = cm.listen(12345);
        uniq4 = cm.listen(432);
        channels_before = [];
        _ref = cm.channels;
        for (userid in _ref) {
          subscribers = _ref[userid];
          _ref1 = subscribers.subscribers;
          for (uniq in _ref1) {
            subscriber = _ref1[uniq];
            channels_before.push(userid + ":" + uniq);
          }
        }
        setTimeout(function() {
          return promise.emit('success', {
            uniqs: [uniq1, uniq2, uniq3, uniq4],
            cm: cm,
            channels_subscribed: channels_subscribed,
            channels_unsubscribed: channels_unsubscribed,
            channels_before: channels_before
          });
        }, 550);
        return promise;
      },
      "The uniqs are all unique": function(result) {
        var i, j, uniq, uniq2, _i, _len, _ref, _results;
        _ref = result.uniqs;
        _results = [];
        for (uniq = _i = 0, _len = _ref.length; _i < _len; uniq = ++_i) {
          i = _ref[uniq];
          if (i !== 3) {
            _results.push((function() {
              var _j, _len1, _ref1, _results1;
              _ref1 = result.uniqs;
              _results1 = [];
              for (uniq2 = _j = 0, _len1 = _ref1.length; _j < _len1; uniq2 = ++_j) {
                j = _ref1[uniq2];
                if (i !== j && j !== 3) {
                  _results1.push(assert.notEqual(uniq, uniq2));
                }
              }
              return _results1;
            })());
          }
        }
        return _results;
      },
      "The channels were all subscribed": function(result) {
        assert.equal(2, result.channels_subscribed.length);
        assert.notEqual(-1, result.channels_subscribed.indexOf("messages|432"));
        return assert.notEqual(-1, result.channels_subscribed.indexOf("messages|12345"));
      },
      "The channels were inserted into the object": function(result) {
        assert.notEqual(-1, result.channels_before.indexOf("12345:" + result.uniqs[0]));
        assert.notEqual(-1, result.channels_before.indexOf("12345:" + result.uniqs[1]));
        assert.notEqual(-1, result.channels_before.indexOf("12345:" + result.uniqs[2]));
        return assert.notEqual(-1, result.channels_before.indexOf("432:" + result.uniqs[3]));
      },
      "The channels were appropriately unsubscribed": function(result) {
        assert.equal(0, Object.keys(result.cm.channels).length);
        assert.notEqual(-1, result.channels_unsubscribed.indexOf("messages|432"));
        return assert.notEqual(-1, result.channels_unsubscribed.indexOf("messages|12345"));
      }
    },
    "Get Next Message": {
      topic: function() {
        var cm, m, promise, uniq;
        promise = new events.EventEmitter;
        cm = new ChannelManager({
          client: {
            on: function() {},
            subscribe: function() {},
            unsubscribe: function() {}
          },
          cleanup: 500
        });
        uniq = cm.listen("12121");
        cm.gotMessage("messages|12121", "This is a message");
        cm.gotMessage("messages|12121", "Message2");
        m = [];
        cm.getNextMessage("12121", uniq, function(message_list) {
          m = m.concat(message_list);
          return true;
        });
        cm.getNextMessage("12121", uniq, function(message_list) {
          m = m.concat(message_list);
          promise.emit("success", m);
          return true;
        });
        cm.gotMessage("messages|12121", "A last message");
        return promise;
      },
      "All the messages were gotten": function(message_list) {
        console.log(message_list);
        assert.notEqual(-1, message_list.indexOf("This is a message"));
        assert.notEqual(-1, message_list.indexOf("Message2"));
        return assert.notEqual(-1, message_list.indexOf("A last message"));
      }
    }
  }).run();

}).call(this);
