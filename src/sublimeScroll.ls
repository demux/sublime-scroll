class SublimeScroll
    el:
        wrapper:        null
        iframe:         null
        scroll_bar:     null
        overlay:        null

    dragActive:     false
    scaleFactor:    null
    wrapperHeight:  null
    viewportHeight: null
    settings:       null

    update: (options) ->
        @settings = $.extend(@settings, options)

    # Settings getters:
    _get_setting: (setting) ->
        if typeof(@settings[setting]) is "function"
            return @settings[setting].call(this, @settings)
        else
            return @settings[setting]

    get_scrollWith: -> @_get_setting('scrollWidth')
    get_scrollHeight: -> @_get_setting('scrollHeight')
    get_contentWidth: -> @_get_setting('contentWidth')
    get_contentHeight: -> @_get_setting('contentHeight')
    get_minWidth: -> @_get_setting('minWidth')

    # Constructor:
    (options) ->
        console.log 'init'
        # Don't render inside iframes
        if not (top.document is document)
            return @

        # Default settings:
        @settings =
            top: 0
            bottom: 0
            fixedElements: ''
            scrollWidth: 150
            scrollHeight: -> $(window).height() - @settings.top - @settings.bottom
            contentWidth: -> $(document).outerWidth(true)
            contentHeight: -> $(document).outerHeight(true)
            minWidth: -> @get_contentWidth()

        # Update default settings with options:
        @update(options)

        console.log @settings

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
            width: @get_scrollWith()
            height: @get_scrollHeight()
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
        $html.find(@settings.fixedElements).remove().addClass('sublime-scroll-fixed-element').appendTo(@el.scroll_ar)

        @el.iframe.on('load', @onIframeLoad)

        @iframe_document.write($html.html())
        @iframe_document.close()

        @el.overlay = $ '<div>', do
            id: 'sublime-scroll-overlay'
        .css do
            top: @settings.top
            width: @get_scrollWith()
        .appendTo(@el.wrapper)

    # On iframe load event:
    onIframeLoad: (event) ~>
        @el.scroll_bar = $('#sublime-scroll-bar', @iframe_document)
        $(window).resize().scroll()
        @el.wrapper.animate({opacity: 1}, 100)

    # On resize event:
    onResize: (event) ~>
        contentWidth = @get_contentWidth()
        contentHeight = @get_contentHeight()

        if $(window).width() > @get_minWidth()
            @el.wrapper.show()
        else
            @el.wrapper.hide()

        @scaleFactor = @get_scrollWith() / contentWidth

        @contentWidth_scaled = contentWidth * @scaleFactor
        @contentHeight_scaled = contentHeight * @scaleFactor

        @el.iframe.css do
            width: contentWidth
            height: contentHeight
            transform: 'scale(' + @scaleFactor + ')'
            marginLeft: -(contentWidth / 2 - @contentWidth_scaled / 2)
            marginTop: -(contentHeight / 2 - @contentHeight_scaled / 2)

        # Scroll wrapper
        @wrapperHeight = @get_scrollHeight()
        @el.wrapper.css do
            height: @wrapperHeight

        # Scroll bar
        @viewportHeight = $(window).height()
        @viewportHeight_scaled = @viewportHeight * @scaleFactor

        @el.scroll_bar.css do
            height: @viewportHeight

        $(window).scroll()

    # On scroll event:
    onScroll: (event) ~>
        if not @dragActive
            @el.scroll_bar.css do
                top: $(window).scrollTop()

        if @contentHeight_scaled > @wrapperHeight
            y = @el.scroll_bar.position().top * @scaleFactor

            ch = @contentHeight_scaled - @viewportHeight_scaled

            max_margin = ch - @wrapperHeight
            
            factor = y / ch

            viewportFactor = @viewportHeight_scaled / ch

            margin = -(factor * max_margin + viewportFactor * y)
        else
            margin = 0

        @el.iframe.css do
            top: margin

        return @

    # On drag end event:
    onDragEnd: (event) ~>
        event.preventDefault()

        @el.overlay.css do
            width: @get_scrollWith()

        $(window).off('mousemove.sublimeScroll', @onDrag)

        @dragActive = false

    # On drag event:
    onDrag: (event) ~>
        @dragActive = true
        if not (event.target is @el.overlay[0])
            return false

        offsetY = event.offsetY or event.originalEvent.layerY
        if @contentHeight_scaled > @wrapperHeight
            _scaleFactor = @wrapperHeight / @get_contentHeight()
        else
            _scaleFactor = @scaleFactor

        y = (offsetY / _scaleFactor - @viewportHeight / 2)

        max_pos = @get_contentHeight() - @viewportHeight

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
