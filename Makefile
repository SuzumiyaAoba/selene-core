MOON ?= moon

.PHONY: build run test fmt clean

build:
	$(MOON) build

run:
	$(MOON) run

test:
	$(MOON) test

fmt:
	$(MOON) fmt

clean:
	rm -rf out .moon .cache
