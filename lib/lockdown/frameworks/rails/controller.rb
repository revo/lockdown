module Lockdown
  module Frameworks
    module Rails
      module Controller
        
        def available_actions(klass)
          klass.action_methods
        end

        def controller_name(klass)
          klass.controller_name
        end

        # Locking methods
        module Lock

          def configure_lockdown
            Lockdown.maybe_parse_init
            check_session_expiry
            store_location
          end

          # Basic auth functionality needs to be reworked as 
          # Lockdown doesn't provide authentication functionality.
          def set_current_user
            #login_from_basic_auth? unless logged_in?
            if logged_in?
              Thread.current[:who_did_it] = Lockdown::System.
                call(self, :who_did_it)
            end
          end

          def check_request_authorization
            unless authorized?(path_from_hash(params))
              raise SecurityError, "Lockdown Authorization failed! \nparams: #{params.inspect}\nsession: #{session.inspect}"
            end
          end

          protected
          def path_allowed?(path, user)
            if user
              return user_groups_allowed_on_path?(path, user.user_groups)
            else
              return path_part_of_public_access?(path)
            end
          end

          def user_groups_allowed_on_path?(path, user_groups)
            if @acces_group_rights.nil?
                @acces_group_rights = {}
            end

            user_groups.each do |user_group|
              user_group_sym = user_group.name.underscore.tr(' ','_').to_sym

              if @acces_group_rights[user_group_sym].nil?
                @acces_group_rights[user_group_sym] = Lockdown::System.public_access + Lockdown::System.access_rights_for_user_group(user_group_sym)
              end

              return true if @acces_group_rights[user_group_sym].include?(path)
            end
            return false
          end

          def path_part_of_public_access?(path)
            return Lockdown::System.public_access.include?(path)
          end
    
          def check_session_expiry
            if session[:expiry_time] && session[:expiry_time] < Time.now
              nil_lockdown_values
              Lockdown::System.call(self, :session_timeout_method)
            end
            session[:expiry_time] = Time.now + Lockdown::System.fetch(:session_timeout)
          end
          
          def store_location
            if (request.method == :get) && (session[:thispage] != sent_from_uri)
              session[:prevpage] = session[:thispage] || ''
              session[:thispage] = sent_from_uri
            end
          end

          def sent_from_uri
            request.request_uri
          end
      
          def authorized?(url, method = nil)
            # Reset access unless caching?
            add_lockdown_session_values unless Lockdown.caching?

            return false unless url

            return true if current_user_is_admin?

            method ||= (params[:method] || request.method)

            url_parts = URI::split(url.strip)

            path = url_parts[5]

            return true if path_allowed?(path, current_user)

            begin
              hash = ActionController::Routing::Routes.recognize_path(path, :method => method)
              return path_allowed?(path_from_hash(hash), current_user) if hash
            rescue Exception => e
              # continue on
            end

            # Mailto link
            return true if url =~ /^mailto:/

            # Public file
            file = File.join(RAILS_ROOT, 'public', url)
            return true if File.exists?(file)

            # Passing in different domain
            return remote_url?(url_parts[2])
          end
    
          def ld_access_denied(e)

            Lockdown.logger.info "Access denied: #{e}"

            if Lockdown::System.fetch(:logout_on_access_violation)
              reset_session
            end
            respond_to do |format|
              format.html do
                store_location
                access_denied_action = Lockdown::System.fetch(:access_denied_action)
                if access_denied_action && respond_to?(access_denied_action)
                  send(access_denied_action)
                else
                  redirect_to Lockdown::System.fetch(:access_denied_path)
                end
                return
              end
              format.xml do
                headers["Status"] = "Unauthorized"
                headers["WWW-Authenticate"] = %(Basic realm="Web Password")
                render :text => e.message, :status => "401 Unauthorized"
                return
              end
            end
          end

          def path_from_hash(hash)
            hash[:controller].to_s + "/" + hash[:action].to_s
          end

          def remote_url?(domain = nil)
            return false if domain.nil? || domain.strip.length == 0
            request.host.downcase != domain.downcase
          end

          def redirect_back_or_default(default)
            if session[:prevpage].nil? || session[:prevpage].blank?
              redirect_to(default) 
            else
              redirect_to(session[:prevpage])
            end
          end
  
          # Called from current_user.  Now, attempt to login by
          # basic authentication information.
          def login_from_basic_auth?
            username, passwd = get_auth_data
            if username && passwd
              set_session_user ::User.authenticate(username, passwd)
            end
          end

          @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
          # gets BASIC auth info
          def get_auth_data
            auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
            auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
            return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
          end
        end # Lock
      end # Controller
    end # Rails
  end # Frameworks
end # Lockdown


