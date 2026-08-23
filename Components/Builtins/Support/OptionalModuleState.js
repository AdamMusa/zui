.pragma library

// Optional QML modules are probed lazily. Remember a failed probe so state patches do not
// repeatedly ask the engine to import the same unavailable module.
var quick3dUnavailable = false
