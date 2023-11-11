require 'cloud-stack-client/client'
require 'cloud-stack-client/configuration'
require 'yaml'
require 'json'

begin
  require 'thor'
  require 'ripl'
rescue LoadError => e
  %w[thor ripl].each do |gem|
    if e.message =~ /#{gem}/
      Rails.logger.debug("Please install the #{gem} gem first ('gem install #{gem}').")
      raise 'Exit'
    end
  end
  raise e.message
end

module CloudstackClient
  class Cli < Thor
    include Thor::Actions

    class_option :config_file,
                 default: Configuration.locate_config_file,
                 aliases: '-c',
                 desc: 'location of your cloudstack-cli configuration file'

    class_option :env,
                 aliases: '-e',
                 desc: 'environment to use'

    class_option :debug,
                 desc: 'enable debug output',
                 type: :boolean

    # rescue error globally
    def self.start(given_args = ARGV, config = {})
      super
    rescue StandardError => e
      error_class = e.class.name.split('::')
      raise unless error_class.size == 2 && error_class.first == 'CloudstackClient'

      Rails.logger.debug("\e[31mERROR\e[0m: #{error_class.last} - #{e.message}")
      Rails.logger.debug e.backtrace if ARGV.include? '--debug'
    end

    desc 'version', 'Print cloud-stack-client version number'
    def version
      say "cloud-stack-client version #{CloudstackClient::VERSION}"
    end
    map %w[-v --version] => :version

    desc 'list_apis', 'list api commands using the Cloudstack API Discovery service'
    option :format, default: 'json', enum: %w[json yaml], desc: 'output format'
    option :pretty_print, default: true, type: :boolean, desc: 'pretty print json output'
    option :remove_response, default: true, type: :boolean, desc: 'remove response sections'
    option :remove_description, default: true, type: :boolean, desc: 'remove description sections'
    def list_apis
      apis = client(no_api_methods: true).send_request('command' => 'listApis')
      apis.each do |command|
        command.delete('response') if options[:remove_response]
        if options[:remove_description]
          command.delete('description')
          command['params'].each { |param| param.delete('description') }
        end
      end

      Rails.logger.debug case options[:format]
      when 'yaml'
        apis.to_yaml
      else
        options[:pretty_print] ? JSON.pretty_generate(apis) : JSON.generate(apis)
      end
    end

    desc 'console', 'Cloudstack Client interactive shell'
    option :api_version,
           desc: 'API version to use',
           default: CloudstackClient::Api::DEFAULT_API_VERSION
    option :api_file,
           desc: 'specify a custom API definition file'
    option :pretty_print,
           desc: 'pretty client output',
           type: :boolean,
           default: true
    def console
      cs_client = client(options)

      Rails.logger.debug("cloud-stack-client version #{CloudstackClient::VERSION}")
      Rails.logger.debug(" CloudStack API version #{cs_client.api.api_version}")
      Rails.logger.debug('  try: list_virtual_machines state: "running"')

      ARGV.clear
      Ripl.config[:prompt] = "#{@config[:environment]} >> "
      Ripl.start binding: cs_client.instance_eval { binding }
    end

    no_commands do
      def client(opts = {})
        @config ||= CloudstackClient::Configuration.load(options)
        @client ||= CloudstackClient::Client.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key],
          opts
        )
      end
    end
  end
end
