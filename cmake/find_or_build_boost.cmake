# Find or build Boost using CPM with required components
# Configures: boost_serialization and needed header-only libraries

# Determine required Boost libraries (removed test components - using Google Test now)
set(_PAGMO_REQUIRED_BOOST_LIBS serialization)

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
set(BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "serialization")
set(BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "any;system;math;safe_numerics;bimap;graph;lexical_cast;integer;variant;variant2;property_map;container;move;type_index;multi_index;type_traits;config;mpl")

add_boost(
  TRY_BOOST_VERSION BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED
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

# Check for different possible Boost target naming patterns
set(BOOST_SERIALIZATION_TARGET "")
set(BOOST_TEST_TARGET "")

# Try different target names for serialization
foreach(target_name IN ITEMS "boost_serialization" "Boost::serialization" "boost_serialization_static" "Boost_serialization")
    if(TARGET ${target_name})
        set(BOOST_SERIALIZATION_TARGET ${target_name})
        message(STATUS "${target_name} target available")
        break()
    endif()
endforeach()

if(NOT BOOST_SERIALIZATION_TARGET)
    message(WARNING "boost_serialization target not found - continuing anyway to see available targets")
endif()

if(PAGMO_BUILD_TESTS)
    # Try different target names for test framework
    foreach(target_name IN ITEMS "boost_unit_test_framework" "Boost::unit_test_framework" "boost_test" "Boost::test" "boost_unit_test_framework_static")
        if(TARGET ${target_name})
            set(BOOST_TEST_TARGET ${target_name})
            message(STATUS "${target_name} target available")
            break()
        endif()
    endforeach()
    
    if(NOT BOOST_TEST_TARGET)
        message(WARNING "No Boost unit test framework target found - continuing anyway")
    endif()
endif()