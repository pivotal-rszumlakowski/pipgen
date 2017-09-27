require 'resource'

class Job

	attr_reader :job_hash, :name, :plan_gets, :plan_puts, :depends_on, :required_resources

	def initialize(job_hash)

		@job_hash = job_hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} # Converts keys in hash to symbols
		@name = ""

		raise "Empty job definition" if @job_hash.empty?

		@name = @job_hash[:name]
		@plan_gets = []
		@plan_puts = []
		@depends_on = []
		@required_resources = []

		return unless @job_hash.key? :plan
		return if @job_hash[:plan].nil? or @job_hash[:plan].empty?

		all_get_items = []
		all_get_items.concat plan_aggregate_items "get"
		all_get_items.concat get_items(@job_hash[:plan])

		all_get_items.each { |get_item|
			@plan_gets << get_item
			@depends_on << get_item["passed"] if get_item.key? "passed"
		}

		@plan_puts = []
		@plan_puts.concat plan_aggregate_items "put"
		@plan_puts.concat put_items @job_hash[:plan]

		@depends_on.flatten!
		@depends_on.uniq!

		@required_resources.concat(find_required_resources(@plan_gets, "get"))
		@required_resources.concat(find_required_resources(@plan_puts, "put"))
	end

	def to_s
		@name
	end

	private

	def plan_aggregate_items item_type
		@job_hash[:plan].select{|p| p.key?("aggregate")}.collect{|p| p["aggregate"]}.flatten.select{|p| p.key? item_type}
	end

	def get_items(plan)
		plan.select{|item| item.key? "get"}
	end

	def put_items(plan)
		plan.select{|item| item.key? "put"}
	end

	def find_required_resources plan_items, resource_type
		plan_items.map{ |item| Resource.from_name(item[resource_type]) }
	end
end
