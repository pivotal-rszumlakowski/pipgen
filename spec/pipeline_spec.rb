require 'spec_helper'
require 'support/factory_girl'
require 'pipeline'

describe Pipeline do
	describe ".initialize" do

		context "given an nil pipeline definition" do
			it "raises an error" do
				expect { Pipeline.define {} }.to raise_error "Empty pipeline definition"
			end
		end

		context "given no job library" do
			it "raises an error" do
				job_with_no_plan = build :job_with_no_plan
				expect { Pipeline.define{ add_job job_with_no_plan }}.to raise_error "Empty job library"
			end
		end

		context "given a nil job" do
			it "raises an error" do
				expect { Pipeline.define{ add_job nil } }.to raise_error "Nil job"
			end
		end

		context "given a non-Job object" do
			it "raises an error" do
				expect { Pipeline.define{ add_job "NOT A JOB" }}.to raise_error "Given job not a Job object"
			end
		end

		context "given nil job library" do
			it "raises an error" do
				expect { Pipeline.define{ library nil }}.to raise_error "Nil job library"
			end
		end

		context "given a non-array job library" do
			it "raises an error" do
				expect { Pipeline.define{ library "NOT AN ARRAY" }}.to raise_error "Job library must be an array"
			end
		end

		context "given empty job library" do
			it "raises an error" do
				expect { Pipeline.define{ library [] }}.to raise_error "Empty job library"
			end
		end

		context "given no jobs" do
			it "raises an error" do
				job_with_no_plan = build :job_with_no_plan
				expect { Pipeline.define{ library [job_with_no_plan] }}. to raise_error "Empty job list"
			end
		end
	end

	describe ".build" do
		context "missing jobs from job_library" do
			it "raises an error if the pipeline definition requests a non-existent job" do
				missing_job = build(:job, name: "missing_job")
				fancy_job = build(:job, name: "fancy_job")

				expect { Pipeline.define{
					add_job missing_job
					library [fancy_job]
				}}.to raise_error "Missing job: missing_job"
			end
		end

		context "pipeline with one job" do
			it "resolves a pipeline with one job" do
				simple_job = build(:job, name: "simple_job")

				expect { Pipeline.define{
					add_job simple_job
					library [simple_job]
				}}.not_to raise_error
			end
		end
	end
end

