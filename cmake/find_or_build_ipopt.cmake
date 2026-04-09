# Find or build IPOPT using ExternalProject when enabled
# Configures: Ipopt::Ipopt target

if(PAGMO_WITH_IPOPT)
    message(STATUS "Configuring IPOPT dependency...")
    
    include(ExternalProject)
    
    # Place ipopt in the shared deps cache when available so all build types
    # (release, debug, etc.) share the same build and installation of ipopt
    if(DEFINED CPM_SOURCE_CACHE)
        set(_IPOPT_BASE_DIR "${CPM_SOURCE_CACHE}/ipopt")
    else()
        set(_IPOPT_BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}/ipopt")
    endif()

    # Set the install directory
    set(IPOPT_INSTALL_DIR "${_IPOPT_BASE_DIR}_install")
    
    # Create the include directory structure beforehand
    file(MAKE_DIRECTORY ${IPOPT_INSTALL_DIR}/include/coin-or)
    file(MAKE_DIRECTORY ${IPOPT_INSTALL_DIR}/lib)
    
    # Build IPOPT from source using ExternalProject with minimal dependencies
    ExternalProject_Add(
        ipopt_external
        URL https://github.com/coin-or/Ipopt/archive/releases/3.14.12.tar.gz
        PREFIX ${_IPOPT_BASE_DIR}
        CONFIGURE_COMMAND <SOURCE_DIR>/configure 
            --prefix=${IPOPT_INSTALL_DIR}
            --disable-shared
            --enable-static
            --with-pic
            --with-lapack-lflags=-llapack\ -lblas
            --without-hsl
            --without-mumps
            --without-asl  
            --disable-linear-solver-loader
            CXX=${CMAKE_CXX_COMPILER}
            CC=${CMAKE_C_COMPILER}
            F77=gfortran
            FC=gfortran
        BUILD_COMMAND make
        INSTALL_COMMAND make install
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON
        DOWNLOAD_EXTRACT_TIMESTAMP ON
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
        gfortran
    )
    
    message(STATUS "IPOPT will be built from source with linear solver disabled")
endif()