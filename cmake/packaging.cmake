# Release packaging with CPack.
#
# Configure with -DLIBTEMPLATE_BUILD_RELEASE=ON to produce distributable
# archives that ship the library, its headers and the offline documentation
# under share/docs. Then run the 'package' target to build the
# archives into the 'dist' directory of the build tree.
#
# The offline documentation is only generated when DOCS_OFFLINE is ON, so the
# release option turns it on automatically: a released package should always
# carry documentation that works without a web server.

option(LIBTEMPLATE_BUILD_RELEASE
  "Configure CPack and the 'release' target to produce distributable archives"
  OFF
)

if(NOT LIBTEMPLATE_BUILD_RELEASE)
  return()
endif()

if(NOT DOCS_OFFLINE)
  set(DOCS_OFFLINE ON CACHE BOOL
    "Build the documentation for offline use (CPack share/docs, file:// access)"
    FORCE
  )
  message(STATUS "Release packaging: forcing DOCS_OFFLINE=ON for share/docs")
endif()

# Coverage reports are a development aid and must never reach a distributable
# archive, so a release build always turns the instrumentation off.
if(LIBTEMPLATE_ENABLE_COVERAGE)
  set(LIBTEMPLATE_ENABLE_COVERAGE OFF CACHE BOOL
    "Instrument the library and include a Doxide code coverage report in the docs"
    FORCE
  )
  message(STATUS "Release packaging: forcing LIBTEMPLATE_ENABLE_COVERAGE=OFF")
endif()

set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
set(CPACK_PACKAGE_VENDOR "${PROJECT_NAME}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_VERSION_MAJOR "${PROJECT_VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${PROJECT_VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${PROJECT_VERSION_PATCH}")

# Write every archive into <build>/dist instead of the build root.
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}/dist")

set(CPACK_GENERATOR "TGZ")
if(WIN32)
  set(CPACK_GENERATOR "ZIP")
endif()

include(CPack)
