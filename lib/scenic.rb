require "scenic/configuration"
require "scenic/adapters/postgres"
require "scenic/command_recorder"
require "scenic/definition"
require "scenic/railtie"
require "scenic/schema_dumper"
require "scenic/statements"
require "scenic/version"
require "scenic/view"
require "scenic/index"

# Scenic adds methods `ActiveRecord::Migration` to create and manage database
# views in Rails applications.
module Scenic
  # Hooks Scenic into Rails.
  #
  # Enables scenic migration methods, migration reversibility, and `schema.rb`
  # dumping.
  def self.load
    if Gem.loaded_specs.has_key?('roomer') && Gem.loaded_specs.has_key?('roomer-muid')
      ActiveRecord::ConnectionAdapters::AbstractAdapter.include Scenic::Statements
      ActiveRecord::Migration::CommandRecorder.include Scenic::CommandRecorder
      ActiveRecord::SchemaDumper.prepend Scenic::SchemaDumper
    else
      raise 'This version of scenic requires your application to use 2 additional gems, roomer and roomer-muid. Check the readme for details.'
    end
  end

  # The current database adapter used by Scenic.
  #
  # This defaults to {Adapters::Postgres} but can be overridden
  # via {Configuration}.
  def self.database
    Scenic::Configuration.new.database
  end
end
