# -*- encoding : utf-8 -*-
# Datasets Controller
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

class DatasetsController < ApplicationController
  include CommentsLoader
  
  before_filter :prepare_filters, :only => [:show]
  privilege_required :edit_record, :only => [:update]
  
  helper_method :has_filters?
  
  def index
    @all_dataset_descriptions = DatasetDescription.where("is_active = 1")
    @dataset_descriptions = @all_dataset_descriptions.group_by(&:category)
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @all_dataset_descriptions }
    end
  end
  
  def show    
    @dataset_description = DatasetDescription.find_by_id!(params[:id])
    @field_descriptions  = @dataset_description.visible_field_descriptions
    @dataset             = @dataset_description.dataset
    @dataset_class       = @dataset.dataset_record_class
    
    unless @dataset_class.table_exists?
      logger.error "Dataset table doesn't exist for #{@dataset_description.title} (#{@dataset_class.table_name})"
      flash[:error] = I18n.t("dataset.internal_dataset_error", :title => @dataset_description.title)
      return redirect_to datasets_path
    end
    
    unless @dataset.has_pk?
      logger.error "Dataset is missing PK _record_id: #{@dataset_description.title} (#{@dataset_description.identifier})"
      flash[:error] = I18n.t("dataset.internal_dataset_error", :title => @dataset_description.title)
      return redirect_to datasets_path
    end
    
    # Comments
    load_comments
    
    # Favorite if there's one
    @favorite = current_user.favorite_for!(@dataset_description, @record) if current_user
    
    # Add pagination stuff to those options
    paginate_options = {}
    paginate_options[:page] = params[:page] ? params[:page] : nil
    paginate_options[:per_page] = current_user ? current_user.records_per_page : RECORDS_PER_PAGE
    paginate_options[:total_entries] = ((params[:page].to_i||1)+9) * paginate_options[:per_page]
    
    @records = create_query_from_params(@dataset_class).paginate(paginate_options)
    
    # This conditions checks if we've reached end of our huge
    # list.
    if params[:page] && params[:page].to_i > 1 && @records.count == 0
      count = @dataset_class.count_by_sql(create_query_from_params(@dataset_class).order('').select("COUNT(1)").to_sql)
      paginate_options[:total_entries] = count
      paginate_options[:page] = (count.to_f/paginate_options[:per_page].to_f).ceil
      @records = create_query_from_params(@dataset_class).paginate(paginate_options)
    end
    
    # Extra javascripts
    add_javascript('datasets/search.js')
    
    respond_to do |wants|
      wants.html { 
        #check to see if user can view the records if the dataset is
        if !@dataset_description.is_active? && !has_privilege?(:view_hidden_records)
          flash[:notice] = 'Dataset is hidden'
          redirect_to :action => 'index'
        else
          render :action => "show" 
        end
      }
      wants.xml { 
        if !@dataset_description.is_active? && !has_privilege?(:view_hidden_records)
          render :xml => 'Dataset is hidden'
        else
          render :xml => @records 
        end
      }
      wants.json { 
        if !@dataset_description.is_active? && !has_privilege?(:view_hidden_records)
          render :json => 'Dataset is hidden'
        else
          render :json => @records 
        end
      }
      wants.js do
        if !@dataset_description.is_active? && !has_privilege?(:view_hidden_records)
          return render :js => 'Dataset is hidden'
        else
          return render :template => "datasets/admin/show" if current_user && current_user.has_privilege?(:data_management)
          return render :action => "show"
        end
      end
    end
  end
  
  # Batch update
  def update
    @dataset_description = DatasetDescription.find_by_id(params[:id])
    @dataset_class        = @dataset_description.dataset.dataset_record_class
    unless params[:record]
      flash[:error] = I18n.t("dataset.not_enough_records_selected")
      return redirect_to(dataset_path(@dataset_description)) 
    end
      
    # Conditions for update
    update_conditions = {}
        
    if(params[:selection] == "selected")
      # The easier case. User used checkboxes to choose what
      # records they want to edit.
       update_conditions[:_record_id] = params[:record].collect{|id|id.to_i}
       @count_updated = params[:record].count
    elsif(params[:selection] == "all" && params[:search_id])
      # Case when all search matching records should be edited.
      # We wanna get all the ids of matching records and
      # pass them to update statement.
      
      select_options = create_options_for_select
      select_options[:select] = "#{@dataset_class.table_name}._record_id"
      ids = @dataset_class.where(select_options).collect{|r|r._record_id}
      update_conditions[:_record_id] = ids
      @count_updated = ids.count
    elsif(params[:selection] == "all" && params[:search_id].blank?)
      # User has chosen to edit all records and to search is
      # specified. We just won't pass any options to update statement
      # and just update whole dataset.
      @count_updated = @dataset_class.count_all
    end
    
    updates = {}
    updates[:record_status] = params[:status] unless params[:status].blank?
    updates[:quality_status] = params[:quality] unless params[:quality].blank?
    
    # Update attributes (only if using batch edit form)
    if params[:update_attribute] && params[:attribute_value]
      params[:update_attribute].each do |attr_name|
        updates[attr_name] = params[:attribute_value][attr_name]
      end
    end
  
    @dataset_class.update_all(updates, update_conditions)

    flash[:notice] = I18n.t("dataset.batch_updated", :count => @count_updated)
    params.delete(:search_id) if params[:search_id].blank? #FIXME: ewww ugly!
    return redirect_to(dataset_path(@dataset_description, :search_id => params[:search_id]))
  end
  
  def batch_edit
    @dataset_description = DatasetDescription.find_by_id(params[:id])
    @dataset_class        = @dataset_description.dataset.dataset_record_class
    @field_descriptions  = @dataset_description.visible_field_descriptions
  end
  
  def sitemap
    # TODO implement .. somehow ..
  end
  
  protected
  
  def create_query_from_params(dataset_class)
    ### Options for order
    if params[:sort]
      sort_direction = params[:dir] || "asc"
      dataset_class = dataset_class.order("#{params[:sort]} #{sort_direction}").where("#{params[:sort]} IS NOT NULL")
    end
    
    ### Options for search
    unless params[:search_id].blank?
      search_object = Search.find_by_id!(params[:search_id])
      @search_predicates = search_object.query.predicates
      search_query_id = search_object.query.id
      dataset_class = dataset_class.
            from("#{SearchResult.connection.current_database}.search_results").
            joins("LEFT JOIN #{@dataset_class.table_name} ON search_results.record_id = #{@dataset_class.table_name}._record_id").
            select("#{@dataset_class.table_name}.*").
            where("search_results.search_query_id = #{@dataset_class.sanitize(search_query_id)}").
            where("search_results.table_name = #{@dataset_class.sanitize(@dataset_description.identifier)}")
    else
      dataset_class = dataset_class.from @dataset_class.table_name
    end
    
    ### Options for filter
    if @filters
      filters = @filters.find_all{|key,value|!value.blank?}
      filters.each do |key, value|
        dataset_class = dataset_class.where("#{key} = #{@dataset_class.sanitize(value)}")
      end
      # raise select_options.to_yaml
    end
    
    dataset_class
  end
  
  def create_options_for_select()
    select_options = {}
    select_options[:conditions] = []
    
    ### Options for order
    if params[:sort]
      sort_direction = params[:dir] || "asc"
      select_options[:order] = "#{params[:sort]} #{sort_direction}"
      select_options[:conditions] << "#{params[:sort]} IS NOT NULL"
    end
    
    
    ### Options for search
    unless params[:search_id].blank?
      search_object = Search.find_by_id!(params[:search_id])
      @search_predicates = search_object.query.predicates
      search_query_id = search_object.query.id
      select_options[:from] = "#{SearchResult.connection.current_database}.search_results"
      select_options[:joins] = "LEFT JOIN #{@dataset_class.table_name} ON search_results.record_id = #{@dataset_class.table_name}._record_id"
      select_options[:select] = "#{@dataset_class.table_name}.*"
      select_options[:conditions] << "search_results.search_query_id = #{@dataset_class.sanitize(search_query_id)}"
      select_options[:conditions] << "search_results.table_name = #{@dataset_class.sanitize(@dataset_description.identifier)}"
    else
      select_options[:from] = @dataset_class.table_name
    end
    
    ### Options for filter
    if @filters
      filters = @filters.find_all{|key,value|!value.blank?}
      filters.each do |key, value|
        select_options[:conditions] << "#{key} = #{@dataset_class.sanitize(value)}"
      end
      # raise select_options.to_yaml
    end
    
    ### Filtering for those with insufficient privileges
    unless has_privilege?(:view_hidden_records)
      select_options[:finder] = 'active'
    end
    
    select_options
  end
  
  # Creates SQL query from set of options for query.
  # If order is specified, it will create 2 queries and connect
  # them with union, to speed up sorting.
  def create_query_from_options(options)
    query = @dataset_class.options_to_sql(options)
    
    query
  end
  
  def prepare_filters
    if params[:clear_filters]
      @filters = {}
    else
      @filters = params[:filters] || {}
    end
    session[:filters] = @filters
  end
  
  def has_filters?
    @filters && !@filters.empty?
  end
end
