set(MOVEIT_LIB_NAME moveit_collision_detection_fcl)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(fcl REQUIRED)
include_directories(${FCL_INCLUDE_DIRS})

add_library(${MOVEIT_LIB_NAME}
  src/collision_common.cpp
  src/collision_env_fcl.cpp
)
set_target_properties(${MOVEIT_LIB_NAME} PROPERTIES VERSION "${${PROJECT_NAME}_VERSION}")


target_link_libraries(${MOVEIT_LIB_NAME} moveit_collision_detection ${catkin_LIBRARIES} ${urdfdom_LIBRARIES} ${urdfdom_headers_LIBRARIES} ${fcl_LIBRARIES} ${Boost_LIBRARIES})
add_dependencies(${MOVEIT_LIB_NAME} ${catkin_EXPORTED_TARGETS})

add_library(collision_detector_fcl_plugin src/collision_detector_fcl_plugin_loader.cpp)
set_target_properties(collision_detector_fcl_plugin PROPERTIES VERSION "${${PROJECT_NAME}_VERSION}")
target_link_libraries(collision_detector_fcl_plugin ${catkin_LIBRARIES} ${MOVEIT_LIB_NAME} moveit_planning_scene)


install(TARGETS ${MOVEIT_LIB_NAME} collision_detector_fcl_plugin
        LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
        ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
        RUNTIME DESTINATION ${CATKIN_GLOBAL_BIN_DESTINATION})

install(DIRECTORY include/ DESTINATION ${CATKIN_GLOBAL_INCLUDE_DESTINATION})

install(FILES ../collision_detector_fcl_description.xml DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})

if(CATKIN_ENABLE_TESTING)
  catkin_add_gtest(test_fcl_collision_detection test/test_fcl_collision_detection_pr2.cpp)
  target_link_libraries(test_fcl_collision_detection moveit_test_utils ${MOVEIT_LIB_NAME} ${Boost_LIBRARIES})
  if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # TODO: remove if transition to gtest's new API TYPED_TEST_SUITE_P is finished
    target_compile_options(test_fcl_collision_detection PRIVATE -Wno-deprecated-declarations)
  endif()

  catkin_add_gtest(test_fcl_collision_detection_panda test/test_fcl_collision_detection_panda.cpp)
  target_link_libraries(test_fcl_collision_detection_panda moveit_test_utils ${MOVEIT_LIB_NAME} ${Boost_LIBRARIES})
  if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # TODO: remove if transition to gtest's new API TYPED_TEST_SUITE_P is finished
    target_compile_options(test_fcl_collision_detection_panda PRIVATE -Wno-deprecated-declarations)
  endif()
endif()
