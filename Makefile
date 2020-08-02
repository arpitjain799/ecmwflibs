SHELL=/bin/bash

ARCH := $(shell uname | tr '[A-Z]' '[a-z]')
PYTHON3 := $(shell which python3)
PIP3 := $(shell which pip3)


ifeq ($(ARCH), darwin)
LIB64=lib
# This seems to be needed for py36 and py37, but not anymore from py38
CMAKE_EXTRA="-DCMAKE_INSTALL_RPATH=$(CURDIR)/install/lib"
else
LIB64=lib64
# Make sure the right libtool is used (installing gobject-... changes libtool)
export PATH := $(CURDIR)/install/bin:/usr/bin:$(PATH)
endif



export ACLOCAL_PATH=/usr/share/aclocal
export NOCONFIGURE=1
export PKG_CONFIG_PATH=$(CURDIR)/install/lib/pkgconfig:$(CURDIR)/install/$(LIB64)/pkgconfig
export LD_LIBRARY_PATH=$(CURDIR)/install/lib:$(CURDIR)/install/$(LIB64)
#export DYLD_LIBRARY_PATH=$(CURDIR)/install/lib
#export RPATH=$(CURDIR)/install/lib
#export DYLD_FALLBACK_LIBRARY_PATH=$(CURDIR)/install/lib

target: wheel
all: all.$(ARCH)

wheel: wheel.$(ARCH)
wheels: wheels.$(ARCH)
tools: tools.$(ARCH)


all.darwin: image
	rm -fr dist wheelhouse install build-ecmwf wheelhouse.darwin wheelhouse.linux
	make wheels.darwin
	mv wheelhouse wheelhouse.darwin
	rm -fr dist wheelhouse install build-ecmwf
	./dockcross-build-ecmwflibs make wheels.linux
	mv wheelhouse wheelhouse.linux
	ls -l wheelhouse.*


#################################################################
ecbuild: src/ecbuild

src/ecbuild:
	git clone --depth 1 https://github.com/ecmwf/ecbuild.git src/ecbuild

#################################################################
eccodes: ecbuild install/lib/pkgconfig/eccodes.pc

src/eccodes:
	git clone --depth 1 https://github.com/ecmwf/eccodes.git src/eccodes

#-DCMAKE_SKIP_BUILD_RPATH=1 \ -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 \ -DCMAKE_INSTALL_RPATH=$(CURDIR)/lib \ -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=1 \

build-ecmwf/eccodes/build.ninja: src/eccodes
	mkdir -p build-ecmwf/eccodes
	(cd build-ecmwf/eccodes; ../../src/ecbuild/bin/ecbuild  ../../src/eccodes -GNinja \
		-DENABLE_PYTHON=0 \
		-DENABLE_FORTRAN=0 \
		-DENABLE_MEMFS=1 \
		-DENABLE_INSTALL_ECCODES_DEFINITIONS=0 \
		-DENABLE_INSTALL_ECCODES_SAMPLES=0 \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/install $(CMAKE_EXTRA))


install/lib/pkgconfig/eccodes.pc: build-ecmwf/eccodes/build.ninja
	ninja -C build-ecmwf/eccodes install

#################################################################
magics-depend-darwin: eccodes

magics-depend-linux: eccodes cairo pango proj

magics:  magics-depend-$(ARCH) install/lib/pkgconfig/magics.pc

src/magics:
	git clone --depth 1 https://github.com/ecmwf/magics src/magics

build-ecmwf/magics/build.ninja: src/magics
	- $(PIP3) install jinja2
	mkdir -p build-ecmwf/magics
	(cd build-ecmwf/magics; ../../src/ecbuild/bin/ecbuild  ../../src/magics -GNinja \
		-DPYTHON_EXECUTABLE=$(PYTHON3) \
		-DENABLE_PYTHON=0 \
		-DENABLE_FORTRAN=0 \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/install $(CMAKE_EXTRA))

install/lib/pkgconfig/magics.pc: build-ecmwf/magics/build.ninja
	ninja -C build-ecmwf/magics install
	touch install/lib/pkgconfig/magics.pc

#################################################################

sqlite: install/lib/pkgconfig/sqlite3.pc

src/sqlite/configure:
	git clone --depth 1 https://github.com/sqlite/sqlite.git src/sqlite

src/sqlite/config.status: src/sqlite/configure
	(cd src/sqlite; \
		./configure \
		--disable-tcl \
		--prefix=$(CURDIR)/install )


install/lib/pkgconfig/sqlite3.pc: src/sqlite/config.status
	make -C src/sqlite install

#################################################################

proj: sqlite install/lib/pkgconfig/proj.pc

src/proj/autogen.sh:
	git clone --depth 1 https://github.com/OSGeo/PROJ.git src/proj

src/proj/config.status: src/proj/autogen.sh
	(cd src/proj; ./autogen.sh ; ./configure --prefix=$(CURDIR)/install )


install/lib/pkgconfig/proj.pc: src/proj/config.status
	make -C src/proj install

#################################################################
# Pixman is needed by cairo

pixman: install/lib/pkgconfig/pixman-1.pc

src/pixman/autogen.sh:
	git clone --depth 1 https://github.com/freedesktop/pixman src/pixman

src/pixman/config.status: src/pixman/autogen.sh
	(cd src/pixman; ./autogen.sh ; ./configure --prefix=$(CURDIR)/install )


install/lib/pkgconfig/pixman-1.pc: src/pixman/config.status
	make -C src/pixman install


#################################################################
cairo: pixman install/lib/pkgconfig/cairo.pc

src/cairo/autogen.sh:
	git clone --depth 1 https://github.com/freedesktop/cairo src/cairo

src/cairo/config.status: src/cairo/autogen.sh
	(cd src/cairo; ./autogen.sh; \
		./configure \
		--disable-xlib \
		--disable-xcb \
		--disable-qt \
		--disable-quartz \
		--disable-gl \
		--disable-gobject \
		--prefix=$(CURDIR)/install )

install/lib/pkgconfig/cairo.pc: src/cairo/config.status
	make -C src/cairo install
	touch install/lib/pkgconfig/cairo.pc


#################################################################
harfbuzz: cairo install/$(LIB64)/pkgconfig/harfbuzz.pc

src/harfbuzz/meson.build:
	git clone --depth 1 https://github.com/harfbuzz/harfbuzz.git src/harfbuzz

# 		-Dglib=disabled
#		-Dgobject=disabled

build-other/harfbuzz/build.ninja: src/harfbuzz/meson.build
	mkdir -p build-other/harfbuzz
	(cd src/harfbuzz; \
		meson setup --prefix=$(CURDIR)/install \
		-Dintrospection=disabled \
		-Dwrap_mode=nofallback \
		$(CURDIR)/build-other/harfbuzz )

install/$(LIB64)/pkgconfig/harfbuzz.pc: build-other/harfbuzz/build.ninja
	ninja -C build-other/harfbuzz install
	touch install/$(LIB64)/pkgconfig/harfbuzz.pc

#################################################################
fridibi: harfbuzz install/$(LIB64)/pkgconfig/fridibi.pc

src/fridibi/meson.build:
	git clone --depth 1 https://github.com/fribidi/fribidi.git src/fridibi


build-other/fridibi/build.ninja: src/fridibi/meson.build
	mkdir -p build-other/fridibi
	(cd src/fridibi; \
		meson setup --prefix=$(CURDIR)/install \
		-Dintrospection=false \
		-Dwrap_mode=nofallback \
		-Ddocs=false \
		$(CURDIR)/build-other/fridibi )


install/$(LIB64)/pkgconfig/fridibi.pc: build-other/fridibi/build.ninja
	ninja -C build-other/fridibi install
	touch install/$(LIB64)/pkgconfig/fridibi.pc


#################################################################
pango: cairo harfbuzz fridibi install/$(LIB64)/pkgconfig/pango.pc

# Versions after 1.43.0 require versions of glib2 higher than
# the one in the dockcross image

src/pango/meson.build:
	git clone https://gitlab.gnome.org/GNOME/pango.git src/pango
	(cd src/pango; git checkout 1.43.0)

# 		-Dintrospection=false \

build-other/pango/build.ninja: src/pango/meson.build
	mkdir -p build-other/pango
	(cd src/pango; \
		meson setup --prefix=$(CURDIR)/install \
		-Dwrap_mode=nofallback \
		$(CURDIR)/build-other/pango )


install/$(LIB64)/pkgconfig/pango.pc: build-other/pango/build.ninja
	ninja -C build-other/pango install
	touch install/$(LIB64)/pkgconfig/pango.pc

#################################################################
# If setup.py is changed, we need to remove

.inited: setup.py ecmwflibs/__init__.py ecmwflibs/_ecmwflibs.cc
	rm -fr build
	touch .inited

#################################################################

wheel.linux: .inited eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	cp -r install/share ecmwflibs/
	strip --strip-debug install/lib/*.so install/lib64/*.so
	$(PYTHON3) setup.py bdist_wheel
	auditwheel repair dist/*.whl
	unzip -l wheelhouse/*.whl | grep /lib

wheels.linux: .inited eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	cp -r install/share ecmwflibs/
	strip --strip-debug install/lib/*.so install/lib64/*.so

	/opt/python/cp35-cp35m/bin/python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	rm -fr dist

	/opt/python/cp36-cp36m/bin/python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	rm -fr dist

	/opt/python/cp37-cp37m/bin/python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	rm -fr dist

	/opt/python/cp38-cp38/bin/python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	rm -fr dist

wheel.darwin: .inited eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	mkdir -p install/share/magics
	cp -r install/share ecmwflibs/
	cp -r /usr/local/Cellar/proj/*/share ecmwflibs/
	strip -S install/lib/*.dylib
	$(PYTHON3) setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	unzip -l wheelhouse/*.whl | grep /lib


wheels.darwin: .inited pyenv-versions eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	cp -r install/share ecmwflibs/
	strip -S install/lib/*.dylib

	$(HOME)/.pyenv/versions/py35/bin/python setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	rm -fr dist

	$(HOME)/.pyenv/versions/py36/bin/python setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	rm -fr dist

	$(HOME)/.pyenv/versions/py37/bin/python setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	rm -fr dist

	$(HOME)/.pyenv/versions/py38/bin/python setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	rm -fr dist


pyenv-versions: $(HOME)/.pyenv/versions/py35/bin/python \
                $(HOME)/.pyenv/versions/py36/bin/python \
                $(HOME)/.pyenv/versions/py37/bin/python \
                $(HOME)/.pyenv/versions/py38/bin/python


$(HOME)/.pyenv/versions/py35/bin/python:
	pyenv install 3.5.9
	pyenv virtualenv 3.5.9 py35
	$(HOME)/.pyenv/versions/py35/bin/pip install wheel jinja2

$(HOME)/.pyenv/versions/py36/bin/python:
	pyenv install 3.6.10
	pyenv virtualenv 3.6.10 py36
	$(HOME)/.pyenv/versions/py36/bin/pip install wheel jinja2

$(HOME)/.pyenv/versions/py37/bin/python:
	pyenv install 3.7.7
	pyenv virtualenv 3.7.7 py37
	$(HOME)/.pyenv/versions/py37/bin/pip install wheel jinja2

$(HOME)/.pyenv/versions/py38/bin/python:
	pyenv install 3.8.3
	pyenv virtualenv 3.8.3 py38
	$(HOME)/.pyenv/versions/py38/bin/pip install wheel jinja2

tools.darwin:
	brew install pyenv pyenv-virtualenv
	brew install cmake
	brew install pango cairo proj pkg-config boost
	brew install netcdf

tools.linux:
	true

clean:
	rm -fr build install dist *.so *.whl *.egg-info wheelhouse build-ecmwf build-other src build-other


image: dockcross-build-ecmwflibs

dockcross-build-ecmwflibs: Dockerfile
	docker build -t build-ecmwflibs .
	docker run --rm dockcross/manylinux2014-x64:latest | sed 's,dockcross/manylinux2014-x64:latest,build-ecmwflibs:latest,' > dockcross-build-ecmwflibs
	chmod +x dockcross-build-ecmwflibs

# test-wheel:
# 	make -C testing
