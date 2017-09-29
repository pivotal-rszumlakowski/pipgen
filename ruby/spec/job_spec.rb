require 'spec_helper'
require 'support/factory_girl'
require 'job'

describe Job do
	describe ".initialize" do

		context "given an empty hash" do
			it "returns an invalid job" do
				expect{Job.new(EMPTY_JOB)}.to raise_error "Empty job definition"
			end
		end

		context "given a job with just a name" do
			
			before :each do
				@job = mkjob "awesome_job"
			end

			it "saves the name" do
				expect(@job.name).to eq "awesome_job"
			end

			it "makes a job with no gets" do
				expect(@job.plan_gets).to be_empty
			end

			it "makes a job with no puts" do
				expect(@job.plan_puts).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to be_empty
			end

			it "makes a job with no required resources" do
				expect(@job.required_resources).to be_empty
			end
		end

		context "given a job with a plan with some gets but no passed elements" do

			before :each do
				@job = mkjob "my_job", mkget("get1"), mkget("get2"), mkget("get3")
			end

			it "makes a job with three gets" do
				expect(@job.plan_gets).to contain_exactly({"get"=>"get1"}, {"get"=>"get2"}, {"get"=>"get3"})
			end

			it "makes a job with no puts" do
				expect(@job.plan_puts).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to be_empty
			end

			it "makes a job with three required resources" do
				expect(@job.required_resources.map{|r|r.name}).to contain_exactly("get1", "get2", "get3")
			end
		end

		context "given a job with a plan with some puts but no passed elements" do

			before :each do
				@job = mkjob "my_job", mkput("put1"), mkput("put2"), mkput("put3")
			end

			it "makes a job with no gets" do
				expect(@job.plan_gets).to be_empty
			end

			it "makes a job with no puts" do
				expect(@job.plan_puts.map{|p|p.values}.flatten).to contain_exactly("put1", "put2", "put3")
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to be_empty
			end

			it "makes a job with three required resources" do
				expect(@job.required_resources.map{|r|r.name}).to contain_exactly("put1", "put2", "put3")
			end
		end

		context "given a job with a plan with some aggregated gets but no passed elements" do

			before :each do
				@job = mkjob "my_job", mkaggregate(mkget("get4"), mkget("get5"), mkget("get6"))
			end

			it "makes a job with three gets" do
				expect(@job.plan_gets.map{|g|g.values}.flatten).to contain_exactly("get4", "get5", "get6")
			end

			it "makes a job with no puts" do
				expect(@job.plan_puts).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to be_empty
			end

			it "makes a job with three required resources" do
				expect(@job.required_resources.map{|r|r.name}).to contain_exactly("get4", "get5", "get6")
			end
		end

		context "given a job with three aggregated gets" do

			before :each do
				@job = mkjob "my_job",
					mkaggregate(mkget("get1"), mkget("get2"), mkget("get3")),
					mkaggregate(mkget("get4"), mkget("get5"), mkget("get6")),
					mkaggregate(mkget("get7"), mkget("get8"), mkget("get9"))
			end

			it "makes a job with nine gets" do
				expect(@job.plan_gets).to contain_exactly({"get"=>"get1"}, {"get"=>"get2"}, {"get"=>"get3"}, {"get"=>"get4"}, {"get"=>"get5"}, {"get"=>"get6"}, {"get"=>"get7"}, {"get"=>"get8"}, {"get"=>"get9"})
			end

			it "makes a job with no puts" do
				expect(@job.plan_puts).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to be_empty
			end

			it "makes a job with nine required resources" do
				expect(@job.required_resources.map{|r|r.name}).to contain_exactly("get1", "get2", "get3","get4", "get5", "get6", "get7", "get8", "get9")
			end
		end

		context "given a job with many gets and puts" do

			before :each do
				@job = mkjob "very_big_job",
					mkaggregate(mkget("get1"), mkget("get2"), mkget("get3")),
					mkget("get13"),
					mkget("get14"),
					mkget("get15"),
					mkput("put1"),
					mkput("put2"),
					mkput("put3"),
					mkaggregate(mkget("get4"), mkget("get5"), mkget("get6")),
					mkaggregate(mkget("get7"), mkget("get8"), mkget("get9")),
					mkget("get10"),
					mkget("get11"),
					mkget("get12"),
					mkaggregate(mkput("put4"), mkput("put5"), mkput("put6"))
			end

			it "makes a job with twelve gets" do
				expect(@job.plan_gets.map{|g|g.values}.flatten).to contain_exactly("get1", "get2", "get3", "get4", "get5", "get6", "get7", "get8", "get9", "get10", "get11", "get12", "get13", "get14", "get15")
			end

			it "makes a job with six puts" do
				expect(@job.plan_puts.map{|p|p.values}.flatten).to contain_exactly("put1", "put2", "put3", "put4", "put5", "put6")
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to be_empty
			end

			it "makes a job with eighteen required resources" do
				expect(@job.required_resources.map{|r|r.name}).to contain_exactly("get1", "get2", "get3","get4", "get5", "get6", "get7", "get8", "get9",
					"get10", "get11", "get12", "get13", "get14", "get15", "put1", "put2", "put3", "put4", "put5", "put6")
			end
		end

		context "given a job with simple dependencies" do

			before :each do
				@job = mkjob "my_job", mkget("the_only_get", "job_dependency1", "job_dependency2", "job_dependency3")
			end

			it "makes a job with three gets" do
				expect(@job.plan_gets).to contain_exactly(
					{"get"=>"the_only_get", "passed"=>["job_dependency1", "job_dependency2", "job_dependency3"]})
			end

			it "makes a job with no puts" do
				expect(@job.plan_puts).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to contain_exactly("job_dependency1", "job_dependency2", "job_dependency3")
			end

			it "makes a job with one required resource" do
				expect(@job.required_resources.map{|r| r.name}).to contain_exactly("the_only_get")
			end
		end

		context "given a job with two gets and unique dependencies" do

			before :each do
				@job = mkjob "my_job",
					mkget("the_first_get", "job_dependency1", "job_dependency2", "job_dependency3"),
					mkget("the_second_get", "job_dependency4", "job_dependency5", "job_dependency6")
			end

			it "makes a job with three gets" do
				expect(@job.plan_gets).to contain_exactly(
					{"get"=>"the_first_get",  "passed"=>["job_dependency1", "job_dependency2", "job_dependency3"]},
					{"get"=>"the_second_get", "passed"=>["job_dependency4", "job_dependency5", "job_dependency6"]})
			end

			it "makes a job with no puts" do
				expect(@job.plan_puts).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to contain_exactly(
					"job_dependency1", "job_dependency2", "job_dependency3",
					"job_dependency4", "job_dependency5", "job_dependency6")
			end

			it "makes a job with two required resources" do
				expect(@job.required_resources.map{|r| r.name}).to contain_exactly("the_first_get", "the_second_get")
			end
		end

		context "given a job with two gets and shared dependencies" do

			before :each do
				@job = mkjob "my_job",
					mkget("the_first_get", "job_dependency1", "job_dependency2", "job_dependency3"),
					mkaggregate(mkget("the_second_get", "job_dependency1", "job_dependency2", "job_dependency4"))
			end

			it "makes a job with three gets" do
				expect(@job.plan_gets).to contain_exactly(
					{"get"=>"the_first_get",  "passed"=>["job_dependency1", "job_dependency2", "job_dependency3"]},
					{"get"=>"the_second_get", "passed"=>["job_dependency1", "job_dependency2", "job_dependency4"]})
			end

			it "makes a job with no puts" do
				expect(@job.plan_puts).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(@job.depends_on).to contain_exactly(
					"job_dependency1", "job_dependency2", "job_dependency3", "job_dependency4")
			end

			it "makes a job with two required resources" do
				expect(@job.required_resources.map{|r| r.name}).to contain_exactly("the_first_get", "the_second_get")
			end
		end
	end
end
