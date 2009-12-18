module Lockdown
  module Frameworks
    module Rails
      module View
        def self.included(base)
          base.class_eval do
            alias_method :link_to_open, :link_to
            alias_method :link_to, :link_to_secured

            alias_method :link_to_remote_open, :link_to_remote
            alias_method :link_to_remote, :link_to_remote_secured

            alias_method :button_to_open, :button_to
            alias_method :button_to, :button_to_secured

            alias_method :button_to_remote_open, :button_to_remote
            alias_method :button_to_remote, :button_to_secured

          end
        end

        def link_to_secured(name, options = {}, html_options = nil)
          secured_link_for(:link_to_open, name, options, html_options)
        end

        def link_to_remote_secured(name, options = {}, html_options = nil)
          secured_link_for(:link_to_remote_open, name, options, html_options)
        end


        def button_to_secured(name, options = {}, html_options = nil)
          secured_link_for(:button_to_open, name, options, html_options)
        end

        def button_to_remote_secured(name, options = {}, html_options = nil)
          secured_link_for(:button_to_remote_open, name, options, html_options)
        end


        def link_to_or_show(name, options = {}, html_options = nil)
          lnk = link_to(name, options, html_options)
          lnk.length == 0 ? name : lnk
        end

        def links(*lis)
          rvalue = []
          lis.each{|link| rvalue << link if link.length > 0 }
          rvalue.join( Lockdown::System.fetch(:link_separator) )
        end

        def secured_link_for(link_method_name, name, options, html_options)
          url = url_from(options)
          method = html_options ? html_options[:method] : :get
          url_to_authorize = remove_subdirectory(url)
          if authorized?(url_to_authorize, method)
            return send(link_method_name, name, options, html_options)
          end
          return ""
        end

        private

        def remove_subdirectory(url)
          subdir = Lockdown::System.fetch(:subdirectory)
          subdir ? url.gsub(/^\/?#{subdir}/,'') : url
        end

        def url_from(options)
          url = options.is_a?(Hash) ? options[:url] || options : options
          url_for(url)
        end


      end # View
    end # Rails
  end # Frameworks
end # Lockdown
