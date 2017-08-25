require 'factory_girl'
require 'yaml'
require 'job'

FactoryGirl.define do

	factory :job do
		name "awesome_job"
		initialize_with {new(attributes)}
	end

end
