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
		context "given empty job library" do
			it "raises an error" do
				expect { Pipeline.define{ library }}.to raise_error "Empty job library"
			end
		end

		context "given nil job library" do
			it "raises an error" do
				expect { Pipeline.define{ library nil }}.to raise_error "Job library must be an array of Job objects"
			end
		end

		context "given an array with a non-Job object" do
			it "raises an error" do
				job1 = build_job "job1"
				job2 = build_job "job2"
				expect { Pipeline.define{ library job1, "NOT A JOB", job2 }}.to raise_error "Job library must be an array of Job objects"
			end
		end

		context "given an array with duplicate jobs" do
			it "raises an error" do
				a_job = build_job "job1"
				different_job = build_job "job2"
				duplicate_job = build_job "job1"
				expect { Pipeline.define{ library a_job, different_job, duplicate_job }}.to raise_error "Duplicated job in library: 'job1'"
			end
		end
	end

	describe "add_job method" do
		context "given no job library" do
			it "raises an error" do
				job = build_job
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
		context "given an empty list" do
			it "raises an error" do
				expect { Pipeline.define{ add_jobs }}.to raise_error "Empty job list"
			end
		end

		context "given nil" do
			it "raises an error" do
				expect { Pipeline.define{ add_jobs nil }}.to raise_error "Job list must be an array of Job objects"
			end
		end

		context "given an array with non-Job objects" do
			it "raises an error" do
				job1 = build_job "job1"
				job2 = build_job "job2"
				expect { Pipeline.define{ add_jobs job1, "NOT A JOB", job2 }}.to raise_error "Job list must be an array of Job objects"
			end
		end
	end

	describe "building simple pipelines" do

		context "given no jobs" do
			it "raises an error" do
				job = build_job
				expect { Pipeline.define{ library job }}.to raise_error "Empty job list"
			end
		end

		context "pipeline with one job" do
			it "resolves a pipeline with one job" do
				simple_job = build_job "simple_job"

				p = Pipeline.define do
					add_job simple_job
					library simple_job
				end

				expect(p.job_order).to contain_exactly("simple_job")
			end
		end

		context "pipeline with two jobs and three jobs in its library" do
			it "resolves a pipeline with one job" do
				job1 = build_job "job1"
				job2 = build_job "job2"
				job3 = build_job "job3"

				p = Pipeline.define do
					add_jobs job1, job2
					library job1, job2, job3
				end

				expect(p.job_order).to contain_exactly("job1", "job2")
			end
		end

		context "pipeline with one job that depends on another job in its library" do
			it "resolves the pipeline of two jobs" do

				job0 = build_job "job0"
				job1 = build_job "job1", build_get("get0", "job0")

  				p = Pipeline.define do
					add_job job1 # depends on job0
					library job0, job1
				end
				
				expect(p.job_order).to contain_exactly("job0", "job1")
				
				expect(p.job_order).to include_job("job0").and_be_before_job("job1")
			end
		end

		context "pipeline with two jobs and each depend on three different other jobs in the library" do
			it "resolves the pipeline of two jobs" do
				job00 = build_job "job00"
				job01 = build_job "job01"
				job02 = build_job "job02"
				job10 = build_job "job10"
				job11 = build_job "job11"
				job12 = build_job "job12"

				job0 = build_job "job0", build_get("get0", "job00", "job01", "job02")
				job1 = build_job "job1", build_get("get1", "job10", "job11", "job12")

				p = Pipeline.define do
					add_jobs job0, job1
					library job0, job1, job00, job01, job02, job10, job11, job12
				end

				expect(p.job_order).to contain_exactly("job0", "job1", "job00", "job01", "job02", "job10", "job11", "job12")
			end
		end

		context "pipeline with two jobs and each depend on three of the same jobs in the library" do
			it "resolves the pipeline of two jobs" do
				job00 = build_job "job00"
				job01 = build_job "job01"
				job02 = build_job "job02"

				job0 = build_job "job0", build_get("get0", "job00", "job01", "job02")
				job1 = build_job "job1", build_get("get1", "job00", "job01", "job02")

				p = Pipeline.define do
					add_jobs job0, job1
					library job0, job1, job00, job01, job02
				end

				expect(p.job_order).to contain_exactly("job0", "job1", "job00", "job01", "job02")
			end
		end

		context "two levels of dependencies in the pipeline" do
			it "resolves the pipeline and includes all the dependencies" do
				job0 = build_job  "job0",  build_get("get00", "job00"), build_get("get01", "job01", "job02")
				job00 = build_job "job00", build_get("get000", "job000", "job001"), build_get("get001", "job002")
				job01 = build_job "job01", build_get("get002", "job000", "job001"), build_get("get003", "job002")
				job02 = build_job "job02", build_get("get004", "job003", "job004"), build_get("get003", "job005")
				job000 = build_job "job000"
				job001 = build_job "job001"
				job002 = build_job "job002"
				job003 = build_job "job003"
				job004 = build_job "job004"
				job005 = build_job "job005"

				p = Pipeline.define do
					add_job job0
					library job0, job00, job01, job02, job000, job001, job002, job003, job004, job005
				end

				expect(p.job_order).to contain_exactly("job0", "job00", "job01", "job02", "job000", "job001", "job002", "job003", "job004", "job005")
			end
		end

		context "pipeline with a job that depends on another job that is missing from its library" do
			it "raises an error" do

				job1 = build_job "job1", build_get("get0", "job0")

  				expect { Pipeline.define do
					add_job job1 # depends on missing job0
					library job1
				end }.to raise_error "Job 'job1' depends on missing job: 'job0'"

			end
		end

		context "missing job from job_library" do
			it "raises an error if the pipeline definition requests a non-existent job" do
				missing_job = build_job "missing_job"
				fancy_job =   build_job "fancy_job"

				expect { Pipeline.define{
					add_job missing_job
					library fancy_job
				}}.to raise_error "Missing job: missing_job"
			end
		end

		context "one missing job and one found job" do
			it "raises an error if the pipeline definition requests a non-existent job" do
				mystery_job = build_job "mystery_job"
				fancy_job =   build_job "fancy_job"
				awesome_job = build_job "awesome_job"
				silly_job =   build_job "silly_job"

				expect { Pipeline.define{
					add_jobs mystery_job, awesome_job
					library fancy_job, awesome_job, silly_job
				}}.to raise_error "Missing job: mystery_job"
			end
		end
	end

	describe "detecting cycles in the dependency graph" do

		context "cycle with one job" do
			it "raises an error" do
				job0 = build_job "job0", build_get("get0", "job0")
				
				expect { Pipeline.define do
					add_job job0
					library job0
				end }.to raise_error "Job 'job0' depends on itself"
			end
		end

		context "cycle with two jobs" do
			it "raises an error" do
				job0 = build_job "job0", build_get("get0", "job1")
				job1 = build_job "job1", build_get("get1", "job0")

				expect { Pipeline.define do
					add_jobs job0, job1
					library job0, job1
				end }.to raise_error "Found a circular dependency!"
			end
		end

		context "cycle with three jobs" do
			it "raises an error" do
				job0 = build_job "job0", build_get("get0", "job1")
				job1 = build_job "job1", build_get("get1", "job2")
				job2 = build_job "job2", build_get("get2", "job0")

				expect { Pipeline.define do
					add_jobs job0, job1, job2
					library job0, job1, job2
				end }.to raise_error "Found a circular dependency!"
			end
		end

		context "two disconnected subgraphs, each with one cycle" do
			it "raises an error" do
				job0 = build_job "job0", build_get("get0", "job1")
				job1 = build_job "job1", build_get("get1", "job2")
				job2 = build_job "job2", build_get("get2", "job0")
				job3 = build_job "job3", build_get("get3", "job4")
				job4 = build_job "job4", build_get("get4", "job5")
				job5 = build_job "job5", build_get("get5", "job3")

				expect { Pipeline.define do
					add_jobs job0, job1, job2, job3, job4, job5
					library job0, job1, job2, job3, job4, job5
				end }.to raise_error "Found a circular dependency!"
			end
		end

		context "something complicated" do
			it "raises an error" do

				job0 = build_job "job0"
				job1 = build_job "job1", build_get("get1", "job0")
				job2 = build_job "job2", build_get("get2a", "job0"), build_get("get2b", "job5")
				job3 = build_job "job3", build_get("get3a", "job6"), build_get("get3b", "job1") 
				job4 = build_job "job4", build_get("get4a", "job2"), build_get("get4b", "job3"), build_get("get4c", "job6")
				job5 = build_job "job5", build_get("get5", "job4")
				job6 = build_job "job6"
				job7 = build_job "job7", build_get("get7a", "job4"), build_get("get7b", "job6")
				job8 = build_job "job8", build_get("get8a", "job7"), build_get("get8b", "job6")
				job9 = build_job "job9", build_get("get9", "job8")

				#  0 -> 1 -> 3 <- 6 ----.    The cycle is 4 -> 5 -> 2
				#  |          \ /  \    |
				#  \          VV   v    v
				#  `---> 2 -> 4 -> 7 -> 8
				#        ^    |         |
				#       /     |         v
				#       `- 5 <'         9

				expect { Pipeline.define do
					add_jobs job5, job9
					library job0, job1, job2, job3, job4, job5, job6, job7, job8, job9
				end }.to raise_error "Found a circular dependency!"
			end
		end

	end
end

