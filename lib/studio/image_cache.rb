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
    # Idempotent: variants already present in ImageCache are skipped. If
    # nothing is missing, the source is never downloaded.
    def self.cache!(owner:, purpose:, source_url:, key_prefix:, widths:, content_type: "image/png")
      ext = EXT_BY_TYPE[content_type] || "bin"
      requested = ["original", *widths.map(&:to_s)]

      existing = ::ImageCache.where(owner: owner, purpose: purpose).index_by(&:variant)
      missing  = requested - existing.keys
      return existing if missing.empty?

      require "open-uri"
      require "mini_magick"

      body = URI.open(source_url, read_timeout: 30).read

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
