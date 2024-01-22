#!/bin/bash
#

IOS_MIN_SDK_VERSION="13.0"
TVOS_MIN_SDK_VERSION="9.0"
MACOSX_MIN_SDK_VERSION="10.15"

export DEVELOPER=$(xcode-select -print-path)

rm -fr libssh2
git clone https://github.com/libssh2/libssh2/
cd libssh2
git checkout 1c3f1b7da588f2652260285529ec3c1f1125eb4e # libssh2 1.11.1

export FOLDER=build-sim-x86_64
export PLATFORM="iPhoneSimulator"
export ARCH=x86_64
export OPENSSLDIR="$PWD/../../../openssl/iOS-simulator"
echo "Building for $PLATFORM $ARCH in $FOLDER"
mkdir $FOLDER
cd $FOLDER
export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT"
cmake -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON .. 
cmake --build .
make install
cd ..

export PLATFORM="iPhoneSimulator"
export ARCH=arm64
export OPENSSLDIR="$PWD/../../../openssl/iOS-simulator"
echo "Building for $PLATFORM $ARCH in $FOLDER"
mkdir $FOLDER
cd $FOLDER
export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT"
cmake -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON .. 
cmake --build .
make install
cd ..

export PLATFORM="iPhoneOS"
export ARCH=arm64
export OPENSSLDIR="$PWD/../../../openssl/iOS"
echo "Building for $PLATFORM $ARCH in $FOLDER"
mkdir $FOLDER
cd $FOLDER
export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT"
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$SDKROOT -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON .. 
cmake --build .
make install
cd ..

export PLATFORM="MacOSX"
export ARCH=arm64
export OPENSSLDIR="$PWD/../../../openssl/Mac"
echo "Building for $PLATFORM $ARCH in $FOLDER"
mkdir $FOLDER
cd $FOLDER
export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT"
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$SDKROOT -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON .. 
cmake --build .
make install
cd ..

export PLATFORM="MacOSX"
export ARCH=x86_64
export OPENSSLDIR="$PWD/../../../openssl/Mac"
echo "Building for $PLATFORM $ARCH in $FOLDER"
mkdir $FOLDER
cd $FOLDER
export SDKROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -fPIE -isysroot $SDKROOT -mios-version-min=12.0"
cmake -DCMAKE_INSTALL_PREFIX=$PWD/install -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR=${OPENSSLDIR} -DOPENSSL_LIBRARIES=${OPENSSLDIR}/lib -DENABLE_ZLIB_COMPRESSION=ON .. 
cmake --build .
make install
cd ..

# MACOSX_MIN_SDK_VERSION="10.15"