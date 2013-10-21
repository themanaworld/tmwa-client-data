prefix=/usr/local
bindir=${prefix}/bin

LDLIBS=-lz

all: adler32

adler32: adler32.c

clean:
	rm -f adler32

install:
	install -D adler32 ${bindir}/

.PHONY: clean install
