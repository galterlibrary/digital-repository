class IndexFullText < ActiveRecord::Migration
  def change
    GenericFile.where('has_model_ssim' => 'GenericFile').each do |gf|
      gf.characterize
      gf.save!
    end
  end
end
