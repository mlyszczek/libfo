fo.c:
	../fogen.sh -l ../functions.db -o fo

fo.o: fo.c
	gcc -fPIC -c fo.c -o fo.o

libfo.so: fo.o
	gcc -shared -fPIC -Wl,-soname,libfo.so.1 -o libfo.so fo.o -lc

fo-test: libfo.so
	gcc fo-test.c -o fo-test -L. -lfo -ldl

check: fo-test
	LD_PRELOAD=./libfo.so ./fo-test

clean:
	rm -f fo.c
	rm -f fo.h
	rm -f fo.o
	rm -f libfo.so
	rm -f fo-test
