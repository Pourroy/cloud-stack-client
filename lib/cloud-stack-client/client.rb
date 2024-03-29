require 'cloud-stack-client/version'
require 'cloud-stack-client/api'
require 'cloud-stack-client/error'
require 'cloud-stack-client/utils'
require 'cloud-stack-client/connection'

module CloudstackClient
  class Client < Connection
    include Utils

    attr_accessor :options, :async
    attr_reader :api

    def initialize(transaction, api_url, api_key, secret_key, telemetry = nil, options = {}, method_process = nil)
      super(transaction, telemetry, api_url, api_key, secret_key, options, method_process)
      @telemetry = telemetry
      define_api_methods unless options[:no_api_methods]
    end

    def define_api_methods
      @api = Api.new(@options)
      @api.commands.each do |_name, command|
        method_name = camel_case_to_underscore(command['name']).to_sym
        define_singleton_method(method_name) do |args = {}, options = {}|
          @telemetry&.add_event("CloudstackClient: { :api => '#{command['name']}', :body => #{filtering_params(args)} }")
          params = { 'command' => command['name'] }

          args.each do |k, v|
            k = k.to_s.gsub('_', '')
            params[k] = v if v && @api.command_supports_param?(command['name'], k)
          end

          raise Error.new('ParserError', 405, @api.missing_params_msg(command['name'])) unless @api
            .all_required_params?(command['name'], params)

          if command['isasync'].instance_of?(FalseClass) || options[:sync]
            send_request(params)
          else
            send_async_request(params)
          end
        end
      end
    end

    def jobid_status_check(jobid)
      params = {
        'command' => 'queryAsyncJobResult',
        'jobid' => jobid
      }
      result = send_request(params)
      case result['jobstatus']
      when 1
        Rails.logger.info("::jobid_status_check::JobId:#{jobid} - Job Finished")
        'Finished'
      when 2
        raise Error.new('JobError', result['jobresultcode'], result['jobresult']['errortext'])
      else
        Rails.logger.info("jobid_status_check::JobId:#{jobid} - Proccessing")
        'Processing'
      end
    end
  end
end
