module DBRocket
  module Command
    class InvalidCommand < RuntimeError; end
    class CommandFailed  < RuntimeError; end

    class << self
      def run(command, args)
        run_internal(command, args)
      rescue InvalidCommand
        display "Unknown command. Run 'db_rocket help' for usage information."
      end

      def run_internal(command, args)
        namespace, command = parse(command)
        require "#{namespace}"
        klass = DBRocket::Command.const_get(namespace.capitalize).new(args)
        raise InvalidCommand unless klass.respond_to?(command)
        klass.send(command)
      end

      def display(msg)
        puts(msg)
      end

      def parse(command)
        parts = command.split(':')
        case parts.size
          when 1
            if namespaces.include? command
              return command, 'index'
            else
              return 'app', command
            end
          when 2
            raise InvalidCommand unless namespaces.include? parts[0]
            return parts
          else
            raise InvalidCommand
        end
      end

      def namespaces
        @@namespaces ||= Dir["#{File.dirname(__FILE__)}/commands/*"].map do |namespace|
          namespace.gsub(/.*\//, '').gsub(/\.rb/, '')
        end
      end
    end
  end
end

