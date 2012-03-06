require 'time'
require 'rack'

module Wee

  class Response < Rack::Response
    alias << write
  end

  class GenericResponse < Response
    EXPIRE_OFFSET = 3600*24*365*20   # 20 years
    EXPIRES_HEADER = 'Expires'.freeze
    CONTENT_TYPE_HEADER = 'Content-Type'.freeze
    CONTENT_TYPE = 'text/html; charset=UTF-8'.freeze

    def initialize(*args)
      super
      self[EXPIRES_HEADER] ||= (Time.now + EXPIRE_OFFSET).rfc822
      self[CONTENT_TYPE_HEADER] = CONTENT_TYPE 
    end
  end

  class RedirectResponse < Response
    LOCATION_HEADER = 'Location'.freeze

    def initialize(location)
      super(['<title>302 - Redirect</title><h1>302 - Redirect</h1>',
             '<p>You are being redirected to <a href="', location, '">', 
             location, '</a>'], 302, LOCATION_HEADER => location)
    end
  end

  class RefreshResponse < Response
    def initialize(message, location, seconds=5)
      super([%[<html>
        <head>
          <meta http-equiv="REFRESH" content="#{seconds};URL=#{location}">
          <title>#{message}</title>
        </head>
        <body>
          <h1>#{message}</h1>
          You are being redirected to <a href="#{location}">#{location}</a> 
          in #{seconds} seconds.
        </body>
        </html>]])
    end
  end

  class NotFoundResponse < Response
    def initialize
      super(['<title>404 - Not Found</title><h1>404 - Not Found</h1>'], 404)
    end
  end

  class ErrorResponse < Response
    include Rack::Utils

    def initialize(exception)
      super()
      self << "<html><head><title>#{exception.class.name}</title></head><body>"
      self << "<p> <b>#{exception.class.name}</b> :  #{ escape_html(exception.message) } </p>  "
      self << exception.backtrace.map{|s| escape_html(s)}.join("<br/>") 
      self << "</body></html>"
    end
  end
  
  class FileResponse < Response
    #usage:     r.session.send_response(Wee::FileResponse.new(path,r.request.path_info)) 
        
    attr_accessor :path
        
    def initialize(path,location)
       @path = path
       size = File.size?(path) 
       body = [File.read(path)]

       header =  {
         "Last-Modified"  => File.mtime(path).httpdate,
         "Content-Type"   => Rack::Mime.mime_type(File.extname(path), 'text/plain'),
         "Content-Length" => size.to_s,
         "Content-Disposition" => "attachment; filename=\"#{File.basename(path)}\"",
         "Location" => location
       } 
       super(body,200,header)
    end
    
    
  end
  
end # module Wee
