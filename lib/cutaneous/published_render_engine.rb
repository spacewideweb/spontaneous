# encoding: UTF-8

module Cutaneous
  class PublishedRenderEngine < RenderEngine

    def render_engine
      @render_engine ||= SecondRenderEngine.new(@template_root)
    end


    def is_dynamic?(render)
      Template::STMT_PATTERN === render || Template::EXPR_PATTERN === render
    end

    def render_content(page, format=:html, params={})
      render_engine.render_content(page, format, params)
    end
  end
end


