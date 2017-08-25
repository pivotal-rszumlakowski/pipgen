require 'factory_girl'
require 'yaml'
require 'job'

FactoryGirl.define do

	factory :job, aliases: [:job_with_no_plan] do
		name "my_job_name"
		initialize_with {new(attributes)}
	end

end
