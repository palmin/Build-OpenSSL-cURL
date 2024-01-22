#!/bin/bash
#

set -e

rm -fr libssh2
git clone https://github.com/libssh2/libssh2/
cd libssh2
git checkout 1c3f1b7da588f2652260285529ec3c1f1125eb4e # libssh2 1.11.1

# Define the combinations of PLATFORM, ARCH, OPENSSLDIR, and FOLDER
combinations=(
    "MacOSX x86_64 $PWD/../../openssl/Mac build-macos-x86_64"
    "MacOSX arm64 $PWD/../../openssl/Mac build-macos-arm64"
    "iPhoneSimulator x86_64 $PWD/../../openssl/iOS-simulator build-sim-x86_64"
    "iPhoneSimulator arm64 $PWD/../../openssl/iOS-simulator build-sim-arm64"
    "iPhoneOS arm64 $PWD/../../openssl/iOS build-ios-arm64"
)

export DEVELOPER=$(xcode-select -print-path)

for combo in "${combinations[@]}"; do
    # Read the variables from the current combination
    read -r PLATFORM ARCH OPENSSLDIR FOLDER <<< "$combo"

    # Echo the current configuration
    echo
    echo "Building for $PLATFORM $ARCH in $FOLDER"
    echo "------------------------------------------------"

    # Create and enter the folder
    mkdir "$FOLDER"
    cd "$FOLDER" || exit

    # Set SDKROOT and CFLAGS
    export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
    export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT"

    # Special case for arm64 MacOSX to make it clear we are not building for iOS
    CMAKE_EXTRA=""
    #if [ "$PLATFORM" = "MacOSX" ] && [ "$ARCH" = "arm64" ]; then
	#    CMAKE_EXTRA="-DCMAKE_OSX_ARCHITECTURES=$ARCH -DCMAKE_OSX_SYSROOT=$SDKROOT "
	#fi

    # Run cmake and build commands
    echo cmake -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON $CMAKE_EXTRA ..
    cmake -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON $CMAKE_EXTRA ..
    cmake --build .
    make install

    # Return to the original directory
    cd ..
done



# MACOSX_MIN_SDK_VERSION="10.15"