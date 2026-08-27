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

Smart Home is a local application gem that depends on the local Zui gem. A full bundle installs the
locked `smart-home-energy` gem into its private CRuby runtime while Zui itself is supplied by the
packaged framework load path.
