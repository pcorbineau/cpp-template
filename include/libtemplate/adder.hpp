/**
 * Integer arithmetic utilities for libtemplate.
 *
 * This header provides basic arithmetic operations as part of the
 * libtemplate library. Include this header to use the functions
 * defined in the `libtemplate` namespace.
 *
 * !!! example "Quick start"
 *
 *     ```cpp title="quick_start.cpp" linenums="1"
 *     #include <libtemplate/adder.hpp>
 *
 *     int result = libtemplate::add(2, 3); // returns 5
 *     ```
 *
 * !!! tip
 *
 *     The whole library lives in a single `libtemplate` namespace, so a
 *     `using namespace libtemplate;` is usually enough to get started.
 */

#pragma once

/**
 * A minimal C++23 template library providing common utility functions.
 *
 * The libtemplate namespace contains a collection of basic utility
 * functions intended to serve as a starting point or boilerplate for
 * larger C++ projects.
 *
 * !!! abstract "What's inside"
 *
 *     Each function is documented with its parameters, return value and a
 *     runnable example. See the [function reference](#functions) below for
 *     the full list.
 */

namespace libtemplate {

/**
 * Adds two integers together.
 *
 * Computes the sum of two integer values:
 *
 * $$
 * a + b
 * $$
 *
 * !!! warning "No overflow checking"
 *
 *     The addition is performed in `int` arithmetic with no overflow
 *     checking, so the behavior is undefined if the result is not
 *     representable as an `int`.[^ub]
 *
 * @param a The first operand.
 * @param b The second operand.
 * @return The sum of @p a and @p b.
 *
 * !!! example
 *
 *     ```cpp title="add.cpp" linenums="1"
 *     auto result = libtemplate::add(10, 20); // returns 30
 *     ```
 *
 * [^ub]: Undefined behavior means the C++ standard places no requirements on
 *     the result. Enable a sanitizer such as `-fsanitize=undefined` while
 *     developing to catch violations early.
 */
auto add(int a, int b) -> int;

/**
 * Adds two values together with an additional offset.
 *
 * Computes the sum of @p x, @p y and @p offset.
 *
 * !!! note "Requirements"
 *
 *     Being a template, this works for any type @p T that supports
 *     `operator+` and is copyable.
 *
 * @tparam T The type of the operands and of the result.
 * @param x The first operand.
 * @param y The second operand.
 * @param offset The value added on top of the sum of @p x and @p y.
 * @return The sum of @p x, @p y and @p offset.
 *
 * !!! example
 *
 *     === "Built-in types"
 *
 *         ```cpp title="builtin.cpp"
 *         auto result = libtemplate::add_with_offset(10, 20, 5); // returns 35
 *         ```
 *
 *     === "Custom types"
 *
 *         ```cpp title="custom.cpp"
 *         struct offset { int value; };
 *
 *         auto operator+(offset lhs, int rhs) -> offset {
 *             return {lhs.value + rhs};
 *         }
 *
 *         auto result = libtemplate::add_with_offset(offset{10}, 20, 5);
 *         ```
 */
template <typename T>
auto add_with_offset(T x, T y, T offset) -> T {
    return x + y + offset;
}

} // namespace libtemplate
