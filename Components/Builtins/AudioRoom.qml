import QtQuick
import QtQuick3D.SpatialAudio
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A box of space with an acoustic material on each wall, so reflections
// and reverberation match what the room is built of.
AudioRoom {
    id: audioRoom

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: audioRoom
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "position"
        property: "position"
        value: Value3d.vector3d(audioRoom.renderer.prop("position"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "dimensions"
        property: "dimensions"
        value: Value3d.vector3d(audioRoom.renderer.prop("dimensions"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "rotation"
        property: "rotation"
        value: Value3d.quaternion(audioRoom.renderer.prop("rotation"))
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "left_material"
        property: "leftMaterial"
        value: Value3d.enumeration(audioRoom.renderer.prop("left_material"), {
            "transparent": AudioRoom.Transparent,
            "acoustic_ceiling_tiles": AudioRoom.AcousticCeilingTiles,
            "brick_bare": AudioRoom.BrickBare,
            "brick_painted": AudioRoom.BrickPainted,
            "concrete_block_coarse": AudioRoom.ConcreteBlockCoarse,
            "concrete_block_painted": AudioRoom.ConcreteBlockPainted,
            "curtain_heavy": AudioRoom.CurtainHeavy,
            "fiber_glass_insulation": AudioRoom.FiberGlassInsulation,
            "glass_thin": AudioRoom.GlassThin,
            "glass_thick": AudioRoom.GlassThick,
            "grass": AudioRoom.Grass,
            "linoleum_on_concrete": AudioRoom.LinoleumOnConcrete,
            "marble": AudioRoom.Marble,
            "metal": AudioRoom.Metal,
            "parquet_on_concrete": AudioRoom.ParquetOnConcrete,
            "plaster_rough": AudioRoom.PlasterRough,
            "plaster_smooth": AudioRoom.PlasterSmooth,
            "plywood_panel": AudioRoom.PlywoodPanel,
            "polished_concrete_or_tile": AudioRoom.PolishedConcreteOrTile,
            "sheetrock": AudioRoom.Sheetrock,
            "water_or_ice_surface": AudioRoom.WaterOrIceSurface,
            "wood_ceiling": AudioRoom.WoodCeiling,
            "wood_panel": AudioRoom.WoodPanel,
            "uniform": AudioRoom.Uniform
        }, AudioRoom.Transparent)
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "right_material"
        property: "rightMaterial"
        value: Value3d.enumeration(audioRoom.renderer.prop("right_material"), {
            "transparent": AudioRoom.Transparent,
            "acoustic_ceiling_tiles": AudioRoom.AcousticCeilingTiles,
            "brick_bare": AudioRoom.BrickBare,
            "brick_painted": AudioRoom.BrickPainted,
            "concrete_block_coarse": AudioRoom.ConcreteBlockCoarse,
            "concrete_block_painted": AudioRoom.ConcreteBlockPainted,
            "curtain_heavy": AudioRoom.CurtainHeavy,
            "fiber_glass_insulation": AudioRoom.FiberGlassInsulation,
            "glass_thin": AudioRoom.GlassThin,
            "glass_thick": AudioRoom.GlassThick,
            "grass": AudioRoom.Grass,
            "linoleum_on_concrete": AudioRoom.LinoleumOnConcrete,
            "marble": AudioRoom.Marble,
            "metal": AudioRoom.Metal,
            "parquet_on_concrete": AudioRoom.ParquetOnConcrete,
            "plaster_rough": AudioRoom.PlasterRough,
            "plaster_smooth": AudioRoom.PlasterSmooth,
            "plywood_panel": AudioRoom.PlywoodPanel,
            "polished_concrete_or_tile": AudioRoom.PolishedConcreteOrTile,
            "sheetrock": AudioRoom.Sheetrock,
            "water_or_ice_surface": AudioRoom.WaterOrIceSurface,
            "wood_ceiling": AudioRoom.WoodCeiling,
            "wood_panel": AudioRoom.WoodPanel,
            "uniform": AudioRoom.Uniform
        }, AudioRoom.Transparent)
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "front_material"
        property: "frontMaterial"
        value: Value3d.enumeration(audioRoom.renderer.prop("front_material"), {
            "transparent": AudioRoom.Transparent,
            "acoustic_ceiling_tiles": AudioRoom.AcousticCeilingTiles,
            "brick_bare": AudioRoom.BrickBare,
            "brick_painted": AudioRoom.BrickPainted,
            "concrete_block_coarse": AudioRoom.ConcreteBlockCoarse,
            "concrete_block_painted": AudioRoom.ConcreteBlockPainted,
            "curtain_heavy": AudioRoom.CurtainHeavy,
            "fiber_glass_insulation": AudioRoom.FiberGlassInsulation,
            "glass_thin": AudioRoom.GlassThin,
            "glass_thick": AudioRoom.GlassThick,
            "grass": AudioRoom.Grass,
            "linoleum_on_concrete": AudioRoom.LinoleumOnConcrete,
            "marble": AudioRoom.Marble,
            "metal": AudioRoom.Metal,
            "parquet_on_concrete": AudioRoom.ParquetOnConcrete,
            "plaster_rough": AudioRoom.PlasterRough,
            "plaster_smooth": AudioRoom.PlasterSmooth,
            "plywood_panel": AudioRoom.PlywoodPanel,
            "polished_concrete_or_tile": AudioRoom.PolishedConcreteOrTile,
            "sheetrock": AudioRoom.Sheetrock,
            "water_or_ice_surface": AudioRoom.WaterOrIceSurface,
            "wood_ceiling": AudioRoom.WoodCeiling,
            "wood_panel": AudioRoom.WoodPanel,
            "uniform": AudioRoom.Uniform
        }, AudioRoom.Transparent)
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "back_material"
        property: "backMaterial"
        value: Value3d.enumeration(audioRoom.renderer.prop("back_material"), {
            "transparent": AudioRoom.Transparent,
            "acoustic_ceiling_tiles": AudioRoom.AcousticCeilingTiles,
            "brick_bare": AudioRoom.BrickBare,
            "brick_painted": AudioRoom.BrickPainted,
            "concrete_block_coarse": AudioRoom.ConcreteBlockCoarse,
            "concrete_block_painted": AudioRoom.ConcreteBlockPainted,
            "curtain_heavy": AudioRoom.CurtainHeavy,
            "fiber_glass_insulation": AudioRoom.FiberGlassInsulation,
            "glass_thin": AudioRoom.GlassThin,
            "glass_thick": AudioRoom.GlassThick,
            "grass": AudioRoom.Grass,
            "linoleum_on_concrete": AudioRoom.LinoleumOnConcrete,
            "marble": AudioRoom.Marble,
            "metal": AudioRoom.Metal,
            "parquet_on_concrete": AudioRoom.ParquetOnConcrete,
            "plaster_rough": AudioRoom.PlasterRough,
            "plaster_smooth": AudioRoom.PlasterSmooth,
            "plywood_panel": AudioRoom.PlywoodPanel,
            "polished_concrete_or_tile": AudioRoom.PolishedConcreteOrTile,
            "sheetrock": AudioRoom.Sheetrock,
            "water_or_ice_surface": AudioRoom.WaterOrIceSurface,
            "wood_ceiling": AudioRoom.WoodCeiling,
            "wood_panel": AudioRoom.WoodPanel,
            "uniform": AudioRoom.Uniform
        }, AudioRoom.Transparent)
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "floor_material"
        property: "floorMaterial"
        value: Value3d.enumeration(audioRoom.renderer.prop("floor_material"), {
            "transparent": AudioRoom.Transparent,
            "acoustic_ceiling_tiles": AudioRoom.AcousticCeilingTiles,
            "brick_bare": AudioRoom.BrickBare,
            "brick_painted": AudioRoom.BrickPainted,
            "concrete_block_coarse": AudioRoom.ConcreteBlockCoarse,
            "concrete_block_painted": AudioRoom.ConcreteBlockPainted,
            "curtain_heavy": AudioRoom.CurtainHeavy,
            "fiber_glass_insulation": AudioRoom.FiberGlassInsulation,
            "glass_thin": AudioRoom.GlassThin,
            "glass_thick": AudioRoom.GlassThick,
            "grass": AudioRoom.Grass,
            "linoleum_on_concrete": AudioRoom.LinoleumOnConcrete,
            "marble": AudioRoom.Marble,
            "metal": AudioRoom.Metal,
            "parquet_on_concrete": AudioRoom.ParquetOnConcrete,
            "plaster_rough": AudioRoom.PlasterRough,
            "plaster_smooth": AudioRoom.PlasterSmooth,
            "plywood_panel": AudioRoom.PlywoodPanel,
            "polished_concrete_or_tile": AudioRoom.PolishedConcreteOrTile,
            "sheetrock": AudioRoom.Sheetrock,
            "water_or_ice_surface": AudioRoom.WaterOrIceSurface,
            "wood_ceiling": AudioRoom.WoodCeiling,
            "wood_panel": AudioRoom.WoodPanel,
            "uniform": AudioRoom.Uniform
        }, AudioRoom.Transparent)
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "ceiling_material"
        property: "ceilingMaterial"
        value: Value3d.enumeration(audioRoom.renderer.prop("ceiling_material"), {
            "transparent": AudioRoom.Transparent,
            "acoustic_ceiling_tiles": AudioRoom.AcousticCeilingTiles,
            "brick_bare": AudioRoom.BrickBare,
            "brick_painted": AudioRoom.BrickPainted,
            "concrete_block_coarse": AudioRoom.ConcreteBlockCoarse,
            "concrete_block_painted": AudioRoom.ConcreteBlockPainted,
            "curtain_heavy": AudioRoom.CurtainHeavy,
            "fiber_glass_insulation": AudioRoom.FiberGlassInsulation,
            "glass_thin": AudioRoom.GlassThin,
            "glass_thick": AudioRoom.GlassThick,
            "grass": AudioRoom.Grass,
            "linoleum_on_concrete": AudioRoom.LinoleumOnConcrete,
            "marble": AudioRoom.Marble,
            "metal": AudioRoom.Metal,
            "parquet_on_concrete": AudioRoom.ParquetOnConcrete,
            "plaster_rough": AudioRoom.PlasterRough,
            "plaster_smooth": AudioRoom.PlasterSmooth,
            "plywood_panel": AudioRoom.PlywoodPanel,
            "polished_concrete_or_tile": AudioRoom.PolishedConcreteOrTile,
            "sheetrock": AudioRoom.Sheetrock,
            "water_or_ice_surface": AudioRoom.WaterOrIceSurface,
            "wood_ceiling": AudioRoom.WoodCeiling,
            "wood_panel": AudioRoom.WoodPanel,
            "uniform": AudioRoom.Uniform
        }, AudioRoom.Transparent)
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "reflection_gain"
        property: "reflectionGain"
        value: Number(audioRoom.renderer.prop("reflection_gain"))
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "reverb_gain"
        property: "reverbGain"
        value: Number(audioRoom.renderer.prop("reverb_gain"))
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "reverb_time"
        property: "reverbTime"
        value: Number(audioRoom.renderer.prop("reverb_time"))
    }

    Support.Prop3dBinding {
        renderer: audioRoom.renderer
        target: audioRoom
        name: "reverb_brightness"
        property: "reverbBrightness"
        value: Number(audioRoom.renderer.prop("reverb_brightness"))
    }
}
