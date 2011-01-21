require 'thor'

module Spontaneous
  module Cli
    class Base < Thor
      include Thor::Actions

      class_option :site, :type => :string, :aliases => ["-s", "--root"], :desc => "Site root dir"
      class_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development, :desc => "Spontaneous Environment"
      class_option :mode, :type => :string,  :aliases => "-m", :default => :back, :desc => "Spontaneous mode ('front' or 'back')"
      class_option :help, :type => :boolean, :desc => "Show help usage"

      desc :start, "Starts the Spontaneous CMS"
      def start
        prepare :start
        puts "starting"
      end

      desc :publish, "Publishes the site"
      method_option :changes, :type => :array, :desc => "List of changesets to include"
      method_option :logfile, :type => :string, :desc => "Location of logfile"

      def publish
        prepare :publish
        # TODO: set up logging
        require File.expand_path('config/boot.rb')
        Spontaneous::Logger.setup(:logfile => options.logfile) if options.logfile
        logger.info { "publishing revision #{Site.revision} of site #{options.site}" }
        if options.changes
          logger.info "Publishing changes #{options.changes.inspect}"
          Site.publish_changes(options.changes)
        else
          logger.info "Publishing all"
          Site.publish_all
        end
      end

      desc :revision, "Shows the site status"
      def revision
        prepare :revision
        require File.expand_path('config/boot.rb')
        puts "Site is at revision #{Site.revision}"
      end

      desc :console, "Gives you console access to the current site"
      def console
        prepare :console
        ARGV.clear
        puts "=> Loading #{options.environment} console"
        require 'irb'
        require File.expand_path('config/boot.rb')
        IRB.setup(nil)
        irb = IRB::Irb.new
        IRB.conf[:MAIN_CONTEXT] = irb.context
        irb.context.evaluate("require 'irb/completion'", 0)
        irb.context.evaluate("require '#{File.expand_path(File.dirname(__FILE__) + '/console')}'", 0)
        irb.context.evaluate("include Spontaneous", 0)
        trap("SIGINT") do
          irb.signal_handle
        end
        catch(:IRB_EXIT) do
          irb.eval_input
        end
      end

      private
      def prepare(task)
        if options.help?
          help(task.to_s)
          raise SystemExit
        end
        ENV["SPOT_ENV"] ||= options.environment.to_s
        ENV["SPOT_MODE"] ||= options.mode.to_s
        ENV["RACK_ENV"] = ENV["SPOT_ENV"] # Also set this for middleware
        chdir(options.site)
        # unless File.exist?('config/boot.rb')
        #   puts "=> Could not find boot file in: #{options.chdir}/config/boot.rb !!!"
        #   raise SystemExit
        # end
      end

      protected
      def chdir(dir)
        return unless dir
        begin
          Dir.chdir(dir.to_s)
        rescue Errno::ENOENT
          puts "=> Specified site '#{dir}' does not appear to exist!"
        rescue Errno::EACCES
          puts "=> Specified site '#{dir}' cannot be accessed by the current user!"
        end
      end

    end # Base
  end # Cli
end # Spontaneous
