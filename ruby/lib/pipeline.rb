require 'job'
require 'dag'
require 'resource'
#require 'pry'

class Pipeline

	# DSL start method
	def self.define &block
		pipeline_definition = Pipeline.new
		pipeline_definition.instance_eval &block
		pipeline_definition.make
	end

	def add_job job
		raise "Nil job" if job.nil?
		raise "Given job not a Job object" unless job.is_a? Job
		@jobs ||= []
		@jobs << job
	end

	def add_jobs *jobs
		raise "Empty job list" if jobs.nil? or jobs.empty?
		raise "Job list must be an array of Job objects" if jobs.any? {|j| not j.is_a? Job}
		@jobs ||= []
		@jobs.concat jobs
	end

	def resource_library *resource_library
		@resource_library = resource_library
	end

	def job_library *job_library
		raise "Empty job library" if job_library.empty?
		raise "Job library must be an array of Job objects" unless job_library.is_a? Array
		raise "Job library must be an array of Job objects" if job_library.any? {|j| not j.is_a? Job}

		# Ensure each job in the library has a unique name
		job_library.each { |job|
			num_instances = job_library.count { |other_job| job.name == other_job.name }
			raise "Duplicated job in library: '#{job.name}'" if num_instances > 1
		}
		
		@job_library = job_library
	end

	attr_reader :job_order
	attr_reader :required_resources

	def initialize
		@jobs = nil
		@job_library = nil
		@job_order = nil
		@resource_library = []
		@required_resources = nil
		@dag = Dag.new
	end

	def make
		raise "Empty pipeline definition" if @jobs.nil? and @job_library.nil?
		raise "Empty job list" if @jobs.nil? or @jobs.empty? and not @job_library.nil?
		raise "Empty job library" if @job_library.nil? or @job_library.empty? and not @jobs.nil?

		build_dag @jobs, @job_library, @dag

		@dag.assign_dependencies

		raise "Found a circular dependency!" if @dag.has_cycle?

		@job_order = @dag.topological_sort # TODO - map these Dag::Node objects into Job objects?

		@required_resources = get_required_resources @job_order, @resource_library

		return self
	end

	private

	def build_dag jobs, job_library, dag, dependent_job = nil
		
		jobs.each do |j|

			resolved_job = resolve_job j, job_library, dependent_job

			next if dag.any? { |d| d.name == resolved_job.name } # Don't add duplicate nodes
			
			dag_node = Dag::Node.new resolved_job

			resolved_job.depends_on.each do |dependency|

				raise "Job '#{resolved_job.name}' depends on itself" if dependency == resolved_job.name

				resolved_dependency = resolve_job dependency, job_library, j
				dag_node.add_dependency resolved_dependency
			end

			dag << dag_node
			
			build_dag(resolved_job.depends_on, job_library, dag, resolved_job) unless resolved_job.depends_on.empty?
		end
	end

	# Looks for and returns a job or job name in the job_library
	def resolve_job job, job_library, dependent_job
		if job.is_a? Job
			resolved_job = @job_library.find{ |l| l.name == job.name }
			raise "Missing job: " + job.name if resolved_job.nil?
			return resolved_job
		elsif job.is_a? String
			resolved_job = @job_library.find{ |l| l.name == job }
			raise "Job '#{dependent_job}' depends on missing job: '#{job}'" if resolved_job.nil?
			return resolved_job
		else
			raise "You must provide a Job object or String with a job name to the 'resolve_job' method!"
		end
	end

	# Maps the resources required by each job into the resource definitions in the resource library
	def get_required_resources job_order, resource_library
		required_resources = []
		job_order.each do |node|
			node.job.required_resources.each do |resource|
				library_resource = resource_library.find{ |l| l["name"] == resource.name}
				raise "Missing resource '#{resource.name}' required by job '#{node.job.name}'" if library_resource.nil?
				required_resources << Resource.new(library_resource) unless required_resources.any? {|r| r.name == resource.name}
			end
		end
		required_resources
	end

end
