class Job

	attr_reader :job_hash, :name, :plan_gets, :plan_puts, :depends_on

	def initialize(job_hash)

		@job_hash = job_hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} # Converts keys in hash to symbols
		@name = ""

		raise "Empty job definition" if @job_hash.empty?

		@name = @job_hash[:name]
		@plan_gets = []
		@plan_puts = []
		@depends_on = []

		return unless @job_hash.key? :plan
		return if @job_hash[:plan].nil? or @job_hash[:plan].empty?

		all_get_items = []
		all_get_items.concat(plan_aggregate_items())
		all_get_items.concat(get_items(@job_hash[:plan]))

		all_get_items.each { |get_item|
			@plan_gets << get_item
			@depends_on << get_item["passed"] if get_item.key?("passed")
		}

		@plan_puts = put_items(@job_hash[:plan])

		@depends_on.flatten!
		@depends_on.uniq!
	end

	def to_s
		@name
	end

	private

	def plan_aggregate_items
		@job_hash[:plan].select{|p| p.key?("aggregate")}.collect{|p| p["aggregate"]}.flatten
	end

	def get_items(plan)
		plan.select{ |item| item.key?("get") }
	end

	def put_items(plan)
		plan.select{ |item| item.key?("put") }
	end
end
