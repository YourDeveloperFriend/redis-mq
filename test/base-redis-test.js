vows = require('vows')
base_test = require("./base-test");
RedisBase = require("../lib/redis-mq/RedisBase").RedisBase;

test = base_test.build_test(RedisBase);
vows.describe("Creating a Redis Base").addBatch(test).run();