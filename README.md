# contenttruck-rb

The Ruby SDK for Contenttruck.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add contenttruck-rb

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install contenttruck-rb

## Usage

To use the client, initialise a instance of the Client with the base URL.
```ruby
c = Contenttruck::Client.new 'http://localhost:4000'
```
From here, you will have access to all of the SDK methods.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/WebScaleSoftwareLtd/contenttruck-rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
