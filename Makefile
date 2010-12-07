.PHONY: all build test install clean distclean purge

PERL6 = perl6
PREFIX = ~/.perl6
BLIB = blib
P6LIB = $(PWD)/$(BLIB)/lib:$(PWD)/lib:$(PERL6LIB)

SOURCES=lib/Websight.pm lib/Webtoo.pm lib/WW/Plugin.pm lib/WW/Cache.pm \
        lib/WW/Controller.pm lib/WW/Controller/Flower.pm \
        lib/WW/Controller/JSON.pm lib/WW/ChainLoader.pm \
        lib/Websight/Headers.pm lib/Websight/XML.pm \
        lib/Websight/Layout.pm lib/Websight/Autoroot.pm \
        lib/Websight/Index.pm lib/Websight/Content.pm \
        lib/Websight/Lighter.pm lib/Websight/Index/Update.pm \
        lib/Websight/Example.pm lib/Websight/Dispatch.pm \
        lib/Websight/Metadata.pm lib/Websight/Flower.pm \
        lib/Webtoo/File.pm
SCRIPTS=bin/ww6
RESOURCES=share/ww6/
PIRS = $(patsubst %.pm6,%.pir,$(SOURCES:%.pm=%.pir))
BLIB_PIRS = $(PIRS:%=$(BLIB)/%)
BLIB_PMS = $(SOURCES:%=$(BLIB)/%)
INSTALL_SOURCES = $(SOURCES:%=$(PREFIX)/%)
INSTALL_SCRIPTS = $(SCRIPTS:%=$(PREFIX)/%)
INSTALL_RESOURCES = $(RESOURCES:%=$(PREFIX)/%)
INSTALL_PIRS = $(PIRS:%=$(PREFIX)/%)
TESTS = $(shell if [ -d 't' ]; then find t -name '*.t'; fi)

all:: build

build:: $(BLIB_PIRS) $(BLIB_PMS)

$(BLIB)/%.pm:: %.pm
	mkdir -p `dirname '$@'`
	cp $< $@

$(BLIB)/%.pm6:: %.pm6
	mkdir -p `dirname '$@'`
	cp $< $@

$(BLIB)/%.pir:: %.pm
	mkdir -p `dirname '$@'`
	env PERL6LIB=$(P6LIB) $(PERL6) --target=pir --output=$@ $<

$(BLIB)/%.pir:: %.pm6
	mkdir -p `dirname '$@'`
	env PERL6LIB=$(P6LIB) $(PERL6) --target=pir --output=$@ $<

test:: build
	env PERL6LIB=$(P6LIB) prove -e '$(PERL6)' -r t/

$(TESTS):: build
	env PERL6LIB=$(P6LIB) prove -v -e '$(PERL6)' -r $@

install:: build $(INSTALL_SOURCES) $(INSTALL_PIRS) $(INSTALL_SCRIPTS) $(INSTALL_RESOURCES)

$(PREFIX)/%.pm:: %.pm
	mkdir -p `dirname '$@'`
	install $< $@

$(PREFIX)/%.pm6:: %.pm6
	mkdir -p `dirname '$@'`
	install $< $@

$(PREFIX)/%.pir:: blib/%.pir
	mkdir -p `dirname '$@'`
	install $< $@

$(PREFIX)/bin/%:: bin/%
	mkdir -p `dirname '$@'`
	install $< $@

$(PREFIX)/share/%:: share/%
	mkdir -p `dirname '$@'`
	rsync -av --delete $</ $@

clean::
	rm -fr $(BLIB)
	
distclean purge:: clean
	echo "This Makefile is NOT managed by UFO"

