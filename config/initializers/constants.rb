FantasyScoringType = Struct.new(:name) do
  def self.standard
    new(:standard)
  end

  def self.ppr
    new(:ppr)
  end

  def self.half_ppr
    new(:half_ppr)
  end
end
