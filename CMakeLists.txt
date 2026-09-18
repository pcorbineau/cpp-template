cmake_minimum_required(VERSION 3.30)

project(template
  VERSION 0.1.0
  DESCRIPTION "A minimal C++23 template library providing common utility functions."
)

include(GNUInstallDirs)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(libtemplate)

target_sources(libtemplate
	PUBLIC
	FILE_SET HEADERS
	BASE_DIRS include
	FILES
	include/libtemplate/adder.hpp
	PRIVATE
	src/adder.cpp
)

target_include_directories(libtemplate
	PUBLIC
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
	$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
	PRIVATE
	src
)

target_compile_features(libtemplate PUBLIC cxx_std_23)

# --- Installation -------------------------------------------------------------

install(TARGETS libtemplate
  EXPORT libtemplate-targets
  FILE_SET HEADERS
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
  INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

install(EXPORT libtemplate-targets
  FILE libtemplateTargets.cmake
  NAMESPACE libtemplate::
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/libtemplate"
)

include(CMakePackageConfigHelpers)
configure_package_config_file(
  "${CMAKE_SOURCE_DIR}/cmake/libtemplateConfig.cmake.in"
  "${CMAKE_BINARY_DIR}/libtemplateConfig.cmake"
  INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/libtemplate"
)
write_basic_package_version_file(
  "${CMAKE_BINARY_DIR}/libtemplateConfigVersion.cmake"
  COMPATIBILITY SameMajorVersion
)
install(FILES
  "${CMAKE_BINARY_DIR}/libtemplateConfig.cmake"
  "${CMAKE_BINARY_DIR}/libtemplateConfigVersion.cmake"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/libtemplate"
)

enable_testing()
include(doctest-deps)
add_subdirectory(tests)

# Release packaging is configured first: it may force the offline documentation
# on, which docs.cmake has to observe when it generates the Zensical config.
include(packaging)
include(docs)
