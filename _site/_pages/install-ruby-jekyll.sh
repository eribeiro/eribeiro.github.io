brew install ruby
echo 'export PATH="$(brew --prefix ruby)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
ruby -v


cd /path/to/project/[username].github.io
rm -f Gemfile.lock
gem install bundler
bundle install
bundle exec jekyll serve