# frozen_string_literal: true

require 'zlib'
require 'json'
require 'ea-op-ful-cloud-stack-client/utils'

module EaOpFulCloudstackClient
  class Api
    include Utils

    DEFAULT_API_VERSION = '4.5'
    API_PATH = File.expand_path('../../data', __dir__)

    attr_reader :api_version, :api_file, :api_path, :commands

    def self.versions(api_path = API_PATH)
      Dir["#{api_path}/*.json.gz"].map do |path|
        File.basename(path, '.json.gz')
      end
    end

    def initialize(options = {})
      load_api_path(options)
      load_api_version_and_file(options)
      load_commands
    end

    def command_supported?(command)
      @commands.key? underscore_to_camel_case(command)
    end

    def command_supports_param?(command, key)
      command = underscore_to_camel_case(command)
      if @commands[command]['params'].detect do |params|
        params['name'] == key.to_s
      end
        true
      else
        false
      end
    end

    def required_params(command)
      params(command).map do |param|
        param['name'] if param['required'] == true
      end.compact
    end

    def params(command)
      @commands[command]['params']
    end

    def all_required_params?(command, args)
      required_params(command).all? { |k| args.key? k }
    end

    def missing_params_msg(command)
      "#{command} requires the following parameter" \
      "#{'s' if required_params(command).size > 1}: " +
        required_params(command).join(', ')
    end

    private

    def load_api_version_and_file(options)
      if options[:api_file]
        @api_file = options[:api_file]
        @api_version = File.basename(@api_file, '.json.gz')
      else
        load_api_version(options)
        @api_file = File.join(@api_path, "#{@api_version}.json.gz")
      end
    end

    def load_api_path(options)
      @api_path = if options[:api_path]
        File.expand_path(options[:api_path])
      else
        API_PATH
      end
    end

    def load_api_version(options)
      @api_version = options[:api_version] || DEFAULT_API_VERSION
      unless Api.versions(@api_path).include? @api_version
        if options[:api_version]
          error_api_message = "API definition not found for version '#{@api_version}' in api_path '#{@api_path}'"
          raise error_api_message if options[:api_version]

        elsif Api.versions(@api_path).empty?
          raise "no API file available in api_path '#{@api_path}'"
        else
          @api_version = Api.versions(@api_path).last
        end
      end
      @api_version
    end

    def load_commands
      @commands = {}
      zlibz = Zlib::GzipReader.open(@api_file) do |gz|
        JSON.parse(gz.read)
      end
      zlibz.each do |cmd|
        @commands[cmd['name']] = cmd
      end
    rescue StandardError => e
      raise "Error: Unable to read file '#{@api_file}': #{e.message}"
    end
  end
end
