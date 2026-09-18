#!/bin/sh
# Regenerate the CatPlay source bundle consumed by the Yocto recipes.
#
# Both recipes in this layer build from the same archive so the daemon and the
# USB gadget modules can never drift apart:
#
#   recipes-apps/catplay/catplay_git.bb        the daemon
#   recipes-bsp/g-iphone/g-iphone_git.bb       g_iphone / iap2_char / iap2_scan
#
# The archive is deliberately NOT committed: it is a build input derived from
# the catplay-rock repository, and a checked-in tarball silently goes stale.
# Run this after every change to the application source.
#
# Usage:  ./make-catplay-bundle.sh [path-to-catplay-rock]
set -eu

REPO=${1:-../../../catplay-rock}
HERE=$(cd "$(dirname "$0")" && pwd)
OUT="$HERE/files/catplay-src/catplay.tar.gz"

[ -d "$REPO/.git" ] || { echo "not a git repository: $REPO" >&2; exit 2; }

mkdir -p "$(dirname "$OUT")"

# Archive the committed tree of the current branch (rock2a-port), so the
# bundle is exactly the revision that was reviewed and tested.
git -C "$REPO" archive --format=tar.gz -o "$OUT" HEAD

echo "wrote $OUT"
echo "  from $(git -C "$REPO" rev-parse --short HEAD) ($(git -C "$REPO" rev-parse --abbrev-ref HEAD))"
echo "  size $(wc -c < "$OUT") bytes"
