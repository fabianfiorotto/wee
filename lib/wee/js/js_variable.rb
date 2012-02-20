module Wee 
 class JsVariable < JsObject
  
   def initialize
     @stream = ""
   end
  
   def [](js_variable)
     @stream += "." if @stream != "" 
     @stream += js_variable 
     self
   end
     
   def call(name,*args)
    @stream +=  ".#{name}(" + (args.map{ |arg|  javascript_code(arg)} * ',' )+ ")"
    self
   end
  
   def method_missing(name, *args, &block)
      self.call(name.to_s, *args)
   end  
   
   def to_s
     @stream
   end
  
 end

 class Component
  def jsVar
   return JsVariable.new
  end
 end
 
end 