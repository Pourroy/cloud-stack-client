module CloudstackClient
  module Utils
    FILTERABLE_PARAMETERS = %i[publickey keypair password apiKey].freeze

    def camel_case_to_underscore(camel_case)
      camel_case.gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_').downcase
    end

    def underscore_to_camel_case(underscore)
      if underscore.include? '_'
        string = underscore.split('_').collect(&:capitalize).join
        string[0].downcase + string[1..]
      else
        underscore
      end
    end

    def print_debug_output(output, separator = '-' * 80)
      Rails.logger.info separator
      Rails.logger.info output
      Rails.logger.info separator
    end

    def filtering_params(params)
      return params unless params.is_a?(Hash)

      forbidden_words = ActiveSupport::ParameterFilter.new(FILTERABLE_PARAMETERS)
      forbidden_words.filter(params)
    end
  end
end
