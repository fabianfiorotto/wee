module Wee 
 class JsScript < JsObject
    #this object represent a sequence of JavaScript statements.
  
   def initialize
    @statements = Array.new
    @message = false;
   end
  
   def call(name,*args)
    if @message then
     @statements[@statements.length-1] +=  ".#{name}(" + (args.map{ |arg|  javascript_code(arg)} * ',' )+ ")"
    else
     @statements << name+"(" + (args.map{ |arg|  javascript_code(arg)} * ',' )+ ")" 
    end
    @message = false
    self
   end
  
  
   def [](js_variable)
     if @message then
       @statements[@statements.length-1] += "." +js_variable 
     else  
       @statements << js_variable
     end
     @message = true;
     self
   end
   
   def []=(js_variable,value)
     if @message then
       @statements[@statements.length-1] += "." +js_variable + " = "+javascript_code(value) 
     else  
       @statements << js_variable + " = "+javascript_code(value)
     end
     self
   end
  
   def to_s
    @statements * ';'
   end
   
   def method_missing(name, *args, &block)
        self.call(name.to_s, *args)
   end  
   
   def function(*args,&block)
     @statements = ["function(#{ args * ',' }){#{ block.call unless block.nil? }}"]
     self
   end
   
   def if(bool,&block)
    @message = false
    @statements << "if(#{bool}){#{block.call}}"
    self
   end

   def while(bool,&block)
    @message = false
    @statements << "if(#{bool}){#{block.call}}"
    self
   end

   def else(&block)
    @statements[@statements.length-1] += "else{#{block.call}}"
    self	 
   end
   
  end
  
 class Component
  def jsScript
   return JsScript.new
  end
 end
  
end
