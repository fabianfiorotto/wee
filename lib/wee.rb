module Wee
  Version = "0.2-dev"
end

require 'wee/core'

require 'wee/context'
require 'wee/application'
require 'wee/requesthandler'
require 'wee/request'
require 'wee/response'
require 'wee/session'

require 'wee/snapshot_ext'

require 'wee/renderer/html/writer'
require 'wee/renderer/html/brushes'
require 'wee/renderer/html/canvas'
Wee::DefaultRenderer = Wee::HtmlCanvas

require 'wee/idgen'
