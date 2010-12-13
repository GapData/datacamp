# -*- encoding : utf-8 -*-
class SearchPredicate < ActiveRecord::Base
cattr_reader :datatype_operators

belongs_to :search_query

# FIXME: change to method, get from more generic hash
@@datatype_operators = {
  :integer => [:greater, :less, :greater_or_equal, :less_or_equal, :equal, :not_equal, :is_set, :is_not_set],
  :date => [:within_last_days, :within_last_weeks, :within_last_months, :greater, :less, :greater_or_equal, :less_or_equal, :equal, :not_equal, :is_set, :is_not_set],
  :string => [:contains, :begins_with, :ends_with, :does_not_contain, :matches, :is_set, :is_not_set]
}

@@operator_codes = {
	:greater => "gt",
	:less => "lt",
	:greater_or_equal => "ge",
	:less_or_equal => "le",
	:equal => "eq",
	:notequal => "ne",
	:is_set => "st",
	:not_set => "ns",
	:begins_with => "bw",
	:ends_with => "ew",
	:contains => "co",
	:does_not_contain => "nc",
	:matches => "ma",
	:does_not_end => "ne",
	:does_not_begin => "nb",
	:within_last_days => "ld",
	:within_last_weeks => "lw",
	:within_last_months => "lm"	
}

def sql_condition_for_operand(operand)
	sql_argument = argument
	operand = "(#{operand})"
	
	case operator
	when "begins_with"
		sql_argument = "#{argument}%"
		condition = "#{operand} LIKE :ARGUMENT"
	when "does_not_begin_with"
		sql_argument = "#{argument}%"
		condition = "(#{operand} IS NULL) OR (#{field} NOT LIKE :ARGUMENT)"
	when "ends_with"
		sql_argument = "%#{argument}"
		condition = "#{operand} LIKE :ARGUMENT"
	when "does_not_end_with"
		sql_argument = "%#{argument}"
		condition = "(#{operand} IS NULL) OR (#{field} NOT LIKE :ARGUMENT)"
	when "contains"
		sql_argument = "%#{argument}%"
		condition = "#{operand} LIKE :ARGUMENT"
	when "does_not_contain"
		sql_argument = "%#{argument}%"
		condition = "(#{operand} IS NULL) OR (#{field} NOT LIKE :ARGUMENT)"
	when "matches"
		condition = "#{operand} = :ARGUMENT"
	when "greater"
		condition = "#{operand} > :ARGUMENT"
	when "greater_or_equal"
		condition = "#{operand} >= :ARGUMENT"
	when "less"
		condition = "#{operand} < :ARGUMENT"
	when "less_or_equal"
		condition = "#{operand} <= :ARGUMENT"
	when "not_equal"
		condition = "(#{operand} IS NULL) OR (#{field} <> :ARGUMENT)"
	when "is_set"
		condition = "#{operand} IS NOT NULL"
	when "is_not_set"
		condition = "#{operand} IS NULL"
	else
		raise "Unknown search predicate operator #{operator}"
	end
	
	condition = condition.sub(":ARGUMENT", ActiveRecord::Base.sanitize(sql_argument))
		
	return "(#{condition})"
end

end
