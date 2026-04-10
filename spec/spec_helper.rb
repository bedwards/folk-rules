$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "folk_rules"

RSpec.configure do |c|
  c.filter_run_excluding iac: true unless ENV["FOLK_RULES_IAC"] == "1"
  c.expect_with(:rspec) { |e| e.syntax = :expect }
end
