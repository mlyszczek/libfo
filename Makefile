all: libfo.so

fo.c:
	./fogen.sh -d functions.db -o fo

fo.o: fo.c
	gcc -fPIC -c fo.c -o fo.o

libfo.so: fo.o
	gcc -shared -fPIC -Wl,-soname,libfo.so.1 -o libfo.so fo.o -lc

check:
	make check -C tst

clean:
	rm -f fo.c
	rm -f fo.h
	rm -f fo.o
	rm -f libfo.so
	make clean -C tst
