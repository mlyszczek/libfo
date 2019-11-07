VERSION=$(shell cat fogen | grep version=\" | cut -f2 -d\")
BASE_VERSION=$(shell cat fogen | grep version=\" | cut -f2 -d\" | cut -f1 -d-)
GITSHA=$(shell git rev-parse --short HEAD)
DIST_DIR=libfo-$(VERSION)
DESTDIR?=/usr/local
RM ?= rm -f
RMDIR ?= rmdir --ignore-fail-on-non-empty
MKDIR ?= mkdir -p

all: libfo.so

fo.c:
	./fogen -r.

fo.o: fo.c
	gcc -fPIC -c fo.c -o fo.o

libfo.so: fo.o
	gcc -shared -fPIC -Wl,-soname,libfo.so.1 -o libfo.so fo.o -lc

check:
	make check -C tst

distpack:
	$(RM) -r $(DIST_DIR)
	mkdir $(DIST_DIR)
	cp Makefile fogen db.conf readme.md gen-download-page.sh $(DIST_DIR)
	cp LICENSE man2html.sh fo.c.in fo.h.in $(DIST_DIR)
	mkdir $(DIST_DIR)/man
	cp man/*.1 man/*.3 man/*.7 $(DIST_DIR)/man
	mkdir $(DIST_DIR)/tst
	cp tst/Makefile tst/fo-test.c tst/mtest.h $(DIST_DIR)/tst
	cp tst/memcmp.c tst/mtest.sh tst/fo-test.sh $(DIST_DIR)/tst
	mkdir $(DIST_DIR)/www
	cp www/Makefile www/custom.css www/footer.in www/header.in $(DIST_DIR)/www
	cp www/index.in www/index.md www/post-process.sh $(DIST_DIR)/www
	mkdir $(DIST_DIR)/custom
	cp custom/* $(DIST_DIR)/custom


dist-gzip dist: distpack
	tar czf $(DIST_DIR).tar.gz $(DIST_DIR)

dist-bzip2: distpack
	tar cjf $(DIST_DIR).tar.bz2 $(DIST_DIR)

dist-xz: distpack
	tar cJf $(DIST_DIR).tar.xz $(DIST_DIR)

dist-all: dist-gzip dist-bzip2 dist-xz

distclean: clean
	$(RM) -r libfo-*

distcheck: dist
	$(RM) -r $(DIST_DIR)
	tar xzf $(DIST_DIR).tar.gz
	$(MAKE) -C $(DIST_DIR) check
	$(MKDIR) $(DIST_DIR)/install
	DESTDIR=install $(MAKE) -C $(DIST_DIR) install
	$(MAKE) -C $(DIST_DIR) distclean

www:
	./gen-download-page.sh
	./man2html.sh
	make www -C www

clean:
	$(RM) fo.c
	$(RM) fo.h
	$(RM) fo.o
	$(RM) libfo.so
	make clean -C tst
	make clean -C www

install:
	if [ "$(BASE_VERSION)" = "9999" ]; then \
		sed -i 's/^version="9999\(-[[:alnum:]]\+\)\?"$$/version="9999-$(GITSHA)"/' fogen; \
	fi
	for f in custom/*; do \
		install -m0644 -D $$f $(DESTDIR)/share/fogen/$$f; \
	done
	install -m0755 -D fogen         $(DESTDIR)/bin/fogen
	install -m0644 -D fo.c.in       $(DESTDIR)/share/fogen/fo.c.in
	install -m0644 -D fo.h.in       $(DESTDIR)/share/fogen/fo.h.in
	install -m0644 -D db.conf       $(DESTDIR)/share/fogen/db.conf
	install -m0644 -D man/fogen.1   $(DESTDIR)/share/man/man1/fogen.1
	install -m0644 -D man/fo_init.3 $(DESTDIR)/share/man/man3/fo_init.3
	install -m0644 -D man/fo_fail.3 $(DESTDIR)/share/man/man3/fo_fail.3
	install -m0644 -D man/libfo.7   $(DESTDIR)/share/man/man7/libfo.7

uninstall:
	for f in custom/*; do \
		$(RM) $(DESTDIR)/share/fogen/$$f; \
	done
	$(RM) $(DESTDIR)/bin/fogen
	$(RM) $(DESTDIR)/share/fogen/fo.c.in
	$(RM) $(DESTDIR)/share/fogen/fo.h.in
	$(RM) $(DESTDIR)/share/fogen/db.conf
	$(RM) $(DESTDIR)/share/man/man1/fogen.1
	$(RM) $(DESTDIR)/share/man/man3/fo_init.3
	$(RM) $(DESTDIR)/share/man/man3/fo_fail.3
	$(RM) $(DESTDIR)/share/man/man7/libfo.7
	$(RMDIR) $(DESTDIR)/share/fogen/custom
	$(RMDIR) $(DESTDIR)/share/fogen/

.PHONY: www all check dist distclean clean install uninstall
