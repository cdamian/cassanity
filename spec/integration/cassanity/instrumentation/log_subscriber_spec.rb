require 'helper'
require 'cassanity/instrumentation/log_subscriber'

describe Cassanity::Instrumentation::LogSubscriber do
  let(:client) {
    Cassanity::Client.new('127.0.0.1:9160', {
      instrumenter: ActiveSupport::Notifications,
    })
  }

  let(:keyspace) { client[:cassanity_test] }

  let(:column_family) {
    keyspace.column_family({
      name: :apps,
      schema: {
        primary_key: :id,
        columns: {
          id: :timeuuid,
          name: :text,
        },
      },
    })
  }

  before do
    @io = StringIO.new
    Cassanity::Instrumentation::LogSubscriber.logger = Logger.new(@io)

    keyspace.recreate
    column_family.recreate
  end

  after do
    Cassanity::Instrumentation::LogSubscriber.logger = nil
  end

  it "works" do
    column_family.insert({
      data: {
        id: SimpleUUID::UUID.new,
        name: 'GitHub.com',
      },
    })

    query = "INSERT INTO cassanity_test.apps (id, name) VALUES (?, ?)"
    log = @io.string
    log.should match(/#{Regexp.escape(query)}/i)
    log.should match(/UUID/i)
    log.should match(/GitHub\.com/i)
  end

  it "does not fail when no bind variables" do
    client.keyspaces
    query = "SELECT * FROM system.schema_keyspaces"
    log = @io.string
    log.should match(/#{Regexp.escape(query)}/i)
  end

  it "works through exceptions" do
    client.driver.should_receive(:execute).and_raise(Exception.new('boom'))
    begin
      client.keyspaces
    rescue Exception => e
    end

    query = "SELECT * FROM system.schema_keyspaces"
    log = @io.string.split("\n").last
    log.should match(/#{Regexp.escape(query)}/i)
  end
end
