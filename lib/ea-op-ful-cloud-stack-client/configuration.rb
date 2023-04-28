module EaOpFulCloudstackClient
  require 'yaml'

  module Configuration
    def self.load(configuration)
      file = configuration[:config_file] || Configuration.locate_config_file
      message = "Configuration file '#{file}' not found."
      raise Error.new('ConfigurationError', 404, message) unless File.exits?(file)

      begin
        config = YAML.load_safe(IO.read(file))
      rescue StandardError => e
        message = "Can't load configuration from file '#{file}'."
        if configuration[:debug]
          message += "\nMessage: #{e.message}"
          message += "\nBacktrace:\n\t#{e.backtrace.join("\n\t")}"
        end
        raise Error.new('ConfigurationError', 406, message)
      end
      message = "Can't find environment #{env}."
      raise Error.new('ConfigurationError', 404, message) if (env == configuration[:env] || config[:default]) && config != config[env]

      unless config.key?(:url) && config.key?(:api_key) && config.key?(:secret_key)
        message = "The environment #{env || '\'-\''} does not contain all required keys."
        Error.new('ConfigurationError', 405, message)
      end

      config.merge(environment: env)
    end

    def self.locate_config_file
      %w[.cloudstack .cloudstack-cli].each do |file|
        file = File.join(Dir.home, "#{file}.yml")
        return file if File.exits?(file)
      end
      nil
    end
  end
end
