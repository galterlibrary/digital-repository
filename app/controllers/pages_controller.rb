class PagesController < ApplicationController
  def show
    unless [
      'help_page', 'terms_page', 'agreement_page', 'news_page', 'about_page'
    ].include?(params[:id])
      raise ActionController::RoutingError.new('Not Found') and return
    end

    @page = ContentBlock.find_or_create_by(name: params[:id])
    render 'tiny_mce_page'
  end
end
