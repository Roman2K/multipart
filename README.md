# Multipart

Streaming multipart builder for Ruby.

May not conform to RFC 2388 but `Rack::Multipart` parses its output properly
(see `test/`).

## Usage

```ruby
params = {
  my_str: "Str",
  my_arr: ["A", "B", "C"],
  my_hash: {
    foo: "Foo",
    bar: ["Bar"],
  },
  my_file: Multipart::File.new('test.jpg', 'Content-Type' => 'image/jpeg'),
}

multipart = Multipart.new(params)

# Content-Type header value:
multipart.content_type  # => "multipart/form-data; boundary=c4f6e864-191d-488a-8a81-da094cb8c77d"

# Request body:
multipart.to_s  # => "--c4f6e864-191d-488a-8a81-da094cb8c77d\r\nContent-Disposition: form-data; name=\"my_...

# Or:
multipart.each { |chunk| }
```
