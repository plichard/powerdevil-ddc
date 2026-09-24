# powerdevil-ddc

Fedora's `powerdevil` package with one change: the DDC/CI brightness debounce is
100 ms instead of 1 s, so external monitors follow the Plasma brightness slider
almost immediately (Plasma 5.27 used 100 ms; Plasma 6 raised it to 1 s).

The change is `ddc-delay.patch`. Everything else is Fedora's own packaging.

## Install

```bash
sudo dnf copr enable eagle2com/powerdevil-ddc
sudo dnf upgrade --refresh powerdevil
systemctl --user restart plasma-powerdevil
```

## How it stays current

- `.github/workflows/sync.yml` runs daily and calls `sync.sh`, which takes
  Fedora's `powerdevil.spec` from the branch in `fedora-branch`, adds the patch,
  appends `.ddc1` to the release, and checks the patch still applies to the
  tarball Fedora ships. If anything changed it commits and pushes.
- The push triggers COPR (webhook), which builds with the `make_srpm` method
  (`.copr/Makefile`).
- Until the rebuild lands, Fedora's newer stock build may briefly replace this one.

If the Action fails (you get a GitHub email), the patch or Fedora's spec changed
in a way that needs a look.

## Upgrading Fedora

Enable the new chroot in the COPR project settings and change `fedora-branch`
(e.g. to `f45`). Until then dnf simply falls back to Fedora's stock package.

## Build it locally

```bash
./sync.sh
make -f .copr/Makefile srpm outdir=$PWD
```
