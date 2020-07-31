# ecmwflibs

## Compiling on a Mac
### Creating the macos version of the package

First make sure you have the required packages:

```bash
brew install python3
brew install cmake
brew install pango cairo proj pkg-config boost
brew install netcdf
pip3 install ninja jinja2 delocate wheel
```

Then:

```bash
cd ~/git/ecmwflibs
make clean
make
twine upload wheelhouse/*
```

### To select an earlier version of Python, use pyenv:

```bash
brew install pyenv
brew install pyenv-virtualenv
pyenv install 3.6.5
pyenv virtualenv 3.6.5 py36

pyenv activate py36
pip3 install ninja jinja2 delocate wheel
cd ~/git/ecmwflibs
make clean
make
twine upload wheelhouse/*

```

### Creating the linux version of the package

Cross compiling a Linux version on a Mac requires Docker installed.

```bash
cd ~/git/ecmwflibs
make image
make clean
./dockcross-build-ecmwflibs make
twine upload wheelhouse/*
```

You can also compile interactivaly

```bash
./dockcross-build-ecmwflibs bash
make
exit
```

### Creating *all* linux versions of the package
```bash
cd ~/git/ecmwflibs
make image
make clean
./dockcross-build-ecmwflibs make wheels.linux
twine upload wheelhouse/*
```

## Compiling on Linux

Not tried, but the docker-based solution should work.

# Usefull links

* https://stackoverflow.com/questions/47042483/how-to-build-and-distribute-a-python-cython-package-that-depends-on-third-party
* https://cython.readthedocs.io/en/latest/src/tutorial/cython_tutorial.html
* https://malramsay.com/post/perils_of_packaging/
* https://python-packaging-tutorial.readthedocs.io/en/latest/binaries_dependencies.html
* https://scikit-build.readthedocs.io/en/latest/
* https://stackoverflow.com/questions/24347450/how-do-you-add-additional-files-to-a-wheel
