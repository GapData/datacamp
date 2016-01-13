# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class RegisUpdate < RegisExtraction

    UPDATE_ATTRIBUTES = [:ico, :name, :legal_form, :date_start, :date_end, :address, :place, :region, :activity1, :activity2, :account_sector, :ownership, :size]

    def self.config
      @configuration ||= EtlConfiguration.find_by_name('regis_update')
    end

    def self.update_last_run_time
      config.update_attribute(:last_run_time, Time.now)
    end

    def self.update_start_id(start_id)
      last_doc_id = Staging::StaRegisMain.order(:doc_id).last.doc_id
      start_id = 1 if start_id > last_doc_id
      config.start_id = start_id
      config.save
    end

    def save(organisation_hash)
      staging_element = Staging::StaRegisMain.find_by_doc_id(id)
      if staging_element.present?
        # save history
        if staging_element.name != organisation_hash[:name]
          name_history = staging_element.name_history || {}
          staging_element.name_history = name_history.merge(Time.current => staging_element.name)
        end
        staging_element.attributes = organisation_hash.select { |k, _| UPDATE_ATTRIBUTES.include? k }
      end
      staging_element.save!
    end
  end
end
