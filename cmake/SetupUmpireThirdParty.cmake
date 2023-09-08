##############################################################################
# Copyright (c) 2016-23, Lawrence Livermore National Security, LLC and Umpire
# project contributors. See the COPYRIGHT file for details.
#
# SPDX-License-Identifier: (MIT)
##############################################################################
if (EXISTS ${SHROUD_EXECUTABLE})
  execute_process(COMMAND ${SHROUD_EXECUTABLE}
    --cmake ${CMAKE_CURRENT_BINARY_DIR}/SetupShroud.cmake
    ERROR_VARIABLE SHROUD_cmake_error
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  if (${SHROUD_cmake_error})
    message(FATAL_ERROR "Error from Shroud: ${SHROUD_cmake_error}")
  endif ()
  include(${CMAKE_CURRENT_BINARY_DIR}/SetupShroud.cmake)
endif ()

if (UMPIRE_ENABLE_UMAP)
  find_library( UMAP_LIBRARY
    libumap.so
    PATHS ${UMAP_ROOT}/lib
  )
  if (NOT UMAP_LIBRARY)
    message(FATAL_ERROR "Could not find UMAP library, check UMAP installation at UMAP_ROOT")
  endif()
  find_path( UMAP_INCLUDE_DIR
    NAMES "umap/umap.h"
    PATHS ${UMAP_ROOT}/include
  )
  if (NOT UMAP_INCLUDE_DIR)
    message(FATAL_ERROR "Headers missing, check UMAP installation at UMAP_ROOT")
  endif ()
  blt_import_library(NAME umap
    INCLUDES ${UMAP_INCLUDE_DIR}
    LIBRARIES ${UMAP_LIBRARY}
    DEPENDS_ON -lpthread -lrt)
endif ()

if (ENABLE_SLIC AND ENABLE_LOGGING)
  find_library( SLIC_LIBRARY
    libslic.a
    PATHS ${SLIC_LIBRARY_PATH} 
  )

  if (NOT SLIC_LIBRARY)
    message(FATAL_ERROR "Could not find SLIC library, make sure SLIC_LIBRARY_PATH is set properly")
  endif()

  find_library( SLIC_UTIL_LIBRARY
    libaxom_utils.a
    PATHS ${SLIC_LIBRARY_PATH} 
  )

  if (NOT SLIC_UTIL_LIBRARY)
    message(FATAL_ERROR "Could not find Axom Utility Library for SLIC, make sure SLIC_LIBRARY_PATH is set properly")
  endif()

  find_path( SLIC_INCLUDE_DIR
    slic/slic.hpp
    PATHS ${SLIC_INCLUDE_PATH}
  )

  if (NOT SLIC_INCLUDE_DIR)
    message(FATAL_ERROR "Could not find SLIC include directory, make sure SLIC_INCLUDE_PATH is set properly")
  endif()

  blt_register_library( NAME slic
                        INCLUDES ${SLIC_INCLUDE_DIR}
                        LIBRARIES ${SLIC_LIBRARY} ${SLIC_UTIL_LIBRARY}
                      )
endif ()

if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
  blt_register_library( NAME backtrace_symbols
    LIBRARIES ${CMAKE_DL_LIBS}
    )
endif ()

if (UMPIRE_ENABLE_SQLITE_EXPERIMENTAL)
  find_package(SQLite3 REQUIRED)
endif()


#################################################
# use bonafide cmake targets for openmp and mpi
#################################################
set(umpire_mpi_deps "")
if (UMPIRE_ENABLE_MPI)
  if(ENABLE_FIND_MPI)
      set (umpire_mpi_deps MPI::MPI_CXX)
  endif()
endif()

set(umpire_openmp_deps "")
if (UMPIRE_ENABLE_OPENMP)
  set (umpire_openmp_deps OpenMP::OpenMP_CXX)
endif ()

#################################################
# export necessary blt targets
#################################################

set(UMPIRE_BLT_TPL_DEPS_EXPORTS)

blt_list_append(TO UMPIRE_BLT_TPL_DEPS_EXPORTS ELEMENTS cuda cuda_runtime IF UMPIRE_ENABLE_CUDA)
blt_list_append(TO UMPIRE_BLT_TPL_DEPS_EXPORTS ELEMENTS blt_hip blt_hip_runtime IF UMPIRE_ENABLE_HIP)

foreach(dep ${UMPIRE_BLT_TPL_DEPS_EXPORTS})
    # If the target is EXPORTABLE, add it to the export set
    get_target_property(_is_imported ${dep} IMPORTED)
    if(NOT ${_is_imported})
        install(TARGETS              ${dep}
                EXPORT               umpire-targets
                DESTINATION          lib/cmake/umpire)
        # Namespace target to avoid conflicts
        set_target_properties(${dep} PROPERTIES EXPORT_NAME umpire::blt_tpl_exports_${dep})
    endif()
endforeach()

