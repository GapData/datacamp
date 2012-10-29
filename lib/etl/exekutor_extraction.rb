# -*- encoding : utf-8 -*-

module Etl
  class ExekutorExtraction

    def document_url
      "http://www.ske.sk/ExecutorList/"
    end

    def download
      Nokogiri::HTML(Typhoeus::Request.get(document_url).body)
    end

    def self.update_last_run_time
      EtlConfiguration.find_by_name('executor_extraction').update_attribute(:last_run_time, Time.now)
      DatasetDescription.find_by_identifier('executors').update_attribute(:data_updated_at, Time.zone.now)
    end

    def is_acceptable?(document)
      document.xpath("//div[@id='main']").present?
    end

    def elements_to_parse_count
      download.xpath("//div[@id='main']/div").count
    end

    def digest(doc)
      doc.xpath("//div[@id='main']/div").map do |list_item|
        address = (list_item.inner_html.match(/<strong>Adresa:<\/strong>(?<address> .*?)<br>/)[:address].strip rescue nil)
        if address
          street = address.split(',').first
          city = address.split(',').last.match(/(?<zip>\d+ \d+|\d+)\s?(?<city>[^\d]+\d?)/)[:city] if address.split(',').last.match(/(?<zip>\d+ \d+|\d+)\s?(?<city>[^\d]+\d?)/).present?
          zip = address.split(',').last.match(/(?<zip>\d+ \d+|\d+)/)[:zip] if address.split(',').last.match(/(?<zip>\d+ \d+)/).present?
        end
        {
          :name => list_item.xpath("./h5").inner_text.strip,
          :street => street,
          :zip => zip,
          :city => city,
          :telephone => (list_item.inner_html.match(/<strong>Tel.:<\/strong>(?<tel> .*?)<br>/)[:tel].strip rescue nil),
          :fax => (list_item.inner_html.match(/<strong>Fax:<\/strong>(?<fax> .*?)<br>/)[:fax].strip rescue nil),
          :email => (list_item.inner_html.match(/<strong>E-mail:<\/strong>(?<email> [^ @]+@[^ @]+\.[a-zA-Z]{2,4})/)[:email].strip rescue nil)
        }
      end
    end


    def save(executors_hash)
      Kernel::DsExecutor.update_all(record_status: 'suspended')
      active_executor_ids = executors_hash.map do |executor_hash|
        executor = Kernel::DsExecutor.find_or_initialize_by_name_and_city(executor_hash[:name], executor_hash[:city])
        executor.update_attributes(executor_hash)
        executor.id
      end
      Kernel::DsExecutor.where(_record_id: active_executor_ids).update_all(record_status: 'published')
    end

    def perform
      document = download
      if is_acceptable?(document)
        executors_hash = digest(document)
        save(executors_hash)
      end
    end

  end
end
