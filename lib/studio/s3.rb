module Studio
  module S3
    class Error < StandardError; end
    class NotConfigured < Error; end

    class << self
      def upload(key:, body:, content_type: nil, cache_control: nil)
        opts = { bucket: bucket, key: key, body: body }
        opts[:content_type] = content_type if content_type
        opts[:cache_control] = cache_control if cache_control
        client.put_object(**opts)
        url(key: key)
      end

      def download(key:)
        client.get_object(bucket: bucket, key: key).body.read
      end

      def url(key:)
        "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"
      end

      def signed_url(key:, expires_in: 3600)
        require "aws-sdk-s3"
        Aws::S3::Presigner.new(client: client).presigned_url(:get_object, bucket: bucket, key: key, expires_in: expires_in)
      end

      def exists?(key:)
        client.head_object(bucket: bucket, key: key)
        true
      rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
        false
      end

      def delete(key:)
        client.delete_object(bucket: bucket, key: key)
      end

      def list(prefix: nil, max: 1000)
        resp = client.list_objects_v2(bucket: bucket, prefix: prefix, max_keys: max)
        resp.contents.map(&:key)
      end

      def bucket
        prefix = Studio.s3_bucket_prefix
        raise NotConfigured, "Studio.s3_bucket_prefix not set in config/initializers/studio.rb" if prefix.nil? || prefix.empty?
        "#{prefix}-#{environment}"
      end

      def region
        Studio.s3_region
      end

      def client
        @client ||= begin
          require "aws-sdk-s3"
          Aws::S3::Client.new(region: region)
        end
      end

      def reset!
        @client = nil
      end

      private

      def environment
        defined?(Rails) && Rails.env.production? ? "production" : "dev"
      end
    end
  end
end
