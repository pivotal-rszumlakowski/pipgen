require 'job'
require 'yaml'

describe Job do

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

	end
end
