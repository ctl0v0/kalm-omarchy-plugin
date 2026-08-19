import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.ctl0v0.kalm"

  readonly property var session: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property bool sessionActive: session ? session.sessionActive : false
  readonly property string sessionState: session ? session.sessionState : "idle"
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function phasePrefix() {
    if (!session) return ""
    if (sessionState === "countdown") return "READY " + session.countdownNumber
    if (sessionState === "paused") return "PAUSED"
    if (sessionState === "complete") return "DONE"
    if (sessionState !== "running") return ""
    if (session.phaseKind === "inhale") return "IN " + session.phaseSecondsRemaining
    if (session.phaseKind === "exhale") return "OUT " + session.phaseSecondsRemaining
    if (session.phaseKind === "holdFull" || session.phaseKind === "holdEmpty")
      return "HOLD " + session.phaseSecondsRemaining
    return "SET " + session.phaseSecondsRemaining
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.session = root.session
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  onSessionChanged: injectPanel()

  Binding {
    target: root.session
    property: "settings"
    value: root.settings
    when: root.session !== null
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  TextMetrics {
    id: phaseLabelMetrics
    font: phaseLabel.font
    text: "READY 00"
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical ? root.barSize : markRow.implicitWidth + Style.space(12)
    tooltipText: root.sessionState === "idle"
      ? "Kalm - Start a breathing session"
      : (root.sessionState === "complete" ? "Kalm - Session complete" : "Kalm - " + root.phasePrefix())

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }

    Row {
      id: markRow
      anchors.centerIn: parent
      spacing: Style.spacing.md

      BreathBloom {
        width: Style.bar.iconCanvas
        height: width
        anchors.verticalCenter: parent.verticalCenter
        level: root.session
          ? (root.sessionState === "idle" ? 0.28 : root.session.breathLevel)
          : 0.28
        active: root.sessionState === "running"
        reducedMotion: root.session ? root.session.reducedMotion : false
        visualScale: 2.2
        phaseKind: root.session ? root.session.phaseKind : ""
        accent: root.bar ? root.bar.barForeground : Color.accent
        foreground: root.bar ? root.bar.barForeground : Color.foreground
        muted: Color.muted
      }

      Text {
        id: phaseLabel
        visible: !root.vertical && root.sessionState !== "idle"
        anchors.verticalCenter: parent.verticalCenter
        width: phaseLabelMetrics.advanceWidth
        text: root.phasePrefix()
        color: root.sessionState === "complete" ? Color.accent : (root.bar ? root.bar.barForeground : Color.foreground)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: root.sessionState === "running" || root.sessionState === "complete"
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
