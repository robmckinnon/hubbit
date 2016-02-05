require 'morph'
require 'api_cache'

module Hubbit

  class << self
    def user name
      get :user, name
    end

    def org name
      get :org, name
    end

    def repo name
      get :repo, name
    end

    def retrieve_or_get object, url_method, attribute
      field = :"@#{attribute}"
      unless object.instance_variable_get field
        value = retrieve url(object, url_method), type(attribute)
        object.instance_variable_set field, value
      end
      object.instance_variable_get field
    end

    private

    def get type, name
      url = "https://api.github.com/#{type.to_s.pluralize}/#{name}"
      retrieve url, type
    end

    def json url
      APICache.get(url)
    end

    def retrieve url, type
      Morph.from_json(json(url), type, Hubbit)
    end

    def url object, url_method
      object.send(url_method).split('{').first
    end

    def type attribute
      attribute.singularize.to_sym
    end
  end
end

module Hubbit::Listener

  class << self
    def call klass, symbol
      klass.class_eval method_def(symbol) if url_method?(symbol)
    end

    private

    IGNORE_URL_METHODS = %i[
                            avatar_url
                            clone_url
                            git_url
                            html_url
                            mirror_url
                            ssh_url
                            svn_url
                         ].each_with_object({}) {|m,h| h[m] = m}

    def url_method? symbol
      symbol.to_s[/_url$/] && !IGNORE_URL_METHODS.has_key?(symbol)
    end

    def attribute url_method
      attribute = url_method.to_s.chomp('_url')
      "_#{attribute}"
    end

    def method_def url_method
      attribute = attribute(url_method)
      "def #{attribute}; Hubbit.retrieve_or_get(self, :#{url_method}, '#{attribute}'); end"
    end
  end
end

Morph.register_listener Hubbit::Listener
