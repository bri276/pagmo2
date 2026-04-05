# Find or build TBB using system installation or CPM
# Sets up: pagmo_tbb_wrapper target
# Option: PAGMO_FORCE_BUILD_TBB - Force building TBB from source even if system version exists

# Add option to force building from source
option(PAGMO_FORCE_BUILD_TBB "Force building TBB from source instead of using system installation" OFF)

message(STATUS "Configuring TBB dependency...")

set(_PAGMO_TBB_FOUND FALSE)

# First try to find system-installed TBB (unless forced to build from source)
if(NOT PAGMO_FORCE_BUILD_TBB)
    message(STATUS "Searching for system-installed TBB...")
    
    # Try modern TBB CONFIG-based detection first
    find_package(TBB QUIET CONFIG)
    
    if(TBB_FOUND)
        message(STATUS "Found system TBB ${TBB_VERSION} (CONFIG mode)")
        set(_PAGMO_TBB_FOUND TRUE)
        
        # Modern TBB should provide TBB::tbb target
        if(TARGET TBB::tbb)
            message(STATUS "TBB::tbb target available from system installation")
        endif()
        
        message(STATUS "Using system-installed TBB (CONFIG)")
    else()
        # Fallback to traditional FindTBB.cmake approach
        # Look for TBB headers and libraries manually following FindTBB.cmake patterns
        set(_TBB_SEARCH_DIRS)
        
        # Get environment variables for TBB search paths
        if(DEFINED ENV{TBB_ROOT})
            list(APPEND _TBB_SEARCH_DIRS $ENV{TBB_ROOT})
        endif()
        if(DEFINED TBB_ROOT)
            list(APPEND _TBB_SEARCH_DIRS ${TBB_ROOT})
        endif()
        
        # Add common system locations
        list(APPEND _TBB_SEARCH_DIRS
            /usr/local
            /usr
            /opt/intel/tbb
            /opt/tbb)
        
        # Build include search paths
        set(_TBB_INCLUDE_SEARCH_PATHS)
        foreach(dir IN LISTS _TBB_SEARCH_DIRS)
            list(APPEND _TBB_INCLUDE_SEARCH_PATHS 
                ${dir}/include 
                ${dir}/Include
                ${dir}/include/tbb)
        endforeach()
        
        # Build library search paths
        set(_TBB_LIB_SEARCH_PATHS)
        foreach(dir IN LISTS _TBB_SEARCH_DIRS)
            list(APPEND _TBB_LIB_SEARCH_PATHS 
                ${dir}/lib 
                ${dir}/Lib 
                ${dir}/lib/tbb
                ${dir}/lib64
                ${dir}/lib/x86_64-linux-gnu)
            # Add architecture-specific paths
            if(CMAKE_SIZEOF_VOID_P EQUAL 8)
                list(APPEND _TBB_LIB_SEARCH_PATHS 
                    ${dir}/lib/intel64 
                    ${dir}/intel64/lib)
            else()
                list(APPEND _TBB_LIB_SEARCH_PATHS 
                    ${dir}/lib/ia32 
                    ${dir}/ia32/lib)
            endif()
        endforeach()
        
        # Find TBB headers
        find_path(_TBB_INCLUDE_DIR
            NAMES tbb/tbb.h
            PATHS ${_TBB_INCLUDE_SEARCH_PATHS}
            NO_DEFAULT_PATH)
        find_path(_TBB_INCLUDE_DIR NAMES tbb/tbb.h)
        
        # Find TBB library
        find_library(_TBB_LIBRARY
            NAMES tbb
            PATHS ${_TBB_LIB_SEARCH_PATHS}
            NO_DEFAULT_PATH)
        find_library(_TBB_LIBRARY NAMES tbb)
        
        # Check if both header and library were found
        include(FindPackageHandleStandardArgs)
        find_package_handle_standard_args(TBB_SYSTEM DEFAULT_MSG
            _TBB_INCLUDE_DIR _TBB_LIBRARY)
        
        if(TBB_SYSTEM_FOUND)
            message(STATUS "Found system TBB")
            message(STATUS "TBB include dir: ${_TBB_INCLUDE_DIR}")
            message(STATUS "TBB library: ${_TBB_LIBRARY}")
            set(_PAGMO_TBB_FOUND TRUE)
            
            # Create TBB::tbb target following FindTBB.cmake patterns
            if(NOT TARGET TBB::tbb)
                add_library(TBB::tbb UNKNOWN IMPORTED)
                set_target_properties(TBB::tbb PROPERTIES
                    INTERFACE_INCLUDE_DIRECTORIES "${_TBB_INCLUDE_DIR}"
                    IMPORTED_LOCATION "${_TBB_LIBRARY}")
            endif()
            
            # Mark variables as advanced
            mark_as_advanced(_TBB_INCLUDE_DIR _TBB_LIBRARY)
            
            message(STATUS "Using system-installed TBB (traditional detection)")
        else()
            message(STATUS "System TBB not found")
        endif()
    endif()
endif()

# If system TBB not found or forced to build from source, use CPM
if(NOT _PAGMO_TBB_FOUND)
    message(STATUS "Building TBB from source using CPM...")
    
    CPMFindPackage(
      NAME TBB
      GITHUB_REPOSITORY oneapi-src/oneTBB
      VERSION 2021.10.0
      GIT_TAG v2021.10.0
      OPTIONS "TBB_TEST OFF" "TBB_BUILD_TESTS OFF"
    )
    
    message(STATUS "Using CPM-built TBB")
endif()

# Handle TBB target - create a working wrapper
if(TARGET TBB::tbb)
    message(STATUS "TBB::tbb target available")
    
    # Create a wrapper interface target to work around include issues
    if(NOT TARGET pagmo_tbb_wrapper)
        add_library(pagmo_tbb_wrapper INTERFACE)
        # Add proper include directory 
        if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/_deps/tbb-src/include")
            target_include_directories(pagmo_tbb_wrapper INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/_deps/tbb-src/include")
        endif()
        # Link to the actual TBB library files without problematic includes
        get_target_property(TBB_LIBS TBB::tbb INTERFACE_LINK_LIBRARIES)
        if(TBB_LIBS AND NOT "${TBB_LIBS}" STREQUAL "TBB_LIBS-NOTFOUND")
            target_link_libraries(pagmo_tbb_wrapper INTERFACE ${TBB_LIBS})
        endif()
        # Try to link to compiled libraries directly
        if(TARGET tbb)
            target_link_libraries(pagmo_tbb_wrapper INTERFACE tbb)
        endif()
        # Link to TBB::tbb itself
        target_link_libraries(pagmo_tbb_wrapper INTERFACE TBB::tbb)
    endif()
elseif(TARGET tbb)
    message(STATUS "tbb target available, creating wrapper")
    add_library(pagmo_tbb_wrapper INTERFACE)
    target_link_libraries(pagmo_tbb_wrapper INTERFACE tbb)
    # Also create TBB::tbb alias for compatibility
    add_library(TBB::tbb ALIAS tbb)
else()
    message(FATAL_ERROR "No TBB target found")
endif()

# Debug: Check what TBB targets exist
get_property(ALL_TARGETS DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
foreach(target ${ALL_TARGETS})
    if("${target}" MATCHES "[Tt][Bb][Bb]")
        message(STATUS "Found TBB-related target: ${target}")
    endif()
endforeach()

# Clean up variables
unset(_PAGMO_TBB_FOUND)

message(STATUS "TBB configured successfully")
endforeach()