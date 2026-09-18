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

} // namespace libtemplate
