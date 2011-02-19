require 'zippy'

Mime::Type.register 'application/zip', :zip

module ::ActionView
  module TemplateHandlers
    class Zipper < TemplateHandler
      include Compilable
 
      def compile(template)
        "Zippy.new do |zip|\n" +
        (template.respond_to?(:source) ? template.source : template) + "\n" +
        "end.data"
      end
    end
  end
end

if defined? ::ActionView::Template and ::ActionView::Template.respond_to? :register_template_handler
  ::ActionView::Template
else
  ::ActionView::Base
end.register_template_handler(:zipper, ::ActionView::TemplateHandlers::Zipper)
