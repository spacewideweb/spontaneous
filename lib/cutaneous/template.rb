# encoding: UTF-8

module Cutaneous
  class Template < Tenjin::Template
    include TemplateCore

    ## %{ ruby_code }
    STMT_PATTERN = /%\{( |\t|\r?\n)(.*?) *\}(?:[ \t]*\r?\n)?/m

    ##  #{ statement } or ${ statement }
    EXPR_PATTERN = /([\$#])\{(.*?)\}/m

    def stmt_pattern
      STMT_PATTERN
    end

    def expr_pattern
      EXPR_PATTERN
    end


  end
end

