-- Gameplay units:
-- Distance: metre
-- Mass: kilogram
-- Time: second
-- Luminous flux: lumen

-- Celestial units:
-- Distance: megametre
-- Mass: ronnagram
-- Time: second
-- Luminous flux: lumen
-- Radiant flux: watt

local units = {}

-- Conversions between celestial and gameplay unit systems

units.metresPerMegametre = 1e6
units.megametresPerMetre = 1e-6

-- Ronna exponent is 27, kilo is 3, 27-3=24
units.kilogramsPerRonnagram = 1e24
units.ronnagramsPerKilogram = 1e-24

return units
