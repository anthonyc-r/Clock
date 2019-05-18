#
# An example GNUmakefile
#

# Include the common variables defined by the Makefile Package
include $(GNUSTEP_MAKEFILES)/common.make

# Build a simple Objective-C program
VERSION = 0.1
PACKAGE_NAME = Clock
APP_NAME = Clock
Clock_APPLICATION_ICON = 

# The Objective-C files to compile
Clock_OBJC_FILES = clock.m

Clock_RESOURCE_FILES = Resources/clock_background_thin_small.tiff

-include GNUmakefile.preamble

# Include in the rules for making GNUstep command-line programs
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
