class GalterContentBlocksController < ApplicationController
  load_and_authorize_resource class: 'ContentBlock',
                              instance_name: 'content_block'

  def destroy
    @content_block.destroy
    redirect_to root_path
  end

  def refeature_researcher
    @content_block.created_at = Time.zone.now
    @content_block.save!
    redirect_to root_path
  end
end
