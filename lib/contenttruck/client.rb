# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'

module Contenttruck
  class UserError < StandardError
    def initialize(code, message)
      super(message)
      @code = code
    end

    def code
      @code
    end
  end

  class Client
    def initialize(base_url)
      raise ArgumentError, 'base_url must be a String' unless base_url.is_a?(String)
      @rpc_url = URI.parse(base_url)

      # Set the path of the RPC URL to /_contenttruck.
      @rpc_url.path = '/_contenttruck'
    end

    def upload(key, partition, relative_path, content_type, content_or_reader)
      raise ArgumentError, 'key must be a String' unless key.is_a?(String)
      raise ArgumentError, 'partition must be a String' unless partition.is_a?(String)
      raise ArgumentError, 'relative_path must be a String' unless relative_path.is_a?(String)
      raise ArgumentError, 'content_type must be a String' unless content_type.is_a?(String)
      unless content_or_reader.is_a?(String) || content_or_reader.respond_to?(:read)
        raise ArgumentError, 'content_or_reader must be a String or reader'
      end

      _do_rpc_request('Upload', {
        'key' => key,
        'partition' => partition,
        'relative_path' => relative_path,
      }, content_type, content_or_reader)
    end

    def delete(key, partition, relative_path)
      raise ArgumentError, 'key must be a String' unless key.is_a?(String)
      raise ArgumentError, 'partition must be a String' unless partition.is_a?(String)
      raise ArgumentError, 'relative_path must be a String' unless relative_path.is_a?(String)

      _do_rpc_request('Delete', {
        'key' => key,
        'partition' => partition,
        'relative_path' => relative_path,
      })
    end

    def create_key(sudo_key, partitions)
      raise ArgumentError, 'sudo_key must be a String' unless sudo_key.is_a?(String)
      raise ArgumentError, 'partitions must be an Array' unless partitions.is_a?(Array)
      partitions.each do |partition|
        raise ArgumentError, 'partitions must be an Array of Strings' unless partition.is_a?(String)
      end

      _do_rpc_request('CreateKey', {
        'sudo_key' => sudo_key,
        'partitions' => partitions,
      })
    end

    def delete_key(sudo_key, key)
      raise ArgumentError, 'sudo_key must be a String' unless sudo_key.is_a?(String)
      raise ArgumentError, 'key must be a String' unless key.is_a?(String)

      _do_rpc_request('DeleteKey', {
        'sudo_key' => sudo_key,
        'key' => key,
      })
    end

    def create_partition(sudo_key, name, rule_set)
      raise ArgumentError, 'sudo_key must be a String' unless sudo_key.is_a?(String)
      raise ArgumentError, 'name must be a String' unless name.is_a?(String)
      raise ArgumentError, 'rule_set must be a String' unless rule_set.is_a?(String)

      _do_rpc_request('CreatePartition', {
        'sudo_key' => sudo_key,
        'name' => name,
        'rule_set' => rule_set,
      })
    end

    def delete_partition(sudo_key, name)
      raise ArgumentError, 'sudo_key must be a String' unless sudo_key.is_a?(String)
      raise ArgumentError, 'name must be a String' unless name.is_a?(String)

      _do_rpc_request('DeletePartition', {
        'sudo_key' => sudo_key,
        'name' => name,
      })
    end

    private

    def _to_json(value)
      # Basically works around the fact that some people might not have ActiveSupport loaded.
      return value.to_json if value.respond_to?(:to_json)
      JSON.generate(value)
    end

    def _get_user_error(response)
      begin
        content = JSON.parse(response.body)
        return UserError.new(content['code'], content['message']) if content['code'] && content['message']
      rescue; end
    end

    def _do_rpc_request(type, body, content_type = nil, content_reader = nil)
      http = Net::HTTP.new(@rpc_url.host, @rpc_url.port)
      http.use_ssl = true if @rpc_url.scheme == 'https'

      request = Net::HTTP::Post.new(@rpc_url)
      request['X-Type'] = type
      if content_type
        # Include the JSON in a header and send the body.
        request['X-Json-Body'] = _to_json(body)
        request['Content-Type'] = content_type
        content_length = 0
        if content_reader.instance_of?(String)
          request.body = content_reader
          content_length = content_reader.bytesize
        else
          request.body_stream = content_reader
          content_length = content_reader.size
        end
        request['Content-Length'] = content_length.to_s
      else
        # Send the body as JSON.
        request['Content-Type'] = 'application/json'
        json = _to_json(body)
        request['Content-Length'] = json.bytesize.to_s
        request.body = json
      end

      response = http.request(request)

      # Handle ok responses.
      return nil if response.code == '204'
      return JSON.parse(response.body) if response.code == '200'

      # Handle errors.
      x = _get_user_error(response)
      raise x if x
      raise StandardError, "Unexpected response code #{response.code} (body: #{response.body})"
    end
  end
end
