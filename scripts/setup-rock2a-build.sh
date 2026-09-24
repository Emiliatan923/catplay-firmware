#!/bin/sh
# Recreate the source tree and build configuration used for the validated
# CatPlay ROCK 2A fastboot-v3 image. All upstream repositories and the CatPlay
# application are pinned by commit, rather than by a moving branch name.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WORK=${CATPLAY_ROCK2A_WORKDIR:-"$ROOT/_rock2a"}
SOURCES="$WORK/sources"
BUILD="$WORK/build"

POKY_REV=77d1feb37e280733684ae8a9449fb031d5d7ff40
META_OE_REV=b5874ea07d69919d9b40d59f2c2f0bbd24bc3259
META_CLANG_REV=cc29beb210ab94eacc53bbd67e287e4e33ede342
META_ARM_REV=0a4b911d9fd63ab29c4532a907fae3282dbdcfe4
META_LTS_REV=eedcdc7486ff15c3510c2ceff68c87d9db141312
META_ROCKCHIP_REV=b7fa236acd9ac33bb41fbb7433987e9c7d3ad2a9
CATPLAY_REV=4d343419d0f27d27ee9d7ade7893b59e28317321

checkout_exact() {
    name=$1
    url=$2
    revision=$3
    destination="$SOURCES/$name"

    if [ ! -d "$destination/.git" ]; then
        mkdir -p "$destination"
        git -C "$destination" init
        git -C "$destination" remote add origin "$url"
    elif [ "$(git -C "$destination" remote get-url origin)" != "$url" ]; then
        echo "$destination has an unexpected origin; refusing to replace it" >&2
        exit 2
    fi

    if ! git -C "$destination" diff --quiet || ! git -C "$destination" diff --cached --quiet; then
        echo "$destination has local changes; refusing to overwrite them" >&2
        exit 2
    fi

    if ! git -C "$destination" cat-file -e "$revision^{commit}" 2>/dev/null; then
        git -C "$destination" fetch --depth 1 origin "$revision"
    fi
    git -C "$destination" checkout --detach "$revision"

    actual=$(git -C "$destination" rev-parse HEAD)
    [ "$actual" = "$revision" ] || {
        echo "$name resolved to $actual, expected $revision" >&2
        exit 2
    }
}

mkdir -p "$SOURCES"
checkout_exact poky https://github.com/yoctoproject/poky.git "$POKY_REV"
checkout_exact meta-openembedded https://github.com/openembedded/meta-openembedded.git "$META_OE_REV"
checkout_exact meta-clang https://github.com/kraj/meta-clang.git "$META_CLANG_REV"
checkout_exact meta-arm https://git.yoctoproject.org/meta-arm "$META_ARM_REV"
checkout_exact meta-lts-mixins https://git.yoctoproject.org/meta-lts-mixins "$META_LTS_REV"
checkout_exact meta-rockchip https://github.com/radxa/meta-rockchip.git "$META_ROCKCHIP_REV"
checkout_exact catplay https://github.com/Emiliatan923/catplay.git "$CATPLAY_REV"

"$ROOT/meta-rock2a-c2a/make-catplay-bundle.sh" "$SOURCES/catplay"
mkdir -p "$BUILD"

# oe-init-build-env creates the build directory and changes the current shell's
# directory. This script runs it in a subshell, so callers stay where they are.
(
    # Poky's environment helper intentionally probes several optional unset
    # variables (for example BBSERVER), so nounset must be disabled while it
    # initializes BitBake's shell environment. Dash cannot discover the path
    # of a sourced script or pass arguments to it, so run it from Poky's
    # directory and set the build-directory positional argument as documented.
    set +u
    cd "$SOURCES/poky"
    set -- "$BUILD"
    . "$SOURCES/poky/oe-init-build-env" >/dev/null
    set -u

    cat > conf/bblayers.conf <<EOF
POKY_BBLAYERS_CONF_VERSION = "2"
BBPATH = "\${TOPDIR}"
BBFILES ?= ""
BBLAYERS ?= " \\
  $SOURCES/poky/meta \\
  $SOURCES/poky/meta-poky \\
  $SOURCES/meta-openembedded/meta-oe \\
  $SOURCES/meta-openembedded/meta-python \\
  $SOURCES/meta-openembedded/meta-networking \\
  $SOURCES/meta-openembedded/meta-multimedia \\
  $SOURCES/meta-clang \\
  $SOURCES/meta-arm/meta-arm \\
  $SOURCES/meta-arm/meta-arm-toolchain \\
  $SOURCES/meta-lts-mixins \\
  $SOURCES/meta-rockchip \\
  $ROOT/meta-rock2a-c2a \\
  "
EOF

    threads=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 8)
    cat > conf/local.conf <<EOF
MACHINE = "rockchip-rk3528-rock-2a"
DISTRO = "poky"
PACKAGE_CLASSES = "package_ipk"
BB_NUMBER_THREADS = "$threads"
PARALLEL_MAKE = "-j $threads"
DL_DIR = "\${TOPDIR}/../downloads"
SSTATE_DIR = "\${TOPDIR}/../sstate-cache"
LICENSE_FLAGS_ACCEPTED = "commercial"

# Produce the bootable Rockchip GPT/WIC image and vendor update image, not
# just a rootfs archive.
INHERIT += "rockchip-image"

# CatPlay services are systemd units. Poky's default sysvinit configuration
# would build successfully but would not start them on the target.
DISTRO_FEATURES:append = " systemd usrmerge"
DISTRO_FEATURES:remove = "sysvinit"
VIRTUAL-RUNTIME_init_manager = "systemd"
DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"

# These match Radxa's Yocto configuration for its vendor/upstream patches.
ERROR_QA:remove = "patch-status"
WARN_QA:remove = "patch-fuzz"
CONF_VERSION = "2"
EOF
)

cat <<EOF
ROCK 2A build tree is ready at:
  $BUILD

Build with:
  cd "$ROOT"
  . "$SOURCES/poky/oe-init-build-env" "$BUILD"
  bitbake catplay-rock2a-image
EOF
