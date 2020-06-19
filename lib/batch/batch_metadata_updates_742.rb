require "#{Rails.root}/lib/batch/batch_update_subject_geographic"

# Updates to Subject Geographic field values
# for https://github.com/galterlibrary/digital-repository/issues/742

# 'Ayn al-Turk (Algeria)
puts "Subject Geographic Update: 'Ayn al-Turk (Algeria)"
ayn_solr_query = "ayn"
ayn_old_terms = ["ayn al-turk", "ayn al-turk (algeria)"]
ayn_new_term = "'Ayn al-Turk (Algeria)"
batch_update_subject_geographic(
  solr_query: ayn_solr_query,
  old_terms: ayn_old_terms,
  new_term: ayn_new_term
)

# Livorno (Italy)
puts "Subject Geographic Update: Livorno (Italy)"
livorno_solr_query = "livorno"
livorno_old_terms = ["italy--livorno"]
livorno_new_term = "Livorno (Italy)"
batch_update_subject_geographic(
  solr_query: livorno_solr_query,
  old_terms: livorno_old_terms,
  new_term: livorno_new_term
)

# Naples (Italy)
puts "Subject Geographic Update: Naples (Italy)"
naples_solr_query = "naples"
naples_old_terms = ["italy--naples"]
naples_new_term = "Naples (Italy)"
batch_update_subject_geographic(
  solr_query: naples_solr_query,
  old_terms: naples_old_terms,
  new_term: naples_new_term
)

# Fort Custer (Mich.)
puts "Subject Geographic Update: Fort Custer (Mich.)"
fortcuster_solr_query = "fort custer"
fortcuster_old_terms = ["michigan--fort custer"]
fortcuster_new_term = "Fort Custer (Mich.)"
batch_update_subject_geographic(
  solr_query: fortcuster_solr_query,
  old_terms: fortcuster_old_terms,
  new_term: fortcuster_new_term
)
