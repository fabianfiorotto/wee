module Wee
	class ErrorPage <  Component
	 
	 def initialize(exception)
	  @exception = exception
	 end

	 def render(r)
	  	r.page.title(@exception.class.to_s).with{
		 r.text @exception.class.to_s
		 r.text " : "
		 r.text @exception.message
		}
	 end 

	end

end
