class PagesController < ApplicationController
  def show
    @page = ContentBlock.find_or_create_by( name: params[:id])
    render 'tiny_mce_page'
  end
end
