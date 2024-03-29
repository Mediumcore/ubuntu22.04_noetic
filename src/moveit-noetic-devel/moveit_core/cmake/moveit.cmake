macro(moveit_build_options)
  # for Ubuntu bionic/focal
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  # if((CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "11") OR
  #    (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "16"))
  #   if(NOT "${CMAKE_CXX_STANDARD}")
  #     set(CMAKE_CXX_STANDARD 17)
  #   endif()
  #   set(CMAKE_CXX_STANDARD_REQUIRED ON)
  #   set(CMAKE_CXX_EXTENSIONS OFF)
  # endif()

  find_package(backward_ros QUIET)

  if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    message("${PROJECT_NAME}: You did not request a specific build type: Choosing 'Release' for maximum performance")
    set(CMAKE_BUILD_TYPE Release)
  endif()

  option(MOVEIT_CI_WARNINGS "Enable all warnings used by CI" ON)
  if(MOVEIT_CI_WARNINGS)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      add_compile_options(-Wall -Wextra -Wwrite-strings -Wunreachable-code -Wpointer-arith -Wredundant-decls -Wcast-qual)
    endif()
    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
      add_compile_options(-Wall -Wextra -Wwrite-strings -Wunreachable-code -Wpointer-arith -Wredundant-decls -Wcast-qual)
    endif()
  endif()
endmacro()

# catkin_package DEPENDS does not consider INTERFACE_* of imported targets.
# this macro makes them explicit in ${namespace}_INCLUDE_DIRS and ${namespace}_LIBRARIES
# so that catkin-generated cmake files include them for downstream packages
macro(moveit_get_include_and_libs_from_target namespace tgt)
  get_target_property(${namespace}_INCLUDE_DIRS ${tgt} INTERFACE_INCLUDE_DIRECTORIES)

  get_target_property(${namespace}_INTERFACE_LINK_LIBRARIES ${tgt} INTERFACE_LINK_LIBRARIES)
  set(${namespace}_LIBRARIES ${tgt} ${${namespace}_INTERFACE_LINK_LIBRARIES})
endmacro()
