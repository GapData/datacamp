# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class LawyerExtraction
    attr_reader :url

    def initialize(url, reset_url = nil, cookie = nil, parent_url = nil, filter = nil)
      @url, @reset_url, @cookie, @parent_url, @filter = url, reset_url, cookie, parent_url, filter
    end

    def is_acceptable?(document)
      document.xpath("//div[@class='section']/table[@class='filter']").present?
    end

    def download
      if @parent_url.present? && @cookie.present? && @reset_url
        Typhoeus::Request.get(@reset_url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true)
        Typhoeus::Request.get(@parent_url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true)
      end
      Nokogiri::HTML( Typhoeus::Request.get(@url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true).body )
    end

    def digest(doc)
      lawyer_table = doc.xpath("//div[@class='section']/table[@class='filter']").first

      original_name = lawyer_table.xpath('./tr[1]/td[2]').inner_text.strip
      match_data = original_name.match(/(?<last_name>[^\s]+)\s+(?<first_name>[^\s]+)(\s+(?<title>[^\s]+))*/)
      sak_id = (@url.match(/\d+/)[0].to_i rescue nil)
      {
        :original_name => original_name,
        :first_name => "#{match_data[:first_name].mb_chars.capitalize}",
        :last_name => "#{match_data[:last_name].mb_chars.capitalize}",
        :title => match_data[:title],
        :lawyer_type => lawyer_table.xpath('./tr[2]/td[2]').inner_text.strip,
        :street => lawyer_table.xpath('./tr[3]/td[2]').inner_text.strip,
        :city => lawyer_table.xpath('./tr[4]/td[2]').inner_text.strip,
        :zip => lawyer_table.xpath('./tr[5]/td[2]').inner_text.strip,
        :phone => lawyer_table.xpath('./tr[6]/td[2]').inner_text.strip,
        :fax => lawyer_table.xpath('./tr[7]/td[2]').inner_text.strip,
        :cell_phone => lawyer_table.xpath('./tr[8]/td[2]').inner_text.strip,
        :languages => lawyer_table.xpath('./tr[9]/td[2]').inner_text.strip,
        :email => lawyer_table.xpath('./tr[10]/td[2]').inner_text.strip,
        :website => (lawyer_table.xpath('./tr[11]/td[2]/a').first.attributes['href'].value rescue nil),
        :url => @url,
        :sak_id => sak_id,
        :is_part_of_import => true
      }
    end

    def perform
      document = download
      if is_acceptable?(document)
        lawyer_hash = digest(document)
        save(lawyer_hash)
      end
    end

    def save(lawyer_hash)
      lawyer = Kernel::DsLawyer.find_or_initialize_by_sak_id(lawyer_hash[:sak_id])
      lawyer.update_attributes!(lawyer_hash)
    end

    def get_downloads
      id = 0
      downloads = []
      begin
        doc_data = Typhoeus::Request.get(@url + id.to_s, disable_ssl_peer_verification: true)
        cookie = doc_data.headers_hash['Set-Cookie'].match(/[^ ;]*/)[0]
        doc = Nokogiri::HTML( doc_data.body )
        downloads << parse_for_links(doc, @reset_url, cookie, @url + id.to_s, @filter)
        id += 10
      end while doc.xpath("//div[@class='buttonbar']/table//tr[1]//td[@style='opacity: 0.5']").inner_html.match(/but_arrow_right.gif/).blank?
      downloads.flatten
    end

    def get_ids_from_downloads
      get_downloads.map{ |d| (d.url.match(/\d+/)[0].to_i rescue nil) }
    end

    def parse_for_links(doc, reset_url, cookie, parent_url, filter)
      doc.xpath("//div[@class='result']/table//a").map do |link|
        Etl::LawyerExtraction.new("https://www.sak.sk/#{link.attributes['href'].value.match(/'(.*)'/)[1]}", reset_url, cookie, parent_url, filter)
      end
    end

  end
end
