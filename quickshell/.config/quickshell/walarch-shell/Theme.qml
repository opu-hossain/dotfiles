pragma Singleton
import QtQuick

// Single source of truth for color/font values. Every widget imports this
// instead of hardcoding hex codes, so the whole shell restyles from one file.
QtObject {
    // Gruvbox Dark — matches kitty/nvim/tmux/waybar
    readonly property color bg: "#1d2021"
    readonly property color bgSoft: "#282828"      // slightly lighter panel bg
    readonly property color fg: "#ebdbb2"
    readonly property color fgMuted: "#a89984"
    readonly property color accent: "#d79921"      // the unified yellow accent
    readonly property color accentAlt: "#458588"   // blue, used sparingly (tmux session name, active tab)
    readonly property color danger: "#cc241d"      // e.g. power/logout confirm

    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 10

    // Shared geometry so bar height / corner radius / spacing stay consistent
    readonly property int barHeight: 32
    readonly property int radius: 6
    readonly property int spacing: 8
}
