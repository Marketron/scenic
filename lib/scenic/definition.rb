require "scenic/configuration"

module Scenic
  # @api private
  class Definition
    def initialize(name, version, shared)
      @name = name
      @version = version.to_i
      @shared = shared
    end

    def to_sql
      File.read(full_path).tap do |content|
        if content.empty?
          raise "Define view query in #{path} before migrating."
        end
      end
    end

    def full_path
      Rails.root.join(path)
    end

    def path
      if(@shared)
        File.join(Roomer.shared_migrations_directory, "views", filename)
      else
        File.join(Roomer.tenanted_migrations_directory, "views", filename)
      end
    end

    def version
      @version.to_s.rjust(2, "0")
    end

    private

    def filename
      "#{@name}_v#{version}.sql"
    end
  end
end
