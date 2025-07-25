require 'spec_helper'

RSpec.describe SQSProcessor do
  it 'has a version number' do
    expect(SQSProcessor::VERSION).not_to be nil
  end

  it 'defines an Error class' do
    expect(SQSProcessor::Error).to be < StandardError
  end
end 