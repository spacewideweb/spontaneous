# encoding: UTF-8


module Spontaneous::Plugins
  module Site
    module Publishing

      module BackgroundPublishing
        def self.publish_changes(revision, change_list)
          # launch background publish to call 
          # ImmediatePublishing.publish with the same args
          # catch any exceptions and pass them onto some notification
          # system
        end

        def self.publish_all(revision)
        end
      end

      module ImmediatePublishing
        def self.publish_changes(revision, change_list)
          changes = change_list.flatten.map { |c|
             c.is_a?(S::Change) ? c : S::Change[c]
          }
          change_set = S::ChangeSet.new(changes)

          publish(revision, change_set.page_ids)

          changes.each do |change|
            change.destroy
          end
        end

        def self.publish_all(revision)
          publish(revision, nil)
          S::Change.delete
        end

        protected

        def self.publish(revision, pages)
          before_publish(revision)
          begin
            S::Content.publish(revision, pages)
            render_revision(revision)
            after_publish(revision)
          rescue Exception => e
            abort_publish(revision)
            raise(e)
          end
        end

        def self.render_revision(revision)
          # do render here
        end

        def self.after_publish(revision)
          S::Revision.create(:revision => revision, :published_at => Time.now)
          S::Site.send(:set_published_revision, revision)
        end

        def self.before_publish(revision)
          S::Site.send(:pending_revision=, revision)
        end

        def self.abort_publish(revision)
          S::Site.send(:pending_revision=, nil)
          S::Content.delete_revision(revision)
        end
      end

      module ClassMethods
        def publishing_method
          @publishing_method ||= ImmediatePublishing
        end

        def publishing_method=(method)
          case method
          when :background
            @publishing_method = BackgroundPublishing
          else
            @publishing_method = ImmediatePublishing
          end
        end

        def publish_changes(change_list=nil)
          publishing_method.publish_changes(self.revision, change_list)
        end

        def publish_all
          publishing_method.publish_all(self.revision)
        end

        protected

        def set_published_revision(revision)
          instance = S::Site.instance
          instance.published_revision = revision
          instance.revision = revision + 1
          instance.save
        end

        def pending_revision=(revision)
          instance = S::Site.instance
          instance.pending_revision = revision
          instance.save
        end


      end # ClassMethods

    end # Publishing
  end # Site
end # Spontaneous::Plugins


