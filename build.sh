#!/bin/sh
# RCP CAN Bus Logger Script
# Copyright (c) 2023 The SECRET Ingredient!
# GNU General Public License v3.0
#

# Get Project Name and Version
project_name=`sed -n -e '/name/ { s/.*: "\(.*\)",/\1/p
                                  q
                                }' package.json`
project_version=`sed -n -e '/version/ { s/.*: "\(.*\)",/\1/p
                                        q
                                      }' package.json`

# Set Project Root Directory
project_root=$(cd $(dirname $0); pwd)

# Set Project Directories
project_source=$project_root/src
project_include=$project_root/src/inc
project_resource=$project_root/res
project_make=$project_root/make
project_build=$project_root/bin

# Display Environment Settings
echo "PROJECT_NAME     = "$project_name
echo "PROJECT_VERSION  = "$project_version
echo "PROJECT_ROOT     = "$project_root
echo
echo "PROJECT_SOURCE   = "$project_source
echo "project_INCLUDE  = "$project_include
echo "PROJECT_RESOURCE = "$project_resource
echo "PROJECT_MAKE     = "$project_make
echo "PROJECT_BUID     = "$project_build
echo

# Clean Make and Build Directory
node_modules/.bin/rimraf $project_make $project_build

# Create Make and Build Directory
mkdir $project_make
mkdir $project_build

# Start Build With Comment Header
echo "Building Project"
cat $project_source/main.lua | sed -e "s/<version>/$project_version/g" > "$project_build/$project_name.lua"

echo
echo "Build Complete: $project_name, v.$project_version"
echo
