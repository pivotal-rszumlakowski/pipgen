require 'rspec/expectations'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end

RSpec::Matchers.define :include_job do |expected_job|

  match do |actual_array|
  	@later_jobs ||= []
    raise "Actual value must be an array" unless actual_array.is_a? Array

	(result, message) = helper actual_array, expected_job, @later_jobs
	return result
  end

  chain :and_be_before_job do |second_expected_job|
	  @later_jobs ||= []
	  @later_jobs << second_expected_job
  end

  chain :and_be_before_jobs do |second_expected_jobs|
      raise "Expected value must be an array" unless second_expected_jobs.is_a? Array
	  @later_jobs ||= []
	  @later_jobs.concat second_expected_jobs
  end

  failure_message do |actual_array|
	(result, message) = helper actual_array, expected_job, @later_jobs
	return message
  end

  private

  def helper(actual_array, expected_job, later_jobs)

	return missing_job_result(actual_array, expected_job) unless actual_array.include? expected_job

	first_index = actual_array.index expected_job
	@later_jobs.each do |j|
		return missing_job_result(actual_array, j) unless actual_array.include? j
	  	j_index = actual_array.index j
	  	return bad_order_result(actual_array, expected_job, j) unless first_index < j_index
	end

	return good_result
  end

  def missing_job_result(actual_array, expected_job)
	  [false, "expected job \"#{expected_job}\" to be in list #{actual_array}"]
  end

  def bad_order_result(actual_array, first_expected_job, second_expected_job)
	  [false, "expected job \"#{first_expected_job}\" to be before job \"#{second_expected_job}\" in list #{actual_array}"]
  end

  def good_result
	  [true, "OK"]
  end

end

RSpec.describe ["job0", "job1", "job2", "job3"] do
  it { is_expected.to include_job("job0").and_be_before_job("job1") }
  it { is_expected.to include_job("job0").and_be_before_jobs(["job1", "job2", "job3"]) }
  it { is_expected.to include_job("job1").and_be_before_job("job2") }
  it { is_expected.to include_job("job1").and_be_before_jobs(["job2", "job3"]) }
  it { is_expected.to include_job("job0") }
  it { is_expected.to include_job("job1") }
  it { is_expected.to_not include_job("jobX") }
end
