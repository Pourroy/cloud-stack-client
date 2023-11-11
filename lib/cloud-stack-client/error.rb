module CloudstackClient
  class Error < StandardError
    attr_accessor :type, :code, :message, :job_id

    def initialize(type, code, message, job_id = nil)
      super(message)
      @type = type
      @code = code
      @message = message.to_s
      @job_id = job_id
    end

    def to_hash
      {
        type: @type,
        code: @code,
        message: @message,
        job_id: @job_id
      }
    end
  end
end
