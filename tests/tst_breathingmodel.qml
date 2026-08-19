import QtQuick
import QtTest
import "../BreathingModel.js" as BreathingModel

TestCase {
  name: "BreathingModel"

  function test_techniqueLookup() {
    compare(BreathingModel.technique("Box Breathing").id, "box")
    compare(BreathingModel.technique("box-sleep").name, "Box Breathing for Sleep")
    compare(BreathingModel.technique("Box Breathing (sleep)").id, "box-sleep")
    compare(BreathingModel.technique("unknown").id, "box")
    compare(BreathingModel.techniqueNames().length, 7)
  }

  function test_cycleDurations() {
    compare(BreathingModel.cycleDurationMs("box"), 16000)
    compare(BreathingModel.cycleDurationMs("resonant"), 11000)
    compare(BreathingModel.cycleDurationMs("478"), 19000)
    compare(BreathingModel.cycleDurationMs("box-sleep"), 16000)
    compare(BreathingModel.cycleDurationMs("coordinated"), 24000)
    compare(BreathingModel.cycleDurationMs("nadi-shodhana"), 32000)
    compare(BreathingModel.cycleDurationMs("yogic"), 13000)
  }

  function test_exactPhaseBoundaries() {
    var start = BreathingModel.phaseAt("box", 0)
    compare(start.phaseKind, "inhale")
    compare(start.phaseRemainingMs, 4000)
    compare(start.breathLevel, 0)

    var fullHold = BreathingModel.phaseAt("box", 4000)
    compare(fullHold.phaseKind, "holdFull")
    compare(fullHold.breathLevel, 1)

    var exhale = BreathingModel.phaseAt("box", 8000)
    compare(exhale.phaseKind, "exhale")
    compare(exhale.breathLevel, 1)

    var emptyHold = BreathingModel.phaseAt("box", 12000)
    compare(emptyHold.phaseKind, "holdEmpty")
    compare(emptyHold.breathLevel, 0)

    var nextCycle = BreathingModel.phaseAt("box", 16000)
    compare(nextCycle.phaseKind, "inhale")
    compare(nextCycle.cycleIndex, 1)
    compare(nextCycle.cycleElapsedMs, 0)
  }

  function test_breathLevelUsesSmoothInterpolation() {
    var inhaleMidpoint = BreathingModel.phaseAt("box", 2000)
    verify(Math.abs(inhaleMidpoint.breathLevel - 0.5) < 0.0001)

    var exhaleMidpoint = BreathingModel.phaseAt("box", 10000)
    verify(Math.abs(exhaleMidpoint.breathLevel - 0.5) < 0.0001)
  }

  function test_nadiSidesAlternate() {
    compare(BreathingModel.phaseAt("nadi-shodhana", 0).guidance, "LEFT")
    compare(BreathingModel.phaseAt("nadi-shodhana", 8000).guidance, "RIGHT")
    compare(BreathingModel.phaseAt("nadi-shodhana", 16000).guidance, "RIGHT")
    compare(BreathingModel.phaseAt("nadi-shodhana", 24000).guidance, "LEFT")
  }

  function test_yogicStages() {
    compare(BreathingModel.phaseAt("yogic", 0).guidance, "BELLY")
    compare(BreathingModel.phaseAt("yogic", 2000).guidance, "MID-TORSO")
    compare(BreathingModel.phaseAt("yogic", 4000).guidance, "UPPER CHEST")
    compare(BreathingModel.phaseAt("yogic", 6500).phaseKind, "exhale")
    compare(BreathingModel.phaseAt("yogic", 6500).guidance, "UPPER CHEST")
    compare(BreathingModel.phaseAt("yogic", 10500).guidance, "BELLY")
  }

  function test_coordinatedCountRepeats() {
    compare(BreathingModel.phaseAt("coordinated", 4000).count, 1)
    compare(BreathingModel.phaseAt("coordinated", 13000).count, 10)
    compare(BreathingModel.phaseAt("coordinated", 14000).count, 1)
  }

  function test_completionRoundsToCycleBoundary() {
    compare(BreathingModel.completionDurationMs("box", 1), 64000)
    compare(BreathingModel.completionDurationMs("resonant", 1), 66000)
    compare(BreathingModel.completionDurationMs("478", 1), 76000)
    compare(BreathingModel.completionDurationMs("nadi-shodhana", 1), 64000)
    compare(BreathingModel.completionDurationMs("yogic", 1), 65000)
  }

  function test_durationAndProgressClamping() {
    compare(BreathingModel.normalizedDurationMinutes(0), 1)
    compare(BreathingModel.normalizedDurationMinutes(10), 5)
    compare(BreathingModel.normalizedDurationMinutes(2.7), 3)
    compare(BreathingModel.sessionProgress(-1, 100), 0)
    compare(BreathingModel.sessionProgress(50, 100), 0.5)
    compare(BreathingModel.sessionProgress(101, 100), 1)
  }

  function test_clockFormatting() {
    compare(BreathingModel.formatClock(0), "0:00")
    compare(BreathingModel.formatClock(1000), "0:01")
    compare(BreathingModel.formatClock(61000), "1:01")
  }
}
