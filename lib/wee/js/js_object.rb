module Wee
 class JsObject

   def javascript_code(object)
	 case object
	 when JsObject, Symbol
		object.to_s
	 when String
		"'" + object.gsub("'", "\\\\'") + "'"
	 when Numeric , TrueClass, FalseClass
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


require 'wee/js/js_variable'
require 'wee/js/js_script'
require 'wee/js/js_operator'
require 'wee/js/jquery_object'
require 'wee/js/jquery_ajax'