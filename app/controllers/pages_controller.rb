class PagesController < ApplicationController
  def home; end
  def solutions; end
  def data_coverage; end
  def how_it_works; end
  def about; end
  def blog
    @posts = Post.published
  end
  def contact; end
end
