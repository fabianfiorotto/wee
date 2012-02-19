module Wee
 class JsOperator < JsObject
  
  def initialize(operator,arg1,arg2)
    @operator = operator
    @arg1 = arg1
    @arg2 = arg2
  end
  
  def to_s
    "#{@arg1} #{@operator} #{javascript_code(@arg2)}" 
  end
  
 end

 class JsObject
   
   def +(v) ; JsOperator.new("+",self,v) end
   def -(v) ; JsOperator.new("-",self,v) end
   def *(v) ; JsOperator.new("*",self,v) end
   def /(v) ; JsOperator.new("/",self,v) end  
   
 end

end

