# Find or build IPOPT using ExternalProject when enabled
# Configures: Ipopt::Ipopt target

if(PAGMO_WITH_IPOPT)
    message(STATUS "Configuring IPOPT dependency...")
    
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
    
    message(STATUS "IPOPT will be built from source with system LAPACK/BLAS")
endif()