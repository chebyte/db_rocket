require 'yaml'
require 'logger'

module DBRocket::Command
  class Server < Base
    def start
      if File.exists?(pid_file)
        puts "db_rocket server is running...."
      else
        load_taps
        opts = parse_server_taps_opts
        Taps.log.level = Logger::DEBUG if opts[:debug]
        Taps::Config.database_url = opts[:database_url]
        Taps::Config.login = opts[:login]
        Taps::Config.password = opts[:password]

        Taps::Config.verify_database_url
        require 'taps/server'
        pid = fork do
          Taps::Server.run!({
            :port => opts[:port],
            :environment => :production,
            :logging => true,
            :dump_errors => true,
          })
        end
        File.open(pid_file, 'w') {|f| f.write(pid) }
      end
    end

    def stop
      if File.exists?(pid_file)
        process_id = File.open(pid_file,'r').readline
        Process.kill 9, process_id.to_i
        FileUtils.rm(pid_file)
      end
    end

    def pid_file
      '/tmp/db_rockets.pid'
    end

    def parse_server_taps_opts
      opts = {}
      opts[:environment] = extract_option("--environment") || ENV['RAILS_ENV'] || ENV['MERB_ENV'] || ENV['RACK_ENV']  || 'development'
      opts[:database_url] = args.shift.strip rescue ''
      if opts[:database_url] == ''
        opts[:database_url] = parse_database_yml(opts[:environment])
        display "Auto-detected local database: #{opts[:database_url]}" if opts[:database_url] != ''
      end
      raise(CommandFailed, "Invalid database url") if opts[:database_url] == ''

      if extract_option("--debug")
        opts[:debug] = true
      end
      conf = YAML.load(File.read(Dir.pwd + "/#{config_file}"))[opts[:environment]]
      opts[:login]    = conf['http_user']
      opts[:password] = conf['http_password']
      opts[:port]     = conf['port']
      opts
    end
  end
end

