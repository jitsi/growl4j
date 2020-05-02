# Find Growl.framework
#
# Once done this will define
#  GROWL_FOUND - system has Growl
#  GROWL_INCLUDE_DIR - the Growl include directory
#  GROWL_LIBRARY - The library needed to use Growl
include(FindPackageHandleStandardArgs)

find_path(GROWL_INCLUDE_DIR Growl/Growl.h)
find_library(GROWL_LIBRARY NAMES Growl)

find_package_handle_standard_args(Growl DEFAULT_MSG GROWL_INCLUDE_DIR GROWL_LIBRARY)
mark_as_advanced(GROWL_INCLUDE_DIR GROWL_LIBRARY)
