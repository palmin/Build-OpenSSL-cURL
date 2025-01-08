#!/bin/bash
#

set -e

rm -fr libssh2
git clone https://github.com/palmin/libssh2/
cd libssh2
git checkout fde216d693998da03846b9c8e58528133ec91a92 # libssh2 1.11.1

# Define the combinations of PLATFORM, ARCH, OPENSSLDIR, and FOLDER
combinations=(
    "AppleTVSimulator arm64 $PWD/../../openssl/tvOS-simulator build-tvos-sim-arm64"
    "AppleTVOS arm64 $PWD/../../openssl/tvOS build-tvos-arm64"
    "MacOSX x86_64 $PWD/../../openssl/Mac build-macos-x86_64"
    "MacOSX arm64 $PWD/../../openssl/Mac build-macos-arm64"
    "iPhoneSimulator x86_64 $PWD/../../openssl/iOS-simulator build-sim-x86_64"
    "iPhoneSimulator arm64 $PWD/../../openssl/iOS-simulator build-sim-arm64"
    "iPhoneOS arm64 $PWD/../../openssl/iOS build-ios-arm64"
)
#    "AppleTVSimulator x86_64 $PWD/../../openssl/tvOS-simulator build-tvos-sim-x86_64"
#    "AppleTVSimulator arm64 $PWD/../../openssl/tvOS-simulator build-tvos-sim-arm64"

export DEVELOPER=$(xcode-select -print-path)
OPTFLAG=-O3

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
    export CFLAGS="-arch $ARCH $OPTFLAG -pipe -no-cpp-precomp -isysroot $SDKROOT"

    # Special case for arm64 MacOSX to make it clear we are not building for iOS
    CMAKE_EXTRA=""
    if [ "$PLATFORM" = "MacOSX" ]; then
	    CMAKE_EXTRA="-DCMAKE_OSX_ARCHITECTURES=$ARCH -DCMAKE_OSX_SYSROOT=$SDKROOT "
	elif [[ "$PLATFORM" == "AppleTVOS" || "$PLATFORM" == "AppleTVSimulator" ]]; then
        # CMAKE_EXTRA="-DCMAKE_SYSTEM_NAME=tvOS "
        CMAKE_EXTRA=""
    fi

    # Run cmake and build commands
    echo cmake -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON -DBUILD_SHARED_LIBS=OFF $CMAKE_EXTRA ..
    cmake -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON -DBUILD_SHARED_LIBS=OFF $CMAKE_EXTRA ..
    cmake --build .
    make install
    
    echo
    lipo -info $PWD/install/lib/libssh2.a
    echo

    # Return to the original directory
    cd ..
    
    # echo "Stopping before time which is useful when debugging"
    # exit 0
done

echo "Creating framework"
rm -fr ../libssh2.xcframework

lipo -create  build-macos-x86_64/install/lib/libssh2.a  build-macos-arm64/install/lib/libssh2.a -output macos-libssh2.a  

echo Creating libssh2.xcframework
xcodebuild -create-xcframework                               \
			-library macos-libssh2.a                         \
			-library build-tvos-arm64/install/lib/libssh2.a  \
			-library build-tvos-sim-arm64/install/lib/libssh2.a  \
			-library build-sim-x86_64/install/lib/libssh2.a  \
			-library build-ios-arm64/install/lib/libssh2.a   \
			-output ../libssh2.xcframework

echo
echo "Building completed"
echo "------------------------------------------------"
