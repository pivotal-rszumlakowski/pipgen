require 'spec_helper'
require 'support/factory_girl'
require 'pipeline'

describe Pipeline do
	describe "simple initialization" do
		context "given an nil pipeline definition" do
			it "raises an error" do
				expect { Pipeline.define {} }.to raise_error "Empty pipeline definition"
			end
		end
	end

	describe "library method" do
		context "given nil job library" do
			it "raises an error" do
				expect { Pipeline.define{ library nil }}.to raise_error "Nil job library"
			end
		end

		context "given a non-array job library" do
			it "raises an error" do
				expect { Pipeline.define{ library "NOT AN ARRAY" }}.to raise_error "Job library must be an array of Job objects"
			end
		end

		context "given empty job library" do
			it "raises an error" do
				expect { Pipeline.define{ library [] }}.to raise_error "Empty job library"
			end
		end

		context "given an array with a non-Job object" do
			it "raises an error" do
				job1 = build(:job, name: "job1")
				job2 = build(:job, name: "job2")
				expect { Pipeline.define{ library [job1, "NOT A JOB", job2] }}.to raise_error "Job library must be an array of Job objects"
			end
		end
	end

	describe "add_job method" do
		context "given no job library" do
			it "raises an error" do
				job = build :job
				expect { Pipeline.define{ add_job job }}.to raise_error "Empty job library"
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
	end

	describe "add_jobs method" do
		context "given nil" do
			it "raises an error" do
				expect { Pipeline.define{ add_jobs nil }}.to  raise_error "Nil job list"
			end
		end

		context "given a non-array job list" do
			it "raises an error" do
				expect { Pipeline.define{ add_jobs "NOT AN ARRAY" }}.to raise_error "Job list must be an array of Job objects"
			end
		end

		context "given an array with non-Job objects" do
			it "raises an error" do
				job1 = build(:job, name: "job1")
				job2 = build(:job, name: "job2")
				expect { Pipeline.define{ add_jobs [job1, "NOT A JOB", job2] }}.to raise_error "Job list must be an array of Job objects"
			end
		end
	end

	describe "building simple pipelines" do

		context "given no jobs" do
			it "raises an error" do
				job = build :job
				expect { Pipeline.define{ library [job] }}.to raise_error "Empty job list"
			end
		end

		context "pipeline with one job" do
			it "resolves a pipeline with one job" do
				simple_job = build(:job, name: "simple_job")

				p = Pipeline.define do
					add_job simple_job
					library [simple_job]
				end

				expect(p.job_order).to contain_exactly("simple_job")
			end
		end

		context "pipeline with two jobs and three jobs in its library" do
			it "resolves a pipeline with one job" do
				job1 = build(:job, name: "job1")
				job2 = build(:job, name: "job2")
				job3 = build(:job, name: "job3")

				p = Pipeline.define do
					add_jobs [job1, job2]
					library [job1, job2, job3]
				end

				expect(p.job_order).to contain_exactly("job1", "job2")
			end
		end

		context "pipeline with one job that depends on another job in its library" do
			it "resolves the pipeline of two jobs" do
				job0 = build(:job, name: "job0")
				job1 = Job.new(YAML.load("
---
name: job1
plan:
- get: get0
  passed: [job0]"))

  				p = Pipeline.define do
					add_job job1 # depends on job0
					library [job0, job1]
				end
				
				expect(p.job_order).to contain_exactly("job0", "job1")
			end
		end

		context "pipeline with a job that depends on another job that is missing from its library" do
			it "raises an error" do
				job1 = Job.new(YAML.load("
---
name: job1
plan:
- get: get0
  passed: [job0]"))
  				expect { Pipeline.define do
					add_job job1 # depends on missing job0
					library [job1]
				end }.to raise_error "Job 'job1' depends on missing job: 'job0'"

			end
		end

		context "missing job from job_library" do
			it "raises an error if the pipeline definition requests a non-existent job" do
				missing_job = build(:job, name: "missing_job")
				fancy_job = build(:job, name: "fancy_job")

				expect { Pipeline.define{
					add_job missing_job
					library [fancy_job]
				}}.to raise_error "Missing job: missing_job"
			end
		end

		context "one missing job and one found job" do
			it "raises an error if the pipeline definition requests a non-existent job" do
				mystery_job = build(:job, name: "mystery_job")
				fancy_job =   build(:job, name: "fancy_job")
				awesome_job = build(:job, name: "awesome_job")
				silly_job =   build(:job, name: "silly_job")

				expect { Pipeline.define{
					add_jobs [mystery_job, awesome_job]
					library [fancy_job, awesome_job, silly_job]
				}}.to raise_error "Missing job: mystery_job"
			end
		end
	end
end

