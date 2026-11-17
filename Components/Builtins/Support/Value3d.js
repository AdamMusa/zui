.pragma library

// Conversions between the JSON values Ruby sends over the protocol and the Qt
// Quick 3D value types the scene graph expects. Every helper accepts the shapes
// a Ruby author would naturally write: a number, an array, or a hash.

function number(value, fallback) {
    var result = Number(value)
    return isFinite(result) ? result : Number(fallback)
}

function vector3d(value, fallbackX, fallbackY, fallbackZ) {
    if (value === undefined || value === null)
        return Qt.vector3d(Number(fallbackX), Number(fallbackY), Number(fallbackZ))
    if (typeof value === "number")
        return Qt.vector3d(value, value, value)
    if (Array.isArray(value))
        return Qt.vector3d(number(value[0], fallbackX), number(value[1], fallbackY),
                           number(value[2], fallbackZ))
    if (typeof value === "object")
        return Qt.vector3d(number(value.x, fallbackX), number(value.y, fallbackY),
                           number(value.z, fallbackZ))
    return Qt.vector3d(Number(fallbackX), Number(fallbackY), Number(fallbackZ))
}

function vector2d(value, fallbackX, fallbackY) {
    if (value === undefined || value === null)
        return Qt.vector2d(Number(fallbackX), Number(fallbackY))
    if (typeof value === "number")
        return Qt.vector2d(value, value)
    if (Array.isArray(value))
        return Qt.vector2d(number(value[0], fallbackX), number(value[1], fallbackY))
    if (typeof value === "object")
        return Qt.vector2d(number(value.x, fallbackX), number(value.y, fallbackY))
    return Qt.vector2d(Number(fallbackX), Number(fallbackY))
}

function vector4d(value, fallbackX, fallbackY, fallbackZ, fallbackW) {
    if (value === undefined || value === null)
        return Qt.vector4d(Number(fallbackX), Number(fallbackY), Number(fallbackZ), Number(fallbackW))
    if (typeof value === "number")
        return Qt.vector4d(value, value, value, value)
    if (Array.isArray(value))
        return Qt.vector4d(number(value[0], fallbackX), number(value[1], fallbackY),
                           number(value[2], fallbackZ), number(value[3], fallbackW))
    if (typeof value === "object")
        return Qt.vector4d(number(value.x, fallbackX), number(value.y, fallbackY),
                           number(value.z, fallbackZ), number(value.w, fallbackW))
    return Qt.vector4d(Number(fallbackX), Number(fallbackY), Number(fallbackZ), Number(fallbackW))
}

// A bare number is read as a rotation in degrees around the Z axis, an array as
// [scalar, x, y, z], and a hash as either a quaternion or Euler angles.
function quaternion(value) {
    if (typeof value === "number")
        return Qt.quaternion(Math.cos(value * Math.PI / 360), 0, 0, Math.sin(value * Math.PI / 360))
    if (Array.isArray(value)) {
        if (value.length === 3)
            return euler(value[0], value[1], value[2])
        return Qt.quaternion(number(value[0], 1), number(value[1], 0),
                             number(value[2], 0), number(value[3], 0))
    }
    if (value !== null && typeof value === "object") {
        if (value.scalar !== undefined || value.w !== undefined) {
            var scalar = value.scalar === undefined ? value.w : value.scalar
            return Qt.quaternion(number(scalar, 1), number(value.x, 0),
                                 number(value.y, 0), number(value.z, 0))
        }
        return euler(value.x, value.y, value.z)
    }
    return Qt.quaternion(1, 0, 0, 0)
}

function euler(pitch, yaw, roll) {
    return Qt.quaternion(1, 0, 0, 0).times(axisAngle(1, 0, 0, number(pitch, 0)))
        .times(axisAngle(0, 1, 0, number(yaw, 0)))
        .times(axisAngle(0, 0, 1, number(roll, 0)))
}

function axisAngle(x, y, z, degrees) {
    var half = degrees * Math.PI / 360
    var sine = Math.sin(half)
    return Qt.quaternion(Math.cos(half), x * sine, y * sine, z * sine)
}

// Maps a snake_case protocol value onto a Qt enumeration through an explicit
// table. An unknown name resolves to the fallback so a typo cannot silently
// select a different rendering path than the one the table documents.
function enumeration(value, table, fallback) {
    var key = String(value === undefined || value === null ? "" : value)
    return table.hasOwnProperty(key) ? table[key] : fallback
}

// Combines several names from a flag enumeration into one bit mask. A single
// name is accepted as well, so a one-flag value reads naturally.
function flags(value, table, fallback) {
    if (value === undefined || value === null)
        return fallback
    var names = Array.isArray(value) ? value : [value]
    var mask = 0
    var matched = false
    for (var index = 0; index < names.length; index++) {
        var key = String(names[index])
        if (table.hasOwnProperty(key)) {
            mask |= table[key]
            matched = true
        }
    }
    return matched ? mask : fallback
}

function flag(value, fallback) {
    if (value === undefined || value === null)
        return fallback === true
    return value === true
}

function matrix4x4(value) {
    if (Array.isArray(value) && value.length === 16)
        return Qt.matrix4x4(value[0], value[1], value[2], value[3],
                            value[4], value[5], value[6], value[7],
                            value[8], value[9], value[10], value[11],
                            value[12], value[13], value[14], value[15])
    return Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
}

function matrixList(value) {
    if (!Array.isArray(value))
        return []
    var matrices = []
    for (var index = 0; index < value.length; index++)
        matrices.push(matrix4x4(value[index]))
    return matrices
}

// Qt Quick 3D addresses its built-in primitives with a "#Name" mesh source,
// which is neither a file nor a URL and must reach the renderer untouched.
function meshSource(renderer, value) {
    var source = String(value === undefined || value === null ? "" : value)
    if (source === "")
        return ""
    if (source.charAt(0) === "#")
        return source
    return renderer.assetUrl(source)
}

// An instance range bound is a number for a scalar property and a vector for a
// position, scale, rotation or custom-data property. Qt takes whichever the
// property expects, so the shape Ruby wrote decides.
// A Qt easing curve property accepts an object carrying a type, so a protocol
// name maps onto the same curve names the rest of Zui's animations use.
function easing(value) {
    return { "type": easingType(value) }
}

function easingType(value) {
    var curves = {
        "linear": Easing.Linear,
        "in_quad": Easing.InQuad, "out_quad": Easing.OutQuad, "in_out_quad": Easing.InOutQuad,
        "in_cubic": Easing.InCubic, "out_cubic": Easing.OutCubic, "in_out_cubic": Easing.InOutCubic,
        "in_back": Easing.InBack, "out_back": Easing.OutBack, "in_out_back": Easing.InOutBack,
        "in_elastic": Easing.InElastic, "out_elastic": Easing.OutElastic,
        "in_out_elastic": Easing.InOutElastic,
        "in_bounce": Easing.InBounce, "out_bounce": Easing.OutBounce,
        "in_out_bounce": Easing.InOutBounce
    }
    var key = String(value === undefined || value === null ? "" : value)
    return curves.hasOwnProperty(key) ? curves[key] : Easing.InOutQuad
}

// Qt takes a loop count as a plain integer with one reserved value meaning
// "forever". The reserved value differs per type, so the caller passes it in
// and Ruby can write either a count or "infinite".
function loops(value, infinite) {
    if (String(value) === "infinite")
        return infinite
    var count = Number(value)
    return isFinite(count) ? count : infinite
}

function rangeValue(value) {
    if (Array.isArray(value)) {
        if (value.length === 4)
            return vector4d(value, 0, 0, 0, 0)
        if (value.length === 3)
            return vector3d(value, 0, 0, 0)
        if (value.length === 2)
            return vector2d(value, 0, 0)
    }
    return value
}

function assetUrls(renderer, value) {
    var sources = Array.isArray(value) ? value : [value]
    var urls = []
    for (var index = 0; index < sources.length; index++) {
        var url = meshSource(renderer, sources[index])
        if (url !== "")
            urls.push(url)
    }
    return urls
}

function identifiers(value) {
    if (value === undefined || value === null || value === "")
        return []
    var list = Array.isArray(value) ? value : [value]
    var names = []
    for (var index = 0; index < list.length; index++) {
        var name = String(list[index] === null ? "" : list[index])
        if (name !== "")
            names.push(name)
    }
    return names
}
