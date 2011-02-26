# Use with Watchr: http://github.com/mynyml/watchr

# If a spec file changes, run it.  Simple, eh?
watch '^spec.*/.*_spec\.rb' do |match|
  system "rspec #{match[0]}"
end

# If a library file changes, run the appropriate spec file.
watch '^lib/(.*)\.rb' do |match|
  system "rspec spec/#{match[1]}_spec.rb"
end

# If a shared example changes, find out which specs reference it and run those.
watch '^spec/shared_examples.*/.*_shared\.rb' do |match|
  if File.read(match[0]) =~ /shared_examples_for ['"](.+)['"]/
    example_type = $1
    specs = `grep -rl 'behaves_like .#{example_type}.' spec`
    system "xargs rspec #{specs}" unless specs.empty?
  end
end

# If the spec_helper changes, re-run everything.
watch '^spec/spec_helper.rb' do |match|
  system "rspec spec"
end

# Having set all that up, let's run the whole suite just for starters.
system "rspec spec"