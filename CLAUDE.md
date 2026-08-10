# CLAUDE.md

Guidance for working with this directory, which builds the native networking stack
(**libcurl + OpenSSL + libssh2**) used by the FTP app in the parent `Files` project.

## What this is

A **customized fork of jasonacox/Build-OpenSSL-cURL**, with two local additions vs.
upstream:
- it also builds **libssh2** (stock jasonacox does not), and
- it patches curl's SFTP backend (`custom-curl-libssh2.c`).

The C sources and intermediate build dirs live only here; the main repo vendors just the
resulting headers + xcframeworks. The output is consumed by `Files/LibCurl/`, whose
Swift/ObjC code (`LibCurl-Object.m`, `OpenSSL+Helper.m`, `CertificateTrust.m`, …) wraps
the binaries in a `LibCurl.framework` that all apps link.

## Pinned versions

Set at the top of `build.sh`:
- OpenSSL **3.0.12**
- libcurl **8.1.2**
- libssh2 **1.11.1** — from the fork `github.com/palmin/libssh2`, pinned to commit
  `fde216d693998da03846b9c8e58528133ec91a92` (cloned fresh by `libssh2-build.sh`)
- nghttp2 1.55.1 — present but **disabled** in our build (no HTTP/2)

## How to build

From this directory:
```bash
./build.sh -b -d -e      # the script itself prints this as the recommended invocation
```
- `-b` no bitcode (forced anyway for OpenSSL 3.x)
- `-d` no HTTP/2 (skip nghttp2)
- `-e` OpenSSL engine support

This is a long, host-specific compile (real Xcode SDKs, ~tens of minutes). Only rebuild
when bumping curl/OpenSSL/libssh2 versions or changing `custom-curl-libssh2.c`.
`clean.sh` removes intermediates; build state is otherwise reused between runs.

`build-curlonly.sh` takes the same flags and skips the OpenSSL and libssh2 stages, reusing
their existing outputs. Minutes rather than tens of minutes when only curl changed. Its
last step (archiving Mac binaries) fails on a missing `/tmp/openssl-*` because that stage
was skipped; the xcframeworks are already written by then, so it is harmless.

### Autoconf feature detection is not to be trusted

curl's configure decides several features with **run** tests, which it skips in favour of a
free "yes" when cross compiling. iOS and tvOS genuinely cross compile; the Mac slices build
natively, so their probes really run, and a probe that fails to *compile* silently reads as
"feature absent". curl 8.1.2's IPv6 probe is a K&R `main()`, which clang 16+ rejects outright
(`-Wimplicit-int`), so Mac shipped without IPv6 for a while: AAAA-only hosts would not
resolve, literal IPv6 addresses failed, and `CURLOPT_IPRESOLVE` was ignored. Hence the
explicit `--enable-ipv6` in `CONF_FLAGS`.

After any rebuild, check the features actually landed rather than assuming, per arch:
```bash
nm -arch arm64 LibCurl/libs/libcurl.xcframework/macos-arm64_x86_64/libcurl.a | grep _Curl_ipv6works
```
`FTPTests/IPv6ResolutionTests.testBundledCurlSupportsIPv6` asserts this from the app side on
every platform, so `scripts/pre-release-tests` catches a regression here.

## Build stages

`build.sh` runs the stages in order, each via its own sub-script:

1. **OpenSSL** — `openssl/openssl-build.sh` → `phase1` (Mac, Catalyst, tvOS) + `phase2`
   (iOS). Outputs per-platform static libs/headers into
   `openssl/{Mac,iOS,iOS-simulator,tvOS,tvOS-simulator}/`.
2. **libssh2** — `libssh2/libssh2-build.sh` clones the palmin fork, then for each
   platform/arch runs CMake (`CRYPTO_BACKEND=OpenSSL`, static, zlib compression) against
   the OpenSSL outputs from step 1. Produces `libssh2/libssh2.xcframework`. (libssh2 is
   **not** added to the `archive/` dir — only this xcframework is produced.)
3. **nghttp2** — skipped because of `-d`.
4. **libcurl** — `curl/libcurl-build.sh` downloads curl 8.1.2, then **overwrites
   `lib/vssh/libssh2.c` with `custom-curl-libssh2.c`** (the SFTP-backend patch, which adds
   e.g. `statvfs`/SFTP-quota handling). Configures each slice with `--with-libssh2=`
   pointing at the matching libssh2 install dir and `--with-ssl=` at the matching OpenSSL
   dir, with HTTP/most protocols disabled (see `CONF_FLAGS`). Builds Mac (x86_64+arm64),
   iOS arm64, iOS-sim (x86_64+arm64), tvOS arm64, tvOS-sim (x86_64+arm64).
5. **Assembly** — `build.sh` lipos the slices and emits
   `libcurl/libcrypto/libssl.xcframework` into
   `archive/libcurl-8.1.2-openssl-3.0.12-nghttp2-NONE/xcframework/` (and into the
   `example/iOS Test App`). `cacert.pem` is also refreshed from curl.se.

## Wiring the output back into the app (manual copy step)

The four xcframeworks consumed by the Xcode project live in `Files/LibCurl/libs/`. After a
build, copy the freshly produced ones over:
- `libcurl.xcframework`, `libcrypto.xcframework`, `libssl.xcframework` from
  `archive/libcurl-8.1.2-openssl-3.0.12-nghttp2-NONE/xcframework/`
- `libssh2.xcframework` from `libssh2/libssh2.xcframework`

There is **no automated step** that copies into `Files/LibCurl/libs/`; it is done by hand
when the stack is rebuilt. Headers used by `LibCurl/` live under `Files/LibCurl/curl/`.

## Files of note

- `build.sh` — top-level orchestrator and version pins
- `custom-curl-libssh2.c` — our replacement for curl's `lib/vssh/libssh2.c`
- `openssl/openssl-build.sh` (+ `phase1`/`phase2`) — OpenSSL build
- `libssh2/libssh2-build.sh` — libssh2 build (clones palmin fork, CMake per platform)
- `curl/libcurl-build.sh` — curl build + patch application
- `clean.sh` — remove intermediate build outputs
- `stage.sh` — upstream S3 CI staging helper (not used in our local flow)
