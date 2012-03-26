module Wee

  class Brush
    attr_accessor :canvas, :document

    # This method is called right after #initialize.  It's only here to
    # simplify the implementation of Brushes, mainly to avoid passing all those
    # arguments to super. 
    #
    # There is a bit of redundancy with canvas and document here. It's there to
    # avoid method calls. 
    #
    # A brush is considered to be closed, when @document is nil. 
    #
    def setup(canvas, document)
      @canvas = canvas
      @document = document
    end

    def with(*args, &block)
      @canvas.nest(&block) if block
      @document = @canvas = nil
    end

    def close
      with if @document
    end

    def self.nesting?() true end
  end

  class Brush::GenericTextBrush < Brush
    def with(text)
      @document.text(text)
      @document = @canvas = nil
    end

    def self.nesting?() false end
  end

  class Brush::GenericEncodedTextBrush < Brush::GenericTextBrush
    def with(text)
      @document.encode_text(text)
      @document = @canvas = nil
    end
  end

  class Brush::GenericTagBrush < Brush
    def self.html_attr(attr, hash={})
      name = hash[:html_name] || attr
      if hash[:type] == :bool
        class_eval %{
          def #{ attr }(bool=true)
            if bool
              @attributes[:"#{ name }"] = nil
            else
              @attributes.delete(:"#{ name }")
            end
            self
          end
        }
      else
        class_eval %{ 
          def #{ attr }(value)
            if value == nil
              @attributes.delete(:"#{ name }")
            else
              @attributes[:"#{ name }"] = value
            end
            self
          end
        }
      end

      (hash[:aliases] || []).each do |a|
        class_eval "alias #{ a } #{ attr }"
      end

      (hash[:shortcuts] || {}).each_pair do |k, v|
        class_eval "def #{ k }() #{ attr }(#{ v.inspect }) end"
      end
    end
  end

  class Brush::GenericTagBrush < Brush
    html_attr :id
    html_attr :name # XXX
    html_attr :css_class, :html_name => :class
    html_attr :css_style, :html_name => :style, :aliases => [:style] 
    html_attr :onclick
    html_attr :ondblclick
    html_attr :onmouseover
    html_attr :onmouseout
    html_attr :onmousedown
    html_attr :onmouseup
    
    def initialize(tag)
      super()
      @tag = tag
      @attributes = Hash.new
      @script = nil
    end

    #
    # Assigns a unique DOM id
    #
    def oid
      id(get_oid())
    end

    #
    # Returns a unique DOM id for the underlying component
    #
    def get_oid
      "wee_#{@canvas.current_component.object_id}"
    end


    # 
    # Generate random id
    #
    def set_random_id
      self.id(rand(36**15).to_s(36)) 
    end
    #
    # generic support for onXXX events
    #

    EVENTS = {:click => 'onclick'.freeze,
              :dblclick => 'ondblclick'.freeze,
              :mouseover => 'onmouseover'.freeze,
              :mouseout => 'onmouseout'.freeze,
              :keypress => 'onkeypress'.freeze,
              :change => 'onchange'.freeze}.freeze

    def javascript_on(event, javascript)
      ev = EVENTS[event] 
      raise ArgumentError unless ev
      @attributes[ev] = "javascript: #{javascript};"
      self
    end

    def callback_on(event, &block)
      raise ArgumentError unless block
      url = @canvas.url_for_callback(block)
      javascript_on(event, "document.location.href='#{ url }'")
      self
    end

    def update_on(event, &render_block)
      raise ArgumentError unless render_block
      url = @canvas.url_for_callback(@canvas.session.render_ajax_proc(render_block, @canvas.current_component))
      javascript_on(event, "wee.update('#{ url }')")
      self
    end

    def update_component_on(event, component=nil, &callback_block)
      component ||= @canvas.current_component

      render_block = proc {|r|
        callback_block.call if callback_block
        r.render(component)
      }

      url = @canvas.url_for_callback(@canvas.session.render_ajax_proc(render_block, component))
      javascript_on(event, "wee.update('#{ url }')")
      self
    end

    def onclick_javascript(v)
      javascript_on(:click, v)
    end

    def onclick_callback(&block)
      callback_on(:click, &block)
    end

    def ondblclick_callback(&block)
      callback_on(:dblclick, &block)
    end

    def with(text=nil, &block)
      @document.start_tag(@tag, @attributes)
      @document.text(text) if text
      @canvas.nest(&block) if block
      @document.end_tag(@tag)
      @canvas.nest{ @canvas.javascript(@script.to_s) }  unless @script.nil?
      @document = @canvas = nil
    end

    def javascript(js)
     if js.respond_to? "oid=" then
       self.set_random_id unless @attributes.has_key? :id
       js.oid = @attributes[:id] 
     end  
     @script = js 
     return self
    end

  end

  class Brush::GenericSingleTagBrush < Brush::GenericTagBrush
    def with
      @document.single_tag(@tag, @attributes) 
      @canvas.nest{ @canvas.javascript(@script.to_s) }  unless @script.nil?
      @document = @canvas = nil
    end

    def self.nesting?() false end
  end

  class Brush::ImageTag < Brush::GenericSingleTagBrush
    HTML_TAG = 'img'.freeze

    html_attr :src
    html_attr :width
    html_attr :height
    html_attr :border
    html_attr :alt

    def initialize
      super(HTML_TAG)
    end
  end

  class Brush::JavascriptTag < Brush::GenericTagBrush
    HTML_TAG = 'script'.freeze
    HTML_TYPE = 'text/javascript'.freeze

    html_attr :src
    html_attr :type

    def initialize
      super(HTML_TAG)
      type(HTML_TYPE)
    end
  end

  class Brush::StyleTag < Brush::GenericTagBrush
    HTML_TAG = 'style'.freeze

    html_attr :type

    def initialize
      super(HTML_TAG)
    end

    def with(text=nil, &block)
      @document.start_tag(@tag, @attributes)
      @document.write("<!--\n")
      @document.text(text) if text
      @canvas.nest(&block) if block
      @document.write("-->\n")
      @document.end_tag(@tag)
      @document = @canvas = nil
    end
  end

  #---------------------------------------------------------------------
  # Table
  #---------------------------------------------------------------------

  class Brush::TableTag < Brush::GenericTagBrush
    HTML_TAG = 'table'.freeze

    html_attr :cellspacing
    html_attr :border

    def initialize
      super(HTML_TAG)
    end
  end  

  class Brush::TableRowTag < Brush::GenericTagBrush
    HTML_TAG = 'tr'.freeze

    html_attr :align, :shortcuts => {
      :align_top => :top, :align_bottom => :bottom
    }

    def initialize
      super(HTML_TAG)
    end

    def columns(*cols, &block)
      with {
        cols.each {|col|
          @canvas.table_data.with {
            if block
              block.call(col)
            else
              @canvas.text(col)
            end
          }
        }
      } 
    end

    def headings(*headers, &block)
      with {
        headers.each {|header|
          @canvas.table_header.with {
            if block
              block.call(header)
            else
              @canvas.text(header)
            end
          }
        }
      } 
    end

    def spanning_column(str, colspan)
      with { @canvas.table_data.col_span(colspan).with(str) }
    end

    def spacer
      with { @canvas.table_data { @canvas.space } }
    end
  end

  class Brush::TableDataTag < Brush::GenericTagBrush
    HTML_TAG = 'td'.freeze

    html_attr :colspan
    html_attr :align, :shortcuts => {
      :align_top => :top,
      :align_bottom => :bottom
    }

    def initialize
      super(HTML_TAG)
    end
  end

  class Brush::TableHeaderTag < Brush::GenericTagBrush
    HTML_TAG = 'th'.freeze

    html_attr :colspan
    html_attr :align, :shortcuts => {
      :align_top => :top,
      :align_bottom => :bottom
    }

    def initialize
      super(HTML_TAG)
    end
  end

  #---------------------------------------------------------------------
  # Callback Mixin
  #---------------------------------------------------------------------

  module CallbackMixin

    def callback_method(id, *args)
      @callback = self
      @callback_object = @canvas.current_component 
      @callback_id = id
      @callback_args = args
      __callback()
      return self
    end

    def callback(&block)
      @callback = block
      __callback()
      return self
    end

    #
    # Is called when #callback_method was used.
    #
    def call(*args)
      args.push(*@callback_args)
      @callback_object.send(@callback_id, *args)
    end

  end

  #---------------------------------------------------------------------
  # Form
  #---------------------------------------------------------------------

  class Brush::FormTag < Brush::GenericTagBrush
    HTML_TAG = 'form'.freeze
    HTML_METHOD_POST = 'POST'.freeze

    html_attr :action
    html_attr :enctype
    html_attr :target

    #
    # Use this enctype when you have a FileUploadTag field.
    #
    def enctype_multipart
      enctype('multipart/form-data')
    end

    def initialize
      super(HTML_TAG)
      @attributes[:method] = HTML_METHOD_POST
    end

    def with(&block)
      # If no action was specified, use a dummy one.
      unless @attributes.has_key?(:action)
        @attributes[:action] = @canvas.build_url
      end
      super
    end

    include CallbackMixin

    def __callback; action(@canvas.url_for_callback(@callback)) end

=begin
    def onsubmit_update(update_id, &block)
      raise ArgumentError if symbol and block
      url = @canvas.url_for_callback(block, :live_update)
      onsubmit("javascript: new Ajax.Updater('#{ update_id }', '#{ url }', {method:'get', parameters: Form.serialize(this)}); return false;")
    end
=end
  end

  #---------------------------------------------------------------------
  # Form - Input
  #---------------------------------------------------------------------

  class Brush::InputTag < Brush::GenericSingleTagBrush
    HTML_TAG = 'input'.freeze

    html_attr :type
    html_attr :name
    html_attr :value
    html_attr :size
    html_attr :maxlength
    html_attr :src
    html_attr :onfocus
    html_attr :onblur
    html_attr :onselect
    html_attr :onchange
    html_attr :checked,  :type => :bool
    html_attr :disabled, :type => :bool
    html_attr :readonly, :type => :bool

    def initialize(_type)
      super(HTML_TAG)
      type(_type)
    end

    include CallbackMixin

    def __callback; name(@canvas.register_callback(:input, @callback)) end
  end

  class Brush::TextInputTag < Brush::InputTag
    HTML_TYPE = 'text'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  class Brush::HiddenInputTag < Brush::InputTag
    HTML_TYPE = 'hidden'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  class Brush::PasswordInputTag < Brush::InputTag
    HTML_TYPE = 'password'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  class Brush::CheckboxTag < Brush::InputTag
    HTML_TYPE = 'checkbox'.freeze

    def initialize
      super(HTML_TYPE)
    end

    def __callback; end # do nothing

    def with
      if @callback
        n = @canvas.register_callback(:input, proc {|input|
          @callback.call(input.send(input.kind_of?(Array) ? :include? : :==, '1'))
        })
        @document.single_tag('input', :type => 'hidden', :name => n, :value => '0')
        name(n)
        value('1')
      end
      super
    end
  end

  #
  # Use a <form> tag with enctype_multipart!
  #
  class Brush::FileUploadTag < Brush::InputTag
    HTML_TYPE = 'file'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  #---------------------------------------------------------------------
  # Form - Buttons
  #---------------------------------------------------------------------

  class Brush::ActionInputTag < Brush::InputTag
    include CallbackMixin

    def __callback; name(@canvas.register_callback(:action, @callback)) end
  end

  class Brush::SubmitButtonTag < Brush::ActionInputTag
    HTML_TYPE = 'submit'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  #
  # NOTE: The form-fields returned by a image-button-tag is browser-specific.
  # Most browsers do not send the "name" key together with the value specified
  # by "value", only "name.x" and "name.y". This conforms to the standard. But
  # Firefox also sends "name"="value". This is why I raise an exception from
  # the #value method. Note that it's neccessary to parse the passed
  # form-fields and generate a "name" fields in the request, to make this
  # image-button work. 
  #
  class Brush::ImageButtonTag < Brush::ActionInputTag
    HTML_TYPE = 'image'.freeze

    def initialize
      super(HTML_TYPE)
    end

    undef :value
  end

  #---------------------------------------------------------------------
  # Form - Textarea
  #---------------------------------------------------------------------

  class Brush::TextAreaTag < Brush::GenericTagBrush
    HTML_TAG = 'textarea'.freeze

    html_attr :name
    html_attr :rows
    html_attr :cols
    html_attr :tabindex
    html_attr :accesskey
    html_attr :onfocus
    html_attr :onblur
    html_attr :onselect
    html_attr :onchange
    html_attr :disabled, :type => :bool
    html_attr :readonly, :type => :bool

    def initialize
      super(HTML_TAG)
    end

    def value(val)
      @value = val
      self
    end

    def with(value=nil)
      super(value || @value)
    end

    include CallbackMixin

    def __callback; name(@canvas.register_callback(:input, @callback)) end
  end
  
  #---------------------------------------------------------------------
  # Form - Select
  #---------------------------------------------------------------------

  class Brush::SelectListTag < Brush::GenericTagBrush
    HTML_TAG = 'select'.freeze

    html_attr :size
    html_attr :disabled, :type => :bool
    html_attr :readonly, :type => :bool
    html_attr :multiple, :type => :bool, :aliases => [:multi]

    def initialize(items)
      super(HTML_TAG)
      @items = items
    end

    def items(items)
      @items = items
      self
    end

    def selected(arg=nil, &block)
      raise ArgumentError if arg and block
      @selected = block || arg
      self
    end

    def labels(arg=nil, &block)
      raise ArgumentError if arg and block
      if block
        @labels = proc {|i| block.call(@items[i])}
      else
        @labels = arg
      end
      self
    end

    include CallbackMixin

    def __callback
      #
      # A callback was specified. We have to wrap it inside another
      # callback, as we want to perform some additional actions.
      #
      name(@canvas.register_callback(:input, method(:handler)) + "[]") 
    end

    def handler(input)
      choosen = input.map {|idx|
        idx = Integer(idx)
        raise IndexError if idx < 0 or idx > @items.size
        @items[idx]
      }

      if @attributes.has_key?(:multiple)
        @callback.call(choosen)
      elsif choosen.size > 1
        raise "more than one element was choosen from a not-multiple SelectListTag" 
      else
        @callback.call(choosen.first)
      end
    end

    protected :handler

    def with
      @labels ||= @items.collect {|i| i.to_s}

      if @attributes.has_key?(:multiple)
        @selected ||= Array.new
        meth = @selected.kind_of?(Proc) ? (:call) : (:include?)
      else
        meth = @selected.kind_of?(Proc) ? (:call) : (:==)
      end

      super {
        @items.each_index do |i|
          @canvas.option.value(i).selected(@selected.send(meth, @items[i])).with(@labels[i])
        end 
      }
    end
  end

  class Brush::SelectOptionTag < Brush::GenericTagBrush
    HTML_TAG = 'option'.freeze

    html_attr :value
    html_attr :selected, :type => :bool

    def initialize
      super(HTML_TAG)
    end
  end

  #---------------------------------------------------------------------
  # Form - Radio
  #---------------------------------------------------------------------

  class Brush::RadioGroup
    def initialize(canvas)
      @name = canvas.register_callback(:input, self)
      @callbacks = {}
      @ids = Wee::IdGenerator::Sequential.new 
    end

    def add_callback(callback)
      value = @ids.next.to_s
      @callbacks[value] = callback
      return [@name, value]
    end

    def call(value)
      if @callbacks.has_key?(value)
        cb = @callbacks[value]
        cb.call(value) if cb
      else
        raise "invalid radio button/group value"
      end
    end
  end

  class Brush::RadioButtonTag < Brush::InputTag
    HTML_TYPE = 'radio'.freeze

    def initialize
      super(HTML_TYPE)
    end

    def group(radio_group)
      @group = radio_group
      self
    end

    include CallbackMixin

    def __callback; end # do nothing

    def with
      if @group
        n, v = @group.add_callback(@callback)
        name(n)
        value(v)
      end
      super
    end
  end

  #---------------------------------------------------------------------
  # Misc
  #---------------------------------------------------------------------

  class Brush::LinkTag < Brush::GenericTagBrush
    HTML_TAG = 'link'.freeze

    html_attr :href,  :aliases => [:url]
    html_attr :type
    html_attr :rel

    def initialize
      super(HTML_TAG)
    end
  end

  class Brush::AnchorTag < Brush::GenericTagBrush
    HTML_TAG = 'a'.freeze

    html_attr :href,  :aliases => [:url]
    html_attr :title, :aliases => [:tooltip]

    def initialize
      super(HTML_TAG)
      href('#')
    end

    def info(info=nil)
      @info = info
      self
    end

    include CallbackMixin

    def __callback
      url(@canvas.url_for_callback(@callback, :action, @info ? {:info => @info} : {}))
    end
  end

  class Brush::Page < Brush
    HTML_HTML = 'html'.freeze
    HTML_HEAD = 'head'.freeze
    HTML_TITLE = 'title'.freeze
    HTML_BODY = 'body'.freeze

    def with(text=nil, &block)
      @document.start_tag(HTML_HTML)
      @document.start_tag(HTML_HEAD)

      if @title
        @document.start_tag(HTML_TITLE)
        @document.text(@title)
        @document.end_tag(HTML_TITLE)
      end

      if @head
        @canvas.nest(&@head)
      end

      @document.end_tag(HTML_HEAD)
      @document.start_tag(HTML_BODY)

      if text
        raise ArgumentError if block
        @document.text(text)
      else
        @canvas.nest(&block) if block 
      end

      @document.end_tag(HTML_BODY)
      @document.end_tag(HTML_HTML)

      @document = @canvas = nil
    end

    def title(t)
      @title = t
      self
    end

    def head(&block)
      raise ArgumentError unless block
      @head = block
      self
    end

  end

 #---
 # extra brushes by Fabian Fiorotto
 #---

 class Brush::AjaxForm < Wee::Brush::FormTag

	 def initialize
	  @success = ""
	  super
	 end

	 def success(javascript)
	  @success = javascript ;self
	 end  

	 def with(&block)
	  @callback = Proc.new{} if @callback.nil?
	  @attributes[:action] = @canvas.url_for_callback(@canvas.session.render_ajax_proc(@callback, @canvas.current_component))
	  @success  = "$('##{@attributes[:target]}').html(response);" + @success.to_s if @attributes.has_key? :target
	  @attributes[:onsubmit]  = %Q{
		$.ajax({  
			data:$.param($(this).serializeArray()),
			success: function(response){ #{@success} },
			type:'post', 
			url:'#{@attributes[:action]}'
		});
		return false;
		}
	  super(&block)
	  return self
	 end


	 def __callback 

	 end
 end #ajax form class

 class Brush::ButtonTag < Brush::GenericTagBrush
    HTML_TAG = 'button'.freeze
    
    html_attr :name
    html_attr :accesskey
    html_attr :dir
    html_attr :title
    html_attr :tabindex
    
    def initialize
      super(HTML_TAG)
    end
    
 end
 
 class Brush::IFrameTag < Brush::GenericTagBrush
    HTML_TAG = 'iframe'.freeze
    
    html_attr :src
    html_attr :name
    html_attr :width
    html_attr :height
    html_attr :scrolling
    html_attr :frameborder
    
    def initialize
      super(HTML_TAG)
    end 
   
 end
   
end # module Wee
