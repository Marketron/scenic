module Scenic
  class Configuration
    # The Scenic database adapter instance to use when executing SQL.
    #
    # Defualts to an instance of {Adapters::Postgres}
    # @return Scenic adapter
    attr_accessor :database

    def initialize
      @database = Scenic::Adapters::Postgres.new
    end

    # name of the shared schema where all the shared tables are be present
    mattr_accessor :shared_schema_name
    @@shared_schema_name = :global

    # The schema seperator. This is used when generating the table name.
    # The default is set to "."
    # Example: tenant's table by default will be global.tenants
    mattr_accessor :schema_seperator
    @@schema_seperator = '.'

    # Directory where schema files will be stored.
    mattr_accessor :schemas_directory
    @@schemas_directory = File.expand_path(File.join("db", "schemas"))

    # Tenanted schema filename.
    mattr_accessor :tenanted_schema_filename
    @@tenanted_schema_filename = "tenanted_schema.rb"

    # Shared schema filename.
    mattr_accessor :shared_schema_filename
    @@shared_schema_filename = "shared_schema.rb"

    # Directory where schema files will be stored.
    mattr_accessor :schemas_directory
    @@schemas_directory = File.expand_path(File.join("db", "schemas"))

    # Tenanted schema filename.
    mattr_accessor :tenanted_schema_filename
    @@tenanted_schema_filename = "tenanted_schema.rb"

    # Shared schema filename.
    mattr_accessor :shared_schema_filename
    @@shared_schema_filename = "shared_schema.rb"

    # Directory where the tenanted migrations are stored.
    # This will be used only if use_tenanted_migration_directory is set to
    # true if not usual rails migration directory db/migrate will be used
    mattr_accessor :tenanted_migrations_directory
    @@tenanted_migrations_directory = File.join("db", "migrate", "tenanted")


    # Directory where shared migrations are stored.
    mattr_accessor :shared_migrations_directory
    @@shared_migrations_directory = File.join("db", "migrate", shared_schema_name.to_s)
  end

  # @return [Scenic::Configuration] Scenic's current configuration
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Set Scenic's configuration
  #
  # @param config [Scenic::Configuration]
  def self.configuration=(config)
    @configuration = config
  end

  # Modify Scenic's current configuration
  #
  # @yieldparam [Scenic::Configuration] config current Scenic config
  # ```
  # Scenic.configure do |config|
  #   config.database = Scenic::Adapters::Postgres.new
  # end
  # ```
  def self.configure
    yield configuration
  end
end
