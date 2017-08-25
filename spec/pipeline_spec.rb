require 'spec_helper'
require 'support/factory_girl'
require 'pipeline'

describe Pipeline do
	describe ".initialize" do

		context "given an nil pipeline definition" do
			it "raises an error" do
				expect {Pipeline.new(nil, [])}.to raise_error "Empty pipeline definition"
			end
		end

		context "given an nil job library" do
			it "raises an error" do
				expect {Pipeline.new(["some_job"], nil)}.to raise_error "Empty job library"
			end
		end

		context "given an empty pipeline definition" do
			it "raises an error" do
				expect {Pipeline.new([], [])}. to raise_error "Empty pipeline definition"
			end
		end

		context "given an empty job library" do
			it "raises an error" do
				expect {Pipeline.new(["some_job"], [])}.to raise_error "Empty job library"
			end
		end
	end

	describe ".build" do
		context "missing jobs from job_library" do
			it "raises an error if the pipeline definition requests a non-existent job" do
				expect {Pipeline.new(["missing_job"], [build(:job)]).build}.to raise_error "Missing job: missing_job"
			end
		end

		context "pipeline with one job" do
			it "resolves a pipeline with one job" do
				expect {Pipeline.new(["awesome_job"], [build(:job)]).build}.not_to raise_error
			end
		end
	end
end

