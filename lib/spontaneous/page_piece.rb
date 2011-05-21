# encoding: UTF-8


module Spontaneous
  class PagePiece < ProxyObject
    extend Plugins
    plugin Plugins::Render

    attr_accessor :container
    attr_reader :target_id, :style_id

    def initialize(container, target_id, style_id)
      @container, @target_id, @style_id = container, target_id, style_id
    end

    def self.find_target(container, id)
      Content[id]
    end

    def target
      @target ||= Content[target_id]
    end

    def depth
      container.content_depth + 1
    end

    def style(format = :html)
      target.class.resolve_style(style_name, format)
    end

    def to_hash
      target.to_shallow_hash.merge(styles_to_hash).merge({
        :depth => self.depth
      })
    end

    def styles_to_hash
      {
        :style => style_id.to_s,
        :styles => container.available_styles(target).map { |n, s| s.name.to_s },
      }
    end

    def serialize_entry
      {
        :page => target.id,
        :style_id => @style_id
      }
    end

    def style=(style)
      @style_id = style
      # because it's not obvious that a change to an entry
      # will affect the fields of the container piece
      # make sure that the container is saved using an instance hook
      target.after_save_hook do
        container.save
      end
      container.entry_modified!(self)
    end

    def style(format = :html)
      target.resolve_style(style_id, format)
    end

    def template(format = :html)
      style(format).template(format)
    end

    def method_missing(method, *args)
      if block_given?
        self.target.__send__(method, *args, &Proc.new)
      else
        self.target.__send__(method, *args)
      end
    end
  end
end

