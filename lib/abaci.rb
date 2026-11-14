module Abaci
  # Read a CSV abaci and returns an Abaci::Table
  def self.read(file)
    Abaci::Table.new(file)
  end
end
