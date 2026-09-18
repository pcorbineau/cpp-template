#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

#include <libtemplate/adder.hpp>

TEST_CASE("add returns sum of two integers") {
    CHECK(libtemplate::add(2, 3) == 5);
    CHECK(libtemplate::add(-1, 1) == 0);
    CHECK(libtemplate::add(0, 0) == 0);
}
