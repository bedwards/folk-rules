# 02_four_on_floor.rb — classic 4/4 drum pattern.
# Kick on 1 & 3, snare on 2 & 4, closed hats on every eighth.
require "folk_rules"

FolkRules.song "02_four_on_floor" do
  context_set key: :c, scale: :major, beats_per_bar: 4

  bus :drums, to: "folk_drums"

  drums :kit, bus: :drums, channel: 9 do
    kick "x...x...x...x..."
    snare "....x.......x..."
    hat_closed "x.x.x.x.x.x.x.x."
  end
end
