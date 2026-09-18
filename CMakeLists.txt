cmake_minimum_required(VERSION 3.30)

project(template)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(libtemplate)

target_sources(libtemplate
	PUBLIC
	include/libtemplate/adder.hpp
	PRIVATE
	src/adder.cpp
)

target_include_directories(libtemplate
	PUBLIC
	include
	PRIVATE
	src
)

target_compile_features(libtemplate PUBLIC cxx_std_23)

include(cmake/docs.cmake)
