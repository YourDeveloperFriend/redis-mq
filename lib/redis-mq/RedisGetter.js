// Generated by CoffeeScript 1.4.0
(function() {
  var RedisBase, RedisGetter,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RedisBase = require('./RedisBase').RedisBase;

  RedisGetter = (function(_super) {

    __extends(RedisGetter, _super);

    function RedisGetter() {
      RedisGetter.__super__.constructor.apply(this, arguments);
      this.redis_object = {};
    }

    RedisGetter.prototype.loadKey = function(key, callback) {
      var _this = this;
      this.keys_waiting++;
      return this.client.get(this.buildKey(key), function(err, value) {
        if (callback) {
          callback(value);
        }
        return _this.set(key, value);
      });
    };

    RedisGetter.prototype.set = function(key, value) {
      this.keys_waiting--;
      this.redis_object[key] = value;
      if (this.isDone()) {
        if (this.listener) {
          return this.listener(this.redis_object);
        }
      }
    };

    return RedisGetter;

  })(RedisBase);

  exports.RedisGetter = RedisGetter;

}).call(this);
