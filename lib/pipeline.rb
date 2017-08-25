require 'job'

class Pipeline

	attr_reader :pipeline_definition
	attr_reader :job_library

	def initialize(pipeline_definition, job_library)
		raise "Empty pipeline definition" if pipeline_definition.nil? or pipeline_definition.empty?
		raise "Empty job library" if job_library.nil? or job_library.empty?

		@pipeline_definition = pipeline_definition
		@job_library = job_library
	end

	def build
		@pipeline_definition.each do |p|
			raise ("Missing job: " + p) unless @job_library[0].name == p
		end
		
	end
end
