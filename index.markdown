Rack::Test
==========

Rack::Test is a small, simple testing API for Rack apps. It can be used on its
own or as a reusable starting point for Web frameworks and testing libraries
to build on.

Rack::Test::Session
-------------------

The simplest way to use Rack::Test is through `Rack::Test::Session`.

    app = lambda { |env| [200, {}, ["Hello World"]] }
    session = Rack::Test::Session.new(app)

Once initialized, the following attributes are available:

* `app` - The Rack application that is being tested

* `last_request` - The latest request that was issued, represented
  as a `Rack::Request` instance.

* `last_response` - The latest request, represented
  as a `Rack::Response` instance

### Making request

The `get`, `put`, `post`, `delete`, and `head` methods simulate the
respective type of request on the application. Tests typically begin with
a call to one of these methods followed by one or more assertions against
the resulting response.

All mock request methods have the same argument signature:

    get "/path", params={}, rack_env={}

 * `/path` is the request path and may optionally include a query string.

 * `params` is a Hash of query/post parameters, a String request body, or
   `nil`.

 * `rack_env` is a Hash of Rack environment values. This can be used to
   set request headers and other request related information, such as session
   data. See the [Rack SPEC][spec] for more information on possible key/values.

**NOTE:** `Rack::Test` doesn't automatically follow redirect response.
However, `follow_redirect!` will request the `Location` header of the
latest response if present, and raise otherwise.

TODO: Cookies with `Rack::Test::Cookie`

### Setting headers

To set persistant header accross requests, use the `header` method.
Example:

    header "User-Agent", "rack/test (#{Rack::Test::VERSION})"

HTTP authorization being so common amongs web app, Rack::Test provides
the `authorize` helper. It encodes the credentials and set the
`HTTP_AUTHORIZATION` header.

    authorize "admin", "password"

To unset an header, simply set it to `nil`:

    header "User-Agent", nil

[spec]: http://rack.rubyforge.org/doc/files/SPEC.html
