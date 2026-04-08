# Find or build Boost using CPM with required header-only components
# Configures: needed header-only libraries (serialization now handled by Cereal)

# No longer need serialization from Boost - using Cereal instead
set(_PAGMO_REQUIRED_BOOST_LIBS "")

message(STATUS "Configuring Boost dependency...")

# If Boost was previously downloaded by CPM, point find_package at it.
if(EXISTS "${CMAKE_BINARY_DIR}/_deps/boost-src/tools/boost_install/BoostConfig.cmake")
    set(Boost_DIR "${CMAKE_BINARY_DIR}/_deps/boost-src/tools/boost_install" CACHE PATH "" FORCE)
endif()

# Try to find Boost (system or previously CPM-downloaded) first.
find_package(Boost 1.90.0 QUIET CONFIG COMPONENTS ${_PAGMO_REQUIRED_BOOST_LIBS})

if(Boost_FOUND)
    message(STATUS "Found system Boost: ${Boost_VERSION}")
else()
    message(STATUS "System Boost not found. Fetching via CPM...")

    # First add AddBoost.cmake to ensure we have the latest CMake support for Boost
    set(AddBoost.cmake_VERSION 3.7.3)
    CPMAddPackage(
      NAME AddBoost.cmake
      VERSION "${AddBoost.cmake_VERSION}"
      URL "https://github.com/Arniiiii/AddBoost.cmake/archive/refs/tags/${AddBoost.cmake_VERSION}.tar.gz"
    )

    set(TRY_BOOST_VERSION "1.90.0")
    set(BOOST_MY_OPTIONS "CMAKE_POSITION_INDEPENDENT_CODE ON;BUILD_SHARED_LIBS OFF")
    set(BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "")
    set(BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "system;container;type_index;multi_index;type_traits;config;mpl;iterator;algorithm;core;unordered")

    add_boost(
      TRY_BOOST_VERSION
      BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED
      BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED
    )
endif()