# SQS Processor Gem

A Ruby gem for processing messages from Amazon SQS queues with configurable message handling and error recovery.

## Features

- **Long Polling**: Efficiently polls SQS with configurable wait times
- **Batch Processing**: Processes multiple messages per batch
- **Error Handling**: Robust error handling with message retention on failure
- **Customizable**: Extensible message processing logic
- **Logging**: Comprehensive logging with configurable levels
- **Graceful Shutdown**: Handles SIGTERM, SIGINT, and SIGQUIT signals gracefully
- **Environment Variables**: Support for AWS credentials and configuration via environment variables

## Prerequisites

- Ruby 2.6 or higher
- AWS credentials configured (via environment variables, IAM roles, or AWS CLI)
- SQS queue URL

## Installation

### As a Gem

```bash
gem install sqs_processor
```

### From Source

1. Clone the repository
2. Install dependencies:

```bash
bundle install
```

3. Build and install the gem:

```bash
bundle exec rake install
```

4. Copy the environment example and configure your settings:

```bash
cp env.example .env
```

5. Edit `.env` with your AWS credentials and SQS queue URL:

```bash
DATA_SYNC_AWS_ACCESS_KEY_ID=your_access_key_here
DATA_SYNC_AWS_SECRET_ACCESS_KEY=your_secret_key_here
DATA_SYNC_AWS_REGION=us-east-1
DATA_SYNC_SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/your-queue-name
```

## Usage

The gem is designed to be used programmatically in your Ruby applications.

### Programmatic Usage

#### Basic Usage

```ruby
require 'sqs_processor'

# Create a processor instance with AWS credentials
processor = SQSProcessor::Processor.new(
  queue_url: 'https://sqs.us-east-1.amazonaws.com/123456789012/my-queue',
  aws_access_key_id: 'your-access-key',
  aws_secret_access_key: 'your-secret-key',
  aws_region: 'us-east-1',
  max_messages: 10,
  visibility_timeout: 30
)

# Start processing messages
processor.process_messages
```

## Message Processing

The gem uses a hook-based approach for message processing. You must implement the `handle_message` method in your subclass to define how messages should be processed.

### Hook Method

The `handle_message(body)` method receives:
- `body`: The parsed JSON body of the message

Return `true` if processing was successful (message will be deleted from queue), or `false` if processing failed (message will remain in queue for retry).

### Example Message Format

```json
{
  "event_type": "data_sync",
  "dataset_id": "12345",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### Custom Processing

To implement custom message processing logic, create a subclass of `SQSProcessor::Processor` and override the `handle_message` method:

```ruby
require 'sqs_processor'

class MyCustomProcessor < SQSProcessor::Processor
  def handle_message(body)
    # This method receives the parsed message body
    # Return true if processing was successful, false otherwise
    
    case body['event_type']
    when 'data_sync'
      process_data_sync(body)
    when 'report_generation'
      process_report_generation(body)
    else
      logger.warn "Unknown event type: #{body['event_type']}"
      false
    end
  end

  private

  def process_data_sync(body)
    logger.info "Processing data sync for dataset: #{body['dataset_id']}"
    # Your custom logic here
    true
  end

  def process_report_generation(body)
    logger.info "Processing report generation for report: #{body['report_id']}"
    # Your custom logic here
    true
  end
end

# Usage
processor = MyCustomProcessor.new(
  queue_url: 'your-queue-url',
  aws_access_key_id: 'your-access-key',
  aws_secret_access_key: 'your-secret-key',
  aws_region: 'us-east-1'
)
processor.process_messages
```

## Configuration

### Constructor Parameters

The `SQSProcessor::Processor.new` method accepts the following parameters:

- `queue_url:` (required) - The SQS queue URL
- `aws_access_key_id:` (required) - AWS access key ID
- `aws_secret_access_key:` (required) - AWS secret access key
- `aws_region:` (optional, default: 'us-east-1') - AWS region
- `aws_session_token:` (optional) - AWS session token for temporary credentials
- `max_messages:` (optional, default: 10) - Maximum messages per batch
- `visibility_timeout:` (optional, default: 30) - Message visibility timeout in seconds
- `logger:` (optional) - Custom logger instance

### Environment Variables

- `DATA_SYNC_AWS_ACCESS_KEY_ID`: Your AWS access key
- `DATA_SYNC_AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `DATA_SYNC_AWS_SESSION_TOKEN`: Your AWS session token (optional, for temporary credentials)
- `DATA_SYNC_AWS_REGION`: AWS region (default: us-east-1)
- `DATA_SYNC_SQS_QUEUE_URL`: Your SQS queue URL

### AWS Credentials

The gem supports multiple ways to provide AWS credentials:

1. **Initializer Configuration**: Set credentials in the initializer block
2. **Environment Variables**: Use the `DATA_SYNC_` prefixed environment variables
3. **AWS SDK Default Chain**: If no credentials are provided, the AWS SDK will use its default credential provider chain (IAM roles, AWS CLI, etc.)
4. **Direct Parameter**: Pass credentials directly to the processor constructor

The script supports multiple ways to provide AWS credentials:

1. **Environment Variables**: Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
2. **IAM Roles**: If running on EC2 with IAM roles
3. **AWS CLI**: If you have AWS CLI configured
4. **AWS SDK Default Credential Provider Chain**: Automatic credential resolution

## Error Handling

- **JSON Parse Errors**: Messages with invalid JSON are logged but kept in queue
- **Processing Errors**: Failed messages remain in queue for retry
- **Network Errors**: Automatic retry with exponential backoff
- **Queue Errors**: Comprehensive error logging with stack traces

## Graceful Shutdown

The processor handles termination signals gracefully:

- **SIGTERM**: Standard termination signal (used by container orchestrators)
- **SIGINT**: Interrupt signal (Ctrl+C)
- **SIGQUIT**: Quit signal

When a shutdown signal is received:
1. The processor stops accepting new messages
2. Completes processing of any current message batch
3. Logs the shutdown process
4. Exits cleanly

This ensures that no messages are lost during deployments or process termination.

## Monitoring

The script provides detailed logging including:

- Queue attributes (message counts)
- Message processing status
- Error details with stack traces
- Processing performance metrics

## Best Practices

1. **Set appropriate visibility timeout**: Should be longer than your processing time
2. **Use long polling**: Reduces API calls and costs
3. **Handle errors gracefully**: Return `false` from processing methods to keep messages in queue
4. **Monitor queue depth**: Use the built-in queue attribute reporting
5. **Use appropriate batch sizes**: Balance between throughput and memory usage
6. **Deploy with graceful shutdown**: The processor handles SIGTERM gracefully for container deployments

## Troubleshooting

### Common Issues

1. **"Queue URL is required"**: Set `DATA_SYNC_SQS_QUEUE_URL` environment variable or use `-q` option
2. **"Access Denied"**: Check AWS credentials and SQS permissions
3. **"Queue does not exist"**: Verify queue URL and region
4. **Messages not being processed**: Check visibility timeout and processing logic

### Debug Mode

To enable debug logging, modify the logger level in the script:

```ruby
@logger.level = Logger::DEBUG
```

## Development

### Running Tests

```bash
bundle exec rspec
```

### Code Style

```bash
bundle exec rubocop
```

### Building the Gem

```bash
bundle exec rake build
```

### Publishing the Gem

```bash
bundle exec rake release
```

## License

This gem is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 