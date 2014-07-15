$:.unshift __dir__ + '/../lib'

require 'minitest/autorun'
require 'rack'
require 'multipart'

class MultipartRackParseTest < MiniTest::Unit::TestCase
  def test_simple
    assert_equal({"a" => "OK"}, parse({a: "OK"}))
  end

  def test_nested
    assert_equal({"a" => {"test" => "OK"}}, parse({a: {test: "OK"}}))
    assert_equal({"a" => {"test1" => {"test2" => "OK"}}}, parse({a: {test1: {test2: "OK"}}}))
    assert_equal({"a" => ["OK"]}, parse({a: ["OK"]}))
    assert_equal({"a" => {"b" => ["OK"]}}, parse({a: {b: ["OK"]}}))
  end

  def test_file
    result = parse({a: Multipart::File.new(__dir__ + '/file')})
    assert_equal "file", result["a"][:filename]
    assert_equal "test contents\n", result["a"][:tempfile].read
  end

  def test_mixed
    result = parse({a: Multipart::File.new(__dir__ + '/file'), b: "OK"})
    assert_equal "file", result["a"][:filename]
    assert_equal "OK", result["b"]

    result = parse({a: "OK", b: Multipart::File.new(__dir__ + '/file')})
    assert_equal "OK", result["a"]
    assert_equal "file", result["b"][:filename]
  end

private

  def parse(params)
    multipart = Multipart.new(params)
    input = StringIO.new(multipart.to_s)
    Rack::Multipart.parse_multipart({
      'CONTENT_TYPE' => multipart.content_type,
      'rack.input' => input,
    })
  end
end
