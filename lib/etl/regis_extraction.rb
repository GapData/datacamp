# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class RegisExtraction < Struct.new(:document_html, :id, :document_url)

    def self.config
      @configuration ||= EtlConfiguration.find_by_name('regis_extraction')
    end

    def self.update_last_run_time
      config.update_attribute(:last_run_time, Time.now)
    end

    def perform
      document = Nokogiri::HTML(document_html)
      organisation_hash = digest(document)
      save(organisation_hash)
    end

    def digest(doc)
      ico = name = place = date_start = date_end = address = region = ''

      trs = doc.css(".detailTable tr.detailTableRow")

      ico = trs[0].css("td.detailValue").first.text.strip
      name = trs[1].css("td.detailValue").first.text.strip
      address = trs[4].css("td.detailValue").first.text.strip
      region = parse_district_name trs[5].css("td.detailValue").first.text.strip
      place = parse_place_name trs[6].css("td.detailValue").first.text.strip

      date_start = trs[2].css("td.detailValue").first.text.strip
      date_end = trs[3].css("td.detailValue").first.text.strip

      legal_form = activity1 = activity2 = account_sector = ownership = size = ''
      legal_form = parse_code trs[7].css("td.detailValue").first.text.strip
      activity1 = parse_code trs[8].css("td.detailValue").first.text.strip
      account_sector = parse_code trs[9].css("td.detailValue").first.text.strip
      ownership = parse_code trs[10].css("td.detailValue").first.text.strip
      size = parse_code trs[11].css("td.detailValue").first.text.strip

      date_start = Date.parse(date_start) rescue nil
      date_end = Date.parse(date_end) rescue nil

      {:doc_id => id,
       :ico => ico,
       :name => name,
       :legal_form => legal_form,
       :date_start => date_start,
       :date_end => date_end,
       :address => address,
       :place => place,
       :region => region,
       :activity1 => activity1,
       :activity2 => activity2,
       :account_sector => account_sector,
       :ownership => ownership,
       :size => size,
       :date_created => Time.now,
       :source_url => document_url}
    end

    def save(procurement_hash)
      Staging::StaRegisMain.create(procurement_hash)
    end

    private

    def parse_district_name(district_name)
      matches = district_name.match(/(.)*(\ )-(\ )Okres(.*)/)
      matches ? matches[4].strip : district_name
    end

    def parse_place_name(place_name)
      matches = place_name.match(/^(..)([A-Z0-9]*)(\ )-(\ )(.*)/)
      matches ? matches[5].strip : ''
    end

    def parse_date(date_str)
      Date.parse(date_str) rescue nil
    end

    def parse_code(code)
      matches = code.match(/(.*)(\ )-(\ )(.*)/)
      code = matches ? matches[1] : nil
      if code == 'xxxxx'
        nil
      elsif code.present?
        code.to_i
      else
        nil
      end
    end

  end
end
