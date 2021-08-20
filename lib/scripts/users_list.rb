require 'csv'

class UsersList
  attr_accessor :csv_file

  def initialize
    @csv_file = File.new("#{Rails.root}/lib/scripts/results/users_list.csv", "w+")
  end

  def populate_user_info
    CSV.open(self.csv_file.path, "w") do |csv|
      # add headers
      csv << ['Formal Name', 'NetID', 'Email', 'Title', 'Address', 'Current Sign In', 'Last Sign In', 'Total Files Deposited', 'Last Deposit Date']

      select_all_users.find_in_batches do |users_batch|
        users_batch.each do |user|
          solr_results = solr_query_by_depositor(user.username).sort_by { |result| result["date_uploaded_dtsi"] }
          count = solr_results.count
          csv << [user.formal_name, user.username, user.email, user.title,
                  user.address, user.current_sign_in_at, user.last_sign_in_at,
                  count, last_upload_date(solr_results, count)]
        end
      end
    end # end block, CSV closes
  end

  private
  def select_all_users
    User.all.select(:id, :formal_name, :username, :email, :title, :address,
                    :current_sign_in_at, :last_sign_in_at)
  end

  def solr_query_by_depositor(depositor)
    ActiveFedora::SolrService.query("depositor_ssim:\"#{depositor}\"", rows: 9999)
  end

  def last_upload_date(result, count)
    if !result.empty?
      result[count - 1]["date_uploaded_dtsi"]
    else
      "No File Uploaded"
    end
  end
end
