require 'cassandra-cql'
require 'cassanity/error'
require 'cassanity/argument_generators/keyspaces'
require 'cassanity/argument_generators/keyspace_create'
require 'cassanity/argument_generators/keyspace_drop'
require 'cassanity/argument_generators/keyspace_use'
require 'cassanity/argument_generators/column_family_create'
require 'cassanity/argument_generators/column_family_drop'
require 'cassanity/argument_generators/column_family_truncate'
require 'cassanity/argument_generators/column_family_insert'
require 'cassanity/argument_generators/column_family_update'
require 'cassanity/argument_generators/column_family_delete'
require 'cassanity/argument_generators/index_create'
require 'cassanity/argument_generators/index_drop'

module Cassanity
  module Executors
    class CassandraCql

      CommandToArgumentGeneratorMap = {
        keyspaces: Cassanity::ArgumentGenerators::Keyspaces.new,
        keyspace_create: Cassanity::ArgumentGenerators::KeyspaceCreate.new,
        keyspace_drop: Cassanity::ArgumentGenerators::KeyspaceDrop.new,
        keyspace_use: Cassanity::ArgumentGenerators::KeyspaceUse.new,
        column_family_create: Cassanity::ArgumentGenerators::ColumnFamilyCreate.new,
        column_family_drop: Cassanity::ArgumentGenerators::ColumnFamilyDrop.new,
        column_family_truncate: Cassanity::ArgumentGenerators::ColumnFamilyTruncate.new,
        column_family_insert: Cassanity::ArgumentGenerators::ColumnFamilyInsert.new,
        column_family_update: Cassanity::ArgumentGenerators::ColumnFamilyUpdate.new,
        column_family_delete: Cassanity::ArgumentGenerators::ColumnFamilyDelete.new,
        index_create: Cassanity::ArgumentGenerators::IndexCreate.new,
        index_drop: Cassanity::ArgumentGenerators::IndexDrop.new,
      }

      # Private
      attr_reader :client

      # Private
      attr_reader :command_to_argument_generator_map

      # Public: Initializes a cassandra-cql based CQL executor.
      #
      # args - The Hash of arguments.
      #        :client - The CassandraCQL::Database connection instance.
      #
      # Examples
      #
      #   connection = CassandraCQL::Database.new('host')
      #   Cassanity::Executors::CassandraCql.new(connection)
      #
      def initialize(args = {})
        @client = args.fetch(:client)
        @command_to_argument_generator_map = args.fetch(:command_to_argument_generator_map) {
          CommandToArgumentGeneratorMap
        }
      end

      # Public: Execute a CQL query.
      #
      # args - One or more arguments to send to execute. First should always be
      #        String CQL query. The rest should be the bound variables if any
      #        are needed.
      #
      # Examples
      #
      #   call({
      #     command: :keyspaces,
      #   })
      #
      #   call({
      #     command: :keyspace_create,
      #     arguments: {name: 'analytics'},
      #   })
      #
      # Returns the result of execution.
      # Raises Cassanity::Error if anything goes wrong during execution.
      def call(args = {})
        command = args.fetch(:command)
        generator = @command_to_argument_generator_map.fetch(command)
        execute_arguments = generator.call(args[:arguments])

        @client.execute *execute_arguments
      rescue KeyError
        raise Cassanity::UnknownCommand
      rescue Exception => e
        raise Cassanity::Error
      end
    end
  end
end
