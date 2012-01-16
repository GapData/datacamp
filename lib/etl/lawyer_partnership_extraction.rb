# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class LawyerPartnershipExtraction
    attr_reader :url
    
    def initialize(url, reset_url = nil, cookie = nil, parent_url = nil, filter = nil)
      @url, @reset_url, @cookie, @parent_url, @filter = url, reset_url, cookie, parent_url, filter
    end
    
    def download
      if @parent_url.present? && @cookie.present? && @reset_url
        Typhoeus::Request.get(@reset_url, :headers => {'Cookie' => @cookie})
        Typhoeus::Request.get(@parent_url, :headers => {'Cookie' => @cookie})
      end
      Nokogiri::HTML( Typhoeus::Request.get(@url, :headers => {'Cookie' => @cookie}).body )
    end
    
    def is_acceptable?(document)
      document.xpath("//div[@class='section']/table[@class='filter']").present?
    end
    
    def perform
      document = download
      if is_acceptable?(document)
        lawyer_partnership_hash = digest(document)
        save(lawyer_partnership_hash)
      end
    end
    
    def digest(doc)
      lawyer_partnership_table = doc.xpath("//div[@class='section']/table[@class='filter']").first
      
      lawyer_sak_links = lawyer_partnership_table.xpath(".//div[@class='section']//table[1]//a")
      lawyer_sak_ids = lawyer_sak_links.map{ |link| link.attributes['href'].value.match(/\d+/); $&; }
      lawyers = Dataset::DsLawyer.find_all_by_sak_id(lawyer_sak_ids)
      
      associate_sak_names = lawyer_partnership_table.xpath(".//div[@class='section']")[1].xpath('.//table//tr/td[2]')
      associates = associate_sak_names.map do |aname| 
        associate = Dataset::DsAssociate.find_by_original_name(aname.inner_text.strip)
        if associate.blank?
          associate_params = aname.inner_text.strip.match(/(?<first_name>[^\s]+)\s+(?<last_name>[^\s]+)(\s+(?<title>[^\s]+))*/)
          associate = Dataset::DsAssociate.create!(original_name: aname.inner_text.strip, first_name: associate_params[:first_name], last_name: associate_params[:last_name], title: associate_params[:title], is_part_of_import: true)
        end
        associate
      end
      
      sak_id = (@url.match(/\d+/)[0].to_i rescue nil)
      {
        :name => lawyer_partnership_table.xpath('./tr[1]/td[2]').inner_text.strip,
        :partnership_type => lawyer_partnership_table.xpath('./tr[2]/td[2]').inner_text.strip,
        :registry_number => lawyer_partnership_table.xpath('./tr[3]/td[2]').inner_text.strip,
        :ico => lawyer_partnership_table.xpath('./tr[4]/td[2]').inner_text.strip,
        :dic => lawyer_partnership_table.xpath('./tr[5]/td[2]').inner_text.strip,
        :street => lawyer_partnership_table.xpath('./tr[6]/td[2]').inner_text.strip,
        :city => lawyer_partnership_table.xpath('./tr[7]/td[2]').inner_text.strip,
        :zip => lawyer_partnership_table.xpath('./tr[8]/td[2]').inner_text.strip,
        :phone => lawyer_partnership_table.xpath('./tr[9]/td[2]').inner_text.strip,
        :fax => lawyer_partnership_table.xpath('./tr[10]/td[2]').inner_text.strip,
        :cell_phone => lawyer_partnership_table.xpath('./tr[11]/td[2]').inner_text.strip,
        :email => lawyer_partnership_table.xpath('./tr[12]/td[2]').inner_text.strip,
        :website => (lawyer_partnership_table.xpath('./tr[13]/td[2]/a').first.attributes['href'].value rescue nil),
        :sak_id => sak_id,
        :ds_lawyers => lawyers,
        :ds_associates => associates,
        :url => @url,
        :is_part_of_import => true
      }
    end
    
    def save(lawyer_partnership_hash)
      lawyer_partnership = Dataset::DsLawyerPartnership.find_or_initialize_by_sak_id(lawyer_partnership_hash[:sak_id])
      lawyer_partnership.update_attributes!(lawyer_partnership_hash)
    end
    
    def get_downloads
      id = 0
      downloads = []
      begin
        doc_data = Typhoeus::Request.get(@url + id.to_s)
        cookie = doc_data.headers_hash['Set-Cookie'].match(/[^ ;]*/)[0]
        doc = Nokogiri::HTML( doc_data.body )
        downloads << parse_for_links(doc, @reset_url, cookie, @url + id.to_s, @filter)
        id += 10
      end while doc.xpath("//div[@class='buttonbar']/table//tr[1]//td[@style='opacity: 0.5']").inner_html.match(/but_arrow_right.gif/).blank?
      downloads.flatten
    end
    
    def parse_for_links(doc, reset_url, cookie, parent_url, filter)
      doc.xpath("//div[@class='result']/table//a").map do |link|
        Etl::LawyerPartnershipExtraction.new("https://www.sak.sk/#{link.attributes['href'].value.match(/'(.*)'/)[1]}", reset_url, cookie, parent_url, filter)
      end
    end
    
  end
end