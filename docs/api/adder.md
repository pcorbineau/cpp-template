# `libtemplate/adder.hpp`

Integer arithmetic utilities for libtemplate.

This header provides basic arithmetic operations as part of the libtemplate
library. Include this header to use the functions defined in the `libtemplate`
namespace.

## `add`

```cpp
auto add(int a, int b) -> int;
```

Adds two integers together. Computes the sum of two integer values:

$$
a + b
$$

!!! warning "No overflow checking"

    The addition is performed in `int` arithmetic with no overflow checking,
    so the behavior is undefined if the result is not representable as an
    `int`.[^ub]

**Parameters**

- `a` — The first operand.
- `b` — The second operand.

**Returns**

The sum of `a` and `b`.

!!! example

    ```cpp title="add.cpp" linenums="1"
    auto result = libtemplate::add(10, 20); // returns 30
    ```

## `add_with_offset`

```cpp
template <typename T>
auto add_with_offset(T x, T y, T offset) -> T;
```

Adds two values together with an additional offset. Computes the sum of `x`,
`y` and `offset`.

!!! note "Requirements"

    Being a template, this works for any type `T` that supports `operator+`
    and is copyable.

**Template parameters**

- `T` — The type of the operands and of the result.

**Parameters**

- `x` — The first operand.
- `y` — The second operand.
- `offset` — The value added on top of the sum of `x` and `y`.

**Returns**

The sum of `x`, `y` and `offset`.

!!! example

    === "Built-in types"

        ```cpp title="builtin.cpp"
        auto result = libtemplate::add_with_offset(10, 20, 5); // returns 35
        ```

    === "Custom types"

        ```cpp title="custom.cpp"
        struct offset { int value; };

        auto operator+(offset lhs, int rhs) -> offset {
            return {lhs.value + rhs};
        }

        auto result = libtemplate::add_with_offset(offset{10}, 20, 5);
        ```

[^ub]: Undefined behavior means the C++ standard places no requirements on the
    result. Enable a sanitizer such as `-fsanitize=undefined` while developing
    to catch violations early.
