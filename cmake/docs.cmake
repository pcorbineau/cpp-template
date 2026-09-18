# Documentation targets built with Doxide and Zensical.
#
#   docs / docs-serve   Build or serve the documentation site.
#
# Doxide reads the public headers and generates the API reference Markdown;
# Zensical reads zensical.toml and renders the Markdown sources under docs/,
# together with the generated API pages, into the build tree. The source tree
# is only read; every generated file is written to the build tree.
#
# Offline packaging is opt-in: configure with -DDOCS_OFFLINE=ON when the
# documentation is going to be distributed alongside the library (e.g. by
# CPack as share/docs) or otherwise served without a web server. That build
# bundles the search index, self-hosts the iframe-worker polyfill and drops the
# fetch-based instant navigation features. Defaults to OFF so normal builds keep
# the richer online navigation.
#
# Code coverage is opt-in too: configure with -DLIBTEMPLATE_ENABLE_COVERAGE=ON
# to instrument the library and tests, run them, collate the data with gcovr
# and include the Doxide coverage report in the site. Release packaging forces
# coverage off so it never ends up in a distributable archive.

option(DOCS_OFFLINE
  "Build the documentation for offline use (CPack share/docs, file:// access)"
  OFF
)

option(LIBTEMPLATE_ENABLE_COVERAGE
  "Instrument the library and include a code coverage report in the docs"
  OFF
)

# --- Required tools -----------------------------------------------------------

find_program(DOXIDE_EXECUTABLE doxide REQUIRED)

# Prefer an install inside the project virtual environment so `zensical` does
# not have to be on the global PATH. Create it once with:
#
#   python3 -m venv .venv && .venv/bin/pip install zensical
#
# then reconfigure before using the targets.
find_program(ZENSICAL_EXECUTABLE zensical
  HINTS "${CMAKE_SOURCE_DIR}/.venv/bin" "${CMAKE_SOURCE_DIR}/.venv/Scripts"
)
if(NOT ZENSICAL_EXECUTABLE)
  message(STATUS
    "zensical not found, 'docs' targets will not be available "
    "(install it with: python3 -m venv .venv && .venv/bin/pip install zensical)")
  return()
endif()

# --- Coverage setup -----------------------------------------------------------

# gcovr is the only supported collator. Without it the documentation still
# builds, it simply does not carry a coverage report.
set(COVERAGE_ACTIVE OFF)
if(LIBTEMPLATE_ENABLE_COVERAGE)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    message(WARNING
      "coverage instrumentation is only supported with GCC or Clang; "
      "no coverage report will be generated")
  else()
    find_program(GCOVR_EXECUTABLE gcovr)
    if(NOT GCOVR_EXECUTABLE)
      message(WARNING
        "gcovr not found; no coverage report will be generated "
        "(install it with: pip install gcovr)")
    else()
      set(COVERAGE_ACTIVE ON)
    endif()
  endif()
endif()

if(COVERAGE_ACTIVE)
  # Flags recommended by https://doxide.org/coverage/ for GCC and Clang.
  set(COVERAGE_FLAGS --coverage -O0 -fno-inline -fno-elide-constructors)
  message(STATUS "Coverage report enabled (${COVERAGE_FLAGS})")

  target_compile_options(libtemplate PRIVATE ${COVERAGE_FLAGS})
  target_link_options(libtemplate PUBLIC --coverage)

  if(TARGET libtemplate_tests)
    target_compile_options(libtemplate_tests PRIVATE ${COVERAGE_FLAGS})
    target_link_options(libtemplate_tests PRIVATE --coverage)
  endif()
elseif(LIBTEMPLATE_ENABLE_COVERAGE)
  message(STATUS "Coverage report requested, but skipped; building docs without it")
else()
  message(STATUS
    "Coverage report disabled; configure with -DLIBTEMPLATE_ENABLE_COVERAGE=ON "
    "to include one")
endif()

# --- Generated file locations (all inside the build tree) ---------------------

set(DOCS_SOURCE_DIR      "${CMAKE_SOURCE_DIR}/docs")
set(DOCS_DOCS_DIR        "${CMAKE_BINARY_DIR}/docs")
set(DOCS_SITE_DIR        "${CMAKE_BINARY_DIR}/site")
set(DOCS_API_DIR         "${CMAKE_BINARY_DIR}/dox-api")
set(DOCS_COVERAGE_FILE   "${CMAKE_BINARY_DIR}/coverage.json")
set(DOCS_ZENSICAL_CONFIG "${CMAKE_BINARY_DIR}/zensical.toml")

# Zensical requires both docs_dir and site_dir to live within the directory of
# the configuration file, so the source zensical.toml is copied into the build
# tree and the Markdown sources are staged next to it. docs_dir ("docs") and
# site_dir ("site") then resolve inside ${CMAKE_BINARY_DIR}, and custom_dir is
# repointed at the absolute overrides directory in the source tree.
# The config below is generated at configure time, so re-run configure whenever
# the source template changes; otherwise the build tree keeps a stale nav.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/zensical.toml"
)

file(READ "${CMAKE_SOURCE_DIR}/zensical.toml" DOCS_ZENSICAL_TOML)
string(REPLACE
  "custom_dir = \"docs/overrides\""
  "custom_dir = \"${CMAKE_SOURCE_DIR}/docs/overrides\""
  DOCS_ZENSICAL_TOML "${DOCS_ZENSICAL_TOML}"
)

if(DOCS_OFFLINE)
  set(DOCS_OFFLINE_BLOCK [=[
# Offline support: bundle the search index so it works when the site
# directory is served or shipped without a web server.
[project.plugins.offline]

# Self-hosted polyfill for the file:// scheme; the iframe-worker name
# keeps Zensical from fetching the shim from unpkg.com.
[project.extra]
polyfills = [
  { path = "javascripts/iframe-worker-shim.js", type = "text/javascript", async = false, defer = false },
]
]=])
  string(REGEX REPLACE
    "# --- offline:begin ---.*# --- offline:end ---"
    "${DOCS_OFFLINE_BLOCK}"
    DOCS_ZENSICAL_TOML "${DOCS_ZENSICAL_TOML}"
  )
  string(REPLACE
    "variant = \"modern\""
    "variant = \"modern\"\nfont = false"
    DOCS_ZENSICAL_TOML "${DOCS_ZENSICAL_TOML}"
  )
  string(REPLACE
    "  \"navigation.instant\",\n  \"navigation.instant.prefetch\",\n"
    ""
    DOCS_ZENSICAL_TOML "${DOCS_ZENSICAL_TOML}"
  )
  message(STATUS "Documentation offline mode enabled (DOCS_OFFLINE=ON)")
endif()

# The coverage navigation entry points at a page that only exists when the
# report is generated, so drop it (markers included) for coverage-less builds.
if(NOT COVERAGE_ACTIVE)
  string(REGEX REPLACE
    "[ \t]*# --- coverage:begin ---.*# --- coverage:end ---\n?"
    ""
    DOCS_ZENSICAL_TOML "${DOCS_ZENSICAL_TOML}"
  )
endif()

file(WRITE "${DOCS_ZENSICAL_CONFIG}" "${DOCS_ZENSICAL_TOML}")

# --- Generation commands ------------------------------------------------------

# Doxide writes the API reference into the build tree. Its per-namespace
# directories are flattened into docs/api (e.g. dox-api/libtemplate/index.md
# becomes docs/api/index.md); the root index.md Doxide also emits is discarded
# because docs/index.md is the hand-written landing page.
#
# Doxide keys coverage by documented entity, so it only annotates the API it
# documents. gcovr is used solely to collate the raw gcov data into the JSON
# report that Doxide consumes; the rendered coverage pages themselves are
# produced by Doxide under coverage/.
#
# The tests are run first so the .gcda counters are current.
if(COVERAGE_ACTIVE)
  set(DOCS_DOXIDE_COVERAGE_OPTION --coverage "${DOCS_COVERAGE_FILE}")
  set(DOCS_COVERAGE_COMMAND
    COMMAND ${CMAKE_CTEST_COMMAND}
      --test-dir "${CMAKE_BINARY_DIR}" --output-on-failure
    COMMAND ${GCOVR_EXECUTABLE}
      --root "${CMAKE_SOURCE_DIR}"
      --gcov-object-directory "${CMAKE_BINARY_DIR}"
      --filter "${CMAKE_SOURCE_DIR}/include"
      --filter "${CMAKE_SOURCE_DIR}/src"
      "--json=${DOCS_COVERAGE_FILE}"
  )
  set(DOCS_COVERAGE_STAGE
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      "${DOCS_API_DIR}/coverage" "${DOCS_DOCS_DIR}/coverage"
  )
else()
  set(DOCS_DOXIDE_COVERAGE_OPTION)
  set(DOCS_COVERAGE_COMMAND)
  set(DOCS_COVERAGE_STAGE)
endif()

set(DOCS_STAGE_COMMANDS
  ${DOCS_COVERAGE_COMMAND}
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${DOCS_API_DIR}"
  COMMAND ${DOXIDE_EXECUTABLE} build ${DOCS_DOXIDE_COVERAGE_OPTION}
    --output "${DOCS_API_DIR}"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${DOCS_DOCS_DIR}"
  COMMAND ${CMAKE_COMMAND} -E copy_directory "${DOCS_SOURCE_DIR}" "${DOCS_DOCS_DIR}"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${DOCS_API_DIR}/libtemplate" "${DOCS_DOCS_DIR}/api"
  ${DOCS_COVERAGE_STAGE}
)

add_custom_target(docs
  ${DOCS_STAGE_COMMANDS}
  COMMAND ${ZENSICAL_EXECUTABLE} build -f "${DOCS_ZENSICAL_CONFIG}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  COMMENT "Documentation in ${DOCS_SITE_DIR}"
  VERBATIM
)

add_custom_target(docs-serve
  ${DOCS_STAGE_COMMANDS}
  COMMAND ${ZENSICAL_EXECUTABLE} serve -f "${DOCS_ZENSICAL_CONFIG}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  COMMENT "Serving documentation from ${CMAKE_BINARY_DIR}"
  VERBATIM
)

if(COVERAGE_ACTIVE)
  add_dependencies(docs libtemplate_tests)
  add_dependencies(docs-serve libtemplate_tests)
endif()

# A release archive must ship the rendered documentation (see packaging.cmake),
# but CPack's 'package' target is generator-provided and only depends on 'all'.
# Adding docs to the default build therefore makes 'cmake --build <dir> --target
# package' generate the site before CPack snapshots the install tree; otherwise
# the install rule for share/docs fails because ${DOCS_SITE_DIR} is missing.
if(LIBTEMPLATE_BUILD_RELEASE)
  set_property(TARGET docs PROPERTY EXCLUDE_FROM_ALL FALSE)
endif()

# --- Installation -------------------------------------------------------------

# Ship the rendered site so packaging (CPack) can distribute it as share/docs
# alongside the library. Only sensible for an offline build, which is why the
# install rule is guarded by DOCS_OFFLINE.
if(DOCS_OFFLINE)
  install(DIRECTORY "${DOCS_SITE_DIR}/"
    DESTINATION "share/docs"
    COMPONENT development
  )
endif()
