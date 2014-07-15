require 'uri'
require 'securerandom'

class Multipart
  EOL = "\r\n"

  def initialize(params)
    @params = ParamsNormalizer.new(params)
    @boundary = SecureRandom.uuid
  end

  attr_reader :boundary

  include Enumerable

  def content_type
    "multipart/form-data; boundary=#{@boundary}"
  end

  def each
    @params.each do |key, value|
      unless value.respond_to?(:to_str) || value.respond_to?(:each)
        value = value.to_s 
      end
      chunk = "--#{@boundary}" << EOL
      build_headers(key, value).each do |hkey, hval|
        chunk << "#{hkey}: #{hval}" << EOL
      end
      chunk << EOL
      if value.respond_to? :to_str
        chunk << value << EOL
        yield chunk
      else
        yield chunk
        value.each { |c| yield c }
        yield EOL
      end
    end
    yield "--#{@boundary}--"
  end

  def to_s
    to_a.join
  end

private

  def build_headers(key, value)
    {}.tap do |headers|
      headers.update value.headers if value.kind_of? File
      dispos = [%(form-data), %(name="#{key}")]
      dispos << %(filename="#{value.filename}") if value.kind_of? File
      headers['Content-Disposition'] = dispos.join('; ')
    end
  end

  class ParamsNormalizer
    def initialize(params)
      @params = params
    end

    include Enumerable

    def each
      @params.kind_of? Hash or raise "params must be a Hash"
      yield_nested = lambda do |value, key|
        case value
        when Hash
          value.each do |k,v|
            escaped_key = if key
              "#{key}[#{URI.encode(k.to_s)}]"
            else
              URI.encode(k.to_s)
            end
            yield_nested.call(v, escaped_key)
          end
        when Array
          k = "#{key}[]"
          value.each do |el|
            yield_nested.call(el, k)
          end
        else
          yield key, value
        end
      end
      yield_nested.call(@params, nil)
    end
  end

  class File
    BUFFER_SIZE = 128 * 1024 * 1024

    def initialize(path, headers={})
      @path = path
      @headers = headers
    end

    attr_reader :headers

    def filename
      ::File.basename @path
    end

    def each
      ::File.open(@path, 'rb') do |f|
        while chunk = f.read(BUFFER_SIZE)
          yield chunk
        end
      end
    end
  end
end
