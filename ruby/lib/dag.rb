require 'open3'
require 'pry'

class Dag

	include Enumerable

	class Node

		attr_reader :name, :job, :depends_on, :is_dependency_for

		def initialize j
			raise "Must provide a job!" unless j.is_a? Job
			@job = j
			@name = j.name
			@depends_on = []
			@is_dependency_for = []
		end

		def add_dependency dependency
			@depends_on << dependency
		end

		def add_is_dependency_for dependency
			@is_dependency_for << dependency
		end

		def to_s
			@name
		end

		def self.list_to_s nodes
			"[" + nodes.map{ |n| n.name }.join(", ") + "]"
		end
	end

	class Edge

		attr_reader :from, :to

		def initialize from, to
			raise "from must be a Node" unless from.is_a? Node
			raise "to must be a Node" unless to.is_a? Node
			@from = from
			@to = to
		end

		def to_s
			"#{from.name}->#{to.name}"
		end

		def self.list_to_s edges
			"[" + edges.map{ |e| e.to_s }.join(", ") + "]"
		end
	end

	def initialize
		@nodes = []
	end

	def each &block # Implements Enumerable
		@nodes.each &block
	end

	def << node
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

		# If there's only one node, then there's no more work to do.
		return [@nodes.first] if @nodes.count == 1

		# First, collect all the nodes that have no dependencies.
		nodes_with_no_dependencies = @nodes.select { |node| node.depends_on.empty? }
		sorted_node_names = nodes_with_no_dependencies.map { |node| node.name }

		# Next, use the external 'tsort' program to do a topographical sort of the remaining nodes
		edges = get_edges @nodes
		Open3.popen2("tsort") do |fin, fout|

			edges.each { |e| fin.puts "#{e.from.name} #{e.to.name}" }
			fin.close

			fout.each_line do |node|
				next if sorted_node_names.include? node.strip # Don't add nodes more than once
				sorted_node_names << node.strip
			end
			fout.close
		end

		#puts "### Read nodes: #{sorted_node_names}"

		return map_nodes(sorted_node_names)
	end

	private

	def map_nodes job_names
		 job_names.map{|job_name| @nodes.find {|n| n.name == job_name}}
	end

	def get_edges nodes
		edges = []
		nodes.each do |node|
			node.is_dependency_for.each do |d|
				edges << Edge.new(node, d)
			end
		end
		edges
	end
	

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

