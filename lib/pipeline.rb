require 'job'
require 'pry'

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

		@dag = []
		build_dag @jobs, @library, @dag

		@dag.uniq! { |job| job.name }

		@job_order = determine_job_order @dag

		return self
	end

	private

	class DagNode

		attr_reader :name, :job, :depends_on

		def initialize(j)
			raise "Must provide a job!" unless j.is_a? Job
			@job = j
			@name = j.name
			@depends_on = []
		end

		def add_dependency(name_of_dependency)
			# TODO - verify that these dependencies get added. perhaps at the same time we build the graph edges?
			@depends_on << name_of_dependency
		end

		def to_s
			@name
		end

		def self.list_to_s(nodes)
			"[" + nodes.map{ |n| n.name }.join(", ") + "]"
		end
	end

	def build_dag(jobs, library, dag, dependent_job = nil)
		
		jobs.each do |j|

			resolved_job = resolve_job j, library, dependent_job

			next if dag.any? { |d| d.name == resolved_job.name } # Don't add duplicate nodes
			
			dag << DagNode.new(resolved_job)

			build_dag(resolved_job.depends_on, library, dag, resolved_job) unless resolved_job.depends_on.empty?
		end
	end

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

	def determine_job_order dag

		# TODO - make sure the dag has no cycles
		# TODO - use the external `tsort` program to topographically sort the graph nodes

		result = []
		dag.each do |j|
			result << j.name
		end
		return result
	end
end
