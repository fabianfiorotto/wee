module Wee
	class ErrorPage <  Component
	 
	 def initialize(exception)
	  @exception = exception
	 end

	 def render(r)
	   r.page.title(@exception.class.to_s).with do
		 r.paragraph do
		  r.bold @exception.class.to_s
		  r.text " : "
		  r.encode_text @exception.message
		 end
		 @exception.backtrace.each do |line|
		  r.text line
		  r.break
		 end
	 	end 
	 end



	end
end
