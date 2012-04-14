module Wee
 class JQueryAjax < JsObject
  
  attr_accessor :canvas
  
  def initialize
     @params = Hash.new
     @data = Array.new
  end
  
  def to_s
   if not @params.has_key? :error then
      @params[:error] = JsRenderer.new{ |j|
        j.function("data"){ j.alert("Error") } 
      }   
   end
   @params[:data] = JsVariable.new['$'].param(@data) if not @data.empty?
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
  
  def success_replace(id)
     @params[:success] =  JsRenderer.new{ |j|
       j.function("data"){j.jQuery[id].html(JsVariable.new["data"]) }
     }  
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
