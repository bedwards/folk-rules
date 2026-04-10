# 01_kick.rb — the simplest possible folk-rules song.
# One kick drum on every beat. If this verifies, the framework works.
require "folk_rules"

FolkRules.song "01_kick" do
  bus :drums, to: "folk_drums"

  drums :beat, bus: :drums do
    kick "x...x...x...x..."
  end
end
