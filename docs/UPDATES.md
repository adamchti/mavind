# Updates

Mavind Settings → Updates has one button, "Check & install updates," that does two
unrelated things back to back:

1. `mpk update && mpk upgrade` — plain Debian package updates (kernel, libraries, apt
   packages generally). Standard `apt` underneath; nothing Mavind-specific here.
2. `mavind-update` — Mavind's own components (`mavind-shell`, `mavind-settings`,
   `mavind-launcher`, the icon set, the wallpapers, ...). These are **not** Debian
   packages — they're compiled straight into the image at ISO-build time — so step 1
   never touches them on its own. This doc is about step 2.

Both run in a visible terminal. Mavind never updates in the background.

## What `mavind-update` actually does

Every push to `main` that passes CI publishes a small bundle — compiled binaries, the
icon SVGs, rasterized wallpapers, and a list of any newly-required apt packages — to a
rolling GitHub Release tagged `update-latest` (see the "Publish Mavind self-update
bundle" step in `.github/workflows/build.yml`). It is **not** a full ISO; typically a
few tens of MB, not ~1 GB.

`system/update/mavind-update`:

- `mavind-update --check` (no root needed) fetches a one-line version marker over
  HTTPS and compares it to `/var/lib/mavind/update-version`, the locally-recorded
  version. Settings' Updates panel calls this to show "up to date" / "update
  available" without downloading anything.
- `mavind-update` (needs root — Settings runs it via `pkexec`) downloads the bundle
  and its `sha256` checksum, **verifies the checksum before extracting anything**,
  then installs the binaries to `/usr/bin`, the icons to
  `/usr/share/icons/hicolor/scalable/apps`, the wallpapers to
  `/usr/share/backgrounds/mavind`, and `apt install`s anything listed in the bundle's
  `packages.txt` that isn't already present (this is how a newly-added runtime
  dependency, like the `librsvg2-common` fix, reaches an already-installed system).

It tells you to log out and back in (or reboot) afterward — it does not try to
hot-restart a running desktop session mid-update.

## Trust model — stated honestly

The download is HTTPS and checksum-verified, which protects against corruption or
tampering in transit. It does **not** add cryptographic signing on top of that — the
checksum is published from the same release it protects, by the same CI job. The real
trust boundary is "whoever has push access to this GitHub repository," identical to
every other file in it. This is intentionally the lightweight option: good enough for
iterating on a system that's actually installed somewhere, not a production update
channel with independent signing keys. A real APT repository (signed, hosted
separately) would be the next step up if this project needs that guarantee later.

## Why not just use `apt` for everything?

Mavind's own apps aren't packaged as `.deb`s at all — nothing in `system/packages/`
lists `mavind-shell` or similar, because they don't exist as installable packages;
they're `cargo build`-ed and `install -Dm755`-ed straight into the rootfs during the
ISO build (see `scripts/20-build-components.sh`). Turning them into real, signed
`.deb`s in a proper repository is possible but a meaningfully bigger undertaking
(signing key management, repo hosting, `Packages`/`Release` file generation) than
what an actively-developed, single-maintainer OS needs right now.
