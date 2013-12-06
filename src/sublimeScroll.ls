class SublimeScroll
    el:
        wrapper:    null
        iframe:     null
        scroll_bar: null
        overlay:    null

    drag_active:        false
    scale_factor:       null
    wrapper_height:     null
    scroll_height:      null
    viewport_height:    null
    content_width:      null
    content_height:     null
    settings:           null

    update: (options) ->
        @settings = $.extend(@settings, options)

    # Settings getters:
    _get_setting: (setting) ->
        if typeof(@settings[setting]) is "function"
            return @settings[setting].call(this, @settings)
        else
            return @settings[setting]

    get_scroll_width: -> @_get_setting('scroll_width')
    get_scroll_height: -> @_get_setting('scroll_height')
    get_content_width: -> @_get_setting('content_width')
    get_content_height: -> @_get_setting('content_height')
    get_min_width: -> @_get_setting('min_width')

    # Constructor:
    (options) ->
        # Don't render inside iframes
        if not (top.document is document)
            return @

        # Default settings:
        @settings =
            top: 0
            bottom: 0
            fixed_elements: ''
            scroll_width: 150
            
        @settings.scroll_height = ->
            return $(window).height() - @settings.top - @settings.bottom

        @settings.content_width = -> $(document).outerWidth(true)

        @settings.content_height = -> $(document).outerHeight(true)

        @settings.min_width = -> @get_content_width()

        # Update default settings with options:
        @update(options)

        # Create settings getters:
        #for key, value of @settings
        #    this['get_' + key] = @_get_setting(key)

        # Create events:
        $(window)
            .bind('resize.sublimeScroll', @onResize)
            .bind('scroll.sublimeScroll', @onScroll)

        # Render scroll bar:
        @render()

        # Events for rendered elements:
        @el.overlay.on 'mousedown.sublimeScroll', (event) ~>
            event.preventDefault()

            @el.overlay.css do
                width:'100%'

            $(window)
                .on('mousemove.sublimeScroll', @onDrag)
                .one('mouseup.sublimeScroll', @onDragEnd)

            @onDrag(event)

        return @
    
    # Render scroll bar:
    render: ->
        # Wrapper:
        @el.wrapper = $ '<div>', do
            id: "sublime-scroll"
        .css do
            width: @get_scroll_width()
            height: @get_scroll_height()
            top: @settings.top
        .appendTo($('body'))

        # iframe:
        @el.iframe = $ '<iframe>', do
            id: 'sublime-scroll-iframe'
            frameBorder: '0'
            scrolling: 'no'
            allowTransparency: true
        .appendTo(@el.wrapper)
        
        @iframe_document = @el.iframe[0].contentDocument or @el.iframe.contentWindow.document

        # Scroll bar:
        @el.scroll_bar = $ '<div>', do
            id: 'sublime-scroll-bar'

        $html = $('html').clone()
        $html.find('body').addClass('sublime-scroll-window')
        $html.find('#sublime-scroll').remove()
        @el.scroll_bar.appendTo($html.find('body'))

        # Move fixed elements:
        $html.find(@settings.fixed_elements).remove().addClass('sublime-scroll-fixed-element').appendTo(@el.scroll_bar)

        @el.iframe.on('load', @onIframeLoad)

        @iframe_document.write($html.html())
        @iframe_document.close()

        @el.overlay = $ '<div>', do
            id: 'sublime-scroll-overlay'
        .css do
            top: @settings.top
            width: @get_scroll_width()
        .appendTo(@el.wrapper)

    # On iframe load event:
    onIframeLoad: (event) ~>
        @el.scroll_bar = $('#sublime-scroll-bar', @iframe_document)
        $(window).resize().scroll()
        @el.wrapper.animate({opacity: 1}, 100)

    # On resize event:
    onResize: (event) ~>
        content_width = @get_content_width()
        content_height = @get_content_height()

        if $(window).width() > @get_min_width()
            @el.wrapper.show()
        else
            @el.wrapper.hide()

        @scale_factor = @get_scroll_width() / content_width

        @content_width_scaled = content_width * @scale_factor
        @content_height_scaled = content_height * @scale_factor

        @el.iframe.css do
            width: content_width
            height: content_height
            transform: 'scale(' + @scale_factor + ')'
            marginLeft: -(content_width / 2 - @content_width_scaled / 2)
            marginTop: -(content_height / 2 - @content_height_scaled / 2)

        # Scroll wrapper
        @wrapper_height = @get_scroll_height()
        @el.wrapper.css do
            height: @wrapper_height

        # Scroll bar
        @viewport_height = $(window).height()
        @viewport_height_scaled = @viewport_height * @scale_factor

        @el.scroll_bar.css do
            height: @viewport_height

        $(window).scroll()

    # On scroll event:
    onScroll: (event) ~>
        if not @drag_active
            @el.scroll_bar.css do
                top: $(window).scrollTop()

        if @content_height_scaled > @wrapper_height
            y = @el.scroll_bar.position().top * @scale_factor

            ch = @content_height_scaled - @viewport_height_scaled

            max_margin = ch - @wrapper_height
            
            factor = y / ch

            viewport_factor = @viewport_height_scaled / ch

            margin = -(factor * max_margin + viewport_factor * y)
        else
            margin = 0

        @el.iframe.css do
            top: margin

        return @

    # On drag end event:
    onDragEnd: (event) ~>
        event.preventDefault()

        @el.overlay.css do
            width: @get_scroll_width()

        $(window).off('mousemove.sublimeScroll', @onDrag)

        @drag_active = false

    # On drag event:
    onDrag: (event) ~>
        @drag_active = true
        if not (event.target is @el.overlay[0])
            return false

        offsetY = event.offsetY or event.originalEvent.layerY
        if @content_height_scaled > @wrapper_height
            _scale_factor = @wrapper_height / @get_content_height()
        else
            _scale_factor = @scale_factor

        y = (offsetY / _scale_factor - @viewport_height / 2)

        max_pos = @get_content_height() - @viewport_height

        if y < 0
            y = 0
        if y > max_pos
            y = max_pos

        @el.scroll_bar.css do
            top: y

        $(window).scrollTop(y)

    # Destroy the scroll bar
    destroy: ->
        # Unbind events:
        $(window)
            .off('resize.sublimeScroll', @onResize)
            .off('scroll.sublimeScroll', @onScroll)

        _sublime_scroll_object = null

        return @

window.SublimeScroll = SublimeScroll

_sublime_scroll_object = null

$.sublimeScroll = (options) ->
    if _sublime_scroll_object and options
        return _sublime_scroll_object.update(options)

    else if _sublime_scroll_object
        return _sublime_scroll_object

    else
        _sublime_scroll_object = new SublimeScroll(options)

        return _sublime_scroll_object
