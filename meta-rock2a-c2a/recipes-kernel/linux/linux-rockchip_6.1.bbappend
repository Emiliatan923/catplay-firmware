FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://catplay-i2c0.cfg \
                   file://0001-aic8800-silence-mgmt-err-printk.patch \
"

# Silence the AIC8800 "mgmt err" printk, which makes the board unusable over
# UART once the AP is up.
#
# rwnx_rx_mgmt() drops management frames with an implausible length and logs
# each one through a bare printk() -- no KERN_ prefix, so it lands at the
# default level, escapes `dmesg -n`, and does not go through the driver's
# AICWFDBG macros. Measured on the ROCK 2A with the CatPlay AP up: ~6 lines
# per second, and the line appears only while the AP is running (it was
# absent through the whole hostapd crash-loop, when the AP never started).
#
# ttyFIQ0 is the console, and the serial console is the only way to reach this
# board -- so the flood removes the single diagnostic channel this port work
# depends on. The patch drops the printk and leaves the frame-drop verdict
# untouched.
#
# Asserted here because a patch that stops applying would otherwise fail
# silently: the build would succeed and the spam would simply come back.
# The assertion lives inside the one do_patch:append() below -- see the note
# there about BitBake concatenating these into a single shell function.

# Enable i2c0 for the CatPlay MFi authentication chip.
#
# The ROCK 2A port wires the MFi 2.0C chip to header pins 3/5, which are i2c0
# SCL/SDA on the m1 pinmux (GPIO4_A1 / GPIO4_A0 -- the same pins Armbian uses
# for its working i2c0 setup). rk3528.dtsi defines the i2c0 controller but
# leaves it `status = "disabled"`, and rk3528-rock-2a.dts never enables it, so
# the image comes up with no /dev/i2c-0:
#
#     $ ls /dev/i2c*
#     /dev/i2c-8
#
# Without it the daemon dies immediately and systemd restarts it forever:
#
#     [ERROR catplay_c2a] Failed to start: MFI I/O error: No such file or
#     directory (os error 2)
#     catplay-c2a.service: Scheduled restart job, restart counter is at 178.
#
# The WiFi/BT stack is unaffected (both were already up); the daemon just gates
# everything on the MFi gate, so the dongle never works.
#
# The node goes into the board dts rather than a .dtsi: appending to an
# included .dtsi can leave the label unreferenced and /omit-if-no-ref/ then
# drops the pinmux, which fails silently.
do_patch:append() {
    local dts="${S}/arch/arm64/boot/dts/rockchip/rk3528-rock-2a.dts"
    local rx="${S}/drivers/net/wireless/aic/aic8800_usb/aic8800_fdrv/rwnx_rx.c"

    # Both board-dts fixes live in ONE function on purpose.  BitBake
    # concatenates every `do_patch:append` in a recipe into a single shell
    # function, so an early `return` in the first block would silently skip the
    # second -- which is exactly how the dr_mode fix went missing once.  The
    # aic8800 assertion below is in here for the same reason.
    if ! grep -q "catplay: mfi i2c0" "$dts"; then
        cat >> "$dts" <<'DTS'

/* catplay: mfi i2c0 -- header pins 3/5, m1 pinmux (GPIO4_A1/A0) */
&i2c0 {
	status = "okay";
	pinctrl-names = "default";
	pinctrl-0 = <&i2c0m1_xfer>;
	clock-frequency = <100000>;
};
DTS
    fi

    if ! grep -q "catplay: usb gadget dr_mode" "$dts"; then
        cat >> "$dts" <<'DTS'

/* catplay: usb gadget dr_mode -- match Armbian, allow device/dual-role */
&usbdrd_dwc3 {
	dr_mode = "otg";
};
DTS
    fi

    grep -q "i2c0m1_xfer" "$dts" || bbfatal "failed to enable i2c0 for the MFi chip"
    grep -q 'dr_mode = "otg"' "$dts" || bbfatal "failed to restore otg dr_mode for the gadget"
    grep -q 'Silenced by CatPlay' "$rx" || bbfatal "aic8800 mgmt err printk patch did not apply"
}

# Put the USB3 OTG controller back into dual-role mode so the board can act as
# a USB *device* (the fake head unit the iPhone talks to).
#
# rk3528.dtsi defaults usbdrd_dwc3 to `dr_mode = "otg"`, but
# rk3528-rock-2a.dts overrides it to "host" -- Rockchip ships the ROCK 2A as a
# host-only board, so the dwc3 core probes in host mode and never registers a
# UDC.  Armbian's ROCK 2A DT keeps "otg", which is why the card could run the
# gadget.  Without this the g_iphone gadget cannot bind:
#
#     $ ls /sys/class/udc
#     (empty)
#
# The extcon is already wired to &usb2phy in the board dts, so dual-role works
# once dr_mode is restored; the role is still steerable at runtime through the
# vendor USB2 PHY's otg_mode sysfs knob.  The append itself lives in the single
# do_patch:append() above.
