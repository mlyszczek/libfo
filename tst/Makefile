fo.c:
	../fogen -r..

fo.o: fo.c
	gcc -fPIC -c $^ -o $@

libfo.so: fo.o
	gcc -shared -fPIC -Wl,-soname,$@.1 -Wl,-init,fo_init -o $@ fo.o -lc -ldl

fo-test: fo-test.c
	gcc -o $@ $^ -L. -lfo

memcmp: memcmp.c
	gcc -o $@ $^ -L. -lfo -fno-inline-functions -fno-builtin

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
