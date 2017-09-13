class Dag

	include Enumerable

	class Node

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

	def initialize
		@nodes = []
	end

	def each(&block) # Implements Enumerable
		@nodes.each(&block)
	end

	def <<(node)
		@nodes << node
	end

	def print
		@nodes.each do |node|
			node.is_dependency_for.each do |d|
				puts "'#{node.name}' --> '#{d.name}'"
			end
		end
	end

	# Builds all the directed graph edges in the reverse order of the dependencies provides.
	# i.e.: edges will be directed from a job to the jobs that depends on them.
	def assign_dependencies
		@nodes.each do |node|
			node.depends_on.each do |dependent_job|
				dependent_node = @nodes.find{ |d| d.name == dependent_job.name }
				raise "Could not find node with name '#{dependent_job.name}' in dag!" if dependent_node.nil?
				dependent_node.add_is_dependency_for node
			end
		end
	end

	def has_cycle?

		# Using example code here: http://www.geeksforgeeks.org/detect-cycle-in-a-graph/

		# Initializes the 'visited' and 'rec_stack' lists to false for each node
		visited = Hash[ @nodes.collect {|node| [node.name, false]} ]
		rec_stack = Hash[ @nodes.collect {|node| [node.name, false]} ]

		@nodes.any?{ |node| is_cyclic_util(node, visited, rec_stack) }
	end

	def topological_sort

		# TODO - use the external `tsort` program to topographically sort the graph nodes

		@nodes.collect{ |node| node.name }
	end

	private

	def is_cyclic_util node, visited, rec_stack
		unless visited[node.name]
			visited[node.name] = true
			rec_stack[node.name] = true

			return true if node.is_dependency_for.any? do |d|
				return true if !visited[d.name] && is_cyclic_util(d, visited, rec_stack)
				rec_stack[d.name]
			end

		end
		rec_stack[node.name] = false
		return false
	end
end

