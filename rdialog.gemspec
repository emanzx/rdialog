Gem::Specification.new do |gem|
  gem.name                       = 'rdialog'
  gem.summary                    = 'Ruby interface to ncurses dialog.'
  gem.description                = %Q{rdialog is a Ruby interface to the ncurses dialog program.}

  gem.version                    = File.exist?('VERSION') ? File.read('VERSION').strip : ''
  gem.platform                   = Gem::Platform::RUBY

  gem.authors                    = ['Aleks Clark', 'Muhammad Muquit', 'Justin Langhorst']
  gem.email                      = ['justin@healthblocks.com']
  gem.homepage                   = 'http://github.com/langhorst/rdialog'
  gem.license                    = 'MIT'

  gem.files                      = Dir.glob('{lib}/**/*') + %w(LICENSE.txt VERSION)
  gem.require_paths              = ['lib']

  gem.required_ruby_version      = '~> 2.2'
end
