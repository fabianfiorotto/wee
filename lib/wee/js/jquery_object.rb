module  Wee
 #require 'json'
 class JQueryObject < JsObject
  
  def initialize
      @arguments = ['this'] 
      @stream = ""
  end
  
  def oid=(value)
    @arguments = [ '\'#'+value+'\''] 
  end

  def [](value)
    if value.kind_of? JsObject then
      @arguments = [value] ;
    else
      @arguments = ['\''+value+'\''] ;
    end    
    self
  end

  def add_class aCssClass
    @arguments << '\'.'+aCssClass+'\'' ;self
  end
  
  def add_element(htmlElement)
    @arguments << '\''+htmlElement+'\'' ;self
  end
  
  
  def to_s
    "$(#{ @arguments * ' ' })"+@stream
  end 
  
      
  def call(name,*args)
    @stream += "."+name+"(" + (args.map{ |arg|  javascript_code(arg) } * ',') + ")"
    self
  end
  
  
  def method_missing(name, *args, &block)
      self.call(name.to_s, *args)
  end    
    
 end


 class Component
	def jQuery
	 return JQueryObject.new
	end
 end

end
