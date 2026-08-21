// ThemedToolTip.qml — a themed drop-in replacement for QQC2's bare
// attached `ToolTip.visible`/`ToolTip.text`/`ToolTip.delay` shorthand
// (quick-260821-6z1 fix wave, operator finding: "the tooltip on the 10
// settings nav-rail items is unthemed and looks foreign").
//
// The attached shorthand lazily instantiates QQC2's OWN default `ToolTip`
// delegate, whose background/text colour come from Qt's INSTALLED STYLE,
// not from any file in this repo — `colour-lint` is structurally unable
// to see it, because the offending colour never appears in a scanned
// .qml file (260821-6z1-RESEARCH.md §6.1, the same blind-spot class that
// already bit `SelectRow`'s Menu/MenuItem before <qqc2_contract> Q-1..Q-4
// fixed it there). **A green colour-lint run is not evidence for this
// defect class** — verify by reading THIS file's own colour bindings.
//
// This is the standalone-`ToolTip {}` idiom `WifiPanel.qml`'s
// `ssidTooltip` / `BluetoothPanel.qml`'s `nameTooltip` already
// established (a declared child object, not the attached shorthand, so
// its own `contentItem`/`background` can be pinned explicitly) —
// factored into one shared component so every call site reads
// `Colours.qml` the same way instead of drifting N hand-styled copies.
// Registered at the cross-tree root (`modules/qmldir`), not
// `modules/settings/common/`, because settings/, bar/, dashboard/ and
// centre/ call sites all need to resolve the SAME type — the same reason
// `Prefs`/`CavaService` are registered there rather than in one leaf
// directory's own manifest.
//
// NOT a replacement for `BarTooltip.qml`/`BarTooltipHost.qml`: those
// exist to solve a POSITION-CLAMPING problem — a QQC2 `ToolTip` is a
// `Popup`, a `Popup` is clamped to its own window, and the bar's own
// window is only `Design.barHeight` (42) tall, so the default clamp
// lands the tooltip almost on top of the bar itself. Their fix is to
// escape to a separate anchored layer-shell surface entirely outside
// that window. Every call site THIS file touches (the settings toplevel,
// dashboard panels, popouts, the notification centre) already renders
// inside a window several hundred pixels tall — `BarTooltipHost.qml`'s
// own header records this exact measurement for the popout sites — so
// the built-in `Popup` clamp already lands clear of the hovered glyph
// with nothing to fix. This component changes ONLY the tooltip's
// colours; it does not touch — and must never touch — where the
// `Popup` positions itself.
import QtQuick
import QtQuick.Controls
import "dashboard"

ToolTip {
    id: root

    delay: Design.tooltipDelayMs

    contentItem: Text {
        text: root.text
        textFormat: Text.PlainText
        wrapMode: Text.NoWrap
        color: Colours.onSurfaceVariant
    }

    background: Rectangle {
        color: Colours.surfaceVariant
        border.width: 1
        border.color: Colours.outline
        radius: Design.spacingXs
    }
}
