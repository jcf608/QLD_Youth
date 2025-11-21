# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'yaml'
require 'erb'

module Pipelines
  # Service for creating timestamped database backups of PROVENANCE DATA ONLY
  # Backs up documents and document_versions tables before cloud infrastructure teardown
  # Does NOT back up RAG infrastructure (chunks, embeddings, indexes) as those are tied to deleted cloud resources
  class DatabaseBackupService
    class BackupError < StandardError; end

    # Tables to backup (provenance only)
    PROVENANCE_TABLES = %w[
      documents
      document_versions
    ].freeze

    def self.call(options = {})
      new.call(options)
    end

    def call(options = {})
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      backup_dir = ensure_backup_directory
      backup_file = File.join(backup_dir, "provenance_backup_#{timestamp}.sql")

      puts "Creating provenance backup: #{backup_file}"
      puts "Backing up tables: #{PROVENANCE_TABLES.join(', ')}"

      # Get database configuration
      db_config = get_database_config

      case db_config[:adapter]
      when 'postgresql'
        backup_postgresql(db_config, backup_file)
      when 'mysql2'
        backup_mysql(db_config, backup_file)
      else
        raise BackupError, "Unsupported database adapter: #{db_config[:adapter]}. Only PostgreSQL and MySQL are supported."
      end

      # Verify backup was created
      unless File.exist?(backup_file)
        raise BackupError, "Backup file was not created: #{backup_file}"
      end

      file_size = File.size(backup_file)
      puts "✅ Backup created successfully: #{backup_file} (#{format_bytes(file_size)})"

      {
        success: true,
        backup_file: backup_file,
        timestamp: timestamp,
        size_bytes: file_size,
        size_formatted: format_bytes(file_size)
      }
    rescue StandardError => e
      {
        success: false,
        error: "Failed to create database backup: #{e.message}"
      }
    end

    private

    # Ensure backup directory exists
    def ensure_backup_directory
      backup_dir = File.join(Dir.pwd, 'tmp', 'backups')
      FileUtils.mkdir_p(backup_dir) unless Dir.exist?(backup_dir)
      backup_dir
    end

    # Get database configuration from environment or config file
    def get_database_config
      if File.exist?('config/database.yml')
        require 'yaml'
        require 'erb'
        config = YAML.safe_load(ERB.new(File.read('config/database.yml')).result, aliases: true)
        env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
        db_config = config[env] || config['development']

        {
          adapter: db_config['adapter'],
          database: db_config['database'],
          host: db_config['host'],
          port: db_config['port'],
          username: db_config['username'],
          password: db_config['password']
        }
      else
        raise BackupError, "Database configuration file not found: config/database.yml"
      end
    end

    # Backup PostgreSQL database (provenance tables only)
    def backup_postgresql(config, backup_file)
      env_vars = {}
      env_vars['PGPASSWORD'] = config[:password] if config[:password]

      # Use -t flag to specify tables
      table_flags = PROVENANCE_TABLES.map { |t| "-t #{t}" }.join(' ')

      cmd_parts = ['pg_dump']
      cmd_parts << "-h #{config[:host]}" if config[:host]
      cmd_parts << "-p #{config[:port]}" if config[:port]
      cmd_parts << "-U #{config[:username]}" if config[:username]
      cmd_parts << table_flags
      cmd_parts << config[:database]
      cmd_parts << "> #{backup_file}"

      cmd = cmd_parts.join(' ')
      result = system(env_vars, cmd)

      unless result
        raise BackupError, "PostgreSQL backup failed"
      end
    end

    # Backup MySQL database (provenance tables only)
    def backup_mysql(config, backup_file)
      cmd_parts = ['mysqldump']
      cmd_parts << "-h #{config[:host]}" if config[:host]
      cmd_parts << "-P #{config[:port]}" if config[:port]
      cmd_parts << "-u #{config[:username]}" if config[:username]
      cmd_parts << "-p#{config[:password]}" if config[:password]
      cmd_parts << config[:database]
      cmd_parts << PROVENANCE_TABLES.join(' ')
      cmd_parts << "> #{backup_file}"

      cmd = cmd_parts.join(' ')
      result = system(cmd)

      unless result
        raise BackupError, "MySQL backup failed"
      end
    end

    # Format bytes to human-readable format
    def format_bytes(bytes)
      return '0 B' if bytes.zero?

      units = %w[B KB MB GB TB]
      exp = (Math.log(bytes) / Math.log(1024)).to_i
      exp = [exp, units.length - 1].min

      "%.2f %s" % [bytes.to_f / (1024 ** exp), units[exp]]
    end
  end
end
