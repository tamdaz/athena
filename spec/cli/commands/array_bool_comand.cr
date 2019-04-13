require "../cli_spec_helper"

struct ArrayBoolCommand < Athena::Cli::Command
  self.name = "aa:array"
  self.description = "Array of bools"

  def self.execute(bools : Array(Bool)) : Array(Bool)
    bools.should be_a(Array(Bool))
    bools.should eq [true, false, false, true]
    bools
  end
end