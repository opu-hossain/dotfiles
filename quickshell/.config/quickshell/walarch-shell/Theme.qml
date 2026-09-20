pragma Singleton
import QtQuick

QtObject {
    // Gruvbox Dark — matches kitty/nvim/tmux/waybar
    readonly property color bg: "#1d2021"
    readonly property color bgSoft: "#282828"
    readonly property color fg: "#ebdbb2"
    readonly property color fgMuted: "#a89984"

    readonly property color accent: "#458588"      // blue — primary accent
    readonly property color accentAlt: "#d79921"   // yellow — secondary
    readonly property color danger: "#cc241d"
    readonly property color warning: "#fabd2f"

    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 12             // was 10 — this is the main visibility fix

    readonly property int barHeight: 36            // was 32, room for the larger type
    readonly property int radius: 6
    readonly property int spacing: 8
}
