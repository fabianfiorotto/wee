module Wee 
 class JsScript < JsObject
    #this object represent a sequence of JavaScript statements.
  
   def initialize
    @statements = Array.new
    @message = false;
   end
  
   def call(name,*args)
    @statements << name+"(" + (args.map{ |arg|  javascript_code(arg)} * ',' )+ ")" 
    self
   end
  
     
   def []=(js_variable,value)
     @statements << js_variable.to_s + " = "+javascript_code(value)
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
    @statements << "if(#{bool}){#{block.call}}"
    self
   end

   def while(bool,&block)
    @statements << "if(#{bool}){#{block.call}}"
    self
   end

   def else(&block)
    @statements[@statements.length-1] += "else{#{block.call}}"
    self	 
   end
   
   def return(value)
     @statements << "return "+javascript_code(value) ; self
   end
   
   def << (js)
     @statements << js.to_s
     self
   end
   
  end
  
 class Component
  def jsScript
   return JsScript.new
  end
 end
  
end
