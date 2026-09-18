# cpp-template

A minimal C++23 template library providing common utility functions.

`libtemplate` is a starting point for C++ projects: a small header plus
compiled source, tests wired into CTest, an installable CMake package and a
Zensical documentation site.

## Requirements

- CMake 3.30 or newer
- A C++23-capable compiler (GCC 13+, Clang 16+, MSVC 19.36+)

## Quick start

```cpp
#include <libtemplate/adder.hpp>

int result = libtemplate::add(2, 3); // returns 5
```

The whole library lives in a single `libtemplate` namespace, so a
`using namespace libtemplate;` is usually enough to get started.

## Building

```sh
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

## Installation

```sh
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/your/prefix
cmake --build build --target install
```

Consume the installed package from another CMake project:

```cmake
find_package(libtemplate REQUIRED)
target_link_libraries(your_target PRIVATE libtemplate::libtemplate)
```

## Documentation

The site is built with [Zensical](https://zensical.org). Install it into a
project virtual environment once:

```sh
python3 -m venv .venv && .venv/bin/pip install zensical
```

Then build or serve the site:

```sh
cmake -S . -B build
cmake --build build --target docs        # renders into build/site
cmake --build build --target docs-serve  # live preview
```

## Release packaging

Configure with release packaging enabled to produce a distributable archive
containing the library, its headers, the CMake package and the offline
documentation under `share/docs`:

```sh
cmake -S . -B build -DLIBTEMPLATE_BUILD_RELEASE=ON
cmake --build build --target release     # writes build/dist/*.tar.gz
```

This forces `DOCS_OFFLINE=ON` so the rendered documentation works from the
filesystem without a web server.

## Project layout

```
include/libtemplate/   Public headers
src/                   Library sources
tests/                 doctest-based tests wired into CTest
cmake/                 Packaging and documentation CMake modules
docs/                  Markdown sources and static assets for the site
```

## License

No license has been chosen yet.
