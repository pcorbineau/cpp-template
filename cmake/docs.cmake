find_program(DOXIDE_EXECUTABLE doxide)
find_program(MKDOCS_EXECUTABLE mkdocs)

if(NOT DOXIDE_EXECUTABLE)
  message(WARNING "doxide not found, 'docs' targets will not be available")
  return()
endif()

if(NOT MKDOCS_EXECUTABLE)
  message(WARNING "mkdocs not found, 'docs' targets will not be available")
  return()
endif()

add_custom_target(docs
  COMMAND ${DOXIDE_EXECUTABLE} build
  COMMAND ${MKDOCS_EXECUTABLE} build
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "Building documentation with Doxide + MkDocs"
  VERBATIM
)

add_custom_target(docs-serve
  COMMAND ${DOXIDE_EXECUTABLE} build
  COMMAND ${MKDOCS_EXECUTABLE} serve
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "Building and serving documentation with Doxide + MkDocs"
  VERBATIM
)
