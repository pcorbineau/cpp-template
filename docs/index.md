# libtemplate

A minimal C++23 template library providing common utility functions.

!!! abstract "What's inside"

    Integer arithmetic utilities exposed through the `libtemplate`
    namespace. See the [API reference](api/adder.md) for the full list of
    functions.

## Quick start

```cpp title="quick_start.cpp" linenums="1"
#include <libtemplate/adder.hpp>

int result = libtemplate::add(2, 3); // returns 5
```

!!! tip

    The whole library lives in a single `libtemplate` namespace, so a
    `using namespace libtemplate;` is usually enough to get started.
