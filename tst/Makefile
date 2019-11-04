fo.c:
	../fogen -d ../functions.db -o fo

fo.o: fo.c
	gcc -fPIC -c fo.c -o fo.o

libfo.so: fo.o
	gcc -shared -fPIC -Wl,-soname,$@.1 -Wl,-init,fo_init -o $@ fo.o -lc

fo-test: fo-test.c
	gcc -o $@ $^ -L. -lfo -ldl

memcmp: memcmp.c
	gcc -o $@ $^ -L. -lfo -ldl -fno-inline-functions -fno-builtin

check: libfo.so fo-test memcmp
	LD_PRELOAD=./libfo.so ./fo-test
	./fo-test.sh

clean:
	rm -f fo.c
	rm -f fo.h
	rm -f fo.o
	rm -f libfo.so
	rm -f fo-test
	rm -f memcmp

.PHONY: clean check
