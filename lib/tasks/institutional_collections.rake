namespace :institutional do
  # Example of converting a collection tree
  #   rake institutional:convert_collection_tree[collection_id,institutional-depositor]
  #   rake institutional:convert_collection_tree[collection_id,institutional-depositor,Some-Root-Admin]
  desc 'Convert a collection tree to institutional type'
  task :convert_collection_tree, [:id, :depositor, :root_admin] => :environment do |t, args|
    root = Collection.find(args[:id])
    unless args[:depositor].to_s.include?('institutional-')
      raise "Depositor #{args[:depositor]} has to start with `institutional-`"
    end

    raise "Root node #{root.title} connot have more then one parent" if root.collections.count > 1
    root.convert_to_institutional(
      args[:depositor],
      root.collections.first.try(:id),
      args[:root_admin]
    )
  end

  # Example of normalizing an institutional collection tree
  #   rake institutional:normalize_collection_tree[collection_id,institutional-depositor]
  #   rake institutional:normalize_collection_tree[collection_id,institutional-depositor,Some-Root-Admin]
  desc 'Normalize institutional tree'
  task :normalize_collection_tree, [:id, :depositor, :root_admin] => :environment do |t, args|
    root = Collection.find(args[:id])
    if args[:depositor].present? && !args[:depositor].include?('institutional-')
      raise "Depositor #{args[:depositor]} has to start with `institutional-`"
    end

    parent_id = root.collections.count > 1 ? nil : root.collections.first.try(:id)
    root.normalize_institutional(args[:depositor], args[:root_admin], parent_id)
  end
end
