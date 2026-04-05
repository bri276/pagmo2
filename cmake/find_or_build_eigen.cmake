# Find or build Eigen3 using system installation or CPM when enabled
# Configures: Eigen3::Eigen target
# Option: PAGMO_FORCE_BUILD_EIGEN3 - Force building Eigen3 from source even if system version exists

if(PAGMO_WITH_EIGEN3)
    # Add option to force building from source
    option(PAGMO_FORCE_BUILD_EIGEN3 "Force building Eigen3 from source instead of using system installation" OFF)
    
    message(STATUS "Configuring Eigen3 dependency...")
    
    set(_PAGMO_EIGEN3_FOUND FALSE)
    set(_PAGMO_EIGEN3_MINIMUM_VERSION 3.3.0)
    
    # First try to find system-installed Eigen3 (unless forced to build from source)
    if(NOT PAGMO_FORCE_BUILD_EIGEN3)
        message(STATUS "Searching for system-installed Eigen3...")
        
        # Try to find Eigen3 using the standard CMake module
        find_package(Eigen3 ${_PAGMO_EIGEN3_MINIMUM_VERSION} QUIET NO_MODULE)
        
        if(Eigen3_FOUND)
            message(STATUS "Found system Eigen3 ${Eigen3_VERSION}")
            set(_PAGMO_EIGEN3_FOUND TRUE)
            
            # Verify the target exists (it should with modern Eigen3)
            if(NOT TARGET Eigen3::Eigen)
                message(STATUS "The 'Eigen3::Eigen' target is missing, creating it.")
                add_library(Eigen3::Eigen INTERFACE IMPORTED)
                set_target_properties(Eigen3::Eigen PROPERTIES 
                    INTERFACE_INCLUDE_DIRECTORIES "${EIGEN3_INCLUDE_DIR}")
            endif()
            
            message(STATUS "Using system-installed Eigen3")
        else()
            message(STATUS "System Eigen3 not found or insufficient version (need >= ${_PAGMO_EIGEN3_MINIMUM_VERSION})")
        endif()
    endif()
    
    # If system Eigen3 not found or forced to build from source, use CPM
    if(NOT _PAGMO_EIGEN3_FOUND)
        message(STATUS "Building Eigen3 from source using CPM...")
        
        CPMFindPackage(
          NAME Eigen3
          GITLAB_REPOSITORY libeigen/eigen
          VERSION 3.4.0
          GIT_TAG 3.4.0
          OPTIONS "EIGEN_BUILD_DOC OFF" "EIGEN_BUILD_TESTING OFF"
        )
        
        message(STATUS "Using CPM-built Eigen3")
    endif()
    
    # Verify the target exists
    if(TARGET Eigen3::Eigen)
        message(STATUS "Eigen3::Eigen target available")
    else()
        message(FATAL_ERROR "Eigen3::Eigen target not found")
    endif()
    
    # Clean up variables
    unset(_PAGMO_EIGEN3_FOUND)
    unset(_PAGMO_EIGEN3_MINIMUM_VERSION)
    
    message(STATUS "Eigen3 configured successfully")
endif()