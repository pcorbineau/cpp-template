# Documentation targets built with Doxide and MkDocs.
#
# Two modes are available:
#
#   default    Build or serve the API documentation only.
#   coverage   Configure a dedicated build directory with
#              -DLIBTEMPLATE_ENABLE_COVERAGE=ON to also instrument the code,
#              run the tests, collate the .gcda data and feed it to Doxide.
#              See https://doxide.org/coverage/ for the workflow.
#
# The source tree is only read; every generated file is written to the build
# tree, so a default build stays free of coverage flags.

option(LIBTEMPLATE_ENABLE_COVERAGE
  "Instrument the build for Doxide code coverage reports (use a separate build directory)"
  OFF
)

# --- Required tools -----------------------------------------------------------

find_program(DOXIDE_EXECUTABLE doxide)
if(NOT DOXIDE_EXECUTABLE)
  message(WARNING "doxide not found, 'docs' targets will not be available")
  return()
endif()

find_program(MKDOCS_EXECUTABLE mkdocs)
if(NOT MKDOCS_EXECUTABLE)
  message(WARNING "mkdocs not found, 'docs' targets will not be available")
  return()
endif()

find_program(GCOV_EXECUTABLE gcov)
find_program(BASH_EXECUTABLE bash)
if(NOT BASH_EXECUTABLE)
  set(BASH_EXECUTABLE sh)
endif()

# --- Coverage mode ------------------------------------------------------------

set(COVERAGE_ENABLED OFF)
if(LIBTEMPLATE_ENABLE_COVERAGE)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    message(WARNING "coverage instrumentation is only supported with GCC or Clang; disabling")
  elseif(NOT GCOV_EXECUTABLE)
    message(WARNING "gcov not found; disabling coverage instrumentation")
  else()
    set(COVERAGE_ENABLED ON)
  endif()
else()
  message(STATUS "Coverage reports disabled; configure with -DLIBTEMPLATE_ENABLE_COVERAGE=ON for 'docs' with coverage")
endif()

if(COVERAGE_ENABLED)
  # Flags recommended by https://doxide.org/coverage/ for GCC and Clang.
  set(COVERAGE_FLAGS --coverage -O0 -fno-inline -fno-elide-constructors)
  message(STATUS "Coverage instrumentation enabled (${COVERAGE_FLAGS})")

  target_compile_options(libtemplate PRIVATE ${COVERAGE_FLAGS})
  target_link_options(libtemplate PUBLIC --coverage)

  if(TARGET libtemplate_tests)
    target_compile_options(libtemplate_tests PRIVATE ${COVERAGE_FLAGS})
    target_link_options(libtemplate_tests PRIVATE --coverage)
  endif()
endif()

# --- Generated file locations (all inside the build tree) ---------------------

set(DOCS_COVERAGE_FILE "${CMAKE_BINARY_DIR}/coverage.gcov")
set(DOCS_DOXIDE_DIR    "${CMAKE_BINARY_DIR}/docs")
set(DOCS_MKDOCS_CONFIG "${CMAKE_BINARY_DIR}/mkdocs.yaml")
set(DOCS_SITE_DIR      "${CMAKE_BINARY_DIR}/site")
set(DOCS_SOURCE_DIR    "${CMAKE_SOURCE_DIR}/docs")
set(DOCS_THEME_DIR     "${DOCS_SOURCE_DIR}/overrides")

# MkDocs has no --docs-dir option, so generate a config in the build tree that
# inherits the source config and repoints both directories. Relative paths from
# the source config would resolve against the generated file, hence the
# absolute custom_dir override.
file(WRITE "${DOCS_MKDOCS_CONFIG}"
  "INHERIT: ${CMAKE_SOURCE_DIR}/mkdocs.yaml\n"
  "docs_dir: ${DOCS_DOXIDE_DIR}\n"
  "site_dir: ${DOCS_SITE_DIR}\n"
  "theme:\n"
  "  custom_dir: ${DOCS_THEME_DIR}\n"
)

# --- Static assets ------------------------------------------------------------

# Doxide only writes Markdown, so the static assets referenced by mkdocs.yaml
# (extra_css/extra_javascript) are copied into the build-tree docs_dir. Absent
# directories are skipped with a warning.
set(DOCS_COPY_ASSETS)
foreach(_asset stylesheets javascripts)
  if(EXISTS "${DOCS_SOURCE_DIR}/${_asset}")
    list(APPEND DOCS_COPY_ASSETS
      COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${DOCS_SOURCE_DIR}/${_asset}" "${DOCS_DOXIDE_DIR}/${_asset}"
    )
  else()
    message(WARNING "docs asset directory not found: ${DOCS_SOURCE_DIR}/${_asset}")
  endif()
endforeach()

# --- Commands shared by the 'docs' and 'docs-serve' targets -------------------

set(DOCS_GENERATE_COMMANDS)
set(DOXIDE_COVERAGE_OPTION)

if(COVERAGE_ENABLED)
  # The gcov collation needs a shell for the pipe and output redirection.
  set(DOXIDE_COVERAGE_OPTION --coverage "${DOCS_COVERAGE_FILE}")
  list(APPEND DOCS_GENERATE_COMMANDS
    COMMAND ${CMAKE_CTEST_COMMAND} --test-dir "${CMAKE_BINARY_DIR}" --output-on-failure
    COMMAND ${BASH_EXECUTABLE} -c
      "find '${CMAKE_BINARY_DIR}' -name '*.gcda' | xargs '${GCOV_EXECUTABLE}' --stdout > '${DOCS_COVERAGE_FILE}'"
  )
  set(DOCS_LABEL "Documentation with coverage")
else()
  set(DOCS_LABEL "Documentation")
endif()

list(APPEND DOCS_GENERATE_COMMANDS
  COMMAND ${DOXIDE_EXECUTABLE} build ${DOXIDE_COVERAGE_OPTION} --output "${DOCS_DOXIDE_DIR}"
  ${DOCS_COPY_ASSETS}
)

# --- Targets ------------------------------------------------------------------

add_custom_target(docs
  ${DOCS_GENERATE_COMMANDS}
  COMMAND ${MKDOCS_EXECUTABLE} build -f "${DOCS_MKDOCS_CONFIG}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  COMMENT "${DOCS_LABEL} (Doxide + MkDocs) in ${CMAKE_BINARY_DIR}"
  VERBATIM
)

add_custom_target(docs-serve
  ${DOCS_GENERATE_COMMANDS}
  COMMAND ${MKDOCS_EXECUTABLE} serve -f "${DOCS_MKDOCS_CONFIG}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  COMMENT "Serving ${DOCS_LABEL} (Doxide + MkDocs) from ${CMAKE_BINARY_DIR}"
  VERBATIM
)

if(COVERAGE_ENABLED)
  add_dependencies(docs libtemplate_tests)
  add_dependencies(docs-serve libtemplate_tests)
endif()
