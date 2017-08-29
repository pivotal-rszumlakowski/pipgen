require 'job'

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

	def library(library)
		raise "Nil job library" if library.nil?
		raise "Empty job library" if library.empty?
		raise "Job library must be an array" unless library.is_a? Array
		@library = library
	end

	def initialize
		@jobs = nil
		@library = nil
	end

	def make
		raise "Empty pipeline definition" if @jobs.nil? and @library.nil?
		raise "Empty job list" if @jobs.nil? or @jobs.empty? and not @library.nil?
		raise "Empty job library" if @library.nil? or @library.empty? and not @jobs.nil?

		raise ("Missing job: " + @jobs[0].name) if @jobs[0].name == @library[0].name
		#@jobs.each do |j|
		#	raise ("Missing job: " + p.name) unless @library[0].name == j.name
		#end
		
		return self
	end
end
