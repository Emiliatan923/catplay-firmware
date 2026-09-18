# Do not auto-enable the stock dnsmasq service.
#
# The CatPlay AP needs DHCP/DNS bound to the AP address only (192.168.66.1:53),
# because the packaged unit binds 0.0.0.0:53 and loses that race to any stub
# resolver -- on the Armbian bring-up it exited with "failed to create
# listening socket for port 53" every boot. catplay-dnsmasq.service runs its own
# instance restricted with --bind-interfaces instead.
#
# The binary is still installed (catplay-dnsmasq.service ExecStarts
# /usr/sbin/dnsmasq); only the unit is left disabled.
SYSTEMD_AUTO_ENABLE:${PN} = "disable"
