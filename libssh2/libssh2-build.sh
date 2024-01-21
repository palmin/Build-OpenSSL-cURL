#!/bin/bash
#

IOS_MIN_SDK_VERSION="13.0"
TVOS_MIN_SDK_VERSION="9.0"
MACOSX_MIN_SDK_VERSION="10.15"

export DEVELOPER=$(xcode-select -print-path)

git clone https://github.com/libssh2/libssh2/
cd libssh2
git checkout 1c3f1b7da588f2652260285529ec3c1f1125eb4e # libssh2 1.11.1

mkdir build-ios
cd build-ios
export PLATFORM="iPhoneOS"
export ARCH=arm64
export OPENSSLDIR="$PWD/../../../openssl/iOS"
export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT"
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$SDKROOT -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON .. 
cmake --build .
make install
cd ..

exit 0

mkdir build-macos-arm64
cd build-macos-arm64
export PLATFORM="MacOSX"
export ARCH=arm64
export OPENSSLDIR="$PWD/../../../openssl/Mac"
export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT"
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$SDKROOT -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON .. 
cmake --build .
make install
cd ..

mkdir build-macos-x86_64
cd build-macos-x86_64
export PLATFORM="MacOSX"
export ARCH=x86_64
export OPENSSLDIR="$PWD/../../../openssl/Mac"
export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -fPIE -isysroot $SDKROOT -mios-version-min=12.0"
cmake -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON .. 
cmake --build .
make install
cd ..

# MACOSX_MIN_SDK_VERSION="10.15"