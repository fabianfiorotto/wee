module Wee
 class JQueryAjax < JsObject
  
  def initialize
     @params = Hash.new
     @data = Array.new
  end
  
  def to_s
   @params[:data] = JsScript.new['$'].param(@data)
	 "$.ajax("+  javascript_code(@params) +")"
  end
  
  def data(canvas,value,&block)  
   @data << { :name => canvas.register_callback(:input, block) , :value => value } ; self   
  end
  
  def type(type)
    @params[:type] = type
    self  
  end
  
  def method_missing(name, *args, &block)
    @params[name] = args[0]
    self  
  end 
  
  def callback(canvas,&block)
    @params[:url] =  canvas.url_for_callback(canvas.session.render_ajax_proc(block, canvas.current_component))
    self
  end
  
 end

 class Component
  def jqAjax
   return JQueryAjax.new
  end
 end
 
end  
