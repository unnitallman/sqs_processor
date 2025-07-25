require 'aws-sdk-sqs'
require 'json'
require 'logger'
require 'dotenv'
require 'optparse'

# Load environment variables
Dotenv.load

module SQSProcessor
  class Processor
    attr_reader :sqs_client, :queue_url, :logger

    def initialize(queue_url:, region: 'us-east-1', max_messages: 10, visibility_timeout: 30,
                   aws_access_key_id: nil, aws_secret_access_key: nil, aws_session_token: nil,
                   aws_credentials: nil, logger: nil)
      @queue_url = queue_url
      @region = region
      @max_messages = max_messages
      @visibility_timeout = visibility_timeout
      @aws_credentials = aws_credentials
      @aws_access_key_id = aws_access_key_id
      @aws_secret_access_key = aws_secret_access_key
      @aws_session_token = aws_session_token

      setup_logger(logger)
      setup_sqs_client

      raise 'Queue URL is required.' unless @queue_url
    end

    def setup_logger(custom_logger = nil)
      @logger = custom_logger || Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
      end
    end

    def setup_sqs_client
      credentials = if @aws_credentials
                      @aws_credentials
                    elsif @aws_access_key_id && @aws_secret_access_key
                      Aws::Credentials.new(@aws_access_key_id, @aws_secret_access_key, @aws_session_token)
                    elsif ENV['DATA_SYNC_AWS_ACCESS_KEY_ID'] && ENV['DATA_SYNC_AWS_SECRET_ACCESS_KEY']
                      Aws::Credentials.new(ENV['DATA_SYNC_AWS_ACCESS_KEY_ID'], ENV['DATA_SYNC_AWS_SECRET_ACCESS_KEY'])
                    else
                      Aws::Credentials.new
                    end

      @sqs_client = Aws::SQS::Client.new(
        region: @region,
        credentials: credentials
      )
    end

    def process_messages
      logger.info 'Starting SQS message processing...'
      logger.info "Queue URL: #{@queue_url}"
      logger.info "Max messages per batch: #{@max_messages}"
      logger.info "Visibility timeout: #{@visibility_timeout} seconds"

      loop do
        receive_messages
        sleep 1 # Small delay between polling cycles
      rescue StandardError => e
        logger.error "Error in message processing loop: #{e.message}"
        logger.error e.backtrace.join("\n")
        sleep 5 # Longer delay on error
      end
    end

    def receive_messages
      response = @sqs_client.receive_message(
        queue_url: @queue_url,
        max_number_of_messages: @max_messages,
        visibility_timeout: @visibility_timeout,
        wait_time_seconds: 20 # Long polling
      )

      if response.messages.empty?
        logger.debug 'No messages received'
        return
      end

      logger.info "Received #{response.messages.length} message(s)"

      response.messages.each do |message|
        process_single_message(message)
      end
    end

    def process_single_message(message)
      logger.info "Processing message: #{message.message_id}"

      begin
        # Parse message body
        body = JSON.parse(message.body)
        logger.info "Message body: #{body}"

        # Call the hook method that should be implemented by the host application
        result = handle_message(JSON.parse(body['Message']))

        if result
          # Delete the message from queue after successful processing
          delete_message(message)
          logger.info "Successfully processed and deleted message: #{message.message_id}"
        else
          logger.warn "Message processing returned false, keeping message in queue: #{message.message_id}"
        end
      rescue JSON::ParserError => e
        logger.error "Failed to parse message body as JSON: #{e.message}"
        logger.error "Raw message body: #{message.body}"
        # Keep message in queue for manual inspection
      rescue StandardError => e
        logger.error "Error processing message #{message.message_id}: #{e.message}"
        logger.error e.backtrace.join("\n")
        # Keep message in queue for retry
      end
    end

    # Hook method that should be implemented by the host application
    # Override this method in your subclass to implement custom message processing
    def handle_message(message, body)
      logger.warn 'handle_message method not implemented. Override this method in your subclass.'
      false
    end

    def delete_message(message)
      @sqs_client.delete_message(
        queue_url: @queue_url,
        receipt_handle: message.receipt_handle
      )
    rescue StandardError => e
      logger.error "Failed to delete message #{message.message_id}: #{e.message}"
    end

    def get_queue_attributes
      response = @sqs_client.get_queue_attributes(
        queue_url: @queue_url,
        attribute_names: ['All']
      )

      attributes = response.attributes
      logger.info 'Queue attributes:'
      logger.info "  Approximate number of messages: #{attributes['ApproximateNumberOfMessages']}"
      logger.info "  Approximate number of messages not visible: #{attributes['ApproximateNumberOfMessagesNotVisible']}"
      logger.info "  Approximate number of messages delayed: #{attributes['ApproximateNumberOfMessagesDelayed']}"

      attributes
    end
  end
end
