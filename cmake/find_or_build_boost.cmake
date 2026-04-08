# Find or build Boost using CPM with required header-only components
# Configures: needed header-only libraries (serialization now handled by Cereal)

# No longer need serialization from Boost - using Cereal instead
set(_PAGMO_REQUIRED_BOOST_LIBS "")

message(STATUS "Configuring Boost dependency...")

# First add AddBoost.cmake to ensure we have the latest CMake support for Boost
set(AddBoost.cmake_VERSION 3.7.3)
CPMAddPackage(
  NAME AddBoost.cmake
  VERSION "${AddBoost.cmake_VERSION}"
  URL "https://github.com/Arniiiii/AddBoost.cmake/archive/refs/tags/${AddBoost.cmake_VERSION}.tar.gz"
)

# Use CPM for Boost to ensure reliable component availability
message(STATUS "Using CPM for Boost to ensure reliable component availability")
set(TRY_BOOST_VERSION "1.90.0")
set(BOOST_MY_OPTIONS "CMAKE_POSITION_INDEPENDENT_CODE ON;BUILD_SHARED_LIBS OFF")
set(BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "")
set(BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "system;bimap;graph;property_map;container;type_index;multi_index;type_traits;config;mpl;iterator;algorithm;core;unordered")

add_boost(
  TRY_BOOST_VERSION
  BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED
  BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED
)

# Verify CPM-provided Boost targets exist
message(STATUS "Required Boost libraries: ${_PAGMO_REQUIRED_BOOST_LIBS}")

# Debug: List all available targets to see what Boost created
get_property(ALL_TARGETS DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
foreach(target ${ALL_TARGETS})
    if("${target}" MATCHES "Boost::")
        message(STATUS "Found Boost-related target: ${target}")
    endif()
endforeach()

# Check for different possible Boost target naming patterns (no longer need serialization)
# The header-only libraries are automatically available through the add_boost call