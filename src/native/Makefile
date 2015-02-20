# Makefile for the Growl4j. Requires Growl.framework from growl.info

CC=gcc -arch i386 -arch x86_64
TARGET=libgrowl4j.dylib
JNI_INCLUDE_PATH=/System/Library/Frameworks/JavaVM.framework/Versions/A/Headers/
GROWL_INCLUDE_PATH=include
CFLAGS=-I$(JNI_INCLUDE_PATH) -I$(GROWL_INCLUDE_PATH)
LDLIBS=-F../../libsrc/Growl-1.3.1-SDK/Framework/
LIBS=-framework Cocoa -framework Growl
OBJS=org_growl4j_Growl.o
INSTALL_DIR=../../lib/

all:$(TARGET)

clean:
	rm -rf $(TARGET) $(OBJS) *~

install:$(TARGET)
	cp $(TARGET) $(INSTALL_DIR)

$(TARGET):$(OBJS)
	$(CC) -dynamiclib -o $(TARGET) $(LDLIBS) $(LIBS) $(CFLAGS) $<
# EOF

