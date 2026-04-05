# Find or build Boost using system installation or CPM
# Configures: boost_serialization, boost_unit_test_framework (if testing enabled)
# Option: PAGMO_FORCE_BUILD_BOOST - Force building Boost from source even if system version exists

# Add option to force building from source
option(PAGMO_FORCE_BUILD_BOOST "Force building Boost from source instead of using system installation" OFF)

# Set minimum version and required libraries (following PagmoFindBoost.cmake patterns)
set(_PAGMO_BOOST_MINIMUM_VERSION 1.68.0)
set(_PAGMO_REQUIRED_BOOST_LIBS serialization)

# Add the unit test framework, if needed.
if(_PAGMO_FIND_BOOST_UNIT_TEST_FRAMEWORK)
    list(APPEND _PAGMO_REQUIRED_BOOST_LIBS unit_test_framework)
endif()

message(STATUS "Configuring Boost dependency...")
message(STATUS "Required Boost libraries: ${_PAGMO_REQUIRED_BOOST_LIBS}")

set(_PAGMO_BOOST_FOUND FALSE)

# First try to find system-installed Boost (unless forced to build from source)
if(NOT PAGMO_FORCE_BUILD_BOOST)
    message(STATUS "Searching for system-installed Boost...")
    
    # Try to find Boost using CONFIG mode (more robust)
    find_package(Boost ${_PAGMO_BOOST_MINIMUM_VERSION} QUIET CONFIG COMPONENTS ${_PAGMO_REQUIRED_BOOST_LIBS})
    
    if(Boost_FOUND)
        message(STATUS "Found system Boost ${Boost_VERSION}")
        message(STATUS "Boost include dirs: ${Boost_INCLUDE_DIRS}")
        set(_PAGMO_BOOST_FOUND TRUE)
        
        # Recreate missing targets if needed (following PagmoFindBoost.cmake patterns)
        if(NOT TARGET Boost::boost)
            message(STATUS "The 'Boost::boost' target is missing, creating it.")
            add_library(Boost::boost INTERFACE IMPORTED)
            set_target_properties(Boost::boost PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}")
        endif()
        
        if(NOT TARGET Boost::disable_autolinking)
            message(STATUS "The 'Boost::disable_autolinking' target is missing, creating it.")
            add_library(Boost::disable_autolinking INTERFACE IMPORTED)
            if(WIN32)
                set_target_properties(Boost::disable_autolinking PROPERTIES INTERFACE_COMPILE_DEFINITIONS "BOOST_ALL_NO_LIB")
            endif()
        endif()
        
        # Create missing component targets if needed
        foreach(_PAGMO_BOOST_COMPONENT ${_PAGMO_REQUIRED_BOOST_LIBS})
            if(NOT TARGET Boost::${_PAGMO_BOOST_COMPONENT})
                message(STATUS "The 'Boost::${_PAGMO_BOOST_COMPONENT}' imported target is missing, creating it.")
                string(TOUPPER ${_PAGMO_BOOST_COMPONENT} _PAGMO_BOOST_UPPER_COMPONENT)
                if(Boost_USE_STATIC_LIBS)
                    add_library(Boost::${_PAGMO_BOOST_COMPONENT} STATIC IMPORTED)
                else()
                    add_library(Boost::${_PAGMO_BOOST_COMPONENT} UNKNOWN IMPORTED)
                endif()
                set_target_properties(Boost::${_PAGMO_BOOST_COMPONENT} PROPERTIES
                    INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}")
                set_target_properties(Boost::${_PAGMO_BOOST_COMPONENT} PROPERTIES
                    IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
                    IMPORTED_LOCATION "${Boost_${_PAGMO_BOOST_UPPER_COMPONENT}_LIBRARY}")
            endif()
        endforeach()
        
        # Create interface targets matching our expected naming convention
        if(NOT TARGET boost_serialization)
            add_library(boost_serialization INTERFACE IMPORTED)
            target_link_libraries(boost_serialization INTERFACE Boost::serialization)
        endif()
        
        if(_PAGMO_FIND_BOOST_UNIT_TEST_FRAMEWORK AND NOT TARGET boost_unit_test_framework)
            if(TARGET Boost::unit_test_framework)
                add_library(boost_unit_test_framework INTERFACE IMPORTED)
                target_link_libraries(boost_unit_test_framework INTERFACE Boost::unit_test_framework)
            endif()
        endif()
        
        message(STATUS "Using system-installed Boost")
    else()
        message(STATUS "System Boost not found or insufficient version")
    endif()
endif()

# If system Boost not found or forced to build from source, use CPM
if(NOT _PAGMO_BOOST_FOUND)
    message(STATUS "Building Boost from source using CPM...")
    
    CPMAddPackage(
        NAME Boost
        VERSION 1.83.0
        URL https://github.com/boostorg/boost/releases/download/boost-1.83.0/boost-1.83.0.tar.xz
        OPTIONS
            "BOOST_ENABLE_CMAKE ON"
            "BOOST_INCLUDE_LIBRARIES serialization\\\\;test\\\\;system\\\\;filesystem"
            "CMAKE_POSITION_INDEPENDENT_CODE ON"
            "BUILD_SHARED_LIBS OFF"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    
    message(STATUS "Using CPM-built Boost")
endif()

# Verify required targets exist
if(TARGET boost_serialization)
    message(STATUS "boost_serialization target available")
else()
    message(FATAL_ERROR "boost_serialization target not found")
endif()

if(_PAGMO_FIND_BOOST_UNIT_TEST_FRAMEWORK)
    if(TARGET boost_unit_test_framework)
        message(STATUS "boost_unit_test_framework target available")
    elseif(TARGET boost_test)
        message(STATUS "boost_test target available")
    else()
        message(FATAL_ERROR "No Boost unit test framework target found")
    endif()
endif()

# Clean up variables (following PagmoFindBoost.cmake patterns)
unset(_PAGMO_BOOST_MINIMUM_VERSION)
unset(_PAGMO_REQUIRED_BOOST_LIBS)
unset(_PAGMO_BOOST_FOUND)