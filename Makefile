setup:
	npm install

test:
	NODE_ENV='test' mocha -R list -u bdd -t 10000 test/*.test.js

.PHONY: test setup