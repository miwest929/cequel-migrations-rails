require 'shearwater'
require 'shearwater/cassandra_cql_backend'

namespace :cequel do
  desc "Create the cequel specified cassandra keystore for the current environment"
  task :create => :environment do
    cql_manager = Cequel::Migrations::Rails::CqlManager.new
    cql_manager.create_keyspace
    cql_manager.use_keyspace
    cql_manager.db.execute("CREATE COLUMNFAMILY schema_migrations (version bigint PRIMARY KEY, migrated_at timestamp)")
  end

  desc "Drop the cequel specified cassandra keystore for the current environment"
  task :drop => :environment do
    cql_manager = Cequel::Migrations::Rails::CqlManager.new
    cql_manager.drop_keyspace
  end

  desc "Migrate the cassandra store"
  task :migrate => :environment do
    cql_manager = Cequel::Migrations::Rails::CqlManager.new
    cql_manager.use_keyspace

    # Create the migrator
    backend = Shearwater::CassandraCqlBackend.new(cql_manager.db)
    migrations_directory = ::Rails.root.join('cequel', 'migrate')
    migrator = Shearwater::Migrator.new(migrations_directory, backend)

    # Migrate
    migrator.migrate
  end

  desc "Rollback to the previous migration version by 1 step"
  task :rollback => :environment do
    cql_manager = Cequel::Migrations::Rails::CqlManager.new
    cql_manager.use_keyspace

    # Create the migrator
    backend = Shearwater::CassandraCqlBackend.new(cql_manager.db)
    migrations_directory = ::Rails.root.join('cequel', 'migrate')
    migrator = Shearwater::Migrator.new(migrations_directory, backend)

    steps = ENV['STEPS'] || 1

    # Migrate
    migrator.rollback(steps.to_i)
  end

  desc "Drop the keystore, recreate it and run the migrations"
  task :reset  do
    Rake::Task["cequel:drop"].invoke
    Rake::Task["cequel:create"].invoke
    Rake::Task["cequel:migrate"].invoke
  end
end
