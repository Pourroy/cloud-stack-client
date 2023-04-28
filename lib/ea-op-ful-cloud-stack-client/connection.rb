require 'base64'
require 'openssl'
require 'uri'
require 'cgi'
require 'net/http'
require 'json'

module EaOpFulCloudstackClient
  class Connection
    include Utils

    attr_accessor :api_url, :api_key, :secret_key, :verbose, :debug, :async_poll_interval, :async_timeout

    DEF_POLL_INTERVAL = 2.0
    DEF_ASYNC_TIMEOUT = 400
    def initialize(transaction, api_url, api_key, secret_key, options = {}, method_process = nil)
      @transaction = transaction
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @verbose = options[:quiet] ? false : true
      @debug = options[:debug] ? true : false
      @async_poll_interval = options[:async_poll_interval] || DEF_POLL_INTERVAL
      @async_timeout = options[:async_timeout] || DEF_ASYNC_TIMEOUT
      @options = options
      @method_process = method_process
      validate_input!
    end

    def send_request(params)
      params['response'] = 'json'
      params['apiKey'] = @api_key
      print_debug_output JSON.pretty_generate(params) if @debug
      data = params_to_data(params)
      uri = URI.parse "#{@api_url}?#{data}&signature=#{create_signature(data)}"

      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      begin
        response = http.request(Net::HTTP::Get.new(uri.request_uri))
      rescue StandardError
        raise Error.new('ConectionError', 500, "API URL \'#{@api_url}\' is not reachable.")
      end

      begin
        body = JSON.parse(response.body).values.first
      rescue JSON::StandardError
        message = "Response from server is not readable. Check if the API endpoint (#{@api_url}) is valid and accessible."
        raise Error.new('ParserError', 405, message)
      end

      if response.is_a?(Net::HTTPOK)
        return body unless body.respond_to?(:keys)
        return body.reject { |key, _| key == 'count' }.values.first if body.size == 2 && body.key?('count')

        if body.size == 1 && body.values.first.respond_to?(:keys)
          item = body.values.first
          item.is_a?(Array) || item.is_a?(Hash) ? item : []
        else
          body.reject! { |key, _| key == 'count' } if body.key?('count')
          body.empty? ? [] : body
        end
      else
        begin
          message = body['errortext']
        rescue body
          raise Error.new('ApiError', response.code, message)
        end
      end
    end

    ##
    # Sends an asynchronous request and waits for the response.
    #
    # The contents of the 'jobresult' element are returned upon completion of the command.

    def send_async_request(params)
      data = send_request(params)
      raise Error.new('InputError', 405, data) if data['jobid'].nil?

      params = {
        'command' => 'queryAsyncJobResult',
        'jobid' => data['jobid']
      }
      return data['jobid'] if @method_process.present?

      max_tries.times do
        data = send_request(params)
        Rails.logger.info("[#{@transaction}] ::JobId:#{data['jobid']} - JobStatus:#{data['jobstatus']}") if @verbose

        case data['jobstatus']
        when 1
          return data['jobresult']
        when 2
          raise Error.new('JobError', data['jobresultcode'], data['jobresult']['errortext'])
        end

        $stdout.flush if @verbose
        sleep @async_poll_interval
      end

      raise Error.new('TimeoutError', 408, 'Asynchronous request timed out.', data['jobid'])
    end

    private

    def validate_input!
      raise Error.new('InputError', 405, 'API URL not set.') if @api_url.nil?
      raise Error.new('InputError', 405, 'API KEY not set.') if @api_key.nil?
      raise Error.new('InputError', 405, 'API SECRET KEY not set.') if @secret_key.nil?
      raise Error.new('InputError', 405, 'ASYNC POLL INTERVAL must be at least 1.') if @async_poll_interval < 1.0
      raise Error.new('InputError', 405, 'ASYNC TIMEOUT must be at least 60.') if @async_timeout < 60
    end

    def params_to_data(params)
      params_arr = params.sort.map do |key, value|
        case value
        when Array # support for maps (Arrays of Hashes)
          map = []
          value.each_with_index do |items, i|
            items.each { |k, v| map << "#{key}[#{i}].#{k}=#{escape(v)}" }
          end
          map.sort.join('&')
        when Hash # support for maps values of values (Hash values of Hashes)
          value.each_with_index.map do |(k, v), i|
            "#{key}[#{i}].key=#{escape(k)}&" \
              "#{key}[#{i}].value=#{escape(v)}"
          end.join('&')
        else
          "#{key}=#{escape(value)}"
        end
      end
      params_arr.sort.join('&')
    end

    def create_signature(data)
      signature = OpenSSL::HMAC.digest('sha1', @secret_key, data.downcase)
      signature = Base64.encode64(signature).chomp
      CGI.escape(signature)
    end

    def max_tries
      (@async_timeout / @async_poll_interval).round
    end

    def escape(input)
      CGI.escape(input.to_s).gsub('+', '%20').gsub(' ', '%20')
    end
  end
end
