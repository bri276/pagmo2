# Find or build IPOPT using system installation or ExternalProject when enabled
# Configures: Ipopt::Ipopt target
# Option: PAGMO_FORCE_BUILD_IPOPT - Force building IPOPT from source even if system version exists

if(PAGMO_WITH_IPOPT)
    # Add option to force building from source
    option(PAGMO_FORCE_BUILD_IPOPT "Force building IPOPT from source instead of using system installation" OFF)
    
    message(STATUS "Configuring IPOPT dependency...")
    
    set(_PAGMO_IPOPT_FOUND FALSE)
    
    # First try to find system-installed IPOPT (unless forced to build from source)
    if(NOT PAGMO_FORCE_BUILD_IPOPT)
        message(STATUS "Searching for system-installed IPOPT...")
        
        # Use the same approach as Findpagmo_IPOPT.cmake but simplified
        # Look for IPOPT headers
        find_path(PAGMO_IPOPT_INCLUDE_DIR NAMES IpIpoptNLP.hpp PATH_SUFFIXES coin coin-or)
        # Look for IPOPT library
        find_library(PAGMO_IPOPT_LIBRARY NAMES ipopt ipopt-3)
        
        # Check if both header and library were found
        include(FindPackageHandleStandardArgs)
        find_package_handle_standard_args(IPOPT_SYSTEM DEFAULT_MSG 
            PAGMO_IPOPT_INCLUDE_DIR PAGMO_IPOPT_LIBRARY)
        
        if(IPOPT_SYSTEM_FOUND)
            message(STATUS "Found system IPOPT")
            message(STATUS "IPOPT include dir: ${PAGMO_IPOPT_INCLUDE_DIR}")
            message(STATUS "IPOPT library: ${PAGMO_IPOPT_LIBRARY}")
            set(_PAGMO_IPOPT_FOUND TRUE)
            
            # Create component targets following Findpagmo_IPOPT.cmake patterns
            if(NOT TARGET pagmo::IPOPT::header)
                message(STATUS "Creating the 'pagmo::IPOPT::header' imported target.")
                add_library(pagmo::IPOPT::header INTERFACE IMPORTED)
                set_target_properties(pagmo::IPOPT::header PROPERTIES 
                    INTERFACE_INCLUDE_DIRECTORIES "${PAGMO_IPOPT_INCLUDE_DIR}")
            endif()
            
            if(NOT TARGET pagmo::IPOPT::libipopt)
                message(STATUS "Creating the 'pagmo::IPOPT::libipopt' imported target.")
                add_library(pagmo::IPOPT::libipopt UNKNOWN IMPORTED)
                set_target_properties(pagmo::IPOPT::libipopt PROPERTIES 
                    IMPORTED_LOCATION "${PAGMO_IPOPT_LIBRARY}")
            endif()
            
            # Create the standard Ipopt::Ipopt target expected by the rest of the code
            if(NOT TARGET Ipopt::Ipopt)
                add_library(Ipopt::Ipopt INTERFACE IMPORTED)
                target_link_libraries(Ipopt::Ipopt INTERFACE 
                    pagmo::IPOPT::header 
                    pagmo::IPOPT::libipopt
                    lapack 
                    blas)
            endif()
            
            # Mark variables as advanced (following Findpagmo_IPOPT.cmake pattern)
            mark_as_advanced(PAGMO_IPOPT_INCLUDE_DIR PAGMO_IPOPT_LIBRARY)
            
            message(STATUS "Using system-installed IPOPT")
        else()
            message(STATUS "System IPOPT not found")
        endif()
    endif()
    
    # If system IPOPT not found or forced to build from source, use ExternalProject
    if(NOT _PAGMO_IPOPT_FOUND)
        message(STATUS "Building IPOPT from source using ExternalProject...")
        
        include(ExternalProject)
        
        # Set the install directory
        set(IPOPT_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/ipopt_install)
        
        # Create the include directory structure beforehand
        file(MAKE_DIRECTORY ${IPOPT_INSTALL_DIR}/include/coin-or)
        file(MAKE_DIRECTORY ${IPOPT_INSTALL_DIR}/lib)
        
        # Build IPOPT from source using ExternalProject
        ExternalProject_Add(
            ipopt_external
            GIT_REPOSITORY https://github.com/coin-or/Ipopt.git
            GIT_TAG releases/3.14.12
            PREFIX ${CMAKE_CURRENT_BINARY_DIR}/ipopt
            CONFIGURE_COMMAND <SOURCE_DIR>/configure 
                --prefix=${IPOPT_INSTALL_DIR}
                --disable-shared
                --enable-static
                --with-pic
                --with-lapack=-llapack
                --with-blas=-lblas
            BUILD_COMMAND make
            INSTALL_COMMAND make install
            LOG_CONFIGURE ON
            LOG_BUILD ON
            LOG_INSTALL ON
        )
        
        # Create an interface target for IPOPT (using namespaced name to avoid conflicts)
        add_library(Ipopt::Ipopt INTERFACE IMPORTED)
        add_dependencies(Ipopt::Ipopt ipopt_external)
        
        # Set include directories and libraries
        target_include_directories(Ipopt::Ipopt INTERFACE ${IPOPT_INSTALL_DIR}/include/coin-or)
        target_link_libraries(Ipopt::Ipopt INTERFACE 
            ${IPOPT_INSTALL_DIR}/lib/libipopt.a
            lapack
            blas
        )
        
        message(STATUS "Using ExternalProject-built IPOPT with system LAPACK/BLAS")
    endif()
    
    # Verify the target exists
    if(TARGET Ipopt::Ipopt)
        message(STATUS "Ipopt::Ipopt target available")
    else()
        message(FATAL_ERROR "Ipopt::Ipopt target not found")
    endif()
    
    # Clean up variables
    unset(_PAGMO_IPOPT_FOUND)
    
    message(STATUS "IPOPT configured successfully")
endif()