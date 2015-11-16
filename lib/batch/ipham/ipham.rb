CENTERS = [
  'Behavior and Health',
  'Buehler Center on Aging, Health and Society',
  'Community Health',
  'Communication and Health',
  'Education in Health Sciences',
  'Engineering and Health',
  'Global Health',
  'Health Information Partnerships',
  'Healthcare Studies',
  'Patient-Centered Outcomes',
  'Population Health Sciences',
  'Primary Care Innovation',
  'Translational Metabolism and Health'
]

FILE_NAMES = [
  'Behavior & Health.xlsx.csv',
  'Buehler.xlsx.csv',
  'Communication and Health.xlsx.csv',
  'Community Health.xlsx.csv',
  'Education in Health Sciences.xlsx.csv',
  'Engineering and Health.xlsx.csv',
  'Global Health.xlsx.csv',
  'Healthcare Studies.xlsx.csv',
  'Health Information Partnerships.xlsx.csv',
  'Patient Centered Outcomes.xlsx.csv',
  'Population Health Sciences.xlsx.csv',
  'Primary Care Innovation.xlsx.csv',
  'Translational Metabolism and Health.xlsx.csv'
]

def netid_in_ldap?(netid)
  return true
  ldap = Nuldap.new.search("uid=#{netid}")
  if ldap[0]
    if ldap[1]['uid'].blank?
      puts "Netid: #{netid} not found in LDAP"
      return false
    end
  else
    raise 'Bad LDAP'
  end
  true
end

def netids_in_csv(filename)
  CSV.foreach("#{Rails.root}/lib/batch/ipham/#{filename}",
              headers: true) do |row|
    next if row['netid'].blank?
    netid = row['netid'].strip.downcase
    next if %w(bar499 rkk654 ekj703 jwt810 curry arl019 mlc926).index(netid)
    next unless netid_in_ldap?(netid)
    yield netid
  end
end

def find_or_crete_user(netid)
  user = User.find_by(username: netid)
  if user.blank?
    user = User.new(username: netid)
    user.populate_attributes
    user.save!
  end
  user
end

def find_center_admins(center)
  ['qew348', 'pls126'].map {|netid| find_or_crete_user(netid) }
end

def find_center_users(center)
  filename = FILE_NAMES[CENTERS.index(center)]
  netids_in_csv(filename) {|netid| yield find_or_crete_user(netid) }
end

def add_group_to_collection(collection, role, perm)
  permission = collection.permissions.to_a.find {|perm|
    perm.agent_name == role
  }
  if permission.blank?
    collection.permissions.create(type: 'group', name: role, access: perm)
  end
end

User.find_or_create_by(username: 'ipham-system')
User.find_or_create_by(username: 'ipham-top-system', email: 'a@b.c')
Role.find_or_create_by(name: 'IPHAM-Admin', description: 'IPHAM-Admin',)

begin
  institute = Collection.find('ipham')
rescue ActiveFedora::ObjectNotFoundError
  institute = Collection.new(
    title: 'Institute for Public Health and Medicine', id: 'ipham')
rescue Ldp::Gone
  Collection.eradicate('ipham')
end
institute.tag = ['ipham']
institute.apply_depositor_metadata('ipham-system-top')
institute.save!

CENTERS.each do |center_name|
  id = center_name.tr(' ', '-').tr(',', '').downcase
  begin
    center = Collection.find(id)
  rescue ActiveFedora::ObjectNotFoundError
    center = Collection.new(title: center_name, id: id)
  rescue Ldp::Gone
    Collection.eradicate(id)
  end
  center.tag = ['ipham']
  center.apply_depositor_metadata('ipham-system')
  center.save!

  institute.members << center

  role_name = center_name.tr(' ', '-').tr(',', '')
  Role.find_or_create_by(name: role_name, description: role_name)
  admin_role_name = role_name + '-Admin'
  Role.find_or_create_by(
    name: admin_role_name, description: admin_role_name)

  add_group_to_collection(center, admin_role_name, 'edit')
  add_group_to_collection(center, role_name, 'edit')
  add_group_to_collection(center, 'IPHAM-Admin', 'edit')
  find_center_admins(center_name).each do |admin|
    admin.add_role(admin_role_name)

    find_center_users(center_name) do |user|
      user.add_role(role_name)
      ProxyDepositRights.find_or_create_by(
        grantor_id: user.id, grantee_id: admin.id)
    end
  end
end

institute.save!
