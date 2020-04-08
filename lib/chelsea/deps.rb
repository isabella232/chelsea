require 'bundler'
require 'bundler/lockfile_parser'
require 'rubygems'
require 'rubygems/commands/dependency_command'
require 'json'
require 'rest-client'
require 'pstore'

<<<<<<< HEAD
require_relative 'dependency_exception'

=======
<<<<<<< HEAD
=======
require_relative 'dependency_exception'
require_relative 'oss_index'

>>>>>>> 27c0113254ecac028c761b368cc36ab4d7613730
>>>>>>> master
module Chelsea
  class Deps
    attr_reader :server_response, :reverse_dependencies, :coordinates, :dependencies

    def initialize(path: , oss_index_client: , quiet: false)
      @oss_index_client = oss_index_client
      @path, @quiet = path, quiet
      ENV['BUNDLE_GEMFILE'] = File.expand_path(path).chomp(".lock")

      begin
        @lockfile = Bundler::LockfileParser.new(
          File.read(@path)
        )
      rescue
        raise "Gemfile.lock not parseable, please check file or that it's path is valid"
      end

      @dependencies = {}
      @reverse_dependencies = {}
      @dependencies_versions = {}
      @coordinates = { 'coordinates' => [] }
      @server_response = []
      @store = PStore.new(_get_db_store_location())
    end

    def nil?
      @dependencies.empty?
    end

    def self.to_purl(name, version)
      return "pkg:gem/#{name}@#{version}"
    end

<<<<<<< HEAD
    def user_agent
      "chelsea/#{Chelsea::VERSION}"
    end

=======
>>>>>>> 27c0113254ecac028c761b368cc36ab4d7613730
    # Parses specs from lockfile instanct var and inserts into dependenices instance var
    def get_dependencies
      @lockfile.specs.each do |gem|\
        begin
          @dependencies[gem.name] = [gem.name, gem.version]
        rescue StandardError => e
          raise Chelsea::DependencyException e, "Parsing dependency line #{gem} failed."
        end
      end
    end

    # Collects all reverse dependencies in reverse_dependencies instance var
    def get_reverse_dependencies
      begin
        reverse = Gem::Commands::DependencyCommand.new
        reverse.options[:reverse_dependencies] = true
        @reverse_dependencies = reverse.reverse_dependencies(@lockfile.specs).to_h
      rescue => e
        raise Chelsea::DependencyException e, "ReverseDependencyException"
      end
    end

    # Iterates over all dependencies and stores them
    # in dependencies_versions and coordinates instance vars
    def get_dependencies_versions_as_coordinates
      @dependencies.each do |p, r|
        o =  r[0]
        v = r[1].to_s
        if v.split('.').length == 1 then
          v = v + ".0.0"
        elsif v.split('.').length == 2 then
            v = v + ".0"
        end
        @dependencies_versions[p] = v
      end

      @dependencies_versions.each do |p, v|
        @coordinates["coordinates"] << self.class.to_purl(p,v);
      end
    end

    # Makes REST calls to OSS for vulnerabilities 128 coordinates at a time
    # Checks cache and stores results in cache
    def get_vulns()
      _check_db_for_cached_values()

      if @coordinates["coordinates"].count() > 0
        chunked = Hash.new()
        @coordinates["coordinates"].each_slice(128).to_a.each do |coords|
          chunked["coordinates"] = coords
<<<<<<< HEAD
          r = RestClient.post "https://ossindex.sonatype.org/api/v3/component-report", chunked.to_json,
            { content_type: :json, accept: :json, 'User-Agent': user_agent }
          if r.code == 200
            @server_response = @server_response.concat(JSON.parse(r.body))
            _save_values_to_db(JSON.parse(r.body))
          end
=======
          res_json = @oss_index_client.call_oss_index(chunked)
          @server_response = @server_response.concat(res_json)
          _save_values_to_db(res_json)
>>>>>>> 27c0113254ecac028c761b368cc36ab4d7613730
        end
      end
    end

    protected
    # This method will take an array of values, and save them to a pstore database
    # and as well set a TTL of Time.now to be checked later
    def _save_values_to_db(values)
      values.each do |val|
        if _get_cached_value_from_db(val["coordinates"]).nil?
          new_val = val.dup
          new_val["ttl"] = Time.now
          @store.transaction do
            @store[new_val["coordinates"]] = new_val
          end
        end
      end
    end

    def _get_db_store_location()
      initial_path = File.join("#{Dir.home}", ".ossindex")
      Dir.mkdir(initial_path) unless File.exists? initial_path
      path = File.join(initial_path, "chelsea.pstore")
    end

    # Checks pstore to see if a coordinate exists, and if it does also
    # checks to see if it's ttl has expired. Returns nil unless a record
    # is valid in the cache (ttl has not expired) and found
    def _get_cached_value_from_db(coordinate)
      record = @store.transaction { @store[coordinate] }
      if !record.nil?
        diff = (Time.now - record['ttl']) / 3600
        if diff > 12
          return nil
        else
          return record
        end
      else
        return nil
      end
    end

    # Goes through the list of @coordinates and checks pstore for them, if it finds a valid coord
    # it will add it to the server response. If it does not, it will append the coord to a new hash
    # and eventually set @coordinates to the new hash, so we query OSS Index on only coords not in cache
    def _check_db_for_cached_values()
      new_coords = Hash.new
      new_coords["coordinates"] = Array.new
      @coordinates["coordinates"].each do |coord|
        record = _get_cached_value_from_db(coord)
        if !record.nil?
          @server_response << record
        else
          new_coords["coordinates"].push(coord)
        end
      end
      @coordinates = new_coords
    end
  end
end
