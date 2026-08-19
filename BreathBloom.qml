pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons

Item {
  id: root

  property real level: 0
  property bool active: false
  property bool preview: false
  property bool reducedMotion: false
  property real visualScale: 1
  property string phaseKind: ""
  property color accent: Color.accent
  property color foreground: Color.foreground
  property color muted: Color.muted

  property real previewLevel: 0.12
  property real livingPulse: 0

  readonly property real clampedLevel: Math.max(0, Math.min(1, preview ? previewLevel : level))
  readonly property real visualLevel: reducedMotion ? 0.45 : clampedLevel
  readonly property real pulseAmount: reducedMotion || !holding ? 0 : livingPulse * 0.008
  readonly property real overallScale: reducedMotion
    ? 0.82 + clampedLevel * 0.13
    : 0.76 + clampedLevel * 0.20 + pulseAmount
  readonly property real spin: reducedMotion ? 0 : -5 + clampedLevel * 10 + (holding ? livingPulse * 0.7 : 0)
  readonly property real side: Math.min(width, height)
  readonly property bool holding: phaseKind === "holdFull" || phaseKind === "holdEmpty"

  SequentialAnimation on previewLevel {
    running: root.preview && root.visible && !root.reducedMotion
    loops: Animation.Infinite

    NumberAnimation {
      from: 0.12
      to: 1
      duration: 4800
      easing.type: Easing.InOutSine
    }
    PauseAnimation { duration: 500 }
    NumberAnimation {
      from: 1
      to: 0.12
      duration: 5600
      easing.type: Easing.InOutSine
    }
    PauseAnimation { duration: 700 }
  }

  SequentialAnimation on livingPulse {
    running: root.active && root.visible && root.holding && !root.reducedMotion
    loops: Animation.Infinite

    NumberAnimation { from: 0; to: 1; duration: 1400; easing.type: Easing.InOutSine }
    NumberAnimation { from: 1; to: 0; duration: 1400; easing.type: Easing.InOutSine }
  }

  Item {
    id: bloom
    width: root.side
    height: root.side
    anchors.centerIn: parent
    scale: root.overallScale * root.visualScale
    rotation: root.spin

    Behavior on scale {
      enabled: root.reducedMotion
      NumberAnimation { duration: 500; easing.type: Easing.InOutSine }
    }

    Rectangle {
      anchors.centerIn: parent
      width: parent.width * (0.30 + root.clampedLevel * 0.08)
      height: width
      radius: width / 2
      color: Util.alpha(root.accent, 0.07)
      scale: 1.12
    }

    Repeater {
      model: 12

      delegate: Item {
        id: outerPetal
        required property int index
        anchors.fill: parent
        rotation: index * 30

        Rectangle {
          readonly property real orbit: root.reducedMotion
            ? bloom.width * 0.08
            : bloom.width * (0.018 + root.clampedLevel * 0.142)

          width: bloom.width * 0.185
          height: bloom.width * (0.38 - root.clampedLevel * 0.035)
          x: bloom.width / 2 - width / 2
          y: bloom.height / 2 - height / 2 - orbit
          radius: width / 2
          color: outerPetal.index % 3 === 0 ? root.foreground : root.accent
          opacity: outerPetal.index % 2 === 0 ? 0.17 : 0.12
          scale: 0.88 + root.clampedLevel * 0.12
          transformOrigin: Item.Center
        }
      }
    }

    Item {
      anchors.fill: parent
      rotation: 15 - root.spin * 0.45
      scale: 0.82 + root.clampedLevel * 0.06

      Repeater {
        model: 12

        delegate: Item {
          id: innerPetal
          required property int index
          anchors.fill: parent
          rotation: index * 30

          Rectangle {
            readonly property real orbit: root.reducedMotion
              ? bloom.width * 0.065
              : bloom.width * (0.012 + root.clampedLevel * 0.115)

            width: bloom.width * 0.16
            height: bloom.width * 0.34
            x: bloom.width / 2 - width / 2
            y: bloom.height / 2 - height / 2 - orbit
            radius: width / 2
            color: innerPetal.index % 2 === 0 ? root.muted : root.accent
            opacity: innerPetal.index % 2 === 0 ? 0.12 : 0.10
          }
        }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: parent.width * (0.10 + root.clampedLevel * 0.035)
      height: width
      radius: width / 2
      color: root.foreground
      opacity: 0.32

      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.54
        height: width
        radius: width / 2
        color: root.accent
        opacity: 0.85
      }
    }
  }
}
