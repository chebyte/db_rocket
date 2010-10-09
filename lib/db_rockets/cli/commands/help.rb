module DBRocket::Command
  class Help < Base
    def index
      display usage
    end

    def usage
      usage = <<EOTXT
=== General Commands

 help                     # show this usage
 create                   # create config file for your app
 push
 pull

=== Server

 server:start             #run db_rocket server
 server:stop              #stop db_rocket server

=== Example story:

 rails myapp
 cd myapp
 (...make edits...)
 db_rocket create
EOTXT
    end
  end
end

