require_relative "test_helper"
require "folk_rules/doctor"

class TestDoctor < Minitest::Test
  def test_normalize_collapses_nonalnum
    d = FolkRules::Doctor.new
    assert_equal "iac_driver_folk_clock", d.send(:normalize, "IAC Driver folk_clock")
  end

  def test_required_buses_constant
    assert_equal %w[folk_clock folk_drums folk_pitched], FolkRules::Doctor::REQUIRED_BUSES
  end
end
