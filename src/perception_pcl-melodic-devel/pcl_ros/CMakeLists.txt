cmake_minimum_required(VERSION 3.0.2)
project(pcl_ros)

# CMake 3.1 added support for CMAKE_CXX_STANDARD to manage the C++ standard version
# Use CMake C++ standard management where possible for better interoperability
# with dependencies that export target standards and/or features
if (${CMAKE_VERSION} VERSION_LESS "3.1")
  add_compile_options(-std=c++17)
else()
  set(CMAKE_CXX_STANDARD 17)
endif()

## Find catkin packages
find_package(catkin REQUIRED COMPONENTS
  dynamic_reconfigure
  geometry_msgs
  message_filters
  nodelet
  nodelet_topic_tools
  pcl_conversions
  pcl_msgs
  pluginlib
  rosbag
  rosconsole
  roscpp
  roslib
  sensor_msgs
  std_msgs
  tf
  tf2
  tf2_eigen
  tf2_ros
)

## Find system dependencies
find_package(PCL REQUIRED COMPONENTS common features filters io segmentation surface)
find_package(Boost REQUIRED COMPONENTS system filesystem thread)
find_package(Eigen3 REQUIRED)

if(NOT "${PCL_LIBRARIES}" STREQUAL "")
  # For debian: https://github.com/ros-perception/perception_pcl/issues/139
  list(REMOVE_ITEM PCL_LIBRARIES
    "vtkGUISupportQt"
    "vtkGUISupportQtOpenGL"
    "vtkGUISupportQtSQL"
    "vtkGUISupportQtWebkit"
    "vtkViewsQt"
    "vtkRenderingQt")
endif()

# There is a bug in the Ubuntu Artful (17.10) version of the VTK package,
# where it includes /usr/include/*-linux-gnu/freetype2 in the include
# directories (which doesn't exist).  This filters down to the PCL_INCLUDE_DIRS,
# and causes downstream projects trying to use these libraries to fail to
# configure properly.  Here we remove those bogus entries so that downstream
# consumers of this package succeed.
if(NOT "${PCL_INCLUDE_DIRS}" STREQUAL "")
  foreach(item ${PCL_INCLUDE_DIRS})
    string(REGEX MATCH "/usr/include/.*-linux-gnu/freetype2" item ${item})
    if(item)
      list(REMOVE_ITEM PCL_INCLUDE_DIRS ${item})
    endif()
  endforeach()
endif()

## Add include directories
include_directories(include)

include_directories(
  SYSTEM
    ${Boost_INCLUDE_DIRS}
    ${catkin_INCLUDE_DIRS}
    ${EIGEN3_INCLUDE_DIRS}
    ${PCL_INCLUDE_DIRS}
)

## Generate dynamic_reconfigure
generate_dynamic_reconfigure_options(
  cfg/EuclideanClusterExtraction.cfg
  cfg/ExtractIndices.cfg
  cfg/ExtractPolygonalPrismData.cfg
  cfg/Feature.cfg
  cfg/Filter.cfg
  cfg/MLS.cfg
  cfg/SACSegmentation.cfg
  cfg/SACSegmentationFromNormals.cfg
  cfg/SegmentDifferences.cfg
  cfg/StatisticalOutlierRemoval.cfg
  cfg/RadiusOutlierRemoval.cfg
  cfg/VoxelGrid.cfg
  cfg/CropBox.cfg
)

## Declare the catkin package
catkin_package(
  INCLUDE_DIRS include
  LIBRARIES
    pcl_ros_filter
    pcl_ros_tf
  CATKIN_DEPENDS
    dynamic_reconfigure
    geometry_msgs
    message_filters
    nodelet
    nodelet_topic_tools
    pcl_conversions
    pcl_msgs
    rosbag
    roscpp
    sensor_msgs
    std_msgs
    tf
    tf2
    tf2_eigen
    tf2_ros
  DEPENDS
    Boost
    EIGEN3
    PCL
)

## Declare the pcl_ros_tf library
add_library(pcl_ros_tf src/transforms.cpp)
target_link_libraries(pcl_ros_tf ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})
add_dependencies(pcl_ros_tf ${catkin_EXPORTED_TARGETS})

## Nodelets

## Declare the pcl_ros_io library
add_library(pcl_ros_io
  src/pcl_ros/io/bag_io.cpp
  src/pcl_ros/io/concatenate_data.cpp
  src/pcl_ros/io/concatenate_fields.cpp
  src/pcl_ros/io/io.cpp
  src/pcl_ros/io/pcd_io.cpp
)
target_link_libraries(pcl_ros_io pcl_ros_tf ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})
class_loader_hide_library_symbols(pcl_ros_io)

## Declare the pcl_ros_features library
add_library(pcl_ros_features
  src/pcl_ros/features/feature.cpp
  # Compilation is much faster if we include all the following CPP files in feature.cpp
  src/pcl_ros/features/boundary.cpp
  src/pcl_ros/features/fpfh.cpp
  src/pcl_ros/features/fpfh_omp.cpp
  src/pcl_ros/features/shot.cpp
  src/pcl_ros/features/shot_omp.cpp
  src/pcl_ros/features/moment_invariants.cpp
  src/pcl_ros/features/normal_3d.cpp
  src/pcl_ros/features/normal_3d_omp.cpp
  src/pcl_ros/features/pfh.cpp
  src/pcl_ros/features/principal_curvatures.cpp
  src/pcl_ros/features/vfh.cpp
)
target_link_libraries (pcl_ros_features ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})
add_dependencies(pcl_ros_features ${PROJECT_NAME}_gencfg)
class_loader_hide_library_symbols(pcl_ros_features)


## Declare library for base filter plugin
add_library(pcl_ros_filter
  src/pcl_ros/filters/filter.cpp
)
target_link_libraries(pcl_ros_filter pcl_ros_tf ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})
add_dependencies(pcl_ros_filter ${PROJECT_NAME}_gencfg)

## Declare the pcl_ros_filters library
add_library(pcl_ros_filters
  src/pcl_ros/filters/extract_indices.cpp
  src/pcl_ros/filters/passthrough.cpp
  src/pcl_ros/filters/project_inliers.cpp
  src/pcl_ros/filters/radius_outlier_removal.cpp
  src/pcl_ros/filters/statistical_outlier_removal.cpp
  src/pcl_ros/filters/voxel_grid.cpp
  src/pcl_ros/filters/crop_box.cpp
)
target_link_libraries(pcl_ros_filters pcl_ros_filter pcl_ros_tf ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})
add_dependencies(pcl_ros_filters ${PROJECT_NAME}_gencfg)
class_loader_hide_library_symbols(pcl_ros_filters)

## Declare the pcl_ros_segmentation library
add_library (pcl_ros_segmentation
  src/pcl_ros/segmentation/extract_clusters.cpp
  src/pcl_ros/segmentation/extract_polygonal_prism_data.cpp
  src/pcl_ros/segmentation/sac_segmentation.cpp
  src/pcl_ros/segmentation/segment_differences.cpp
  src/pcl_ros/segmentation/segmentation.cpp
)
target_link_libraries(pcl_ros_segmentation pcl_ros_tf ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})
add_dependencies(pcl_ros_segmentation ${PROJECT_NAME}_gencfg)
class_loader_hide_library_symbols(pcl_ros_segmentation)

## Declare the pcl_ros_surface library
add_library (pcl_ros_surface
  src/pcl_ros/surface/surface.cpp
  # Compilation is much faster if we include all the following CPP files in surface.cpp
  src/pcl_ros/surface/convex_hull.cpp
  src/pcl_ros/surface/moving_least_squares.cpp
)
target_link_libraries(pcl_ros_surface ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})
add_dependencies(pcl_ros_surface ${PROJECT_NAME}_gencfg)
class_loader_hide_library_symbols(pcl_ros_surface)

## Tools

add_executable(pcd_to_pointcloud tools/pcd_to_pointcloud.cpp)
target_link_libraries(pcd_to_pointcloud ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})

add_executable(pointcloud_to_pcd tools/pointcloud_to_pcd.cpp)
target_link_libraries(pointcloud_to_pcd ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})

add_executable(bag_to_pcd tools/bag_to_pcd.cpp)
target_link_libraries(bag_to_pcd pcl_ros_tf ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})

add_executable(convert_pcd_to_image tools/convert_pcd_to_image.cpp)
target_link_libraries(convert_pcd_to_image ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})

add_executable(convert_pointcloud_to_image tools/convert_pointcloud_to_image.cpp)
target_link_libraries(convert_pointcloud_to_image ${Boost_LIBRARIES} ${catkin_LIBRARIES} ${PCL_LIBRARIES})

## Downloads

#############
## Testing ##
#############

if(CATKIN_ENABLE_TESTING)
  catkin_download(table_scene_lms400.pcd http://download.ros.org/data/pcl/table_scene_lms400.pcd
    DESTINATION ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_SHARE_DESTINATION}/samples/data
    MD5 546b5b4822fb1de21b0cf83d41ad6683
  )
  add_custom_target(download ALL DEPENDS download_extra_data)

  find_package(rostest REQUIRED)
  add_rostest_gtest(test_tf_message_filter_pcl tests/test_tf_message_filter_pcl.launch src/test/test_tf_message_filter_pcl.cpp)
  target_link_libraries(test_tf_message_filter_pcl ${catkin_LIBRARIES} ${GTEST_LIBRARIES})
  add_rostest(samples/pcl_ros/features/sample_normal_3d.launch ARGS gui:=false)
  add_rostest(samples/pcl_ros/filters/sample_statistical_outlier_removal.launch ARGS gui:=false)
  add_rostest(samples/pcl_ros/filters/sample_voxel_grid.launch ARGS gui:=false)
  add_rostest(samples/pcl_ros/segmentation/sample_extract_clusters.launch ARGS gui:=false)
  add_rostest(samples/pcl_ros/surface/sample_convex_hull.launch ARGS gui:=false)

endif(CATKIN_ENABLE_TESTING)


install(DIRECTORY include/${PROJECT_NAME}/
  DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION})

install(
  TARGETS
    pcl_ros_tf
    pcl_ros_io
    pcl_ros_features
    pcl_ros_filter
    pcl_ros_filters
    pcl_ros_surface
    pcl_ros_segmentation
  RUNTIME DESTINATION ${CATKIN_GLOBAL_BIN_DESTINATION}
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
)

install(
  TARGETS
    pcd_to_pointcloud
    pointcloud_to_pcd
    bag_to_pcd
    convert_pcd_to_image
    convert_pointcloud_to_image
  RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
)

install(DIRECTORY plugins samples
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})
