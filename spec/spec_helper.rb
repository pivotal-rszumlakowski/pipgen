require 'yaml'
require 'rspec'

RSpec.configure do |c|
  # filter_run is short-form alias for filter_run_including
  #c.filter_run :focus => true

  Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}
end

EMPTY_JOB = {}

def mkget(name, *passed_job_names)
	hash = {"get" => name}
	hash["passed"] = passed_job_names unless passed_job_names.nil? or passed_job_names.empty?
	return hash
end

def mkput(name)
	{"put" => name}
end

def mkaggregate(*gets)
	{"aggregate" => gets}
end

def mkjob(name = "my_job_name", *items)
	hash = {"name" => name}
	hash["plan"] = items unless items.nil? or items.empty?
	Job.new(hash)
end
