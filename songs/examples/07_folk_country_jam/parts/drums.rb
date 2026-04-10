# Drums: driving country beat with fills every 4 bars.
# Kick on 1+3, snare on 2+4, hats on eighth notes, tambourine accent.
FOLK_JAM_DRUMS = proc do
  drums :kit, bus: :drums, channel: 9 do
    kick "x...x...x...x..."
    snare "....x.......x..."
    hat_closed "x.x.x.x.x.x.x.x."
    tambourine "..x...x...x...x."
  end
end
