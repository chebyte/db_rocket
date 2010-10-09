require 'yaml'
require 'logger'

module DBRocket::Command
  class App < Base
    def create
      name = args.shift.downcase.strip rescue nil
      if make_config_file == "y"
        display "You can configurate db_rocket on config/db_rocket.yml"
      end
    end

    def push
      load_taps
      opts = parse_taps_opts

      display("Warning: Data in the app will be overwritten and will not be recoverable.")

      if extract_option("--force") || confirm
        taps_client(:push, opts)
      end
    end

    def pull
      load_taps
      opts = parse_taps_opts

      display("Warning: Data in the database '#{opts[:database_url]}' will be overwritten and will not be recoverable.")

      if extract_option("--force") || confirm
        taps_client(:pull, opts)
      end
    end
  end
end

