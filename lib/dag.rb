class Dag

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

	attr_reader :nodes

	def initialize
		@nodes = []
	end

	def print
		@nodes.each do |dag_node|
			dag_node.is_dependency_for.each do |d|
				puts "'#{dag_node.name}' --> '#{d.name}'"
			end
		end
	end

	# Builds all the directed graph edges in the reverse order of the dependencies provides.
	# i.e.: edges will be directed from a job to the jobs that depends on them.
	def assign_dependencies
		@nodes.each do |dag_node|
			dag_node.depends_on.each do |dependent_job|
				dependent_dag_node = @nodes.find{ |d| d.name == dependent_job.name }
				raise "Could not find node with name '#{dependent_job.name}' in dag!" if dependent_dag_node.nil?
				dependent_dag_node.add_is_dependency_for dag_node
			end
		end
	end

	def has_cycle?

		# Using example code here: http://www.geeksforgeeks.org/detect-cycle-in-a-graph/

		# Initializes the 'visited' and 'rec_stack' lists to false for each node
		visited = Hash[ @nodes.collect {|dag_node| [dag_node.name, false]} ]
		rec_stack = Hash[ @nodes.collect {|dag_node| [dag_node.name, false]} ]

		@nodes.any?{ |dag_node| is_cyclic_util(dag_node, visited, rec_stack) }
	end

	def topological_sort

		# TODO - use the external `tsort` program to topographically sort the graph nodes

		@nodes.collect{ |node| node.name }
	end

	private

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
end

