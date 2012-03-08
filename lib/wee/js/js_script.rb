module Wee 
 class JsScript < JsObject
    #this object represent a sequence of JavaScript statements.
  
   def initialize(canvas = nil)
    @canvas = canvas
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
  
   def [](*args)
     @statements += args ; self
   end
  
   def to_s
    @statements * ';'
   end
   
   def method_missing(name, *args, &block)
      index = /function_(.*)/ =~ name.to_s  
      if  index != 0 then 
        self.call(name.to_s, *args)
      else
        fun_name = name.to_s
        fun_name = fun_name[9..fun_name.length]
        define_function(fun_name,args,&block)  
      end
   end  
   
   def callback(&block) 
    url =  @canvas.url_for_callback(block, :action,{})
    @statements << "window.location='#{url}'"
    self
   end
    
   def function(*args,&block)
     @statements = ["function(#{ args * ',' }){#{ block.call unless block.nil? }}"]
     self
   end
   
   def define_function(name,args,&block)
     @statements = ["function #{name}(#{ args * ',' }){#{ block.call unless block.nil? }}"]
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
  def jsScript(canvas = nil)
   return JsScript.new(canvas)
  end
 end
  
end
