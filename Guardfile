# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :bundler do
  watch('Gemfile')
  # Uncomment next line if your Gemfile contains the `gemspec' command.
  # watch(/^.+\.gemspec/)
end

guard :rspec,
cmd: 'rspec',
failed_mode: :focus,
all_after_pass: true,
all_on_start: true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^(spec/?.*)/.+?_shared\.rb$}) {|m| m[1]}
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
  watch(%r{^spec/support/.*\.rb}) { "spec" }
end
