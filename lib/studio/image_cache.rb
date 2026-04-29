module Studio
  module ImageCache
    # Downloads source_url, resizes to each width via MiniMagick, uploads each
    # variant to S3, and persists an ::ImageCache row per variant.
    #
    # Idempotent: variants already cached for this owner/purpose are skipped.
    # If every requested variant exists, the source is never downloaded.
    #
    # key_base is the path the original WOULD live at; the variant suffix is
    # appended before the extension. e.g. "foo/bar.png" + width 400 ->
    # "foo/bar-400.png".
    def self.cache!(owner:, purpose:, source_url:, key_base:, widths:, content_type: "image/png")
      existing = ::ImageCache.where(owner: owner, purpose: purpose).index_by(&:variant)
      missing  = widths.map(&:to_s).reject { |w| existing.key?(w) }

      return existing if missing.empty?

      require "open-uri"
      require "mini_magick"

      body = URI.open(source_url, read_timeout: 30).read
      ext  = File.extname(key_base)
      base = key_base.sub(/#{Regexp.escape(ext)}\z/, "")

      missing.each do |variant|
        img = MiniMagick::Image.read(body)
        img.resize "#{variant}x"
        resized = img.to_blob

        s3_key = "#{base}-#{variant}#{ext}"

        Studio::S3.upload(
          key: s3_key,
          body: resized,
          content_type: content_type,
          cache_control: "public, max-age=31536000, immutable"
        )

        existing[variant] = ::ImageCache.create!(
          owner: owner,
          purpose: purpose,
          variant: variant,
          s3_key: s3_key,
          source_url: source_url,
          bytes: resized.bytesize,
          content_type: content_type
        )
      end

      existing
    end
  end
end
