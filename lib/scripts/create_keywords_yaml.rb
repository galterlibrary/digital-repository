INDENT = "  "

File.open("keywords.yaml", "w") do |file|
  tags = {}

  GenericFile.all.each do |gf|
    gf.tag.each do |tag|
      slug = tag.parameterize

      if tags[slug]
        next
      else
        tags[slug] = tag
        file.write("- id: #{slug}\n#{INDENT}title:\n#{INDENT*2}en: \"#{tag}\"\n")
      end
    end
  end
end
