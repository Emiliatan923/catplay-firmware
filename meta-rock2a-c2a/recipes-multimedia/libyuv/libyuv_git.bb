SUMMARY = "libyuv — YUV scaling and conversion library"
DESCRIPTION = "Google's libyuv, used by the CatPlay daemon for colour-space \
conversion and scaling of the CarPlay video frames. No recipe for it exists in \
poky or meta-openembedded, so this layer carries one."
HOMEPAGE = "https://chromium.googlesource.com/libyuv/libyuv"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=464282cfb405b005b9637f11103a7325"

# GitHub mirror of the upstream (chromium.googlesource.com) repository, at the
# identical commit. googlesource serves git slowly enough that bitbake's fetch
# times out; the mirror is byte-identical for this revision.
SRC_URI = "git://github.com/lemenkov/libyuv.git;protocol=https;branch=main"
SRCREV = "2dd4257364d39c38d79465c4ddc4b93137fe729b"

S = "${WORKDIR}/git"

inherit cmake

EXTRA_OECMAKE = " \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DUNIT_TEST=OFF \
"

# Upstream's CMakeLists sets OUTPUT_NAME and PREFIX on the shared target but
# never sets VERSION/SOVERSION, so it produces a bare `libyuv.so` with no
# SONAME. Yocto then classifies that file as a development artefact and ships
# it in libyuv-dev, leaving the runtime package empty -- which shows up later
# as `catplay rdepends on libyuv-dev [dev-deps]`.
#
# Give it a real SONAME. The daemon expects libyuv.so.0 (that is what the
# Armbian build produced), so pin SOVERSION to 0 to keep the runtime
# dependency name identical across both builds.
do_configure:append() {
    # Note the quoting: ${S} must be expanded by bitbake, while CMake's
    # ${ly_lib_shared} must reach the file literally -- hence double quotes
    # around the sed program and a backslash before the CMake expansion.
    sed -i \
        -e 's|^set_target_properties( \${ly_lib_shared} PROPERTIES PREFIX "lib" )$|&\nset_target_properties( \${ly_lib_shared} PROPERTIES VERSION 0.0.0 SOVERSION 0 )|' \
        "${S}/CMakeLists.txt"

    grep -q "SOVERSION 0" "${S}/CMakeLists.txt" || bbfatal "libyuv SOVERSION patch did not apply"
}

BBCLASSEXTEND = "native"
