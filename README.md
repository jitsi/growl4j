# growl4j
the OpenSource Java Solution for using Growl

1) To generate "growl4j.jar" and "libgrowl4j.dylib", just enter "ant make".

Any sowtfare using growl4j must sets the relative path between the native
dynamic library "libgrowl4j.dylib" and the Growl framework location. This can be
done by using the "install_name_tool" conforming to the following example:

// Check the current path between "libgrowl4j.dylib" and the Growl.ramework:
$ otool -L libgrowl4j.dylib
[...]
    @executable_path/../Frameworks/Growl.framework/Versions/A/Growl
[...]

// Modifies the path used to find the Growl.framework ("\" is used to remove the
// trailing characters):
$ install_name_tool -change \
    @executable_path/../Frameworks/Growl.framework/Versions/A/Growl \
    /Users/toto/software/Growl-1.3.1-SDK/Framework/Growl.framework/Versions/A/Growl \
    libgrowl4j.dylib

2) To clean "growl4j.jar" and "libgrowl4j.dylib", just enter "ant clean".
