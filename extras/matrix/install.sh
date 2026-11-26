#!/usr/bin/env bash
# Matrix theme for myomabuntu: green-on-black colours, an animated digital-rain wallpaper and a
# see-through Alacritty so the rain shows behind it.
# A separate, optional install. Run it after the main ./install.sh. See extras/matrix/README.md.
#
#   extras/matrix/install.sh              install the theme, the rain and their packages
#   extras/matrix/install.sh -y           don't ask before apt install
#   extras/matrix/install.sh --skip-apt   no sudo and no apt install (files only)
#   extras/matrix/install.sh --no-switch  install, but don't switch to the theme now
#   extras/matrix/install.sh --uninstall  remove the theme and the rain (packages stay)
#
# Theme colours and wallpapers: https://github.com/BVisagie/omarchy-matrix-theme (MIT),
# pinned to THEME_COMMIT. The rain (matrix-rain.py) is myomabuntu's own.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
THEME_REPO=https://github.com/BVisagie/omarchy-matrix-theme
THEME_COMMIT=59e757b168b49e2a0000065da654895050d0f8fc
OMARCHY_SRC=${OMARCHY_SRC:-$HOME/src/omarchy}
THEME_DIR=$OMARCHY_SRC/themes/matrix
TOOLS=$HOME/.config/hypr/scripts/hypr-tools.sh
RAIN=$HOME/.config/hypr/scripts/matrix-rain.py
FALLBACK_THEME=tokyo-night

# GTK layer shell (draws on the desktop layer), GTK/cairo for Python, katakana font
PKGS=(gir1.2-gtklayershell-0.1 gir1.2-gtk-3.0 python3-gi python3-gi-cairo fonts-noto-cjk git)

ASSUME_YES=0 SKIP_APT=0 SWITCH=1 UNINSTALL=0
for arg in "$@"; do
    case $arg in
        -y|--yes)    ASSUME_YES=1 ;;
        --skip-apt)  SKIP_APT=1 ;;
        --no-switch) SWITCH=0 ;;
        --uninstall) UNINSTALL=1 ;;
        -h|--help)   sed -n '2,13p' "$0"; exit 0 ;;
        *)           echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\n\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# Apply a theme: live if we're inside Hyprland, otherwise just write the files for next login.
theme_set() {
    if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
        OMARCHY_SRC="$OMARCHY_SRC" "$TOOLS" theme-set "$1"
    else
        OMARCHY_SRC="$OMARCHY_SRC" NO_RELOAD=1 "$TOOLS" theme-set "$1"
    fi
}

step "Pre-flight checks"
[[ $EUID -ne 0 ]] || die "Run as your normal user, not root (it uses sudo only for apt)."
[[ -x $TOOLS ]] || die "myomabuntu isn't installed ($TOOLS missing). Run ./install.sh first."
grep -q '^wallpaper-start)' "$TOOLS" \
    || die "Your myomabuntu is older than the Matrix extra (no 'wallpaper-start' in $TOOLS). Re-run ./install.sh first."
[[ -d $OMARCHY_SRC/themes ]] || die "$OMARCHY_SRC/themes missing. Re-run ./install.sh first."
ok "myomabuntu found"

# --- Uninstall ---------------------------------------------------------------
if [[ $UNINSTALL == 1 ]]; then
    step "Removing the Matrix theme"
    if [[ $(cat ~/.config/hypr/theme.name 2>/dev/null) == matrix ]]; then
        theme_set "$FALLBACK_THEME"
        ok "Switched to $FALLBACK_THEME"
    fi
    rm -rf "$THEME_DIR" && ok "Removed $THEME_DIR"
    rm -f "$RAIN" && ok "Removed $RAIN"
    echo "    Packages are left installed: ${PKGS[*]}"
    echo "    Remove the ones you don't use elsewhere with: sudo apt remove gir1.2-gtklayershell-0.1"
    exit 0
fi

# --- Packages ----------------------------------------------------------------
step "Packages"
SIM=$(apt-get -s install --no-install-recommends "${PKGS[@]}" 2>&1) || die "apt simulation failed:
$SIM"
grep -q '^Remv' <<<"$SIM" && { grep '^Remv' <<<"$SIM"; die "The install would remove packages. Stopping."; }
if grep -E '^Inst' <<<"$SIM" | grep -qiE '\b(sddm|lightdm|greetd|gdm3)\b'; then
    die "The install would pull in a display manager. Stopping."
fi
NEW=$(grep -c '^Inst' <<<"$SIM" || true)
if [[ $NEW == 0 ]]; then
    ok "All packages already installed"
elif [[ $SKIP_APT == 1 ]]; then
    warn "--skip-apt: not installing $NEW packages; the rain won't start without them"
else
    grep '^Inst' <<<"$SIM" | awk '{print "      " $2}'
    if [[ $ASSUME_YES == 0 ]]; then
        read -rp "    Install these $NEW packages? [y/N] " reply
        [[ $reply =~ ^[Yy]$ ]] || die "Stopped before installing. Nothing was changed."
    fi
    sudo apt-get install -y --no-install-recommends "${PKGS[@]}"
    ok "Installed"
fi

# --- Theme -------------------------------------------------------------------
step "Matrix theme (${THEME_COMMIT:0:7}) into $THEME_DIR"
if [[ ! -d $THEME_DIR/.git ]]; then
    rm -rf "$THEME_DIR"
    git clone -q "$THEME_REPO" "$THEME_DIR"
fi
git -C "$THEME_DIR" fetch -q origin
git -C "$THEME_DIR" -c advice.detachedHead=false checkout -q "$THEME_COMMIT"
for f in colors.toml backgrounds; do
    [[ -e $THEME_DIR/$f ]] || die "Theme is missing $f"
done
# theme-set needs the 16 terminal colours of the Omarchy 3 format
grep -q '^color15 *=' "$THEME_DIR/colors.toml" || die "Theme colors.toml has no color0..color15"
touch "$THEME_DIR/digital-rain"   # tells theme-set to use the animated wallpaper
cp "$HERE/alacritty.toml" "$THEME_DIR/alacritty-extra.toml"   # see-through terminal for this theme
ok "Theme ready"

# --- Rain --------------------------------------------------------------------
step "Digital rain wallpaper"
install -m 755 "$HERE/matrix-rain.py" "$RAIN"
python3 -m py_compile "$RAIN" && rm -rf "$(dirname "$RAIN")/__pycache__"
ok "$RAIN"
if [[ $SKIP_APT == 0 || $NEW == 0 ]]; then
    python3 -c "import gi; gi.require_version('GtkLayerShell','0.1'); from gi.repository import GtkLayerShell" \
        && ok "GTK layer shell works from Python" || die "Python can't load GtkLayerShell"
fi

# --- Switch ------------------------------------------------------------------
if [[ $SWITCH == 1 ]]; then
    step "Switching to the Matrix theme"
    theme_set matrix
    if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
        ok "Applied"
    else
        ok "Applies at your next Hyprland login"
    fi
fi

step "Done"
echo "    Switch themes:  Super+Shift+Ctrl+Space (pick 'matrix')"
echo "    Wallpaper:      Super+Ctrl+Space -> 'Digital rain (animated)' or a still image"
echo "    Remove:         extras/matrix/install.sh --uninstall"
