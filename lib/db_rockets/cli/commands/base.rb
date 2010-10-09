require 'fileutils'

module DBRocket::Command
  class Base
    attr_accessor :args
    def initialize(args)
      @args = args
    end

    def extract_option(options, default=true)
      values = options.is_a?(Array) ? options : [options]
      return unless opt_index = args.select { |a| values.include? a }.first
      opt_position = args.index(opt_index) + 1
      if args.size > opt_position && opt_value = args[opt_position]
        if opt_value.include?('--')
          opt_value = nil
        else
          args.delete_at(opt_position)
        end
      end
      opt_value ||= default
      args.delete(opt_index)
      block_given? ? yield(opt_value) : opt_value
    end

    def display(msg, newline=true)
      if newline
        puts(msg)
      else
        print(msg)
        STDOUT.flush
      end
    end

    def confirm(message="Are you sure you wish to continue? (y/n)?")
      display("#{message} ", false)
      ask.downcase == 'y'
    end

    def error(msg)
      STDERR.puts(msg)
      exit 1
    end


    def ask
      gets.strip
    end

    def shell(cmd)
      `#{cmd}`
    end

    def home_directory
      running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
    end

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32/
    end

    def config_file
      'config/db_rocket.yml'
    end

    def ask_for_config_file
      if File.exists?(config_file)
        print "The file config/db_rocket.yml exists, do you want overwrite this? (y/n): "
        ask
      else
        "y"
      end
    end

    def parse_database_yml(environment = nil)
      return "" unless File.exists?(Dir.pwd + '/config/database.yml')

      environment = ENV['RAILS_ENV'] || ENV['MERB_ENV'] || ENV['RACK_ENV'] if environment.nil?
      environment = 'development' if environment.nil? or environment.empty?

      conf = YAML.load(File.read(Dir.pwd + '/config/database.yml'))[environment]
      case conf['adapter']
        when 'sqlite3'
          return "sqlite://#{conf['database']}"
        when 'postgresql'
          uri_hash = conf_to_uri_hash(conf)
          uri_hash['scheme'] = 'postgres'
          return uri_hash_to_url(uri_hash)
        else
          return uri_hash_to_url(conf_to_uri_hash(conf))
      end
    rescue Exception => ex
      puts "Error parsing database.yml: #{ex.message}"
      puts ex.backtrace
      ""
    end

    def conf_to_uri_hash(conf)
      uri = {}
      uri['scheme'] = conf['adapter']
      uri['username'] = conf['user'] || conf['username']
      uri['password'] = conf['password']
      uri['host'] = conf['host'] || conf['hostname']
      uri['port'] = conf['port']
      uri['path'] = conf['database']

      conf['encoding'] = 'utf8' if conf['encoding'] == 'unicode' or conf['encoding'].nil?
      uri['query'] = "encoding=#{conf['encoding']}"

      uri
    end

    def userinfo_from_uri(uri)
      username = uri['username'].to_s
      password = uri['password'].to_s
      return nil if username == ''

      userinfo  = ""
      userinfo << username
      userinfo << ":" << password if password.length > 0
      userinfo
    end

    def uri_hash_to_url(uri)
      uri_parts = {
        :scheme   => uri['scheme'],
        :userinfo => userinfo_from_uri(uri),
        :password => uri['password'],
        :host     => uri['host'] || '127.0.0.1',
        :port     => uri['port'],
        :path     => "/%s" % uri['path'],
        :query    => uri['query'],
      }

      URI::Generic.build(uri_parts).to_s
    end

    def parse_taps_opts
      opts = {}
      opts[:default_chunksize] = extract_option("--chunksize") || 1000
      opts[:default_chunksize] = opts[:default_chunksize].to_i rescue 1000
      opts[:environment] = extract_option("--environment") || ENV['RAILS_ENV'] || ENV['MERB_ENV'] || ENV['RACK_ENV']  || 'development'

      if filter = extract_option("--filter")
        opts[:table_filter] = filter
      elsif tables = extract_option("--tables")
        r_tables = tables.split(",").collect { |t| "^#{t.strip}$" }
        opts[:table_filter] = "(#{r_tables.join("|")})"
      end

      if extract_option("--disable-compression")
        opts[:disable_compression] = true
      end

      if resume_file = extract_option("--resume-filename")
        opts[:resume_filename] = resume_file
      end

      opts[:indexes_first] = !extract_option("--indexes-last")

      opts[:database_url] = args.shift.strip rescue ''
      if opts[:database_url] == ''
        opts[:database_url] = parse_database_yml(opts[:environment])
        display "Auto-detected local database: #{opts[:database_url]}" if opts[:database_url] != ''
      end
      raise(CommandFailed, "Invalid database url") if opts[:database_url] == ''

      if extract_option("--debug")
        Taps.log.level = Logger::DEBUG
      end

      #ENV['TZ'] = 'America/Los_Angeles'
      opts
    end

    def taps_client(op, opts)
      Taps::Config.verify_database_url(opts[:database_url])
      if opts[:resume_filename]
        Taps::Cli.new([]).clientresumexfer(op, opts)
      else
        opts[:remote_url] = make_url_from_config(opts[:environment])
        Taps::Cli.new([]).clientxfer(op, opts)
      end
    end

    def make_url_from_config environment
      conf = YAML.load(File.read(Dir.pwd + "/#{config_file}"))[environment]
      "http://#{conf['http_user']}:#{conf['http_password']}@#{conf['server']}:#{conf['port']}"
    end

    def load_taps
      require 'taps/operation'
      require 'taps/cli'
      error "The db rocket gem requires taps 0.3" unless Taps.version =~ /^0.3/
      display "Loaded Taps v#{Taps.version}"
    rescue LoadError
      message  = "Taps 0.3 Load Error: #{$!.message}\n"
      message << "You may need to install or update the taps gem to use db commands.\n"
      message << "On most systems this will be:\n\nsudo gem install taps"
      error message
    end


    def make_config_file
      overwrite_or_create_file = ask_for_config_file
      if overwrite_or_create_file == "y"
        config_file_hash = <<EOFILE
common: &common
  server: 127.0.0.1
  port: 5555
  http_user: user
  http_password: password
development:
  <<: *common
production:
  <<: *common
EOFILE
        File.open(config_file, 'w') do |f|
          f.puts config_file_hash
        end
      end
      overwrite_or_create_file
    end
  end
end

