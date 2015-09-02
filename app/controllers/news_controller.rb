class NewsController < ApplicationController

  def index
    @news = News.published.all
  end

  def show
    @news_item = News.find(params[:id])
  end
end
