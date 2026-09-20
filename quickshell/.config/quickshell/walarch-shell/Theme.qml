pragma Singleton
import QtQuick

QtObject {
    // Gruvbox Dark — base palette
    readonly property color bg: "#1d2021"
    readonly property color bgSoft: "#282828"
    readonly property color bgHard: "#141617"
    readonly property color fg: "#ebdbb2"
    readonly property color fgMuted: "#a89984"

    // Vim Statusline Section Colors
    readonly property color modeNormal: "#458588"   // Blue
    readonly property color modeInsert: "#98971a"   // Green
    readonly property color modeVisual: "#b16286"   // Purple
    readonly property color modeCommand: "#d79921"  // Yellow
    
    readonly property color accent: "#458588"
    readonly property color accentAlt: "#d79921"
    readonly property color danger: "#cc241d"
    readonly property color warning: "#fabd2f"

    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 11

    readonly property int barHeight: 30  // Slim statusline height
    readonly property int radius: 0
    readonly property int spacing: 0
}
