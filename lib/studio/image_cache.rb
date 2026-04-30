module Studio
  module ImageCache
    EXT_BY_TYPE = {
      "image/png"  => "png",
      "image/jpeg" => "jpg",
      "image/jpg"  => "jpg",
      "image/webp" => "webp",
      "image/gif"  => "gif"
    }.freeze

    # Caches an image at S3 under a folder per owner. Every call stores the
    # unmodified source as variant "original", plus one resized variant per
    # entry in widths.
    #
    # Layout:
    #   {key_prefix}/original.{ext}
    #   {key_prefix}/{width}.{ext}
    #
    # Source: provide EITHER source_url (HTTP fetch) OR source_path (local
    # file). source_url is recorded on each ImageCache row regardless — for
    # source_path callers, pass the original URL too if you want it tracked.
    #
    # Idempotent: variants already present in ImageCache are skipped. If
    # nothing is missing, the source is never read.
    def self.cache!(owner:, purpose:, key_prefix:, widths:, source_url: nil, source_path: nil, content_type: "image/png")
      raise ArgumentError, "either source_url or source_path is required" if source_url.nil? && source_path.nil?

      ext = EXT_BY_TYPE[content_type] || "bin"
      requested = ["original", *widths.map(&:to_s)]

      existing = ::ImageCache.where(owner: owner, purpose: purpose).index_by(&:variant)
      missing  = requested - existing.keys
      return existing if missing.empty?

      require "mini_magick"

      body = if source_path
        File.binread(source_path)
      else
        require "open-uri"
        URI.open(source_url, read_timeout: 30).read
      end

      missing.each do |variant|
        if variant == "original"
          payload = body
          s3_key  = "#{key_prefix}/original.#{ext}"
        else
          img = MiniMagick::Image.read(body)
          img.resize "#{variant}x"
          payload = img.to_blob
          s3_key  = "#{key_prefix}/#{variant}.#{ext}"
        end

        Studio::S3.upload(
          key: s3_key,
          body: payload,
          content_type: content_type,
          cache_control: "public, max-age=31536000, immutable"
        )

        existing[variant] = ::ImageCache.create!(
          owner: owner,
          purpose: purpose,
          variant: variant,
          s3_key: s3_key,
          source_url: source_url,
          bytes: payload.bytesize,
          content_type: content_type
        )
      end

      existing
    end
  end
end
