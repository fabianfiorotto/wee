module Wee
 class JQueryAjax < JsObject
  
  attr_accessor :canvas
  
  def initialize
     @params = Hash.new
     @data = Array.new
  end
  
  def to_s
   @params[:data] = JsVariable.new['$'].param(@data)
	 "$.ajax("+  javascript_code(@params) +")"
  end
  
  def data(value, name = nil ,&block)
   if @canvas.nil? then
    @data << { :name => name , :value => value }
   else     
    @data << { :name => @canvas.register_callback(:input, block) , :value => value }    
   end 
   self
  end
  
  def type(type)
    @params[:type] = type
    self  
  end
  
  def method_missing(name, *args, &block)
    @params[name] = args[0]
    self  
  end 
  
  def callback(&block)
    @params[:url] =  @canvas.url_for_callback(@canvas.session.render_ajax_proc(block, @canvas.current_component))
    self
  end
  
 end

 class Component
  def jqAjax(canvas = nil)
   ajax = JQueryAjax.new 
   ajax.canvas = canvas
   return ajax
  end
 end
 
end  
