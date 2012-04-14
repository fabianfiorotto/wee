module Wee 
 class JsFunctionCall < JsObject
  
   def initialize(canvas = nil)
    @canvas = canvas
    @statements = ""
    @message = false;
   end
  
   def call(name,*args)
	@statements << "." unless @statements == ''
    @statements << name+"(" + (args.map{ |arg|  javascript_code(arg)} * ',' )+ ")"
    self
   end
  
   def to_s
    @statements
   end
   
   def method_missing(name, *args, &block)
     self.call(name.to_s, *args)
   end  
   
   def callback(&block) 
    url =  @canvas.url_for_callback(block, :action,{})
    @statements << "window.location='#{url}'"
    self
   end
   
  end
  
  
end
