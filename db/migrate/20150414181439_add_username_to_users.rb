class AddUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string
    add_column :users, :remember_token, :string
    add_index :users, :remember_token, unique: true
    add_index :users, :username, unique: true

    User.all.each do |u|
      username = Nuldap.new.search("mail=#{u.email}")[1]['uid'].try(:first)
      username ||= u.email.gsub(/@.*/, '')
      puts "Setting NetID for '#{u.email}' to '#{username}'"
      u.username = username
      u.save!

      GenericFile.where('depositor_ssim' => u.email).each do |gf|
        gf.apply_depositor_metadata(username)
        gf.save!
      end

      Collection.where('depositor_ssim' => u.email).each do |gf|
        gf.apply_depositor_metadata(username)
        gf.save!
      end
    end
  end
end
