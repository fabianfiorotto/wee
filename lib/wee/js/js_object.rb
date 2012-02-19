module Wee
 class JsObject

   def javascript_code(object)
	 case object
	 when JsObject, Symbol
		object.to_s
	 when String
		"'" + object.gsub("'", "\\\\'") + "'"
	 when Numeric
		object.inspect
	 when Array
		"["+ (object.map{|e| javascript_code(e) } * ",") + "]"
	 when Hash
		"{"+ (object.to_a.map{|a| javascript_code(a[0]) + " : "  +javascript_code(a[1]) } * ',' ) + "}"
	 when NilClass
		"null"
	 end
   end



 end

end
