# shoes - abstract windowing for gtk, osx, and win32
# by why the lucky stiff, released to you under the MIT license

SRC = shoes/app.c shoes/canvas.c shoes/dialogs.c shoes/image.c shoes/internal.c shoes/ruby.c shoes/world.c
OBJ = ${SRC:.c=.o}

PREFIX = /usr/local
INCS = -I. -I/usr/include
LIBS = -L/usr/lib -lcairo -lpangocairo-1.0 -lungif -ljpeg

SVN_VERSION = `svn info | ruby -ne 'x = $$_[/Revision: (.+)/, 1]; puts x if x'`
RUBY_INCS = `ruby -rrbconfig -e 'puts Config::CONFIG["archdir"]'`
RUBY_LIBS = `ruby -rrbconfig -e 'puts Config::CONFIG["LIBRUBYARG_SHARED"]'`
RUBY_PREFIX = `ruby -rrbconfig -e 'puts Config::CONFIG["prefix"]'`
RUBY_SO = `ruby -rrbconfig -e 'puts Config::CONFIG["RUBY_SO_NAME"]'`
CAIRO_CFLAGS = `pkg-config --cflags cairo`
CAIRO_LIB = `pkg-config --libs cairo`
PANGO_CFLAGS = `pkg-config --cflags pango`
PANGO_LIB = `pkg-config --libs pango`
GTK_CFLAGS = `pkg-config --cflags gtk+-2.0`
GTK_LIB = `pkg-config --libs gtk+-2.0`

VERSION = 0.r${SVN_VERSION}
CFLAGS = -DSHOES_GTK ${INCS} ${CAIRO_CFLAGS} ${PANGO_CFLAGS} ${GTK_CFLAGS} -I${RUBY_INCS}
LDFLAGS = -fPIC ${LIBS} ${CAIRO_LIB} ${PANGO_LIB} ${GTK_LIB} ${RUBY_LIBS}

all: options shoes

options:
	@echo shoes build options:
	@echo "CFLAGS   = ${CFLAGS}"
	@echo "LDFLAGS  = ${LDFLAGS}"
	@echo "CC       = ${CC}"
	@echo "RUBY     = ${RUBY_PREFIX}"

.c.o:
	@echo CC $<
	@${CC} -c ${CFLAGS} -o $@ $<

dist/libshoes.so: ${OBJ} 
	@echo CC -o $@
	@mkdir dist
	@${CC} -o $@ ${OBJ} ${LDFLAGS} -shared

dist/shoes-bin: dist/libshoes.so bin/main.o
	@echo CC -o $@
	@${CC} -o $@ ${LDFLAGS} bin/main.o -Ldist -lshoes

dist/shoes: dist/shoes-bin
	@echo 'APPPATH="$${0%/*}"' > dist/shoes
	@echo 'LD_LIBRARY_PATH=$$APPPATH $$APPPATH/shoes-bin $$@' >> dist/shoes
	@chmod 755 dist/shoes

shoes: dist/shoes
	@mkdir -p dist/ruby/lib
	@cp -r ${RUBY_PREFIX}/lib/ruby/1.8/* dist/ruby/lib
	@rm -rf dist/ruby/lib/rdoc
	@rm -rf dist/ruby/lib/rexml
	@rm -rf dist/ruby/lib/rss
	@rm -rf dist/ruby/lib/soap
	@rm -rf dist/ruby/lib/test
	@rm -rf dist/ruby/lib/webrick
	@rm -rf dist/ruby/lib/wsdl
	@rm -rf dist/ruby/lib/xsd
	@cp ${RUBY_PREFIX}/lib/lib${RUBY_SO}.so dist
	@ln -s lib${RUBY_SO}.so dist/libruby.so.1.8
	@cp -r lib dist/lib
	@rm -rf dist/lib/.svn
	@cp -r samples dist/samples
	@rm -rf dist/samples/.svn
	@cp -r static dist/static
	@rm -rf dist/static/.svn
	@cp README COPYING dist

clean:
	@echo cleaning
	@rm -rf dist
	@rm -f ${OBJ} shoes-${VERSION}.tar.gz

dist: clean
	@echo creating dist tarball
	@mkdir -p shoes-${VERSION}
	@cp -R COPYING Makefile README bin shoes samples static \
		shoes-${VERSION}
	@rm -rf shoes-${VERSION}/**/.svn
	@tar -cf shoes-${VERSION}.tar shoes-${VERSION}
	@gzip shoes-${VERSION}.tar
	@rm -rf shoes-${VERSION}

install: all
	@echo installing executable file to ${DESTDIR}${PREFIX}/bin
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@cp -f dist/shoes ${DESTDIR}${PREFIX}/bin
	@chmod 755 ${DESTDIR}${PREFIX}/bin/shoes
	# @echo installing manual page to ${DESTDIR}${MANPREFIX}/man1
	# @mkdir -p ${DESTDIR}${MANPREFIX}/man1
	# @sed "s/VERSION/${VERSION}/g" < shoes.1 > ${DESTDIR}${MANPREFIX}/man1/shoes.1
	# @chmod 644 ${DESTDIR}${MANPREFIX}/man1/shoes.1

uninstall:
	@echo removing executable file from ${DESTDIR}${PREFIX}/bin
	@rm -f ${DESTDIR}${PREFIX}/bin/shoes
	# @echo removing manual page from ${DESTDIR}${MANPREFIX}/man1
	# @rm -f ${DESTDIR}${MANPREFIX}/man1/shoes.1

.PHONY: all options clean dist install uninstall
