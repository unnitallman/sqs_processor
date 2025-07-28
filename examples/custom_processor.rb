#!/usr/bin/env ruby

require 'sqs_processor'

# Example custom processor that implements the handle_message hook
class DataSyncProcessor < SQSProcessor::Processor
  def handle_message(body)
    case body['event_type']
    when 'user_sync'
      process_user_sync(body)
    when 'organization_sync'
      process_organization_sync(body)
    when 'document_sync'
      process_document_sync(body)
    else
      logger.warn "Unknown event type: #{body['event_type']}"
      false
    end
  end

  private

  def process_user_sync(body)
    user_id = body['user_id']
    logger.info "Syncing user: #{user_id}"

    # Your custom user sync logic here
    # Example: update user in database, sync to external service, etc.

    # Simulate some processing
    sleep(0.1)

    # Return true if successful, false if failed
    true
  end

  def process_organization_sync(body)
    org_id = body['organization_id']
    logger.info "Syncing organization: #{org_id}"

    # Your custom organization sync logic here
    # Example: update organization settings, sync members, etc.

    # Simulate some processing
    sleep(0.1)

    true
  end

  def process_document_sync(body)
    doc_id = body['document_id']
    logger.info "Syncing document: #{doc_id}"

    # Your custom document sync logic here
    # Example: update document content, sync to search index, etc.

    # Simulate some processing
    sleep(0.1)

    true
  end
end

# Example usage
if __FILE__ == $0
  # Load environment variables
  Dotenv.load

  # Create and start the processor
  processor = DataSyncProcessor.new(
    queue_url: ENV.fetch('DATA_SYNC_SQS_QUEUE_URL', nil),
    aws_access_key_id: ENV.fetch('DATA_SYNC_AWS_ACCESS_KEY_ID', nil),
    aws_secret_access_key: ENV.fetch('DATA_SYNC_AWS_SECRET_ACCESS_KEY', nil),
    aws_session_token: ENV.fetch('DATA_SYNC_AWS_SESSION_TOKEN', nil),
    aws_region: ENV['DATA_SYNC_AWS_REGION'] || 'us-east-1'
  )
  processor.process_messages
end
