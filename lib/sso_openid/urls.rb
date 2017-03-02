module SsoOpenid
  class Urls

    # Provides a list of the NFG applications by url for environment
    # in which the containing application is running
    # The list of urls can by found in the urls.yml file.

    # Calling SsoOpenid.Urls.<name of application> will return the host
    # value of that application. i.e SsoOpenid.Urls.evo returns the EVO
    # host for the appropriate env


    def self.[](app_name)
      urls_for_current_environment[app_name]
    end

    def self.method_missing(method_name, *arguments, &block)
      # returns the host. If you need a value other than the host
      # use the hash method above
      if urls_for_current_environment[method_name]
        urls_for_current_environment[method_name][:host]
      else
        super
      end
    end

    def self.reset!
      # allows us to clear the list and have it be recreated
      @urls_for_current_environment = nil
    end

    private

    def self.urls_for_current_environment
      return @urls_for_current_environment if @urls_for_current_environment
      url_list = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), 'urls.yml'))).result)
      url_list_hash = HashWithIndifferentAccess.new(url_list)
      if !url_list_hash[Rails.env].nil?
        @urls_for_current_environment = url_list_hash[:defaults].deep_merge(url_list_hash[Rails.env])
      else
        @urls_for_current_environment = url_list_hash[:defaults]
      end
    end
  end

end