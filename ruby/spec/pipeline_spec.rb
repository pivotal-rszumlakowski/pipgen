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

	describe "job library method" do
		context "given empty job library" do
			it "raises an error" do
				expect { Pipeline.define{ job_library }}.to raise_error "Empty job library"
			end
		end

		context "given nil job library" do
			it "raises an error" do
				expect { Pipeline.define{ job_library nil }}.to raise_error "Job library must be an array of Job objects"
			end
		end

		context "given an array with a non-Job object" do
			it "raises an error" do
				job1 = mkjob "job1"
				job2 = mkjob "job2"
				expect { Pipeline.define{ job_library job1, "NOT A JOB", job2 }}.to raise_error "Job library must be an array of Job objects"
			end
		end

		context "given an array with duplicate jobs" do
			it "raises an error" do
				a_job = mkjob "job1"
				different_job = mkjob "job2"
				duplicate_job = mkjob "job1"
				expect { Pipeline.define{ job_library a_job, different_job, duplicate_job }}.to raise_error "Duplicated job in library: 'job1'"
			end
		end
	end

	describe "add_job method" do
		context "given no job library" do
			it "raises an error" do
				job = mkjob "job1"
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
				job1 = mkjob "job1"
				job2 = mkjob "job2"
				expect { Pipeline.define{ add_jobs job1, "NOT A JOB", job2 }}.to raise_error "Job list must be an array of Job objects"
			end
		end
	end

	describe "building simple pipelines" do

		context "given no jobs" do
			it "raises an error" do
				job = mkjob "job1"
				expect { Pipeline.define{ job_library job }}.to raise_error "Empty job list"
			end
		end

		context "pipeline with one job" do
			it "resolves a pipeline with one job" do
				simple_job = mkjob "simple_job"

				p = Pipeline.define do
					add_job simple_job
					job_library simple_job
				end

				expect(p.job_order.map{|j| j.name}).to contain_exactly("simple_job")
			end
		end

		context "pipeline with missing resources" do
			it "raises an error" do
				simple_job = mkjob "simple_job", mkget("get0")

				expect { Pipeline.define do
					add_job simple_job
					job_library simple_job
				end }.to raise_error "Missing resource 'get0' required by job 'simple_job'"
			end
		end

		context "pipeline with two jobs and three jobs in its library" do
			it "resolves a pipeline with one job" do
				job1 = mkjob "job1"
				job2 = mkjob "job2"
				job3 = mkjob "job3"

				p = Pipeline.define do
					add_jobs job1, job2
					job_library job1, job2, job3
				end

				expect(p.job_order.map{|j| j.name}).to contain_exactly("job1", "job2")
			end
		end

		context "pipeline with one job that depends on another job in its library" do
			it "resolves the pipeline of two jobs" do

				job0 = mkjob "job0"
				job1 = mkjob "job1", mkget("get0", "job0")
				get0 = mkresource "get0"

  				p = Pipeline.define do
					add_job job1 # depends on job0
					resource_library get0
					job_library job0, job1
				end
				
				expect(p.job_order.map {|j| j.name}).to contain_exactly("job0", "job1")
				expect(p.job_order).to include_job("job0").and_be_before_job("job1")
				expect(p.required_resources.map{|r| r.name}).to contain_exactly("get0")
			end
		end

		context "pipeline with two jobs and each depend on three different other jobs in the library" do
			it "resolves the pipeline of two jobs" do
				job00 = mkjob "job00"
				job01 = mkjob "job01"
				job02 = mkjob "job02"
				job10 = mkjob "job10"
				job11 = mkjob "job11"
				job12 = mkjob "job12"

				job0 = mkjob "job0", mkget("get0", "job00", "job01", "job02")
				job1 = mkjob "job1", mkget("get1", "job10", "job11", "job12")

				get0 = mkresource "get0"
				get1 = mkresource "get1"

				p = Pipeline.define do
					add_jobs job0, job1
					job_library job0, job1, job00, job01, job02, job10, job11, job12
					resource_library get0, get1
				end

				expect(p.job_order.map{|j| j.name}).to contain_exactly("job00", "job01", "job02", "job10", "job11", "job12", "job0", "job1")
				expect(p.job_order).to include_job("job00").and_be_before_job("job0")
				expect(p.job_order).to include_job("job01").and_be_before_job("job0")
				expect(p.job_order).to include_job("job02").and_be_before_job("job0")
				expect(p.job_order).to include_job("job10").and_be_before_job("job1")
				expect(p.job_order).to include_job("job11").and_be_before_job("job1")
				expect(p.job_order).to include_job("job12").and_be_before_job("job1")
				expect(p.required_resources.map{|r| r.name}).to contain_exactly("get0", "get1")
			end
		end

		context "pipeline with two jobs and each depend on three of the same jobs in the library" do
			it "resolves the pipeline of two jobs" do
				job00 = mkjob "job00"
				job01 = mkjob "job01"
				job02 = mkjob "job02"

				job0 = mkjob "job0", mkget("get0", "job00", "job01", "job02")
				job1 = mkjob "job1", mkget("get1", "job00", "job01", "job02")

				get0 = mkresource "get0"
				get1 = mkresource "get1"

				p = Pipeline.define do
					add_jobs job0, job1
					job_library job0, job1, job00, job01, job02
					resource_library get0, get1
				end

				expect(p.job_order.map{|j| j.name}).to contain_exactly("job0", "job1", "job00", "job01", "job02")
				expect(p.job_order).to include_job("job00").and_be_before_jobs("job0", "job1")
				expect(p.job_order).to include_job("job01").and_be_before_jobs("job0", "job1")
				expect(p.job_order).to include_job("job02").and_be_before_jobs("job0", "job1")
				expect(p.required_resources.map{|r| r.name}).to contain_exactly("get0", "get1")
			end
		end

		context "two levels of dependencies in the pipeline" do
			it "resolves the pipeline and includes all the dependencies" do
				job0 = mkjob  "job0",  mkget("get00", "job00"), mkget("get01", "job01", "job02")
				job00 = mkjob "job00", mkget("get000", "job000", "job001"), mkget("get001", "job002")
				job01 = mkjob "job01", mkget("get002", "job000", "job001"), mkget("get003", "job002")
				job02 = mkjob "job02", mkget("get004", "job003", "job004"), mkget("get003", "job005")
				job000 = mkjob "job000"
				job001 = mkjob "job001"
				job002 = mkjob "job002"
				job003 = mkjob "job003"
				job004 = mkjob "job004"
				job005 = mkjob "job005"
				get00  = mkresource "get00"
				get01  = mkresource "get01"
				get000 = mkresource "get000"
				get001 = mkresource "get001"
				get002 = mkresource "get002"
				get003 = mkresource "get003"
				get004 = mkresource "get004"

				p = Pipeline.define do
					add_job job0
					job_library job0, job00, job01, job02, job000, job001, job002, job003, job004, job005
					resource_library get00, get01, get000, get001, get002, get003, get004
				end

				expect(p.job_order.map{|j| j.name}).to contain_exactly("job0", "job00", "job01", "job02", "job000", "job001", "job002", "job003", "job004", "job005")
				expect(p.job_order).to include_job("job000").and_be_before_jobs("job00", "job01")
				expect(p.job_order).to include_job("job001").and_be_before_jobs("job00", "job01")
				expect(p.job_order).to include_job("job002").and_be_before_jobs("job00", "job01")
				expect(p.job_order).to include_job("job003").and_be_before_job("job02")
				expect(p.job_order).to include_job("job004").and_be_before_job("job02")
				expect(p.job_order).to include_job("job005").and_be_before_job("job02")
				expect(p.required_resources.map{|r| r.name}).to contain_exactly("get00", "get01", "get000", "get001", "get002", "get003", "get004")
			end
		end

		context "pipeline with a job that depends on another job that is missing from its library" do
			it "raises an error" do

				job1 = mkjob "job1", mkget("get0", "job0")

  				expect { Pipeline.define do
					add_job job1 # depends on missing job0
					job_library job1
				end }.to raise_error "Job 'job1' depends on missing job: 'job0'"

			end
		end

		context "missing job from job_library" do
			it "raises an error if the pipeline definition requests a non-existent job" do
				missing_job = mkjob "missing_job"
				fancy_job =   mkjob "fancy_job"

				expect { Pipeline.define{
					add_job missing_job
					job_library fancy_job
				}}.to raise_error "Missing job: missing_job"
			end
		end

		context "one missing job and one found job" do
			it "raises an error if the pipeline definition requests a non-existent job" do
				mystery_job = mkjob "mystery_job"
				fancy_job =   mkjob "fancy_job"
				awesome_job = mkjob "awesome_job"
				silly_job =   mkjob "silly_job"

				expect { Pipeline.define{
					add_jobs mystery_job, awesome_job
					job_library fancy_job, awesome_job, silly_job
				}}.to raise_error "Missing job: mystery_job"
			end
		end
	end

	describe "building big pipelines" do
		context "something big" do
			it "resolves the pipeline" do

				job0  = mkjob "job0"
				job1  = mkjob "job1", mkget("get1", "job0")
				job2  = mkjob "job2", mkget("get2a", "job0")
				job3  = mkjob "job3", mkget("get3a", "job6"), mkget("get3b", "job1") 
				job4  = mkjob "job4", mkget("get4a", "job2"), mkget("get4b", "job3"), mkget("get4c", "job6")
				job5  = mkjob "job5", mkget("get5", "job4")
				job6  = mkjob "job6"
				job7  = mkjob "job7", mkget("get7a", "job4"), mkget("get7b", "job6")
				job8  = mkjob "job8", mkget("get8a", "job7"), mkget("get8b", "job6")
				job9  = mkjob "job9", mkget("get9", "job8")
				get1  = mkresource "get1"
				get2a = mkresource "get2a"
				get3a = mkresource "get3a"
				get3b = mkresource "get3b"
				get4a = mkresource "get4a"
				get4b = mkresource "get4b"
				get4c = mkresource "get4c"
				get5  = mkresource "get5"
				get7a = mkresource "get7a"
				get7b = mkresource "get7b"
				get8a = mkresource "get8a"
				get8b = mkresource "get8b"
				get9  = mkresource "get9"

				#  0 -> 1 -> 3 <- 6 ----.
				#  |          \ /  \    |
				#  \          VV   v    v
				#  `---> 2 -> 4 -> 7 -> 8
				#             |         |
				#             v         v
				#             5         9

				p = Pipeline.define do
					add_jobs job5, job9
					job_library job0, job1, job2, job3, job4, job5, job6, job7, job8, job9
					resource_library get1, get2a, get3a, get3b, get4a, get4b, get4c, get5, get7a, get7b, get8a, get8b, get9
				end

				expect(p.job_order.map{|j| j.name}).to contain_exactly("job0", "job1", "job2", "job3", "job4", "job5", "job6", "job7", "job8", "job9")
				expect(p.job_order).to include_job("job0").and_be_before_jobs("job1", "job2", "job3", "job4", "job5", "job7", "job8", "job9")
				expect(p.job_order).to include_job("job1").and_be_after_job("job0").and_be_before_jobs("job3", "job4", "job5", "job7", "job8", "job9")
				expect(p.job_order).to include_job("job2").and_be_after_job("job0").and_be_before_jobs("job4", "job5", "job7", "job8", "job9")
				expect(p.job_order).to include_job("job3").and_be_after_jobs("job0", "job1").and_be_before_jobs("job4", "job5", "job7", "job8", "job9")
				expect(p.job_order).to include_job("job4").and_be_after_jobs("job0", "job1", "job2", "job3", "job6").and_be_before_jobs("job5", "job7", "job8", "job9")
				expect(p.job_order).to include_job("job5").and_be_after_jobs("job0", "job1", "job2", "job3", "job4", "job6")
				expect(p.job_order).to include_job("job6").and_be_before_jobs("job4", "job5", "job7", "job8", "job9")
				expect(p.job_order).to include_job("job7").and_be_after_jobs("job0", "job1", "job2", "job3", "job4", "job6").and_be_before_jobs("job8", "job9")
				expect(p.job_order).to include_job("job8").and_be_after_jobs("job0", "job1", "job2", "job3", "job4", "job6", "job7").and_be_before_job("job9")
				expect(p.job_order).to include_job("job9").and_be_after_jobs("job0", "job1", "job2", "job3", "job4", "job6", "job7", "job8")
				expect(p.required_resources.map{|r| r.name}).to contain_exactly("get1", "get2a", "get3a", "get3b", "get4a", "get4b", "get4c", "get5", "get7a", "get7b", "get8a", "get8b", "get9")
			end
		end
	end

	describe "detecting cycles in the dependency graph" do

		context "cycle with one job" do
			it "raises an error" do
				job0 = mkjob "job0", mkget("get0", "job0")
				
				expect { Pipeline.define do
					add_job job0
					job_library job0
				end }.to raise_error "Job 'job0' depends on itself"
			end
		end

		context "cycle with two jobs" do
			it "raises an error" do
				job0 = mkjob "job0", mkget("get0", "job1")
				job1 = mkjob "job1", mkget("get1", "job0")

				expect { Pipeline.define do
					add_jobs job0, job1
					job_library job0, job1
				end }.to raise_error "Found a circular dependency!"
			end
		end

		context "cycle with three jobs" do
			it "raises an error" do
				job0 = mkjob "job0", mkget("get0", "job1")
				job1 = mkjob "job1", mkget("get1", "job2")
				job2 = mkjob "job2", mkget("get2", "job0")

				expect { Pipeline.define do
					add_jobs job0, job1, job2
					job_library job0, job1, job2
				end }.to raise_error "Found a circular dependency!"
			end
		end

		context "two disconnected subgraphs, each with one cycle" do
			it "raises an error" do
				job0 = mkjob "job0", mkget("get0", "job1")
				job1 = mkjob "job1", mkget("get1", "job2")
				job2 = mkjob "job2", mkget("get2", "job0")
				job3 = mkjob "job3", mkget("get3", "job4")
				job4 = mkjob "job4", mkget("get4", "job5")
				job5 = mkjob "job5", mkget("get5", "job3")

				expect { Pipeline.define do
					add_jobs job0, job1, job2, job3, job4, job5
					job_library job0, job1, job2, job3, job4, job5
				end }.to raise_error "Found a circular dependency!"
			end
		end

		context "something complicated" do
			it "raises an error" do

				job0 = mkjob "job0"
				job1 = mkjob "job1", mkget("get1", "job0")
				job2 = mkjob "job2", mkget("get2a", "job0"), mkget("get2b", "job5")
				job3 = mkjob "job3", mkget("get3a", "job6"), mkget("get3b", "job1") 
				job4 = mkjob "job4", mkget("get4a", "job2"), mkget("get4b", "job3"), mkget("get4c", "job6")
				job5 = mkjob "job5", mkget("get5", "job4")
				job6 = mkjob "job6"
				job7 = mkjob "job7", mkget("get7a", "job4"), mkget("get7b", "job6")
				job8 = mkjob "job8", mkget("get8a", "job7"), mkget("get8b", "job6")
				job9 = mkjob "job9", mkget("get9", "job8")

				#  0 -> 1 -> 3 <- 6 ----.    The cycle is 4 -> 5 -> 2
				#  |          \ /  \    |
				#  \          VV   v    v
				#  `---> 2 -> 4 -> 7 -> 8
				#        ^    |         |
				#       /     |         v
				#       `- 5 <'         9

				expect { Pipeline.define do
					add_jobs job5, job9
					job_library job0, job1, job2, job3, job4, job5, job6, job7, job8, job9
				end }.to raise_error "Found a circular dependency!"
			end
		end
	end
end
