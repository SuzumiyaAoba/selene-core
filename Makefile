MOON ?= moon

.PHONY: build run run-js test fmt clean

build:
	$(MOON) build

run:
	$(MOON) run src

run-js:
	$(MOON) run src --target js

test:
	$(MOON) test

fmt:
	$(MOON) fmt

clean:
	rm -rf out .moon .cache
