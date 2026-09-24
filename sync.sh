#!/usr/bin/env bash
# Regenerate powerdevil.spec from Fedora's packaging plus ddc-delay.patch.
# Fails loudly if Fedora's spec or KDE's source no longer fit the patch.
set -euo pipefail

cd "$(dirname "$0")"
branch=$(cat fedora-branch)
work=.work
rm -rf "$work"
git clone -q --depth 1 -b "$branch" https://src.fedoraproject.org/rpms/powerdevil.git "$work/fedora"
spec=$work/fedora/powerdevil.spec

grep -qE '^Release:[[:space:]]*[0-9]+%\{\?dist\}[[:space:]]*$' "$spec" || { echo "Unexpected Release: line"; exit 1; }
grep -qE '^%autosetup[[:space:]]+-p1' "$spec" || { echo "%autosetup -p1 missing, patch would not be applied"; exit 1; }

# Release N%{?dist} -> N%{?dist}.ddc1, so it sorts just above Fedora's build.
# Patch100 goes right after the last SourceN: line.
awk '
  /^Release:/ { sub(/%\{\?dist\}/, "%{?dist}.ddc1") }
  { lines[NR] = $0 }
  /^Source[0-9]*:/ { last_source = NR }
  END {
    for (i = 1; i <= NR; i++) {
      print lines[i]
      if (i == last_source) {
        print ""
        print "# Shorter DDC/CI brightness debounce, see https://github.com/plichard/powerdevil-ddc"
        print "Patch100: ddc-delay.patch"
      }
    }
  }
' "$spec" > powerdevil.spec

# Check the patch still applies to the exact tarball Fedora ships.
version=$(awk '/^Version:/ { print $2; exit }' powerdevil.spec)
tarball=powerdevil-$version.tar.xz
curl -sfL -o "$work/$tarball" "https://download.kde.org/stable/plasma/$version/$tarball"
expected=$(sed -nE "s/^SHA512 \($tarball\) = //p" "$work/fedora/sources")
echo "$expected  $work/$tarball" | sha512sum -c --quiet
tar -xf "$work/$tarball" -C "$work"
patch -d "$work/powerdevil-$version" -p1 --dry-run --quiet < ddc-delay.patch

rm -rf "$work"
echo "powerdevil.spec synced to $version from Fedora $branch"
