tools.mingw64_nt:
	vcpkg install boost-property-tree:x64-windows
	vcpkg install boost-property-tree:x86-windows
	vcpkg install netcdf-c:x64-windows
	vcpkg install netcdf-c:x86-windows
	vcpkg install pango:x64-windows
	vcpkg install pango:x86-windows
	vcpkg install proj:x64-windows
	vcpkg install proj:x86-windows
	pip install ninja
	pip install jinja2 wheel