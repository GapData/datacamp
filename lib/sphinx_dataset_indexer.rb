class SphinxDatasetIndexer
  def self.index_all_datasets
    if DatasetDescription.table_exists?
      DatasetDescription.all.each { |dataset_description| index_dataset(dataset_description) }
    end
  end

  def self.index_dataset(dataset_description)
    dataset_description.dataset.dataset_record_class.define_index do
      indexes :_record_id
      indexes :record_status
      indexes :quality_status
      field_count = 0
      dataset_description.visible_field_descriptions(:detail).each do |field|
        if ![:integer, :date, :decimal].include?(field.data_type)
          next if field_count > 28
          field_count += 1
          indexes field.identifier.to_sym, :sortable => true if field.identifier.present?
        else
          if field.identifier.present?
            has field.identifier.to_sym

            if field.data_type == :decimal
              has field.identifier.to_sym, :as => "#{field.identifier}_sort", type: :float
            else
              has field.identifier.to_sym, :as => "#{field.identifier}_sort"
            end
          end
        end
        has "#{field.identifier} IS NOT NULL", :type => :integer, :as => "#{field.identifier}_not_nil" if field.identifier.present?
        has "#{field.identifier} IS NULL", :type => :integer, :as => "#{field.identifier}_nil" if field.identifier.present?
      end
    end
  end
end