# Coverage workflow per https://doxide.org/coverage/:
#   1. configure a dedicated build with -DLIBTEMPLATE_ENABLE_COVERAGE=ON,
#      which instruments the build with
#      --coverage -O0 -fno-inline -fno-elide-constructors (GCC/Clang only),
#      leaving the basic build unpolluted,
#   2. run tests to produce .gcda files,
#   3. collate with gcov --stdout into a single coverage.gcov,
#   4. doxide build --coverage coverage.gcov --output <binary dir>.
option(LIBTEMPLATE_ENABLE_COVERAGE
  "Instrument the build for Doxide code coverage reports (use a separate build directory)"
  OFF
)

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

if(LIBTEMPLATE_ENABLE_COVERAGE AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  message(STATUS "Coverage instrumentation enabled (--coverage -O0 -fno-inline -fno-elide-constructors)")
  target_compile_options(libtemplate PRIVATE --coverage -O0 -fno-inline -fno-elide-constructors)
  target_link_options(libtemplate PUBLIC --coverage)
  if(TARGET libtemplate_tests)
    target_compile_options(libtemplate_tests PRIVATE --coverage -O0 -fno-inline -fno-elide-constructors)
    target_link_options(libtemplate_tests PRIVATE --coverage)
  endif()
endif()

# All generated files live in CMAKE_BINARY_DIR, never in the source tree:
#   - coverage data:  ${CMAKE_BINARY_DIR}/coverage.gcov
#   - doxide output:  ${CMAKE_BINARY_DIR}/docs  (--output overrides doxide.yaml)
#   - mkdocs config:  ${CMAKE_BINARY_DIR}/mkdocs.yaml (inherits source config,
#                     overrides docs_dir/site_dir, which have no CLI equivalent)
#   - mkdocs site:    ${CMAKE_BINARY_DIR}/site
#
# Doxide only emits generated Markdown, so the static MkDocs assets
# (stylesheets and javascripts referenced by mkdocs.yaml) are copied from the
# source docs/ directory into the build-tree docs_dir before MkDocs runs.
set(DOCS_COVERAGE_FILE "${CMAKE_BINARY_DIR}/coverage.gcov")
set(DOCS_DOXIDE_DIR "${CMAKE_BINARY_DIR}/docs")
set(DOCS_MKDOCS_CONFIG "${CMAKE_BINARY_DIR}/mkdocs.yaml")
set(DOCS_SITE_DIR "${CMAKE_BINARY_DIR}/site")
set(DOCS_SOURCE_DIR "${CMAKE_SOURCE_DIR}/docs")
set(DOCS_THEME_DIR "${CMAKE_SOURCE_DIR}/docs/overrides")

# MkDocs offers -d/--site-dir but no --docs-dir option, so generate a config
# in the build tree that inherits the source config and repoints the two
# directories. Relative paths inherited from the source config would resolve
# against this file (i.e. into ${CMAKE_BINARY_DIR}), so theme.custom_dir is
# overridden with an absolute path to the source overrides.
file(WRITE "${DOCS_MKDOCS_CONFIG}"
  "INHERIT: ${CMAKE_SOURCE_DIR}/mkdocs.yaml\n"
  "docs_dir: ${DOCS_DOXIDE_DIR}\n"
  "site_dir: ${DOCS_SITE_DIR}\n"
  "theme:\n"
  "  custom_dir: ${DOCS_THEME_DIR}\n"
)

find_program(GCOV_EXECUTABLE gcov)
find_program(BASH_EXECUTABLE bash)
if(NOT BASH_EXECUTABLE)
  set(BASH_EXECUTABLE sh)
endif()

# Static assets referenced by mkdocs.yaml (extra_css/extra_javascript), copied
# into the build-tree docs_dir after Doxide has written its Markdown.
set(DOCS_COPY_ASSETS
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${DOCS_SOURCE_DIR}/stylesheets" "${DOCS_DOXIDE_DIR}/stylesheets"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${DOCS_SOURCE_DIR}/javascripts" "${DOCS_DOXIDE_DIR}/javascripts"
)

if(GCOV_EXECUTABLE AND LIBTEMPLATE_ENABLE_COVERAGE)
  # NOTE: the gcov collation needs a shell for the find | xargs pipe and the
  # `>` redirect (cmake -E env runs no shell, and VERBATIM forbids `>`).
  add_custom_target(docs
    COMMAND ${CMAKE_CTEST_COMMAND} --test-dir ${CMAKE_BINARY_DIR} --output-on-failure
    COMMAND ${BASH_EXECUTABLE} -c "find ${CMAKE_BINARY_DIR} -name '*.gcda' | xargs ${GCOV_EXECUTABLE} --stdout > ${DOCS_COVERAGE_FILE}"
    COMMAND ${DOXIDE_EXECUTABLE} build --coverage ${DOCS_COVERAGE_FILE} --output ${DOCS_DOXIDE_DIR}
    ${DOCS_COPY_ASSETS}
    COMMAND ${MKDOCS_EXECUTABLE} build -f ${DOCS_MKDOCS_CONFIG}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Building documentation with coverage (Doxide + MkDocs) in ${CMAKE_BINARY_DIR}"
    VERBATIM
  )
  add_dependencies(docs libtemplate_tests)

  add_custom_target(docs-serve
    COMMAND ${CMAKE_CTEST_COMMAND} --test-dir ${CMAKE_BINARY_DIR} --output-on-failure
    COMMAND ${BASH_EXECUTABLE} -c "find ${CMAKE_BINARY_DIR} -name '*.gcda' | xargs ${GCOV_EXECUTABLE} --stdout > ${DOCS_COVERAGE_FILE}"
    COMMAND ${DOXIDE_EXECUTABLE} build --coverage ${DOCS_COVERAGE_FILE} --output ${DOCS_DOXIDE_DIR}
    ${DOCS_COPY_ASSETS}
    COMMAND ${MKDOCS_EXECUTABLE} serve -f ${DOCS_MKDOCS_CONFIG}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Building and serving documentation with coverage (Doxide + MkDocs) from ${CMAKE_BINARY_DIR}"
    VERBATIM
  )
  add_dependencies(docs-serve libtemplate_tests)
else()
  if(NOT LIBTEMPLATE_ENABLE_COVERAGE)
    message(STATUS "Coverage reports disabled; configure with -DLIBTEMPLATE_ENABLE_COVERAGE=ON for 'docs' with coverage")
  endif()
  add_custom_target(docs
    COMMAND ${DOXIDE_EXECUTABLE} build --output ${DOCS_DOXIDE_DIR}
    ${DOCS_COPY_ASSETS}
    COMMAND ${MKDOCS_EXECUTABLE} build -f ${DOCS_MKDOCS_CONFIG}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Building documentation with Doxide + MkDocs in ${CMAKE_BINARY_DIR}"
    VERBATIM
  )

  add_custom_target(docs-serve
    COMMAND ${DOXIDE_EXECUTABLE} build --output ${DOCS_DOXIDE_DIR}
    ${DOCS_COPY_ASSETS}
    COMMAND ${MKDOCS_EXECUTABLE} serve -f ${DOCS_MKDOCS_CONFIG}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Building and serving documentation with Doxide + MkDocs from ${CMAKE_BINARY_DIR}"
    VERBATIM
  )
endif()
