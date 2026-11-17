# Habitat One

A smart-home energy twin written entirely in Ruby. Its image-backed living room is a real reactive
simulation: toggle its lights, drag the dimmer, or select Morning, Focus, Away, and Night scenes and
the room's brightness, saturation, wattage, scene status, and whole-home load all change together.
It also exercises live solar/battery/load gauges, room automation, stacked energy charts, comfort
heatmaps, scheduled balancing, security state, and an energy-report dialog.

```bash
bundle install
bundle exec zui run main.rb
bundle exec zui bundle --full
```

Smart Home remains an application project rather than a gem. Its Gemfile locks the local Zui gem as
the only project dependency. A full bundle keeps the application sources and assets separate, installs
only the runtime-pruned Zui gem into private CRuby, and packages the native host and tree-shaken QML
framework without duplicate sources.
