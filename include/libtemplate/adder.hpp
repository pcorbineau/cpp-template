/**
 * Integer arithmetic utilities for libtemplate.
 *
 * This header provides basic arithmetic operations as part of the
 * libtemplate library. Include this header to use the functions
 * defined in the libtemplate namespace.
 *
 * ```cpp
 * #include <libtemplate/adder.hpp>
 *
 * int result = libtemplate::add(2, 3); // returns 5
 * ```
 */

#pragma once

/**
 * A minimal C++23 template library providing common utility functions.
 *
 * The libtemplate namespace contains a collection of basic utility
 * functions intended to serve as a starting point or boilerplate for
 * larger C++ projects.
 */

namespace libtemplate {

/**
 * Adds two integers together.
 *
 * Computes the sum of two integer values. This is a straightforward
 * addition operation with no overflow checking.
 *
 * @param a The first operand.
 * @param b The second operand.
 * @return The sum of @p a and @p b.
 *
 * ```cpp
 * auto result = libtemplate::add(10, 20); // returns 30
 * ```
 */
auto add(int a, int b) -> int;

/**
 * Adds two values together with an additional offset.
 *
 * Computes the sum of @p x, @p y and @p offset. Being a template, this
 * works for any type @p T that supports `operator+` and is copyable.
 *
 * @tparam T The type of the operands and of the result.
 * @param x The first operand.
 * @param y The second operand.
 * @param offset The value added on top of the sum of @p x and @p y.
 * @return The sum of @p x, @p y and @p offset.
 *
 * ```cpp
 * auto result = libtemplate::add_with_offset(10, 20, 5); // returns 35
 * ```
 */
template <typename T>
auto add_with_offset(T x, T y, T offset) -> T {
    return x + y + offset;
}

} // namespace libtemplate
