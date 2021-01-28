module Galtersufia
  module GenericFile
    module HeaderLookup
      extend ActiveSupport::Concern

      BASE_SPARQL_MESH_URI ="https://id.nlm.nih.gov/mesh/sparql?format=JSON&limit=10&inference=true&query=PREFIX%20rdfs"\
        "%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23%3E%0D%0APREFIX%20meshv%3A%20%3Chttp%3A%2F%2Fid.nlm."\
        "nih.gov%2Fmesh%2Fvocab%23%3E%0D%0APREFIX%20mesh2018%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0A%0D%0ASELECT"\
        "%20%3Fd%20%3FdName%0D%0AFROM%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0AWHERE%20%7B%0D%0A%20%20%3Fd%20a%20"\
        "meshv%3ADescriptor%20.%0D%0A%20%20%3Fd%20rdfs%3Alabel%20%3FdName%0D%0A%20%20FILTER(REGEX(%3FdName%2C%27"
      END_SPARQL_MESH_URI = "%27%2C%20%27i%27))%20%0D%0A%7D%20%0D%0AORDER%20BY%20%3Fd%20%0D%0A"
      LCSH_BASE_URI = "http://id.loc.gov/authorities/subjects/suggest/?q="

      def pid_lookup_by_scheme(term, scheme)
        scheme == :mesh ? mesh_term_pid_lookup(term) : lcsh_term_pid_lookup(term)
      end

      # return PID for provided mesh_header using SPARQL query
      def mesh_term_pid_lookup(mesh_term="")
        return unless mesh_term.present?

        result = memoized_mesh_lookups[mesh_term]
        return result if result.present?

        query_result  = HTTParty.get(BASE_SPARQL_MESH_URI + mesh_term + END_SPARQL_MESH_URI)
        json_parsed_result = JSON.parse(query_result)

        if hits = hits_from_mesh_sparql(json_parsed_result)
          result = pid_from_mesh_hits(hits)
          memoized_mesh_lookups[mesh_term] = result
          result
        else
          ["Error Searching"]
        end
      end

      # return PID for provided lcsh_term
      def lcsh_term_pid_lookup(lcsh_term="")
        return unless lcsh_term.present?

        result = memoized_lcsh_lookups[lcsh_term]
        return result if result.present?

        subject_names, subject_id_uris = perform_and_parse_lcsh_query(lcsh_term)

        if subject_names && subject_id_uris
          result = pid_from_lcsh_hits(lcsh_term, subject_names, subject_id_uris)
          memoized_lcsh_lookups[lcsh_term] = result
        else
          ["Error Searching"]
        end
      end

      private

      def perform_and_parse_lcsh_query(lcsh_term)
        # perform search with lcsh_term's whitespace replaced with '*' character
        query_result = HTTParty.get(LCSH_BASE_URI + "*#{lcsh_term.gsub(/\s/,'*')}*")
        hits = JSON.parse(query_result)

        subject_names = hits.try(:[], 1)
        subject_id_uris = hits.try(:[], -1)

        return subject_names, subject_id_uris
      end

      def pid_from_lcsh_hits(lcsh_term, subject_names, subject_id_uris)
        subject_match_index = subject_names.index{ |name| name == lcsh_term }
        subject_id_uris[subject_match_index].split('/').last
      end

      def hits_from_mesh_sparql(json_parsed_result)
        json_parsed_result.try(:[], "results").try(:[], "bindings")
      end

      def pid_from_mesh_hits(id_uris)
        if id_uris.length > 1
          id_uris.map{ |id_uri| id_uri["d"]["value"].split('/').last }
        else
          id_uris.shift["d"]["value"].split('/').last
        end
      end

      # store searched mesh term as key and PID as value
      def memoized_mesh_lookups
        @memoized_mesh ||= {}
      end

      # store searched lcsh term as key and PID as value
      def memoized_lcsh_lookups
        @memoized_lcsh ||= {}
      end
    end
  end
end
