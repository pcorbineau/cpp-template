# Documentation targets built with Zensical.
#
#   docs / docs-serve   Build or serve the documentation site.
#
# Zensical reads zensical.toml and renders the Markdown sources under docs/
# into the build tree. The source tree is only read; every generated file is
# written to the build tree.
#
# Offline packaging is opt-in: configure with -DDOCS_OFFLINE=ON when the
# documentation is going to be distributed alongside the library (e.g. by
# CPack as share/docs) or otherwise served without a web server. That build
# bundles the search index, self-hosts the iframe-worker polyfill and drops the
# fetch-based instant navigation features. Defaults to OFF so normal builds keep
# the richer online navigation.

option(DOCS_OFFLINE
  "Build the documentation for offline use (CPack share/docs, file:// access)"
  OFF
)

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

set(DOCS_SOURCE_DIR     "${CMAKE_SOURCE_DIR}/docs")
set(DOCS_DOCS_DIR       "${CMAKE_BINARY_DIR}/docs")
set(DOCS_SITE_DIR       "${CMAKE_BINARY_DIR}/site")
set(DOCS_ZENSICAL_CONFIG "${CMAKE_BINARY_DIR}/zensical.toml")

# Zensical requires both docs_dir and site_dir to live within the directory of
# the configuration file, so the source zensical.toml is copied into the build
# tree and the Markdown sources are staged next to it. docs_dir ("docs") and
# site_dir ("site") then resolve inside ${CMAKE_BINARY_DIR}, and custom_dir is
# repointed at the absolute overrides directory in the source tree.
file(READ "${CMAKE_SOURCE_DIR}/zensical.toml" DOCS_ZENSICAL_TOML)
string(REPLACE
  "custom_dir = \"../overrides\""
  "custom_dir = \"${CMAKE_SOURCE_DIR}/overrides\""
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

file(WRITE "${DOCS_ZENSICAL_CONFIG}" "${DOCS_ZENSICAL_TOML}")

set(DOCS_STAGE_COMMANDS
  COMMAND ${CMAKE_COMMAND} -E copy_directory "${DOCS_SOURCE_DIR}" "${DOCS_DOCS_DIR}"
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

# --- Installation -------------------------------------------------------------

# Ship the rendered site so packaging (CPack) can distribute it as share/docs
# alongside the library. Only sensible for an offline build, which is why the
# install rule is guarded by DOCS_OFFLINE.
if(DOCS_OFFLINE)
  install(DIRECTORY "${DOCS_SITE_DIR}/"
    DESTINATION "share/docs"
    COMPONENT documentation
  )
endif()
