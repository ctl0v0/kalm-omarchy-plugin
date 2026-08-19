import QtQuick
import Quickshell.Io
import "BreathingModel.js" as BreathingModel

Item {
  id: root
  visible: false

  property var shell: null
  property var manifest: null
  property var settings: ({})

  readonly property string idleState: "idle"
  readonly property string countdownState: "countdown"
  readonly property string runningState: "running"
  readonly property string pausedState: "paused"
  readonly property string completeState: "complete"

  property string sessionState: idleState
  property string selectedTechniqueId: "box"
  property int selectedDurationMinutes: 1
  property bool reducedMotion: false

  property string activeTechniqueId: "box"
  property string activeTechniqueName: "Box Breathing"
  property int activeDurationMinutes: 1
  property int completionMs: 60000
  property int sessionElapsedMs: 0
  property int sessionRemainingMs: completionMs
  property real sessionProgress: 0
  property int completedCycles: 0
  property int currentCycle: 1

  property string phaseKind: ""
  property string phaseLabel: ""
  property string guidance: ""
  property int countValue: 0
  property int phaseRemainingMs: 0
  property int phaseSecondsRemaining: 0
  property real phaseProgress: 0
  property real breathLevel: 0
  property int countdownNumber: 3

  property double countdownStartedAtMs: 0
  property double runStartedAtMs: 0
  property int accumulatedElapsedMs: 0

  readonly property bool sessionActive: sessionState === countdownState || sessionState === runningState || sessionState === pausedState
  readonly property bool canConfigure: sessionState === idleState || sessionState === completeState
  readonly property string selectedTechniqueName: BreathingModel.technique(selectedTechniqueId).name
  readonly property string selectedTechniqueSummary: BreathingModel.technique(selectedTechniqueId).summary
  readonly property string selectedTechniqueCadence: BreathingModel.technique(selectedTechniqueId).cadence
  readonly property string remainingText: BreathingModel.formatClock(sessionRemainingMs)
  readonly property string elapsedText: BreathingModel.formatClock(sessionElapsedMs)

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function syncDefaults() {
    reducedMotion = setting("reducedMotion", false) === true
    if (!canConfigure) return
    selectedTechniqueId = BreathingModel.technique(setting("defaultTechnique", "Box Breathing")).id
    selectedDurationMinutes = BreathingModel.normalizedDurationMinutes(setting("defaultDurationMinutes", 1))
  }

  function selectTechnique(value) {
    if (!canConfigure) return
    selectedTechniqueId = BreathingModel.technique(value).id
  }

  function selectDuration(minutes) {
    if (!canConfigure) return
    selectedDurationMinutes = BreathingModel.normalizedDurationMinutes(minutes)
  }

  function startSession() {
    activeTechniqueId = BreathingModel.technique(selectedTechniqueId).id
    activeTechniqueName = BreathingModel.technique(activeTechniqueId).name
    activeDurationMinutes = BreathingModel.normalizedDurationMinutes(selectedDurationMinutes)
    completionMs = BreathingModel.completionDurationMs(activeTechniqueId, activeDurationMinutes)
    sessionElapsedMs = 0
    sessionRemainingMs = completionMs
    sessionProgress = 0
    completedCycles = 0
    currentCycle = 1
    phaseKind = "countdown"
    phaseLabel = "GET READY"
    guidance = ""
    countValue = 0
    phaseRemainingMs = 3000
    phaseSecondsRemaining = 3
    phaseProgress = 0
    breathLevel = 0.12
    countdownNumber = 3
    accumulatedElapsedMs = 0
    countdownStartedAtMs = Date.now()
    sessionState = countdownState
    tickTimer.start()
  }

  function beginBreathing(now) {
    accumulatedElapsedMs = 0
    runStartedAtMs = now
    sessionState = runningState
    applyElapsed(0)
  }

  function applyElapsed(value) {
    var elapsed = Math.max(0, Math.min(completionMs, Math.round(Number(value) || 0)))
    var snapshot = BreathingModel.phaseAt(activeTechniqueId, elapsed)
    sessionElapsedMs = elapsed
    sessionRemainingMs = Math.max(0, completionMs - elapsed)
    sessionProgress = BreathingModel.sessionProgress(elapsed, completionMs)
    completedCycles = snapshot.cycleIndex
    currentCycle = snapshot.cycleIndex + 1
    phaseKind = snapshot.phaseKind
    phaseLabel = snapshot.phaseLabel
    guidance = snapshot.guidance
    countValue = snapshot.count
    phaseRemainingMs = Math.round(snapshot.phaseRemainingMs)
    phaseSecondsRemaining = Math.max(1, Math.ceil(snapshot.phaseRemainingMs / 1000))
    phaseProgress = snapshot.phaseProgress
    breathLevel = snapshot.breathLevel
  }

  function update(now) {
    var current = Number(now) || Date.now()
    if (sessionState === countdownState) {
      var countdownElapsed = Math.max(0, current - countdownStartedAtMs)
      var remaining = Math.max(0, 3000 - countdownElapsed)
      phaseRemainingMs = Math.round(remaining)
      phaseSecondsRemaining = Math.max(1, Math.ceil(remaining / 1000))
      countdownNumber = Math.max(1, Math.ceil(remaining / 1000))
      phaseProgress = Math.min(1, countdownElapsed / 3000)
      breathLevel = 0.12 * (1 - phaseProgress)
      if (remaining <= 0) beginBreathing(current)
      return
    }

    if (sessionState !== runningState) return
    var elapsed = accumulatedElapsedMs + Math.max(0, current - runStartedAtMs)
    if (elapsed >= completionMs) {
      applyElapsed(Math.max(0, completionMs - 1))
      sessionElapsedMs = completionMs
      sessionRemainingMs = 0
      sessionProgress = 1
      completedCycles = Math.round(completionMs / BreathingModel.cycleDurationMs(activeTechniqueId))
      currentCycle = completedCycles
      phaseKind = "complete"
      phaseLabel = "COMPLETE"
      guidance = ""
      countValue = 0
      phaseRemainingMs = 0
      phaseSecondsRemaining = 0
      phaseProgress = 1
      breathLevel = 0.62
      sessionState = completeState
      tickTimer.stop()
      return
    }
    applyElapsed(elapsed)
  }

  function pauseSession() {
    if (sessionState !== runningState) return
    update(Date.now())
    accumulatedElapsedMs = sessionElapsedMs
    sessionState = pausedState
    tickTimer.stop()
  }

  function resumeSession() {
    if (sessionState !== pausedState) return
    runStartedAtMs = Date.now()
    sessionState = runningState
    tickTimer.start()
  }

  function togglePause() {
    if (sessionState === pausedState) resumeSession()
    else if (sessionState === runningState) pauseSession()
  }

  function endSession() {
    tickTimer.stop()
    sessionState = idleState
    phaseKind = ""
    phaseLabel = ""
    guidance = ""
    countValue = 0
    phaseRemainingMs = 0
    phaseSecondsRemaining = 0
    phaseProgress = 0
    breathLevel = 0
    sessionElapsedMs = 0
    sessionRemainingMs = 0
    sessionProgress = 0
    completedCycles = 0
    currentCycle = 1
  }

  function repeatSession() {
    selectedTechniqueId = activeTechniqueId
    selectedDurationMinutes = activeDurationMinutes
    startSession()
  }

  onSettingsChanged: syncDefaults()

  Timer {
    id: tickTimer
    interval: 33
    repeat: true
    running: false
    onTriggered: root.update(Date.now())
  }

  IpcHandler {
    target: "io.github.ctl0v0.kalm"

    function start(): string {
      root.startSession()
      return "ok"
    }

    function pause(): string {
      if (root.sessionState !== root.runningState) return "unhandled"
      root.pauseSession()
      return "ok"
    }

    function resume(): string {
      if (root.sessionState !== root.pausedState) return "unhandled"
      root.resumeSession()
      return "ok"
    }

    function stop(): string {
      root.endSession()
      return "ok"
    }

    function status(): string {
      return JSON.stringify({
        state: root.sessionState,
        technique: root.activeTechniqueName,
        phase: root.phaseKind,
        phaseSecondsRemaining: root.phaseSecondsRemaining,
        elapsedMs: root.sessionElapsedMs,
        remainingMs: root.sessionRemainingMs,
        progress: root.sessionProgress,
        completedCycles: root.completedCycles
      })
    }
  }

  Component.onCompleted: syncDefaults()
}
