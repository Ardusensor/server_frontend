IMAGES_INPUT := $(wildcard src/img/*)
IMAGES_OUTPUT := $(patsubst src/%,dist/%, $(IMAGES_INPUT))

COFFEEFILES := $(shell find src/ -type f -name '*.coffee')
OUTPUTJSFILES := $(patsubst src/%.coffee, dist/%.js, $(COFFEEFILES))

INPUTFILES := $(wildcard src/*.*)
OUTPUTMISCFILES := $(patsubst, src/%, dist/%, $(INPUTFILES))

default: run

run:
	@coffee --nodejs --stack_size=4096 server/index.coffee

release: $(IMAGES_OUTPUT) $(OUTPUTMISCFILES) coffee node_modules
	@echo $(IMAGES_OUTPUT)
	@echo $(OUTPUTMISCFILES)
	@echo > /dev/null

node_modules: dist
	@cd dist && npm install --silent

coffee: $(OUTPUTJSFILES)
	@echo > /dev/null

dist/%.js: src/%.coffee
	coffee -co $(@D) $<

dist/img/%: $(IMAGES_INPUT) dist/img
	cp $< $@

dist/img: dist
	mkdir -p dist/img

dist/index.html: dist
	cp src/index.html dist/index.html

dist/robots.txt: dist
	cp src/robots.txt dist/robots.txt

dist/favicon.ico: dist
	cp src/favicon.ico dist/favicon.ico

dist:
	mkdir -p dist