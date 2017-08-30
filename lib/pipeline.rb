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

	def add_jobs(jobs)
		raise "Nil job list" if jobs.nil?
		raise "Job list must be an array of Job objects" unless jobs.is_a? Array
		raise "Job list must be an array of Job objects" if jobs.any? {|j| not j.is_a? Job}
		@jobs ||= []
		@jobs.concat jobs
	end

	def library(library)
		raise "Nil job library" if library.nil?
		raise "Empty job library" if library.empty?
		raise "Job library must be an array of Job objects" unless library.is_a? Array
		raise "Job library must be an array of Job objects" if library.any? {|j| not j.is_a? Job}
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

		# Verify that each job can be found in the job library
		@jobs.each do |j|
			raise "Missing job: " + j.name unless @library.any?{ |i| i.name == j.name }
		end
		
		return self
	end
end
