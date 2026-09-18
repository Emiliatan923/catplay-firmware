# meta-rockchip (scarthgap-vendor) points this recipe at a date-stamped branch
# that no longer exists upstream:
#
#     SRC_URI:append = " git://github.com/JeffyCN/xorg-xserver;protocol=https;\
#                        nobranch=1;branch=${PV}_2024_06_24;"
#
# With PV=21.1.18 that resolves to `21.1.18_2024_06_24`, which is absent from
# the repository, so `bitbake -p` fails before any build can start:
#
#     Fetcher failure: Unable to resolve '21.1.18_2024_06_24' in upstream git
#     repository in git ls-remote output for github.com/JeffyCN/xorg-xserver
#
# The same date-stamped tag scheme still exists for later dates, so repoint at
# a tag that is actually present. This keeps the Rockchip-patched xorg-server
# that the vendor layer wants, rather than dropping the recipe.
#
# The CatPlay dongle is headless and never uses X, but xserver-xorg is pulled
# in via the rockchip distro's X11 support, so it has to parse for any image
# build to proceed.
SRC_URI:remove = "git://github.com/JeffyCN/xorg-xserver;protocol=https;nobranch=1;branch=${PV}_2024_06_24;"
SRC_URI:append = " git://github.com/JeffyCN/xorg-xserver;protocol=https;nobranch=1;branch=${PV}_2025_11_06;"
