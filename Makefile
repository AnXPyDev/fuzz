VERSION=1.0

CPPFLAGS=-DVERSION=\"${VERSION}\" -D_GNU_SOURCE
CFLAGS+=-MD -Wall -Wextra -g -std=c99 -O3 -pedantic -Ideps -Werror=vla
PREFIX?=/usr/local
MANDIR?=$(PREFIX)/share/man
BINDIR?=$(PREFIX)/bin
DEBUGGER?=

INSTALL=install
INSTALL_PROGRAM=$(INSTALL)
INSTALL_DATA=${INSTALL} -m 644

LIBS=-lpthread
OBJECTS=src/fuzz.o src/match.o src/tty.o src/choices.o src/options.o src/tty_interface.o
THEFTDEPS = deps/theft/theft.o deps/theft/theft_bloom.o deps/theft/theft_mt.o deps/theft/theft_hash.o
TESTOBJECTS=test/fuzztest.c test/test_properties.c test/test_choices.c test/test_match.c src/match.o src/choices.o src/options.o $(THEFTDEPS)

all: fuzz

test/fuzztest: $(TESTOBJECTS)
	$(CC) $(CFLAGS) $(CCFLAGS) -Isrc -o $@ $(TESTOBJECTS) $(LIBS)

acceptance: fuzz
	cd test/acceptance && bundle --quiet && bundle exec ruby acceptance_test.rb

test: check
check: test/fuzztest
	$(DEBUGGER) ./test/fuzztest

fuzz: $(OBJECTS)
	$(CC) $(CFLAGS) $(CCFLAGS) -o $@ $(OBJECTS) $(LIBS)

%.o: %.c config.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

config.h: src/config.def.h
	cp src/config.def.h config.h

install: fuzz
	mkdir -p $(DESTDIR)$(BINDIR)
	cp fuzz $(DESTDIR)$(BINDIR)/
	chmod 755 ${DESTDIR}${BINDIR}/fuzz
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	cp fuzz.1 $(DESTDIR)$(MANDIR)/man1/
	chmod 644 ${DESTDIR}${MANDIR}/man1/fuzz.1

fmt:
	clang-format -i src/*.c src/*.h

clean:
	rm -f fuzz test/fuzztest src/*.o src/*.d deps/*/*.o

veryclean: clean
	rm -f config.h

.PHONY: test check all clean veryclean install fmt acceptance

-include $(OBJECTS:.o=.d)
