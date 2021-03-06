# encoding: utf-8

module Backup
  module Storage
    class SCMBase < SSHBase

      include Utilities::Helpers

      def initialize(model, storage_id = nil)
        super
      end

      def transfer!
        connection do |ssh|
          self.init_repo ssh
          self.prepare_syncer
          self.syncer.perform!
          Logger.info "Commiting changes"
          self.commit ssh
        end
      end

      def syncer
        self.rsync
      end

      protected

      # now the triggers were run we can find and add them to the syncer
      def prepare_syncer
        Dir.glob(File.join(Config.tmp_path, package.trigger, '*')).each do |dir|
          syncer.add dir
        end
      end

      def init_repo(ssh)
        ssh.exec! "mkdir -p '#{ remote_path }'"
      end
      def commit(ssh)
        raise 'Not implemented'
      end

      def filenames
        syncer.directories.map{ |d| File.basename d }
      end

      # Reimplement to remove time from path
      def remote_path pkg = package
        @remote_path ||= path.strip
      end

      def rsync
        unless @rsync
          @rsync = Backup::Syncer::RSync::Push.new
          @rsync.mode = :ssh
          @rsync.mirror = true
          @rsync.compress = true
          @rsync.host = self.ip
          @rsync.port = self.port
          @rsync.ssh_user = self.username
          @rsync.path = self.remote_path

          self.excludes.each do |dir|
            @rsync.exclude dir
          end
        end
        @rsync
      end

      # Disable cycling for an obvious reason
      def cycle!
      end

      def excludes
        []
      end

    end
  end
end

