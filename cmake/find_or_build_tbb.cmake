# Find or build TBB using CPM with proper target handling
# Sets up: pagmo_tbb_wrapper target

message(STATUS "Configuring TBB dependency...")

CPMFindPackage(
  NAME TBB
  GITHUB_REPOSITORY oneapi-src/oneTBB
  VERSION 2021.10.0
  GIT_TAG v2021.10.0
  OPTIONS "TBB_TEST OFF" "TBB_BUILD_TESTS OFF"
)

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