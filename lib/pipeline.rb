require 'job'
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

		@dag = []
		build_dag @jobs, @library, @dag # TODO move the dag into its own class
		assign_dependencies @dag

		raise "Found a circular dependency!" if has_cycle? @dag

		@job_order = determine_job_order @dag

		return self
	end

	private

	# TODO - move into its own class
	class DagNode

		attr_reader :name, :job, :depends_on, :is_dependency_for

		def initialize(j)
			raise "Must provide a job!" unless j.is_a? Job
			@job = j
			@name = j.name
			@depends_on = []
			@is_dependency_for = []
		end

		def add_dependency(dependency)
			@depends_on << dependency
		end

		def add_is_dependency_for(dependency)
			@is_dependency_for << dependency
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
			
			dag_node = DagNode.new(resolved_job)

			resolved_job.depends_on.each do |dependency|

				raise "Job '#{resolved_job.name}' depends on itself" if dependency == resolved_job.name

				resolved_dependency = resolve_job dependency, library, j
				dag_node.add_dependency resolved_dependency
			end

			dag << dag_node
			
			build_dag(resolved_job.depends_on, library, dag, resolved_job) unless resolved_job.depends_on.empty?
		end
	end

	# Builds all the directed graph edges in the reverse order of the dependencies provides.
	# i.e.: edges will be directed from a job to the jobs that depends on them.
	def assign_dependencies dag
		dag.each do |dag_node|
			dag_node.depends_on.each do |dependent_job|
				dependent_dag_node = dag.find{ |d| d.name == dependent_job.name }
				raise "Could not find node with name '#{dependent_job.name}' in dag!" if dependent_dag_node.nil?
				dependent_dag_node.add_is_dependency_for dag_node
			end
		end
	end

	def print_dag dag
		dag.each do |dag_node|
			dag_node.is_dependency_for.each do |d|
				puts "'#{dag_node.name}' --> '#{d.name}'"
			end
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

	def has_cycle? dag

		# Using example code here: http://www.geeksforgeeks.org/detect-cycle-in-a-graph/

		# Initializes the 'visited' and 'rec_stack' lists to false for each node
		visited = Hash[ dag.collect {|dag_node| [dag_node.name, false]} ]
		rec_stack = Hash[ dag.collect {|dag_node| [dag_node.name, false]} ]

		dag.any?{ |dag_node| is_cyclic_util(dag_node, visited, rec_stack) }
	end

	def is_cyclic_util dag_node, visited, rec_stack
		unless visited[dag_node.name]
			visited[dag_node.name] = true
			rec_stack[dag_node.name] = true

			return true if dag_node.is_dependency_for.any? do |d|
				return true if !visited[d.name] && is_cyclic_util(d, visited, rec_stack)
				rec_stack[d.name]
			end

		end
		rec_stack[dag_node.name] = false
		return false
	end

	def determine_job_order dag

		# TODO - use the external `tsort` program to topographically sort the graph nodes

		dag.collect{ |d| d.name }
	end
end
