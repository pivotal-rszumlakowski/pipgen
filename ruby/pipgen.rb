require 'yaml'
require 'erb'
require 'job'

FILENAME = "data/bbr.yml.erb"
VARIABLES = { "opsmanager_glob" => "butts" }

def binding_with(hash)
	b = binding()
	hash.each_pair{ |k, v| b.local_variable_set(k, v) }
	return b
end

erb = ERB.new(File.read(FILENAME))
yml = erb.result(binding_with(VARIABLES))
jobs = YAML.load(yml)

puts "Loaded jobs:"
jobs["jobs"].each{ |j| 
	job = Job.new(j)
	if job.plan_gets.empty?
	    puts "  #{job.name}"
	else
	    puts "  #{job.name}: \t#{job.depends_on}"
	end
}
