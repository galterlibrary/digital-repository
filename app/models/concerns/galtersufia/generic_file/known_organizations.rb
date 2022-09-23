module Galtersufia
  module GenericFile
    module KnownOrganizations
      extend ActiveSupport::Concern

      KNOWN_ORGANIZATIONS = [
        "Galter Health Sciences Library",
        "12th General Hospital",
        "Northwestern University, Medical School",
        "United States Army Office of Information and Education",
        "United States. Army",
        "World's Columbian Dental Congress (1893 : Chicago, Ill.)",
        "Cartoleria Abussi (Firm)",
        "Center for Behavioral Intervention Technologies, Department",
        "U.S. Army Photograph",
        "Artaud et Nozals (Firm)",
        "World's Columbian Exposition (1893 : Chicago, Ill.)",
        "Almer Coe & Company",
        "Alterocca Terni (Firm)",
        "Association for Library Collections and Technical Services. Subject Analysis Committee. Subcommittee on Semantic Interoperability",
        "Bromostampa (Firm)",
        "Chicago, North Shore and Milwaukee Railroad",
        "Enterprise Generale de Peinture F. Pascual",
        "FORCE11 Attribution Working Group",
        "Feinberg School of Medicine",
        "Fruits & Vegetables Joe Ray Wholesale and Retail",
        "Galter Health Sciences Librry", # TODO should we update this record before migrating?
        "McCoy Printing Company",
        "Medical Library Association Latino Special Interest Group",
        "Northwestern University (Evanston, Ill.). Medical School",
        "Northwestern University (Evanston, Ill.). Medical Alumni Association",
        "OpenVIVO Working Group",
        "Polar Ice & Fuel Co.",
        "Polk's Best",
        "Prevention Science Methodology Group",
        "Railway Express Agency",
        "Remington Typewriter Co.",
        "Societe Graphique Neuchatel",
        "The Polk Sanitary Milk Company",
        "United States. War Department",
        "United States. War Department. Transportation Corps",
        "World's Columbian Dental Congress (1893 : Chicago, Ill.)",
        "World's Columbian Dental Congress (1893 : Chicago, Ill.). Committee on Essays.",
        "World's Columbian Dental Congress (1893 : Chicago, Ill.). Finance Committee for Illinois",
        "World's Columbian Exposition (1893 : Chicago, Ill.). World's Congress Auxiliary",
        "Northwestern University (Evanston, Ill.). Women's Health Research Institute"
      ]

      def organization?(creator_formal_name)
        KNOWN_ORGANIZATIONS.include?(creator_formal_name)
      end
    end
  end
end
