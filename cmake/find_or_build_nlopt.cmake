# Find or build NLopt using system installation or CPM when enabled
# Configures: NLopt::nlopt or nlopt target
# Option: PAGMO_FORCE_BUILD_NLOPT - Force building NLopt from source even if system version exists

if(PAGMO_WITH_NLOPT)
    # Add option to force building from source
    option(PAGMO_FORCE_BUILD_NLOPT "Force building NLopt from source instead of using system installation" OFF)
    
    message(STATUS "Configuring NLopt dependency...")
    
    set(_PAGMO_NLOPT_FOUND FALSE)
    set(_PAGMO_NLOPT_MINIMUM_VERSION 2.6.0)
    
    # First try to find system-installed NLopt (unless forced to build from source)
    if(NOT PAGMO_FORCE_BUILD_NLOPT)
        message(STATUS "Searching for system-installed NLopt...")
        
        # Try to find NLopt using CONFIG mode first (modern NLopt installations)
        find_package(NLopt ${_PAGMO_NLOPT_MINIMUM_VERSION} QUIET CONFIG)
        
        if(NLopt_FOUND)
            message(STATUS "Found system NLopt ${NLopt_VERSION} (CONFIG mode)")
            set(_PAGMO_NLOPT_FOUND TRUE)
            
            # Modern NLopt should provide NLopt::nlopt target
            if(TARGET NLopt::nlopt)
                message(STATUS "NLopt::nlopt target available")
            else()
                message(STATUS "Creating NLopt::nlopt target wrapper")
                add_library(NLopt::nlopt INTERFACE IMPORTED)
                if(TARGET nlopt)
                    target_link_libraries(NLopt::nlopt INTERFACE nlopt)
                endif()
            endif()
            
            message(STATUS "Using system-installed NLopt (CONFIG)")
        else()
            # Try traditional pkg-config based search
            find_package(PkgConfig QUIET)
            if(PkgConfig_FOUND)
                pkg_check_modules(NLOPT_PC QUIET nlopt>=${_PAGMO_NLOPT_MINIMUM_VERSION})
                if(NLOPT_PC_FOUND)
                    message(STATUS "Found system NLopt ${NLOPT_PC_VERSION} (pkg-config)")
                    set(_PAGMO_NLOPT_FOUND TRUE)
                    
                    # Create targets from pkg-config results
                    if(NOT TARGET NLopt::nlopt)
                        add_library(NLopt::nlopt INTERFACE IMPORTED)
                        target_include_directories(NLopt::nlopt INTERFACE ${NLOPT_PC_INCLUDE_DIRS})
                        target_link_libraries(NLopt::nlopt INTERFACE ${NLOPT_PC_LIBRARIES})
                        target_compile_options(NLopt::nlopt INTERFACE ${NLOPT_PC_CFLAGS_OTHER})
                    endif()
                    
                    message(STATUS "Using system-installed NLopt (pkg-config)")
                else()
                    message(STATUS "System NLopt not found via pkg-config")
                endif()
            else()
                message(STATUS "pkg-config not available, skipping traditional NLopt search")
            endif()
        endif()
    endif()
    
    # If system NLopt not found or forced to build from source, use CPM
    if(NOT _PAGMO_NLOPT_FOUND)
        message(STATUS "Building NLopt from source using CPM...")
        
        CPMFindPackage(
          NAME NLopt
          GITHUB_REPOSITORY stevengj/nlopt
          VERSION 2.7.1
          GIT_TAG v2.7.1
          OPTIONS "NLOPT_PYTHON OFF" "NLOPT_OCTAVE OFF" "NLOPT_MATLAB OFF" "NLOPT_GUILE OFF" "NLOPT_SWIG OFF" "NLOPT_TESTS OFF"
        )
        
        message(STATUS "Using CPM-built NLopt")
    endif()
    
    # Verify required targets exist (following the pattern from main CMakeLists.txt)
    if(TARGET NLopt::nlopt)
        message(STATUS "NLopt::nlopt target available")
    elseif(TARGET nlopt)
        message(STATUS "nlopt target available")
    else()
        message(FATAL_ERROR "No suitable NLopt target found")
    endif()
    
    # Clean up variables
    unset(_PAGMO_NLOPT_FOUND)
    unset(_PAGMO_NLOPT_MINIMUM_VERSION)
    
    message(STATUS "NLopt configured successfully")
endif()