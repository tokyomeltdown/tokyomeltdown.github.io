#!/bin/bash
# Renders tools/og-source.html to /og-image.png at 1200x630, the size the
# social cards use; "x" and "icons" render the X header and the square marks.
#
# Chrome rather than a screenshot tool, because the size has to be exact: a
# card that is a pixel off gets rescaled and the type goes soft.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

[ -x "$CHROME" ] || { echo "Google Chrome not found at $CHROME"; exit 1; }

# --headless writes screenshot.png into the working directory and ignores a
# path given to --screenshot in some builds, so it renders into a scratch
# directory and the result is moved.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

render () {   # source, width, height, output
    ( cd "$TMP" && "$CHROME" --headless --disable-gpu --hide-scrollbars \
        --force-device-scale-factor=1 --window-size="$2,$3" \
        --screenshot="$TMP/out.png" \
        "file://$ROOT/tools/$1" >/dev/null 2>&1 )

    [ -f "$TMP/out.png" ] || { echo "Chrome produced no image for $1"; exit 1; }
    mv "$TMP/out.png" "$ROOT/$4"
    sips -g pixelWidth -g pixelHeight "$ROOT/$4"
    echo "wrote $ROOT/$4"
}

# With "x", the X profile header instead: it is uploaded by hand, not served.
# With "icons", the home screen icon and the X profile picture.
if [ "$1" = "x" ]; then
    render x-header-source.html 1500 500 tools/x-header.png
elif [ "$1" = "icons" ]; then
    render icon-source.html 500 500 tools/x-avatar.png
    cp "$ROOT/tools/x-avatar.png" "$ROOT/apple-touch-icon.png"
    sips -z 400 400 "$ROOT/tools/x-avatar.png" >/dev/null
    sips -z 180 180 "$ROOT/apple-touch-icon.png" >/dev/null
    echo "scaled to 400 and 180"
else
    render og-source.html 1200 630 og-image.png
fi
