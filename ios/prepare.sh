#!/bin/zsh

set -e

# Ensure Homebrew paths are in PATH (needed when running from CocoaPods)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Check if the library already exists
if [ -f "third_party/sfizz/build/libsfizz_fat.a" ]; then
    echo "libsfizz_fat.a already exists, skipping build"
    exit 0
fi

# Check if cmake is installed
if ! command -v cmake &> /dev/null; then
    echo "Error: cmake is not installed. Please install cmake first:"
    echo "  brew install cmake"
    exit 1
fi

if [ ! -d third_party ]; then
    mkdir third_party
fi
cd third_party

if [ ! -d ios-cmake ]; then
    git clone https://github.com/leetal/ios-cmake.git
    cd ios-cmake
    git checkout a7a5dd0e9ca8e818c0d73a1d3da06d830fa45970
    cd ..
fi

if [ ! -d sfizz ]; then
    git clone https://github.com/sfztools/sfizz.git
    cd sfizz
    git checkout fc1f0451cebd8996992cbc4f983fcf76b03295c5
    git submodule update --init --recursive
    cd ..
fi

cd sfizz

if [ ! -d build ]; then
    mkdir build
fi

cd build

# Generate XCode project for Sfizz
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DDEPLOYMENT_TARGET=13.0 \
    -DSFIZZ_JACK=OFF \
    -DSFIZZ_RENDER=OFF \
    -DSFIZZ_LV2=OFF \
    -DSFIZZ_LV2_UI=OFF \
    -DSFIZZ_VST=OFF \
    -DSFIZZ_AU=OFF \
    -DSFIZZ_SHARED=OFF \
    -DCMAKE_TOOLCHAIN_FILE=../../ios-cmake/ios.toolchain.cmake \
    -DAPPLE_APPKIT_LIBRARY=/System/Library/Frameworks/AppKit.framework \
    -DAPPLE_CARBON_LIBRARY=/System/Library/Frameworks/Carbon.framework \
    -DAPPLE_COCOA_LIBRARY=/System/Library/Frameworks/Cocoa.framework \
    -DAPPLE_OPENGL_LIBRARY=/System/Library/Frameworks/OpenGL.framework \
    -DPLATFORM=OS64COMBINED \
    -G Xcode \
    ..

xcodebuild -project sfizz.xcodeproj -scheme ALL_BUILD -xcconfig ../../../overrides.xcconfig -configuration Release -destination "generic/platform=iOS" -destination "generic/platform=iOS Simulator"

# Create fat libraries
# Use find instead of glob to avoid zsh glob issues
deviceLibs=($(find . -path "*/Release-iphoneos/*.a" -type f))
simulatorLibs=($(find . -path "*/Release-iphonesimulator/*.a" -type f))

if [ ${#deviceLibs[@]} -eq 0 ] || [ ${#simulatorLibs[@]} -eq 0 ]; then
    echo "Error: Could not find built libraries"
    exit 1
fi

libtool -static -o libsfizz_all_iphoneos.a "${deviceLibs[@]}"
libtool -static -o libsfizz_all_iphonesimulator.a "${simulatorLibs[@]}"
lipo \
    -create libsfizz_all_iphoneos.a libsfizz_all_iphonesimulator.a \
    -output libsfizz_fat.a

