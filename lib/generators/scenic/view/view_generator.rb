require "rails/generators"
require "rails/generators/active_record"
require "generators/scenic/materializable"
require "scenic/configuration"

module Scenic
  module Generators
    # @api private
    class ViewGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      include Scenic::Generators::Materializable
      source_root File.expand_path("templates", __dir__)

      def initialize(args, *options)
        if args.present? && args[1].present?
          if %w(true shared global).include? args[1].downcase
            @shared = true
          elsif (args[1].include?("="))
            @shared = args[1].split('=')[1].downcase == "true"
          elsif (args[1].include?(":"))
            @shared = args[1].split('=')[1].downcase == "true"
          else
            @shared = false
          end
        else
          @shared = false
        end
        super(args, options)
      end

      def shared?
        @shared
      end

      def create_views_directory
        unless views_directory_path.exist?
          empty_directory(views_directory_path)
        end
      end

      def create_view_definition
        if creating_new_view?
          create_file definition.path
        else
          copy_file previous_definition.full_path, definition.full_path
        end
      end

      def create_migration_file
        migration_path = "db/migrate"
        if(@shared)
          migration_path = Roomer.shared_migrations_directory
        else
          migration_path = Roomer.tenanted_migrations_directory
        end
        if creating_new_view? || destroying_initial_view?
          migration_template(
            "db/migrate/create_view.erb",
            Rails.root.join(migration_path, "roomer_create_#{plural_file_name}.rb"),
          )
        else
          migration_template(
            "db/migrate/update_view.erb",
            Rails.root.join(migration_path, "roomer_update_#{plural_file_name}_to_version_#{version}.rb"),
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @previous_version ||=
            Dir.entries(views_directory_path)
              .map { |name| version_regex.match(name).try(:[], "version").to_i }
              .max
        end

        def version
          @version ||= destroying? ? previous_version : previous_version.next
        end

        def migration_class_name
          if creating_new_view?
            "RoomerCreate#{class_name.tr('.', '').pluralize}"
          else
            "RoomerUpdate#{class_name.pluralize}ToVersion#{version}"
          end
        end

        def activerecord_migration_class
          if ActiveRecord::Migration.respond_to?(:current_version)
            "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
          else
            "ActiveRecord::Migration"
          end
        end
      end

      private

      def views_directory_path
        if(@shared)
          @views_directory_path ||= Rails.root.join(Roomer.shared_migrations_directory, 'views')
        else
          @views_directory_path ||= Rails.root.join(Roomer.tenanted_migrations_directory, 'views')
        end
      end

      def version_regex
        /\A#{plural_file_name}_v(?<version>\d+)\.sql\z/
      end

      def creating_new_view?
        previous_version.zero?
      end

      def definition
        Scenic::Definition.new(plural_file_name, version, @shared)
      end

      def previous_definition
        Scenic::Definition.new(plural_file_name, previous_version, @shared)
      end

      def plural_file_name
        @plural_file_name ||= file_name.pluralize.tr(".", "_")
      end

      def destroying?
        behavior == :revoke
      end

      def formatted_plural_name
        if plural_name.include?(".")
          "\"#{plural_name}\""
        else
          ":#{plural_name}"
        end
      end

      def create_view_options
        options = ""
        options += ", materialized: #{no_data? ? '{ no_data: true }' : true}" if @materialized
        options += ", shared: true" if @shared
        options
      end

      def destroying_initial_view?
        destroying? && version == 1
      end
    end
  end
end
