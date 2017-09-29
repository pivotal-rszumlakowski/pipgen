class Resource

  attr_reader :name

  def self.from_name name
	  Resource.new "name" => name
  end

  def initialize hash
	@hash = hash
    @name = hash["name"]
  end

  def == other_resource
    other_resource.name == @name
  end
end
