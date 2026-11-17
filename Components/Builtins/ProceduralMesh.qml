import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A mesh built from vertex arrays declared in Ruby: positions, normals,
// tangents, UVs, colours, joints and weights, with an index array and a
// primitive mode. Subsets declared inside it split the mesh so each part
// can take its own material.
ProceduralMesh {
    id: proceduralMesh

    required property var renderer

    subsets: renderer.childObjectsAndReferences(["procedural_mesh_subset"], "subsets")

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "positions"
        property: "positions"
        value: Value3d.vector3d(proceduralMesh.renderer.prop("positions"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "normals"
        property: "normals"
        value: Value3d.vector3d(proceduralMesh.renderer.prop("normals"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "tangents"
        property: "tangents"
        value: Value3d.vector3d(proceduralMesh.renderer.prop("tangents"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "binormals"
        property: "binormals"
        value: Value3d.vector3d(proceduralMesh.renderer.prop("binormals"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "uv0s"
        property: "uv0s"
        value: Value3d.vector2d(proceduralMesh.renderer.prop("uv0s"), 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "uv1s"
        property: "uv1s"
        value: Value3d.vector2d(proceduralMesh.renderer.prop("uv1s"), 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "colors"
        property: "colors"
        value: Value3d.vector4d(proceduralMesh.renderer.prop("colors"), 0, 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "joints"
        property: "joints"
        value: Value3d.vector4d(proceduralMesh.renderer.prop("joints"), 0, 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "weights"
        property: "weights"
        value: Value3d.vector4d(proceduralMesh.renderer.prop("weights"), 0, 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "indexes"
        property: "indexes"
        value: Number(proceduralMesh.renderer.prop("indexes"))
    }

    Support.Prop3dBinding {
        renderer: proceduralMesh.renderer
        target: proceduralMesh
        name: "primitive_mode"
        property: "primitiveMode"
        value: Value3d.enumeration(proceduralMesh.renderer.prop("primitive_mode"), {
            "points": ProceduralMesh.Points,
            "line_strip": ProceduralMesh.LineStrip,
            "lines": ProceduralMesh.Lines,
            "triangle_strip": ProceduralMesh.TriangleStrip,
            "triangle_fan": ProceduralMesh.TriangleFan,
            "triangles": ProceduralMesh.Triangles
        }, ProceduralMesh.Points)
    }
}
