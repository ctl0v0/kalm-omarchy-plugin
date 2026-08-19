.pragma library

var techniques = [
  {
    id: "box",
    name: "Box Breathing",
    shortName: "Box",
    summary: "An even four-part cadence.",
    cadence: "IN 4  /  HOLD 4  /  OUT 4  /  HOLD 4",
    phases: [
      { kind: "inhale", label: "BREATHE IN", durationMs: 4000, from: 0, to: 1 },
      { kind: "holdFull", label: "HOLD", durationMs: 4000, from: 1, to: 1 },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 4000, from: 1, to: 0 },
      { kind: "holdEmpty", label: "HOLD", durationMs: 4000, from: 0, to: 0 }
    ]
  },
  {
    id: "resonant",
    name: "Resonant Breathing",
    shortName: "Resonant",
    summary: "A slow, balanced breathing rhythm.",
    cadence: "IN 5.5  /  OUT 5.5",
    phases: [
      { kind: "inhale", label: "BREATHE IN", durationMs: 5500, from: 0, to: 1 },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 5500, from: 1, to: 0 }
    ]
  },
  {
    id: "478",
    name: "4-7-8 Breathing",
    shortName: "4-7-8",
    summary: "A longer hold followed by a slow exhale.",
    cadence: "IN 4  /  HOLD 7  /  OUT 8",
    phases: [
      { kind: "inhale", label: "BREATHE IN", durationMs: 4000, from: 0, to: 1 },
      { kind: "holdFull", label: "HOLD", durationMs: 7000, from: 1, to: 1 },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 8000, from: 1, to: 0 }
    ]
  },
  {
    id: "box-sleep",
    name: "Box Breathing for Sleep",
    shortName: "Box Sleep",
    summary: "A box cadence with a longer exhale.",
    cadence: "IN 4  /  HOLD 4  /  OUT 6  /  HOLD 2",
    phases: [
      { kind: "inhale", label: "BREATHE IN", durationMs: 4000, from: 0, to: 1 },
      { kind: "holdFull", label: "HOLD", durationMs: 4000, from: 1, to: 1 },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 6000, from: 1, to: 0 },
      { kind: "holdEmpty", label: "HOLD", durationMs: 2000, from: 0, to: 0 }
    ]
  },
  {
    id: "coordinated",
    name: "Coordinated Breathing",
    shortName: "Coordinated",
    summary: "A gentle inhale followed by a counted exhale.",
    cadence: "IN 4  /  OUT 20",
    phases: [
      { kind: "inhale", label: "BREATHE IN", durationMs: 4000, from: 0, to: 1 },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 20000, from: 1, to: 0, counted: true }
    ]
  },
  {
    id: "nadi-shodhana",
    name: "Nadi Shodhana",
    shortName: "Nadi",
    summary: "Alternate the left and right nostrils.",
    cadence: "IN 4  /  HOLD 4  /  OUT 4  /  HOLD 4  /  REVERSE",
    phases: [
      { kind: "inhale", label: "BREATHE IN", durationMs: 4000, from: 0, to: 1, side: "LEFT" },
      { kind: "holdFull", label: "HOLD", durationMs: 4000, from: 1, to: 1, side: "BOTH" },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 4000, from: 1, to: 0, side: "RIGHT" },
      { kind: "holdEmpty", label: "HOLD", durationMs: 4000, from: 0, to: 0, side: "BOTH" },
      { kind: "inhale", label: "BREATHE IN", durationMs: 4000, from: 0, to: 1, side: "RIGHT" },
      { kind: "holdFull", label: "HOLD", durationMs: 4000, from: 1, to: 1, side: "BOTH" },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 4000, from: 1, to: 0, side: "LEFT" },
      { kind: "holdEmpty", label: "HOLD", durationMs: 4000, from: 0, to: 0, side: "BOTH" }
    ]
  },
  {
    id: "yogic",
    name: "Yogic Breathing",
    shortName: "Yogic",
    summary: "Guide one fluid breath through three stages.",
    cadence: "BELLY 2  /  MID 2  /  CHEST 2  /  REVERSE",
    phases: [
      { kind: "inhale", label: "BREATHE IN", durationMs: 2000, from: 0, to: 1 / 3, stage: "BELLY" },
      { kind: "inhale", label: "BREATHE IN", durationMs: 2000, from: 1 / 3, to: 2 / 3, stage: "MID-TORSO" },
      { kind: "inhale", label: "BREATHE IN", durationMs: 2000, from: 2 / 3, to: 1, stage: "UPPER CHEST" },
      { kind: "holdFull", label: "SETTLE", durationMs: 500, from: 1, to: 1, stage: "FULL" },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 2000, from: 1, to: 2 / 3, stage: "UPPER CHEST" },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 2000, from: 2 / 3, to: 1 / 3, stage: "MID-TORSO" },
      { kind: "exhale", label: "BREATHE OUT", durationMs: 2000, from: 1 / 3, to: 0, stage: "BELLY" },
      { kind: "holdEmpty", label: "SETTLE", durationMs: 500, from: 0, to: 0, stage: "EMPTY" }
    ]
  }
]

function clamp(value, low, high) {
  return Math.max(low, Math.min(high, value))
}

function normalizedKey(value) {
  return String(value || "").trim().toLowerCase()
    .replace(/[()]/g, "")
    .replace(/\s+/g, "-")
}

function technique(value) {
  var key = normalizedKey(value)
  if (key === "box-breathing-sleep") key = "box-sleep"
  for (var i = 0; i < techniques.length; i++) {
    var item = techniques[i]
    if (key === normalizedKey(item.id) || key === normalizedKey(item.name)
        || key === normalizedKey(item.shortName)) return item
  }
  return techniques[0]
}

function techniqueNames() {
  var result = []
  for (var i = 0; i < techniques.length; i++) result.push(techniques[i].name)
  return result
}

function cycleDurationMs(value) {
  var item = technique(value)
  var total = 0
  for (var i = 0; i < item.phases.length; i++) total += item.phases[i].durationMs
  return total
}

function easedProgress(progress) {
  var t = clamp(Number(progress) || 0, 0, 1)
  return 0.5 - Math.cos(Math.PI * t) / 2
}

function phaseAt(value, elapsedMs) {
  var item = technique(value)
  var cycleMs = cycleDurationMs(item.id)
  var elapsed = Math.max(0, Number(elapsedMs) || 0)
  var cycleIndex = Math.floor(elapsed / cycleMs)
  var cycleElapsedMs = elapsed % cycleMs
  var phaseStartMs = 0
  var selected = item.phases[0]
  var phaseIndex = 0

  for (var i = 0; i < item.phases.length; i++) {
    var end = phaseStartMs + item.phases[i].durationMs
    if (cycleElapsedMs < end) {
      selected = item.phases[i]
      phaseIndex = i
      break
    }
    phaseStartMs = end
  }

  var phaseElapsedMs = cycleElapsedMs - phaseStartMs
  var progress = selected.durationMs > 0 ? phaseElapsedMs / selected.durationMs : 1
  var eased = easedProgress(progress)
  var level = selected.from + (selected.to - selected.from) * eased
  var guidance = selected.stage || selected.side || ""
  var count = selected.counted ? (Math.floor(phaseElapsedMs / 1000) % 10) + 1 : 0

  return {
    techniqueId: item.id,
    techniqueName: item.name,
    phaseIndex: phaseIndex,
    phaseKind: selected.kind,
    phaseLabel: selected.label,
    phaseElapsedMs: phaseElapsedMs,
    phaseRemainingMs: Math.max(0, selected.durationMs - phaseElapsedMs),
    phaseProgress: clamp(progress, 0, 1),
    breathLevel: clamp(level, 0, 1),
    guidance: guidance,
    count: count,
    cycleIndex: cycleIndex,
    cycleElapsedMs: cycleElapsedMs,
    cycleDurationMs: cycleMs
  }
}

function normalizedDurationMinutes(value) {
  var duration = Math.round(Number(value) || 1)
  return clamp(duration, 1, 5)
}

function completionDurationMs(value, durationMinutes) {
  var cycleMs = cycleDurationMs(value)
  var targetMs = normalizedDurationMinutes(durationMinutes) * 60000
  return Math.ceil(targetMs / cycleMs) * cycleMs
}

function sessionProgress(elapsedMs, completionMs) {
  var total = Math.max(1, Number(completionMs) || 1)
  return clamp((Number(elapsedMs) || 0) / total, 0, 1)
}

function formatClock(ms) {
  var seconds = Math.max(0, Math.ceil((Number(ms) || 0) / 1000))
  var minutes = Math.floor(seconds / 60)
  var remainder = seconds % 60
  return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
}
