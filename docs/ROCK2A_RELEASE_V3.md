# ROCK 2A fastboot v3 release inputs

The validated ROCK 2A image is built from `meta-rock2a-c2a` plus the exact
source revisions encoded in `scripts/setup-rock2a-build.sh`. The script is the
authoritative reproducible-build entry point; branch names in the longer
bring-up notes are informational only.

Application source:

- repository: `https://github.com/Emiliatan923/catplay.git`
- branch used for development: `rock2a-port`
- validated source tag: `rock2a-fastboot-v3`
- minimal source commit: `d85708d7388b53536819cccce96c7dcad6a940cf`

Validated image checksums:

- compressed WIC SHA256: `231e551fde71947f937ba1966da765f72eb82190a22ec841b2c2d353165dd84a`
- uncompressed WIC SHA256: `faf22036a8670053fe98335cdc30e09d07c8d37e4570f26f91971a83a543ee3b`

The historical test image included development SSH access. The public image
recipe intentionally omits both the credential and the SSH server; neither is
required by CatPlay at runtime.

The Wi-Fi subnet and `catplay1234` AP passphrase are device runtime defaults,
not host/build-environment data. They remain versioned because changing them
would change the tested product behavior.
