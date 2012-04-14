module Wee
	class JsRenderer < JsObject

	 def initialize(canvas=nil,&block)
	  @canvas = canvas
	  @current_object = nil
	  @javascript_code = ""
	  block.call(self) unless block.nil?
	  close_object
	 end

     def []=(js_variable,value)
	  close_object
	  @current_object = JsVariable.new
	  @current_object[js_variable] = value
	  return @current_object
	 end
	  
	 def [](*args)
	    close_object
		@current_object = JsVariable.new[*args]
	 end

	 def jQuery
	    close_object
		  @current_object = JQueryObject.new
		return @current_object
	 end

	 def jqAjax
	    close_object
	 	  @current_object = JQueryAjax.new
	 	  @current_object.canvas = @canvas
		return @current_object
	 end	
	
	 def method_missing(name, *args, &block)
	  close_object
      index = /function_(.*)/ =~ name.to_s  
      if  index != 0 then 
		  @current_object =  JsFunctionCall.new(@canvas)
		  @current_object.send(name, *args, &block)
		  return @current_object
      else
        fun_name = name.to_s
        fun_name = fun_name[9..fun_name.length]
        define_function(fun_name,args,&block)  
      end
	 end

	 def close_object
	  return nil if @current_object.nil?
	  put_coma
	  @javascript_code += @current_object.to_s
	  @current_object = nil
	 end


   def function(*args,&block)
     @javascript_code << "function(#{ args * ',' }){"
		 block.call unless block.nil? 
		 close_object
	   @javascript_code << "}"
     self
   end
   
   def define_function(name,args,&block)
     @javascript_code << "function #{name}(#{ args * ',' }){"
		 block.call unless block.nil? 
		 close_object
	   @javascript_code << "}"
     self
   end
   
   def if(bool,&block)
    close_object
    put_coma
    @javascript_code << "if(#{bool}){"
	    @current_object = nil
		block.call
		close_object
	  @javascript_code << "}"
    self
   end

   def while(bool,&block)
    close_object
    put_coma
    @javascript_code << "while(#{bool}){"
	    @current_object = nil
		block.call
		close_object
	  @javascript_code <<	"}"
    self
   end

   def else(&block)
    @javascript_code << "else{"
		block.call
		close_object
	  @javascript_code << "}"
    self	 
   end
   
   def return(value)
     close_object
     put_coma
     @javascript_code << "return "+javascript_code(value)  ; self
   end

   def put_coma
     if @javascript_code != '' && ! ['{','}'].include?(@javascript_code[-1,1]) then
      @javascript_code << ";" 
     end
   end

	 def to_s
	  @javascript_code
	 end

	end
	
	class Component
    def jsScript(canvas = nil, &block)
      JsRenderer.new(canvas,&block)
    end
  end
	
end
