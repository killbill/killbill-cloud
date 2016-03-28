require 'base64'
require 'json'
require 'logger'
require 'open-uri'
require 'pathname'

module KPM
  class Migrations

    KILLBILL_MIGRATION_PATH = /src\/main\/resources\/org\/killbill\/billing\/[a-z]+\/migration\/(V[0-9a-zA-Z_]+.sql)/
    JAVA_PLUGIN_MIGRATION_PATH = /src\/main\/resources\/migration\/(V[0-9a-zA-Z_]+.sql)/
    RUBY_PLUGIN_MIGRATION_PATH = /db\/migrate\/([0-9a-zA-Z_]+.rb)/

    # Go to https://github.com/settings/tokens to generate a token
    def initialize(from_version, to_version = nil, repository = 'killbill/killbill', oauth_token = nil, logger = Logger.new(STDOUT))
      @from_version = from_version
      @to_version = to_version
      @repository = repository
      @oauth_token = oauth_token
      @logger = logger
    end

    def migrations
      @migrations ||= begin
        if @to_version.nil?
          for_version(@from_version)
        else
          migrations_to_skip = Set.new
          for_version(@from_version, true).each { |migration| migrations_to_skip << migration[:name] }

          for_version(@to_version, false, migrations_to_skip)
        end
      end
    end

    def save(dir = nil)
      return nil if migrations.size == 0

      dir ||= Dir.mktmpdir
      @logger.debug("Storing migrations to #{dir}")
      migrations.each do |migration|
        migration_path = Pathname.new(dir).join(migration[:name])
        File.open(migration_path, 'w') do |file|
          @logger.debug("Storing migration #{migration_path}")
          file.write(migration[:sql])
        end
      end
      dir
    end

    private

    def for_version(version = @from_version, name_only = false, migrations_to_skip = Set.new)
      @logger.info("Looking for migrations repository=#{@repository}, version=#{version}")
      metadata = get_as_json("https://api.github.com/repos/#{@repository}/git/trees/#{version}?recursive=1&access_token=#{@oauth_token}")

      migrations = []
      metadata['tree'].each do |entry|
        match_data = KILLBILL_MIGRATION_PATH.match(entry['path']) || JAVA_PLUGIN_MIGRATION_PATH.match(entry['path']) || RUBY_PLUGIN_MIGRATION_PATH.match(entry['path'])
        next unless match_data

        migration_name = match_data[1]
        @logger.info("Found migration #{migration_name}")
        next if migrations_to_skip.include?(migration_name)

        sql = nil
        unless name_only
          blob_metadata = get_as_json("#{entry['url']}?access_token=#{@oauth_token}")
          sql = decode(blob_metadata['content'], blob_metadata['encoding'])
        end

        migrations << {
            :name => migration_name,
            :sql => sql
        }
      end

      migrations
    end

    def get_as_json(url)
      raw = URI.parse(url).read
      JSON.parse(raw)
    end

    def decode(content, encoding)
      if encoding == 'base64'
        Base64.decode64(content)
      else
        content
      end
    end
  end
end
