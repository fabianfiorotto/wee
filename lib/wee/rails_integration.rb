# Rails integration by Fabian Fiorotto
# 
# Call publish_wee_applications in any controller definition with the name of the action 
# and the component class as parameter. 
# 
# Example: 
#
# publish_wee_applications :counter => Counter
#
# your application is now listening in http://localhost:3000/yourcontroller/counter
#

if defined? ActionController::Base then
  
  class ActionController::Base
      @@weeApplications = {}

    def self.publish_wee_applications(*arg)
     actions =  arg[0]
     actions.each_key do |action| 
      wee_application = Wee::Application.new {
          if actions[action].respond_to? "instanciate" then
            root_component =  actions[action].instanciate
          else
            root_component =  actions[action].new
          end  
          Wee::Session.new(root_component,Wee::Session::ThreadSerializer.new)
      }
      controller = self.to_s.sub(/Controller$/, '').underscore
      if not @@weeApplications.has_key? controller then
          @@weeApplications[controller] = { action => wee_application }
      elsif not @@weeApplications[controller].has_key? action then
          @@weeApplications[controller][action] = wee_aplication 
      end
      define_method(action) do
          application = @@weeApplications[controller][action] 
          response =  application.call(request.env)[2]
          render  :text =>  response.body.to_s,
                  :status => response.status , 
                  :location =>response.header['Location']
      end
     end
    end
 end 
  
end