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

# Generate XCode project for Sfizz with OS64COMBINED (supports both device and simulator)
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

# Build for iOS device (arm64)
xcodebuild -project sfizz.xcodeproj -scheme ALL_BUILD -xcconfig ../../../overrides.xcconfig -configuration Release \
    -destination "generic/platform=iOS" \
    ONLY_ACTIVE_ARCH=NO

# Build for iOS Simulator (x86_64) - OS64COMBINED should build this
xcodebuild -project sfizz.xcodeproj -scheme ALL_BUILD -xcconfig ../../../overrides.xcconfig -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    ONLY_ACTIVE_ARCH=NO

# Build for iOS Simulator (arm64) - need to use SIMULATORARM64 platform
# First, create a separate build directory for arm64 simulator
cd ..
if [ ! -d build_arm64_sim ]; then
    mkdir build_arm64_sim
fi
cd build_arm64_sim

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
    -DPLATFORM=SIMULATORARM64 \
    -G Xcode \
    ..

xcodebuild -project sfizz.xcodeproj -scheme ALL_BUILD -xcconfig ../../../overrides.xcconfig -configuration Release \
    ONLY_ACTIVE_ARCH=NO

cd ../build

# Create fat libraries
# Use find instead of glob to avoid zsh glob issues
deviceLibs=($(find . -path "*/Release-iphoneos/*.a" -type f))
simulatorLibs=($(find . -path "*/Release-iphonesimulator/*.a" -type f))
arm64_sim_libs=($(find ../build_arm64_sim -path "*/Release-iphonesimulator/*.a" -type f 2>/dev/null))

if [ ${#deviceLibs[@]} -eq 0 ] || [ ${#simulatorLibs[@]} -eq 0 ]; then
    echo "Error: Could not find built libraries"
    exit 1
fi

# Extract architectures from simulator libraries
# Some libraries might be x86_64 only, some might be arm64 only, some might be both
libtool -static -o libsfizz_all_iphoneos.a "${deviceLibs[@]}"

# For simulator, we need to handle both x86_64 and arm64
# x86_64 libraries are from the main build
# arm64 simulator libraries are from build_arm64_sim
x86_64_libs=()

for lib in "${simulatorLibs[@]}"; do
    archs=$(lipo -info "$lib" 2>&1 | grep -o "architecture: [a-z0-9_]*" | cut -d' ' -f2)
    for arch in $archs; do
        if [ "$arch" = "x86_64" ]; then
            x86_64_libs+=("$lib")
        fi
    done
done

# Create separate libraries for each architecture
if [ ${#x86_64_libs[@]} -gt 0 ]; then
    libtool -static -o libsfizz_all_iphonesimulator_x86_64.a "${x86_64_libs[@]}"
fi

# Create arm64 simulator library from build_arm64_sim if it exists
if [ ${#arm64_sim_libs[@]} -gt 0 ]; then
    libtool -static -o libsfizz_all_iphonesimulator_arm64.a "${arm64_sim_libs[@]}"
fi

# Create fat library
# Problem: lipo cannot merge two arm64 architectures (device and simulator) into one fat file
# Solution: We need to extract arm64 from device, then combine with simulator architectures
# Strategy: 
# 1. Extract arm64 from device library
# 2. Create simulator fat with x86_64 + arm64
# 3. Combine device arm64 with simulator fat (but this will fail because both have arm64)
# 
# Better approach: Create XCFramework or use conditional linking
# For now, let's try a workaround: replace arm64 in device library with simulator arm64 when building for simulator
# Actually, the best solution is to create separate libraries and let Xcode choose

# Extract arm64 from device library
lipo libsfizz_all_iphoneos.a -thin arm64 -output libsfizz_arm64_device.a 2>/dev/null || cp libsfizz_all_iphoneos.a libsfizz_arm64_device.a

# Create simulator fat with x86_64 and arm64
simulator_fat_args=()
if [ -f "libsfizz_all_iphonesimulator_x86_64.a" ]; then
    simulator_fat_args+=("libsfizz_all_iphonesimulator_x86_64.a")
fi
if [ -f "libsfizz_all_iphonesimulator_arm64.a" ]; then
    simulator_fat_args+=("libsfizz_all_iphonesimulator_arm64.a")
fi

if [ ${#simulator_fat_args[@]} -eq 0 ]; then
    echo "Error: No simulator libraries found"
    exit 1
elif [ ${#simulator_fat_args[@]} -eq 1 ]; then
    cp "${simulator_fat_args[0]}" libsfizz_simulator.a
else
    lipo -create "${simulator_fat_args[@]}" -output libsfizz_simulator.a
fi

# Now we have a problem: we can't merge libsfizz_arm64_device.a and libsfizz_simulator.a
# because both contain arm64. We need to use XCFramework or a different approach.
# 
# Workaround: Create a fat library with device arm64 + simulator x86_64
# Then, for arm64 simulator builds, Xcode will need to link against the simulator arm64 library separately
# But this won't work with vendored_libraries in podspec
#
# Better solution: Create an XCFramework
# Or: Use lipo to replace the arm64 slice in the fat file based on build target
#
# For now, let's create a fat file with device arm64 + simulator x86_64
# And create a separate script or post-install hook to handle arm64 simulator

fat_args=()
fat_args+=("libsfizz_arm64_device.a")
if [ -f "libsfizz_all_iphonesimulator_x86_64.a" ]; then
    fat_args+=("libsfizz_all_iphonesimulator_x86_64.a")
fi

if [ ${#fat_args[@]} -lt 2 ]; then
    # Fallback: just use what we have
    if [ -f "libsfizz_arm64_device.a" ]; then
        cp libsfizz_arm64_device.a libsfizz_fat.a
    elif [ -f "libsfizz_simulator.a" ]; then
        cp libsfizz_simulator.a libsfizz_fat.a
    else
        echo "Error: Cannot create fat library"
        exit 1
    fi
else
    lipo -create "${fat_args[@]}" -output libsfizz_fat.a
fi

# For arm64 simulator, we need to replace the arm64 slice in the fat file
# Extract arm64 from simulator and replace in fat file
if [ -f "libsfizz_all_iphonesimulator_arm64.a" ] && [ -f "libsfizz_fat.a" ]; then
    # Extract non-arm64 architectures from fat file
    lipo libsfizz_fat.a -remove arm64 -output libsfizz_fat_no_arm64.a 2>/dev/null || cp libsfizz_fat.a libsfizz_fat_no_arm64.a
    # Combine with simulator arm64
    lipo -create libsfizz_fat_no_arm64.a libsfizz_all_iphonesimulator_arm64.a -output libsfizz_fat.a
    rm -f libsfizz_fat_no_arm64.a
fi

