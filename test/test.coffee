tests = ["base-redis-test", "redis-getter-test", "redis-setter-test", "channel-manager-test", "redis-mq-test"]

for test in tests
	require "./" + test