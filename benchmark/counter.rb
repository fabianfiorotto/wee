$LOAD_PATH.unshift '../lib'
require 'wee'
require 'wee/webrick'
require 'wee/utils/cache'

class Counter < Wee::Component 
  def initialize(cnt)
    super()
    @cnt = cnt 
    @show_edit_field = false
  end

  def backtrack_state(snap)
    super
    snap.add(self)
  end

  def dec
    @cnt -= 1
  end

  def inc
    @cnt += 1
  end

  def render_content_on(r)
    r.form.action(:submit).with do
      r.anchor.action(:dec).with("--")
      r.space

      if @show_edit_field
        r.text_input.assign(:cnt=).value(@cnt).size(6)
      else
        r.anchor.action(:submit).with(@cnt) 
      end

      r.space
      r.anchor.action(:inc).with("++")
    end
  end

  def submit
    @show_edit_field = !@show_edit_field
  end

  def cnt
    @cnt
  end

  def cnt=(val)
    if val =~ /^\d+$/
      @cnt = val.to_i 
    end
  end
end

class Main < Wee::Component
  def initialize
    super()
    @counters = (1..20).map {|i| Counter.new(i)}
    children.push(*@counters)
  end

  def render_content_on(r)
    r.page.title("Counter Test").with do 
      @counters.each { |cnt| r.render(cnt) }
    end 
  end
end

class MySession < Wee::Session
  def initialize
    super do
      self.root_component = Main.new
      self.page_store = Wee::Utils::LRUCache.new(10) # backtrack up to 10 pages
    end
  end
end

class MyApplication < Wee::Application
  def setup_session_id_generator
    @session_cnt = 0
  end
end


if __FILE__ == $0
  PORT = (ARGV[0] || 2000).to_i
  File.open("counter.#{ PORT }.pid", 'w+') {|f| f.puts($$.to_s) }
  MyApplication.new {|app|
    app.name = 'Counter'
    app.path = '/counter'
    app.session_class = MySession
    app.session_store = Wee::Utils::LRUCache.new(100) # handle up to 100 sessions
  }.start(:Port => PORT) 
end
