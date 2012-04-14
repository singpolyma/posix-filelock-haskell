GHCFLAGS=-Wall -XNoCPP -fno-warn-name-shadowing -XHaskell98 -O2
HLINTFLAGS=-XHaskell98 -XNoCPP -i 'Use camelCase' -i 'Use String' -i 'Use head' -i 'Use string literal' -i 'Use list comprehension' --utf8
VERSION=0.1

.PHONY: all shell clean doc install debian

all: report.html doc dist/build/libHSposix-filelock-$(VERSION).a dist/posix-filelock-$(VERSION).tar.gz

install: dist/build/libHSposix-filelock-$(VERSION).a
	cabal install

debian: debian/control

shell:
	ghci $(GHCFLAGS)

report.html: System/Posix/FileLock.hs
	-hlint $(HLINTFLAGS) --report $^

doc: dist/doc/html/posix-filelock/index.html README

README: posix-filelock.cabal
	tail -n+$$(( `grep -n ^description: $^ | head -n1 | cut -d: -f1` + 1 )) $^ > .$@
	head -n+$$(( `grep -n ^$$ .$@ | head -n1 | cut -d: -f1` - 1 )) .$@ > $@
	-printf ',s/        //g\n,s/^.$$//g\n,s/\\\\\\//\\//g\nw\nq\n' | ed $@
	$(RM) .$@

dist/doc/html/posix-filelock/index.html: dist/setup-config System/Posix/FileLock.hs
	cabal haddock --hyperlink-source

dist/setup-config: posix-filelock.cabal
	cabal configure

clean:
	find -name '*.o' -o -name '*.hi' | xargs $(RM)
	$(RM) -r dist

debian/control: posix-filelock.cabal
	cabal-debian --update-debianization

dist/build/libHSposix-filelock-$(VERSION).a: System/Posix/FileLock.hs dist/setup-config
	cabal build --ghc-options="$(GHCFLAGS)"

dist/posix-filelock-$(VERSION).tar.gz: System/Posix/FileLock.hs README dist/setup-config
	cabal check
	cabal sdist
