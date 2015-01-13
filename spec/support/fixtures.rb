def read_fixture_file(filename)
  case filename
  when /\.yml$/ then YAML.load(File.read("#{fixture_path}/#{filename}")).with_indifferent_access
  when /\.json$/ then JSON.parse(File.read("#{fixture_path}/#{filename}")).with_indifferent_access
  else File.read("#{fixture_path}/#{filename}")
  end
end
