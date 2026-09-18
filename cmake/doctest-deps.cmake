find_package(doctest QUIET)
if(doctest_FOUND)
  return()
endif()

include(FetchContent)
FetchContent_Declare(
  doctest
  GIT_REPOSITORY https://github.com/doctest/doctest.git
  GIT_TAG v2.5.3
)

# doctest is only a test dependency, so keep its headers and CMake package out
# of the install tree and release archives.
set(DOCTEST_NO_INSTALL ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(doctest)

include("${doctest_SOURCE_DIR}/scripts/cmake/doctest.cmake")
