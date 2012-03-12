# -*- encoding : utf-8 -*-
class SystemVariable < ActiveRecord::Base
  translates :description
  locale_accessor :sk, :en
  
  def self.get(name, default = nil)
    @variables_cache ||= self.all
    variable = @variables_cache.detect { |variable| variable.name == name.to_s }
    value = variable ? variable.value : default
    value = false if value == "0"
    value
  end
end
