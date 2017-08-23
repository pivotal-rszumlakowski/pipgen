require 'job'
require 'yaml'


EMPTY_JOB = {}

JOB_WITH_ONLY_NAME = YAML.load "name: awesome_job"

JOB_WITH_EMPTY_PLAN = YAML.load "name: empty_plan_job\nplan:"

JOB_WITH_GETS_AND_NO_PASSED = YAML.load("
---
name: simple_job
plan:
- get: get1
- get: get2
- get: get3")

JOB_WITH_AGGREGATE_GETS_AND_NO_PASSED = YAML.load("
---
name: aggregate_simple_job
plan:
- aggregate:
  - get: get4
  - get: get5
  - get: get6")

JOB_WITH_THREE_AGGREGATE_BLOCKS = YAML.load("
---
name: aggregated_big_job
plan:
- aggregate:
  - get: get1
  - get: get2
  - get: get3
- aggregate:
  - get: get4
  - get: get5
  - get: get6
- aggregate:
  - get: get7
  - get: get8
  - get: get9")

JOB_WITH_MANY_GETS = YAML.load("
---
name: very_big_job
plan:
- aggregate:
  - get: get1
  - get: get2
  - get: get3
- get: get13
- get: get14
- get: get15
- aggregate:
  - get: get4
  - get: get5
  - get: get6
- aggregate:
  - get: get7
  - get: get8
  - get: get9
- get: get10
- get: get11
- get: get12")

JOB_WITH_ONE_PASSED_GET = YAML.load("
---
name: easy_job
plan:
- get: the_only_get
  passed: [job_dependency1, job_dependency2, job_dependency3]")

describe Job do
	describe ".initialize" do

		context "given an empty hash" do
			it "returns an empty job" do
				expect(Job.new(EMPTY_JOB).name).to be_empty
			end

			it "returns an invalid job" do
				expect(Job.new(EMPTY_JOB).valid?).to be false
			end
		end

		context "given a job with just a name" do
			it "saves the name" do
				expect(Job.new(JOB_WITH_ONLY_NAME).name).to eq "awesome_job"
			end

			it "makes a valid job" do
				expect(Job.new(JOB_WITH_ONLY_NAME).valid?).to be true
			end

			it "makes a job with no gets" do
				expect(Job.new(JOB_WITH_ONLY_NAME).plan_gets).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(Job.new(JOB_WITH_ONLY_NAME).depends_on).to be_empty
			end
		end

		context "given a job with an empty plan" do
			it "saves the name" do
				expect(Job.new(JOB_WITH_EMPTY_PLAN).name).to eq "empty_plan_job"
			end

			it "makes a valid job" do
				expect(Job.new(JOB_WITH_EMPTY_PLAN).valid?).to be true
			end

			it "makes a job with no gets" do
				expect(Job.new(JOB_WITH_EMPTY_PLAN).plan_gets).to be_empty
			end

			it "makes a job with no dependencies" do
				expect(Job.new(JOB_WITH_EMPTY_PLAN).depends_on).to be_empty
			end
		end

		context "given a job with a plan with some gets but no passed elements" do
			it "saves the name" do
				expect(Job.new(JOB_WITH_GETS_AND_NO_PASSED).name).to eq "simple_job"
			end

			it "makes a valid job" do
				expect(Job.new(JOB_WITH_GETS_AND_NO_PASSED).valid?).to be true
			end

			it "makes a job with three gets" do
				expect(Job.new(JOB_WITH_GETS_AND_NO_PASSED).plan_gets).to contain_exactly({"get"=>"get1"}, {"get"=>"get2"}, {"get"=>"get3"})
			end

			it "makes a job with no dependencies" do
				expect(Job.new(JOB_WITH_GETS_AND_NO_PASSED).depends_on).to be_empty
			end
		end

		context "given a job with a plan with some aggregated gets but no passed elements" do
			it "saves the name" do
				expect(Job.new(JOB_WITH_AGGREGATE_GETS_AND_NO_PASSED).name).to eq "aggregate_simple_job"
			end

			it "makes a valid job" do
				expect(Job.new(JOB_WITH_AGGREGATE_GETS_AND_NO_PASSED).valid?).to be true
			end

			it "makes a job with three gets" do
				expect(Job.new(JOB_WITH_AGGREGATE_GETS_AND_NO_PASSED).plan_gets).to contain_exactly({"get"=>"get4"}, {"get"=>"get5"}, {"get"=>"get6"})
			end

			it "makes a job with no dependencies" do
				expect(Job.new(JOB_WITH_AGGREGATE_GETS_AND_NO_PASSED).depends_on).to be_empty
			end
		end

		context "given a job with three aggregated gets" do
			it "saves the name" do
				expect(Job.new(JOB_WITH_THREE_AGGREGATE_BLOCKS).name).to eq "aggregated_big_job"
			end

			it "makes a valid job" do
				expect(Job.new(JOB_WITH_THREE_AGGREGATE_BLOCKS).valid?).to be true
			end

			it "makes a job with three gets" do
				expect(Job.new(JOB_WITH_THREE_AGGREGATE_BLOCKS).plan_gets).to contain_exactly({"get"=>"get1"}, {"get"=>"get2"}, {"get"=>"get3"}, {"get"=>"get4"}, {"get"=>"get5"}, {"get"=>"get6"}, {"get"=>"get7"}, {"get"=>"get8"}, {"get"=>"get9"})
			end

			it "makes a job with no dependencies" do
				expect(Job.new(JOB_WITH_THREE_AGGREGATE_BLOCKS).depends_on).to be_empty
			end
		end

		context "given a job with many gets" do
			it "saves the name" do
				expect(Job.new(JOB_WITH_MANY_GETS).name).to eq "very_big_job"
			end

			it "makes a valid job" do
				expect(Job.new(JOB_WITH_MANY_GETS).valid?).to be true
			end

			it "makes a job with three gets" do
				expect(Job.new(JOB_WITH_MANY_GETS).plan_gets).to contain_exactly({"get"=>"get1"}, {"get"=>"get2"}, {"get"=>"get3"}, {"get"=>"get4"}, {"get"=>"get5"}, {"get"=>"get6"}, {"get"=>"get7"}, {"get"=>"get8"}, {"get"=>"get9"}, {"get"=>"get10"}, {"get"=>"get11"}, {"get"=>"get12"}, {"get"=>"get13"}, {"get"=>"get14"}, {"get"=>"get15"})
			end

			it "makes a job with no dependencies" do
				expect(Job.new(JOB_WITH_MANY_GETS).depends_on).to be_empty
			end
		end

		context "given a job with simple dependencies" do
			it "saves the name" do
				expect(Job.new(JOB_WITH_ONE_PASSED_GET).name).to eq "easy_job"
			end

			it "makes a valid job" do
				expect(Job.new(JOB_WITH_ONE_PASSED_GET).valid?).to be true
			end

			it "makes a job with three gets" do
				expect(Job.new(JOB_WITH_ONE_PASSED_GET).plan_gets).to contain_exactly({"get"=>"the_only_get", "passed"=>["job_dependency1", "job_dependency2", "job_dependency3"]})
			end

			it "makes a job with no dependencies" do
				expect(Job.new(JOB_WITH_ONE_PASSED_GET).depends_on).to contain_exactly("job_dependency1", "job_dependency2", "job_dependency3")
			end
		end

	end
end
