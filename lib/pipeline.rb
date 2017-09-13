require 'job'
require 'dag'
#require 'pry'

class Pipeline

	# DSL start method
	def self.define(&block)
		pipeline_definition = Pipeline.new
		pipeline_definition.instance_eval(&block)
		pipeline_definition.make
	end

	def add_job(job)
		raise "Nil job" if job.nil?
		raise "Given job not a Job object" unless job.is_a? Job
		@jobs ||= []
		@jobs << job
	end

	def add_jobs(*jobs)
		raise "Empty job list" if jobs.nil? or jobs.empty?
		raise "Job list must be an array of Job objects" if jobs.any? {|j| not j.is_a? Job}
		@jobs ||= []
		@jobs.concat jobs
	end

	def library(*library)
		raise "Empty job library" if library.empty?
		raise "Job library must be an array of Job objects" unless library.is_a? Array
		raise "Job library must be an array of Job objects" if library.any? {|j| not j.is_a? Job}

		# Ensure each job in the library has a unique name
		library.each { |job|
			num_instances = library.count { |other_job| job.name == other_job.name }
			raise "Duplicated job in library: '#{job.name}'" if num_instances > 1
		}
		
		@library = library
	end

	attr_reader :job_order

	def initialize
		@jobs = nil
		@library = nil
		@job_order = nil
	end

	def make
		raise "Empty pipeline definition" if @jobs.nil? and @library.nil?
		raise "Empty job list" if @jobs.nil? or @jobs.empty? and not @library.nil?
		raise "Empty job library" if @library.nil? or @library.empty? and not @jobs.nil?

		@dag = Dag.new
		build_dag @jobs, @library, @dag # TODO move the dag into its own class
		@dag.assign_dependencies

		raise "Found a circular dependency!" if @dag.has_cycle?

		@job_order = @dag.topological_sort

		return self
	end

	private

	def build_dag(jobs, library, dag, dependent_job = nil)
		
		jobs.each do |j|

			resolved_job = resolve_job j, library, dependent_job

			next if dag.nodes.any? { |d| d.name == resolved_job.name } # Don't add duplicate nodes
			
			dag_node = Dag::DagNode.new(resolved_job)

			resolved_job.depends_on.each do |dependency|

				raise "Job '#{resolved_job.name}' depends on itself" if dependency == resolved_job.name

				resolved_dependency = resolve_job dependency, library, j
				dag_node.add_dependency resolved_dependency
			end

			dag.nodes << dag_node
			
			build_dag(resolved_job.depends_on, library, dag, resolved_job) unless resolved_job.depends_on.empty?
		end
	end

	# Looks for and returns a job or job name in the library
	def resolve_job(job, library, dependent_job)
		if job.is_a? Job
			resolved_job = @library.find{ |l| l.name == job.name }
			raise "Missing job: " + job.name if resolved_job.nil?
			return resolved_job
		elsif job.is_a? String
			resolved_job = @library.find{ |l| l.name == job }
			raise "Job '#{dependent_job}' depends on missing job: '#{job}'" if resolved_job.nil?
			return resolved_job
		else
			raise "You must provide a Job object or String with a job name to the 'resolve_job' method!"
		end
	end

end
