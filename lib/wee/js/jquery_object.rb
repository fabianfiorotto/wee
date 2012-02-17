module  Wee
 #require 'json'
 class JQueryObject
  
  def initialize
      @arguments = ['this'] 
      @stream = ""
  end
  
  def oid=(value)
    @arguments = [ '\'#'+value+'\''] # y las comillas?
  end

  def add_class aCssClass
    @arguments << '\'.'+aCssClass+'\''
  end
  
  def add_element(htmlElement)
    @arguments << '\''+htmlElement+'\''
  end
  
  
  def to_s
    "$(#{ @arguments * ' ' })"+@stream
  end 
  
      
  def call(name,*args)
    @stream += "."+name+"(" + (args.map{ |arg|  arg.to_json} * ',') + ")"
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
