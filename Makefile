VERSION=$(shell cat fogen | grep version=\" | cut -f2 -d\")
DIST_DIR=libfo-$(VERSION)

all: libfo.so

fo.c:
	./fogen -d functions.db -o fo

fo.o: fo.c
	gcc -fPIC -c fo.c -o fo.o

libfo.so: fo.o
	gcc -shared -fPIC -Wl,-soname,libfo.so.1 -o libfo.so fo.o -lc

check:
	make check -C tst

dist:
	rm -rf $(DIST_DIR)
	mkdir $(DIST_DIR)
	cp Makefile fogen functions.db readme.md gen-download-page.sh $(DIST_DIR)
	cp man2html.sh $(DIST_DIR)
	mkdir $(DIST_DIR)/man
	cp man/*.1 man/*.3 man/*.7 $(DIST_DIR)/man
	mkdir $(DIST_DIR)/tst
	cp tst/Makefile tst/fo-test.c tst/mtest.h $(DIST_DIR)/tst
	mkdir $(DIST_DIR)/www
	cp www/Makefile www/custom.css www/footer.in www/header.in $(DIST_DIR)/www
	cp www/index.in www/index.md www/post-process.sh $(DIST_DIR)/www
	tar czf $(DIST_DIR).tar.gz $(DIST_DIR)

distclean: clean
	rm -rf libfo-*

www:
	./gen-download-page.sh
	./man2html.sh
	make www -C www

clean:
	rm -f fo.c
	rm -f fo.h
	rm -f fo.o
	rm -f libfo.so
	make clean -C tst
	make clean -C www

.PHONY: www
