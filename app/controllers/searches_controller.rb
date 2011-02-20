# -*- encoding : utf-8 -*-
# Searches Controller
#
# Copyright:: (C) 2009 Knowerce, s.r.o.
# 
# Author:: Vojto Rinik <vojto@rinik.net>
# Date: Sep 2009
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class SearchesController < ApplicationController
  
  before_filter do |controller|
    controller.add_javascript('datasets/search.js')
  end
  
  def new

  end
  
  ########################################################################
  # Search/Create -> Creates new search spicified by one of the following
  # parameters:
  # 1. query_string -> global search for one string. This way only 5 results
  #                    from each dataset are loaded. After search user is redi-
  #                    rected to search/show with results.
  # 2. predicates   -> dataset-wide search specified by predicates array. This
  #                    search will include all results from a dataset. User
  # =>                 will be redirected back to dataset/view.

  def create
    # @engine = SearchEngine.new
    # @engine.delegate = self
    # 
    # search_params = params[:search] || {}
    # 
    # unless params[:query_string].blank?
    #   search_params[:query_string] = params[:query_string]
    # end
    # 
    #  # Check if we're searching with query or predicates
    # if !search_params[:query_string].blank?
    #   search = @engine.create_global_search_with_string(params[:query_string])
    # elsif search_params[:predicates]
    #   @predicates = create_predicates_from_hash(search_params[:predicates])
    #   search = @engine.create_dataset_search_with_predicates(@predicates, search_params[:dataset])
    # else
    #   return redirect_to new_search_path
    # end
    # 
    # return redirect_to new_search_path unless search
    # 
    # search.session = @current_session
    # search.save
    # 
    # if search.query.scope == "dataset"
    #   # @engine.perform_search(search)
    #   dataset = DatasetDescription.find_by_identifier(search.query.object)
    #   redirect_to dataset_path(dataset, :search_id => search.id)
    # else
    #   @engine.perform_search(search, :dataset_limit => 5)
    #   redirect_to search_path(search)
    # end
    search_params = params[:search] || {}
    if search_params[:predicates]
      query = SearchQuery.query_with_predicates(create_predicates_from_hash(search_params[:predicates]), :scope=>"dataset", :object => search_params[:dataset])
      search = Search.create(:query => query, :search_type => 'predicates', :session => @current_session)
      redirect_to dataset_path(DatasetDescription.find_by_identifier(search.query.object), :search_id => search.id) 
    else
      redirect_to datasets_path, :notice => 'Something went wrong...'
    end
  end
  
  ########################################################################
  # This method is used to get more results for a search and dataset.
  # Basically, it will take an exiting search and run perform_search again
  # but this time with no limit.
  #
  # It's useful because global search includes only 5 results and if user wants
  # to see more from a dataset, they have to broade
    
  def broaden
    @engine = SearchEngine.new
    @engine.delegate = self
    
    @search = Search.find_by_id!(params[:id])
    @dataset = DatasetDescription.find_by_id!(params[:dataset_description_id])
    
    @search.session = @current_session
    @search.save
    
    # 1. Remove those 5 results for this dataset from previous search.
    # We're gonna search this dataset again and reload all results for this
    # dataset and if we left those one here it, there would be duplicates.
    temporary_results = @search.query.results.where(:table_name => @dataset.identifier)
    temporary_results.each{|record|record.destroy}
    
    @engine.perform_search(@search, {:dataset => @dataset.identifier})
    redirect_to dataset_path(@dataset, :search_id => @search.id)
  end
  
  ########################################################################
  # Quick search using Sphinx. If Sphinx search engine couldn't be used
  # redirect to regular search.
  def quick
    query = params[:query_string]
    engine = SphinxSearchEngine.new
    search = engine.create_search_with_string(query)
    # engine.perform_search(search)
    redirect_to search_path(search, :disabled_descriptions => params[:disabled_descriptions])
  end
  
  def show
    @search = Search.find_by_id! params[:id]
    @disabled_descriptions = params[:disabled_descriptions]

    @results = {}
    DatasetCategory.all.each do |dataset_category|
      if params[:disabled_descriptions]
        dds = dataset_category.dataset_descriptions.where('id NOT IN(?)', params[:disabled_descriptions]) 
      else
        dds = dataset_category.dataset_descriptions
      end
      dds.each do |dataset_description|
        dataset_results = dataset_description.dataset.dataset_record_class.search @search.query_string, :limit => 5
        @results[dataset_category] ||= {} and @results[dataset_category].merge!({dataset_description=>dataset_results}) if dataset_results.present?
      end
    end
  end
  
  def search_failed(type, error_message)
    # flash[:notice] = I18n.t("errors.warning", :details => error_message)
    flash_type = :notice
    flash_type = :error if [:error].include?(type)
	# FIXME: LOCALIZE: errors.search_internal_error
    flash[flash_type] = "There was problem with your search: #{error_message}"
  end
  
  protected
  
  def create_predicates_from_hash(hash)
    hash.collect do |predicate|
      SearchPredicate.create({:scope => "record", :search_field => predicate[:field], :operator => predicate[:operator], :argument => predicate[:value]})
    end
  end
  
  def clone_predicates(predicates)
    predicates.collect{|predicate|predicate.clone}
  end
end
