pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "BreathingModel.js" as BreathingModel

Panel {
  id: root
  moduleName: "io.github.ctl0v0.kalm"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var session: null
  property int cursorIndex: 0
  property bool fullscreen: false

  readonly property color foreground: Color.popups.text
  readonly property color accent: Color.accent
  readonly property color muted: Color.muted
  readonly property string viewState: session ? session.sessionState : "idle"
  readonly property bool configuring: viewState === "idle"
  readonly property bool breathing: viewState === "running" || viewState === "paused"
  readonly property bool paused: viewState === "paused"
  readonly property bool complete: viewState === "complete"
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.controller.show()
  }

  function close() {
    fullscreen = false
    root.controller.hide()
  }

  function toggle() {
    root.opened ? close() : open()
  }

  function enterFullscreen() {
    if (breathing) fullscreen = true
  }

  function exitFullscreen() {
    fullscreen = false
  }

  function endSession() {
    if (session) session.endSession()
    fullscreen = false
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function cursorCount() {
    if (configuring) return 5
    if (breathing) return 3
    if (complete) return 2
    return 0
  }

  function moveCursor(direction) {
    var count = cursorCount()
    if (count <= 0) return
    cursorIndex = (cursorIndex + direction + count) % count
  }

  function activateCursor() {
    if (!session) return
    if (configuring) {
      if (cursorIndex === 0) techniqueDropdown.toggle()
      else if (cursorIndex === 1) session.selectDuration(1)
      else if (cursorIndex === 2) session.selectDuration(3)
      else if (cursorIndex === 3) session.selectDuration(5)
      else session.startSession()
      return
    }
    if (breathing) {
      if (cursorIndex === 0) session.togglePause()
      else if (cursorIndex === 1) enterFullscreen()
      else endSession()
      return
    }
    if (complete) {
      if (cursorIndex === 0) session.repeatSession()
      else session.endSession()
    }
  }

  function secondaryGuidance() {
    if (!session) return ""
    if (session.countValue > 0) return String(session.countValue)
    return session.guidance
  }

  onOpenedChanged: if (!opened) fullscreen = false
  onViewStateChanged: {
    cursorIndex = 0
    if (!breathing && !complete) fullscreen = false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root
    bar: root.bar
    open: root.opened && !root.fullscreen
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430), Style.space(500))
    contentHeight: panel.fittedContentHeight(Style.space(440), Style.space(500))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: techniqueDropdown.popupOpen

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.moveCursor(direction) }
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.moveCursor(dy > 0 ? 1 : -1)
        else if (dx !== 0) root.moveCursor(dx > 0 ? 1 : -1)
      }
      onActivateRequested: root.activateCursor()
      onTextKey: function(text) {
        var key = String(text || "").toLowerCase()
        if (key === "s" && root.configuring && root.session) root.session.startSession()
        else if (key === "p" && root.breathing && root.session) root.session.togglePause()
        else if (key === "f" && root.breathing) root.enterFullscreen()
        else if (key === "e" && (root.breathing || root.viewState === "countdown")) root.endSession()
      }

      Item {
        id: setupPage
        anchors.fill: parent
        visible: root.configuring

        Column {
          anchors.centerIn: parent
          width: parent.width
          spacing: Style.spacing.lg

          Text {
            width: parent.width
            text: "KALM"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: Style.spaceReal(1.5)
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            width: parent.width
            text: "Take a moment to reset."
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            horizontalAlignment: Text.AlignHCenter
          }

          Item {
            width: parent.width
            height: Math.min(Style.space(235), Math.max(Style.space(190), setupPage.height * 0.45))

            BreathBloom {
              width: Math.min(parent.width, parent.height)
              height: width
              anchors.centerIn: parent
              preview: true
              reducedMotion: root.session ? root.session.reducedMotion : false
              accent: root.accent
              foreground: root.foreground
              muted: root.muted
            }
          }

          Dropdown {
            id: techniqueDropdown
            width: parent.width
            showLabel: false
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            options: BreathingModel.techniqueNames()
            value: root.session ? root.session.selectedTechniqueName : "Box Breathing"
            hasCursor: root.configuring && root.cursorIndex === 0
            onChanged: function(value) { if (root.session) root.session.selectTechnique(value) }
            onHovered: function(hovered) { if (hovered) root.cursorIndex = 0 }
          }

          Text {
            width: parent.width
            text: root.session ? root.session.selectedTechniqueCadence : ""
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: Style.spaceReal(0.6)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
          }

          Row {
            id: durationRow
            width: parent.width
            spacing: Style.spacing.controlGap

            Repeater {
              model: [1, 3, 5]

              delegate: Button {
                required property int modelData
                required property int index
                width: (durationRow.width - durationRow.spacing * 2) / 3
                text: modelData + " MIN"
                foreground: root.foreground
                accent: root.accent
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                selected: root.session ? root.session.selectedDurationMinutes === modelData : modelData === 1
                hasCursor: root.configuring && root.cursorIndex === index + 1
                bordered: true
                onClicked: if (root.session) root.session.selectDuration(modelData)
                onHovered: function(hovered) { if (hovered) root.cursorIndex = index + 1 }
              }
            }
          }

          Button {
            width: parent.width
            text: "BEGIN"
            iconText: ">"
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            selected: true
            bordered: true
            hasCursor: root.configuring && root.cursorIndex === 4
            onClicked: if (root.session) root.session.startSession()
            onHovered: function(hovered) { if (hovered) root.cursorIndex = 4 }
          }
        }
      }

      Item {
        id: countdownPage
        anchors.fill: parent
        visible: root.viewState === "countdown"

        Column {
          anchors.centerIn: parent
          width: parent.width
          spacing: Style.spacing.xxl

          Text {
            width: parent.width
            text: root.session ? root.session.activeTechniqueName.toUpperCase() : ""
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: Style.spaceReal(1)
            horizontalAlignment: Text.AlignHCenter
          }

          Item {
            width: parent.width
            height: Math.min(Style.space(280), countdownPage.height * 0.56)

            BreathBloom {
              width: Math.min(parent.width, parent.height)
              height: width
              anchors.centerIn: parent
              level: root.session ? root.session.breathLevel : 0
              active: true
              reducedMotion: root.session ? root.session.reducedMotion : false
              phaseKind: "countdown"
              accent: root.accent
              foreground: root.foreground
              muted: root.muted
            }

            Text {
              anchors.centerIn: parent
              text: root.session ? String(root.session.countdownNumber) : "3"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge * 2
              font.bold: true

              Behavior on opacity { NumberAnimation { duration: 180 } }
            }
          }

          Text {
            width: parent.width
            text: "GET READY"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            font.bold: true
            font.letterSpacing: Style.spaceReal(1.2)
            horizontalAlignment: Text.AlignHCenter
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "CANCEL"
            foreground: root.muted
            accent: root.accent
            fontFamily: root.fontFamily
            onClicked: if (root.session) root.session.endSession()
          }
        }
      }

      Item {
        id: activePage
        anchors.fill: parent
        visible: root.breathing

        BreathingView {
          anchors.fill: parent
          fullscreenMode: false
        }
      }

      Item {
        id: completePage
        anchors.fill: parent
        visible: root.complete

        Column {
          anchors.centerIn: parent
          width: parent.width
          spacing: Style.spacing.xxl

          Text {
            width: parent.width
            text: "KALM"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: Style.spaceReal(1.5)
            horizontalAlignment: Text.AlignHCenter
          }

          Item {
            width: parent.width
            height: Math.min(Style.space(235), completePage.height * 0.48)

            BreathBloom {
              width: Math.min(parent.width, parent.height)
              height: width
              anchors.centerIn: parent
              level: 0.62
              active: false
              reducedMotion: root.session ? root.session.reducedMotion : false
              phaseKind: "complete"
              accent: root.accent
              foreground: root.foreground
              muted: root.muted
            }
          }

          Column {
            width: parent.width
            spacing: Style.spacing.xs

            Text {
              width: parent.width
              text: "COMPLETE"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              font.bold: true
              font.letterSpacing: Style.spaceReal(1.1)
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              width: parent.width
              text: root.session
                ? root.session.elapsedText + "  /  " + root.session.completedCycles + " CYCLES"
                : ""
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              horizontalAlignment: Text.AlignHCenter
            }
          }

          Row {
            id: completeActions
            width: parent.width
            spacing: Style.spacing.controlGap

            Button {
              id: againButton
              width: (completeActions.width - completeActions.spacing) * 0.64
              text: "AGAIN"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              selected: true
              bordered: true
              hasCursor: root.complete && root.cursorIndex === 0
              onClicked: if (root.session) root.session.repeatSession()
              onHovered: function(hovered) { if (hovered) root.cursorIndex = 0 }
            }

            Button {
              width: completeActions.width - againButton.width - completeActions.spacing
              text: "DONE"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              bordered: true
              hasCursor: root.complete && root.cursorIndex === 1
              onClicked: {
                if (root.session) root.session.endSession()
                root.close()
              }
              onHovered: function(hovered) { if (hovered) root.cursorIndex = 1 }
            }
          }
        }
      }
    }
  }

  PanelWindow {
    id: fullscreenWindow

    screen: root.anchorItem && root.anchorItem.QsWindow.window
      ? root.anchorItem.QsWindow.window.screen
      : null
    visible: root.opened && root.fullscreen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "kalm-fullscreen"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) Qt.callLater(function() {
      if (fullscreenWindow.visible) fullscreenKeys.forceActiveFocus()
    })

    Rectangle {
      anchors.fill: parent
      color: Color.background

      Rectangle {
        anchors.fill: parent
        color: Util.alpha(root.accent, 0.025 + (root.session ? root.session.breathLevel * 0.025 : 0))
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.exitFullscreen()
      }
    }

    Item {
      id: fullscreenKeys
      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_F) {
          root.exitFullscreen()
          event.accepted = true
        } else if ((event.key === Qt.Key_P || event.key === Qt.Key_Space) && root.breathing && root.session) {
          root.session.togglePause()
          event.accepted = true
        } else if (event.key === Qt.Key_E && root.breathing) {
          root.endSession()
          event.accepted = true
        }
      }

      Item {
        anchors.fill: parent
        visible: root.breathing

        MouseArea { anchors.fill: parent; onClicked: {} }

        BreathingView {
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.space(96), Style.space(760))
          height: Math.min(parent.height - Style.space(96), Style.space(900))
          fullscreenMode: true
        }
      }

      Item {
        anchors.fill: parent
        visible: root.complete

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.space(96), Style.space(640))
          spacing: Style.space(24)

          Text {
            width: parent.width
            text: root.session ? root.session.activeTechniqueName.toUpperCase() : "KALM"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: Style.spaceReal(1.5)
            horizontalAlignment: Text.AlignHCenter
          }

          Item {
            width: parent.width
            height: Math.min(Style.space(420), fullscreenKeys.height * 0.46)

            BreathBloom {
              width: Math.min(parent.width, parent.height)
              height: width
              anchors.centerIn: parent
              level: 0.62
              active: false
              reducedMotion: root.session ? root.session.reducedMotion : false
              phaseKind: "complete"
              accent: root.accent
              foreground: root.foreground
              muted: root.muted
            }
          }

          Column {
            width: parent.width
            spacing: Style.spacing.xs

            Text {
              width: parent.width
              text: "COMPLETE"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              font.bold: true
              font.letterSpacing: Style.spaceReal(1.2)
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              width: parent.width
              text: root.session
                ? root.session.elapsedText + "  /  " + root.session.completedCycles + " CYCLES"
                : ""
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, Style.space(500))
            spacing: Style.spacing.controlGap

            Button {
              id: fullscreenAgainButton
              width: (parent.width - parent.spacing) * 0.62
              text: "AGAIN"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              selected: true
              bordered: true
              onClicked: {
                root.exitFullscreen()
                if (root.session) root.session.repeatSession()
              }
            }

            Button {
              width: parent.width - fullscreenAgainButton.width - parent.spacing
              text: "DONE"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              bordered: true
              onClicked: {
                root.endSession()
                root.close()
              }
            }
          }
        }
      }
    }
  }

  component BreathingView: Column {
    id: breathingView

    property bool fullscreenMode: false

    spacing: fullscreenMode ? Style.space(20) : Style.spacing.lg

    Item {
      width: parent.width
      height: Style.font.subtitle

      Text {
        anchors.left: parent.left
        anchors.right: remainingText.left
        anchors.rightMargin: Style.spacing.controlGap
        text: root.session ? root.session.activeTechniqueName.toUpperCase() : ""
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.letterSpacing: Style.spaceReal(0.8)
        elide: Text.ElideRight
      }

      Text {
        id: remainingText
        anchors.right: parent.right
        text: root.session ? root.session.remainingText : "0:00"
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Item {
      width: parent.width
      height: breathingView.fullscreenMode
        ? Math.min(Style.space(560), Math.max(Style.space(320), breathingView.height * 0.60))
        : Math.min(Style.space(285), Math.max(Style.space(220), breathingView.height * 0.57))
      clip: true

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * (0.10 + (root.session ? root.session.breathLevel : 0) * 0.90)
        color: Util.alpha(root.accent, breathingView.fullscreenMode ? 0.032 : 0.045)

        Behavior on height {
          NumberAnimation { duration: 80; easing.type: Easing.OutSine }
        }
      }

      BreathBloom {
        width: Math.min(parent.width, parent.height)
        height: width
        anchors.centerIn: parent
        level: root.session ? root.session.breathLevel : 0
        active: root.viewState === "running"
        reducedMotion: root.session ? root.session.reducedMotion : false
        phaseKind: root.session ? root.session.phaseKind : ""
        accent: root.accent
        foreground: root.foreground
        muted: root.muted
      }
    }

    Column {
      width: parent.width
      spacing: Style.spacing.xxs

      Text {
        id: phaseText
        width: parent.width
        text: root.paused ? "PAUSED" : (root.session ? root.session.phaseLabel : "")
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: breathingView.fullscreenMode ? Style.font.display : Style.font.heading
        font.bold: true
        font.letterSpacing: Style.spaceReal(1.1)
        horizontalAlignment: Text.AlignHCenter

        onTextChanged: phaseFade.restart()
        SequentialAnimation {
          id: phaseFade
          NumberAnimation { target: phaseText; property: "opacity"; to: 0.35; duration: 90 }
          NumberAnimation { target: phaseText; property: "opacity"; to: 1; duration: 120 }
        }
      }

      Text {
        width: parent.width
        text: root.paused
          ? "Take your time"
          : (root.secondaryGuidance() || (root.session ? String(root.session.phaseSecondsRemaining) : ""))
        color: root.secondaryGuidance() && !root.paused ? root.accent : root.muted
        font.family: root.fontFamily
        font.pixelSize: root.secondaryGuidance() && !root.paused
          ? (breathingView.fullscreenMode ? Style.font.displayLarge : Style.font.title)
          : (breathingView.fullscreenMode ? Style.font.title : Style.font.body)
        font.bold: root.secondaryGuidance() !== "" && !root.paused
        horizontalAlignment: Text.AlignHCenter
      }
    }

    Rectangle {
      width: parent.width
      height: Style.spacing.xxs
      radius: height / 2
      color: Util.alpha(root.foreground, 0.10)

      Rectangle {
        width: parent.width * (root.session ? root.session.sessionProgress : 0)
        height: parent.height
        radius: parent.radius
        color: root.accent

        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutSine } }
      }
    }

    Item {
      width: parent.width
      height: Style.font.caption

      Text {
        anchors.left: parent.left
        text: root.session ? "CYCLE " + root.session.currentCycle : ""
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        anchors.right: parent.right
        text: root.session ? root.session.elapsedText + " ELAPSED" : ""
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Row {
      id: actionRow
      anchors.horizontalCenter: parent.horizontalCenter
      width: breathingView.fullscreenMode ? Math.min(parent.width, Style.space(620)) : parent.width
      spacing: Style.spacing.controlGap
      readonly property real usableWidth: width - spacing * 2

      Button {
        width: actionRow.usableWidth * 0.34
        text: root.paused ? "RESUME" : "PAUSE"
        foreground: root.foreground
        accent: root.accent
        fontFamily: root.fontFamily
        fontSize: breathingView.fullscreenMode ? Style.font.body : Style.font.bodySmall
        selected: true
        bordered: true
        hasCursor: !breathingView.fullscreenMode && root.breathing && root.cursorIndex === 0
        onClicked: if (root.session) root.session.togglePause()
        onHovered: function(hovered) { if (hovered && !breathingView.fullscreenMode) root.cursorIndex = 0 }
      }

      Button {
        width: actionRow.usableWidth * 0.42
        text: breathingView.fullscreenMode ? "EXIT FULL SCREEN" : "FULL SCREEN"
        foreground: root.foreground
        accent: root.accent
        fontFamily: root.fontFamily
        fontSize: breathingView.fullscreenMode ? Style.font.body : Style.font.bodySmall
        bordered: true
        hasCursor: !breathingView.fullscreenMode && root.breathing && root.cursorIndex === 1
        onClicked: breathingView.fullscreenMode ? root.exitFullscreen() : root.enterFullscreen()
        onHovered: function(hovered) { if (hovered && !breathingView.fullscreenMode) root.cursorIndex = 1 }
      }

      Button {
        width: actionRow.usableWidth * 0.24
        text: "END"
        foreground: root.foreground
        accent: Color.urgent
        fontFamily: root.fontFamily
        fontSize: breathingView.fullscreenMode ? Style.font.body : Style.font.bodySmall
        bordered: true
        hasCursor: !breathingView.fullscreenMode && root.breathing && root.cursorIndex === 2
        onClicked: root.endSession()
        onHovered: function(hovered) { if (hovered && !breathingView.fullscreenMode) root.cursorIndex = 2 }
      }
    }
  }
}
