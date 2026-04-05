# Find or build Boost using CPM with required components
# Configures: boost_serialization, boost_unit_test_framework (if testing enabled)

# Determine required Boost libraries
set(_PAGMO_REQUIRED_BOOST_LIBS serialization)
if(PAGMO_BUILD_TESTS)
    list(APPEND _PAGMO_REQUIRED_BOOST_LIBS unit_test_framework)
    # Internal variable that will be used to tell PagmoFindBoost to locate the
    # Boost unit test framework, if tests are required.
    set(_PAGMO_FIND_BOOST_UNIT_TEST_FRAMEWORK TRUE)
endif()

message(STATUS "Configuring Boost dependency...")

# Use CPM for Boost to ensure reliable component availability
message(STATUS "Using CPM for Boost to ensure reliable component availability")
CPMAddPackage(
    NAME Boost
    VERSION 1.83.0
    URL https://github.com/boostorg/boost/releases/download/boost-1.83.0/boost-1.83.0.tar.xz
    OPTIONS
        "BOOST_ENABLE_CMAKE ON"
        "BOOST_INCLUDE_LIBRARIES serialization\\\\;test\\\\;system\\\\;filesystem\\\\;any"
        "CMAKE_POSITION_INDEPENDENT_CODE ON"
        "BUILD_SHARED_LIBS OFF"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

# Verify CPM-provided Boost targets exist
message(STATUS "Required Boost libraries: ${_PAGMO_REQUIRED_BOOST_LIBS}")
if(TARGET boost_serialization)
    message(STATUS "boost_serialization target available")
else()
    message(FATAL_ERROR "boost_serialization target not found")
endif()

if(PAGMO_BUILD_TESTS)
    if(TARGET boost_unit_test_framework)
        message(STATUS "boost_unit_test_framework target available")
    elseif(TARGET boost_test)
        message(STATUS "boost_test target available")
    else()
        message(FATAL_ERROR "No Boost unit test framework target found")
    endif()
endif()