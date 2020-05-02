# growl4j - Java bindings for [Growl](http://growl.info/)
[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.jitsi/growl4j/badge.svg)](https://search.maven.org/search?q=g:org.jitsi%20AND%20a:growl4j)

## Usage
Reference `org.jitsi:growl4j:<current-version>`. In an OSGi environment,
the native binding is loaded automatically. Otherwise extract libgrowl4j.dylib
and put it into your `java.library.path`.

##Build instructions
1. Prerequisites
- CMake (3.16 or newer)
- Xcode
- Java SDK (8 or newer)
- Maven

2. Native library
```
cmake --install --config Release
```

3. Java
```
mvn package
```
