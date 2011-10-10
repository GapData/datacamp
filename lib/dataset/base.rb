# -*- encoding : utf-8 -*-
class Dataset::Base
  
  include Transformations
  
  attr_reader :errors, :description, :derived_fields #:dataset_record_class, :derived_fields
  cattr_reader :system_columns, :prefix
    
  @errors = []
  @@prefix = DatastoreManager.dataset_table_prefix
  
  @@system_columns = {
    :created_at     => :datetime,
    :updated_at     => :datetime,
    :created_by     => :string,
    :updated_by     => :string,
    :record_status  => :string,
    :quality_status => :string,
    :batch_id       => :integer,
    :validity_date  => :date,
    :is_hidden      => :boolean
  }

  ####################################################################################
  # Basic Initializer Method

  def initialize(identifier)    
    if identifier.is_a? DatasetDescription
      @description = identifier
    else
      @description = DatasetDescription.find_by_identifier(identifier.to_s)
      unless @description
        @description = DatasetDescription.new
        @description.identifier = identifier
      end
    end
    
    # Initialize instance variables
    @errors = []
    
    # Setup DatasetRecord based on description
    Kernel.const_set((@@prefix + @description.identifier).classify, Class.new(Dataset::DatasetRecord)) unless dataset_record_class
    dataset_record_class.dataset = self
    dataset_record_class.establish_connection Rails.env + "_data"
    dataset_record_class.set_table_name @@prefix + @description.identifier
    
    @description.relations.each do |relation|
      next if relation.id.blank?
      dataset_record_class.send(relation.relation_type.to_sym, 
                                relation.relation_type == 'has_many' ? relation.relationship_dataset_description.identifier.pluralize : relation.relationship_dataset_description.identifier.singularize,
                                :foreign_key => relation.foreign_key_field_description.identifier.to_sym, 
                                :class_name => (@@prefix + relation.relationship_dataset_description.identifier).classify,
                                :primary_key => :relation_id
                                )
    end
    
    def dataset_record_class.find(*args)
      if dataset.has_derived_fields?
        select_columns = "*, " + dataset.derived_fields.map { |field, value| "#{value} as #{field}" }.join(",")
      else
        select_columns = "*"
      end

      conditions = {}
      # TODO should display only records with ok status

      with_scope(select(select_columns).where(conditions)) do
        super(*args)
      end
    end
    
    # Get connection from model
    @connection = Dataset::DatasetRecord.connection
    
    # Add derived fields
    @derived_fields = Hash.new
    @description.field_descriptions.find(:all, :conditions => { :is_derived => true }).each do |derived_field|
      @derived_fields[derived_field.identifier.to_sym] = derived_field.derived_value
    end
        
    # @dataset
  end
  
  def dataset_record_class
    @dataset_record_class ||= (@@prefix + @description.identifier).classify.constantize
    rescue
      return false
  end
  
  def has_derived_fields?
    !@derived_fields.empty?
  end
  
  
  ####################################################################################
  # Shortcuts
  
  def table_name
    dataset_record_class.table_name
  end
  
  def table_exists?
    dataset_record_class.table_exists?
  end
  
  def to_param
    @description.to_param
  end
  
  def dataset_description
    description
  end
  
  
  ####################################################################################
  # "Finder" method - to retrieve all tables
  
  def self.find_tables *args
    args = args.extract_options!
    tables = Dataset::DatasetRecord.connection.select_all('show tables').collect { |r| r.values[0] }
    if args[:prefix]
      tables = tables.find_all { |r| r =~ /^#{args[:prefix]}_/ }
    end
    if args[:prefix_not]
      tables = tables.delete_if { |r| r =~ /^#{args[:prefix_not]}_/ }
    end
    return tables
  end
  
  ####################################################################################
  # Table information & manipulation
  
  def has_column? column
    return false unless table_exists?
    @columns ||= @connection.columns table_name
    @columns.collect{|col|col.name}.include? column.to_s
  end
  
  def has_pk?
    has_column? "_record_id"
  end
  
  def add_column name, type
    @connection.add_column table_name, name, type
  end
end
