class SublimeScroll
    el:
        wrapper:        null
        iframe:         null
        scrollBar:      null
        overlay:        null

    dragActive:     false
    scaleFactor:    null
    wrapperHeight:  null
    viewportHeight: null
    settings:       null

    update: (options) ->
        @settings = $.extend(@settings, options)

    # Settings getters:
    _setting_getter: (key) -> ->
        if typeof(@settings[key]) is "function"
            return @settings[key].call(this)
        else
            return @settings[key]

    # Constructor:
    (options) ->
        # Don't render inside iframes
        if not (top.document is document)
            return @

        # Default settings:
        @settings =
            top: 0
            bottom: 0
            fixedElements: ''
            scrollWidth: 150
            scrollHeight: -> $(window).height() - @getTop() - @getBottom()
            contentWidth: -> $(document).outerWidth(true)
            contentHeight: -> $(document).outerHeight(true)
            minWidth: null

        # Create getters:
        capFirst = (string) ->
            string.charAt(0).toUpperCase() + string.slice(1)

        for setting, _v of @settings
            this['get' + capFirst(setting)] = @_setting_getter(setting)

        # Update default settings Width options:
        @update(options)

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
            width: @getScrollWidth()
            height: @getScrollHeight()
            top: @getTop()
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
        @el.scrollBar = $ '<div>', do
            id: 'sublime-scroll-bar'

        $html = $('html').clone()
        $html.find('body').addClass('sublime-scroll-window')
        $html.find('#sublime-scroll').remove()
        @el.scrollBar.appendTo($html.find('body'))

        # Move fixed elements:
        $html.find(@getFixedElements()).remove().addClass('sublime-scroll-fixed-element').appendTo(@el.scrollBar)

        @el.iframe.on('load', @onIframeLoad)

        @iframe_document.write($html.html())
        @iframe_document.close()

        @el.overlay = $ '<div>', do
            id: 'sublime-scroll-overlay'
        .css do
            top: @getTop()
            width: @getScrollWidth()
        .appendTo(@el.wrapper)

    # On iframe load event:
    onIframeLoad: (event) ~>
        @el.scrollBar = $('#sublime-scroll-bar', @iframe_document)
        $(window).resize().scroll()
        @el.wrapper.animate({opacity: 1}, 100)

    # On resize event:
    onResize: (event) ~>
        contentWidth = @getContentWidth()
        contentHeight = @getContentHeight()

        if @getMinWidth() and $(window).width() < @getMinWidth()
            @el.wrapper.hide()
        else
            @el.wrapper.show()

        @scaleFactor = @getScrollWidth() / contentWidth

        @contentWidth_scaled = contentWidth * @scaleFactor
        @contentHeight_scaled = contentHeight * @scaleFactor

        @el.iframe.css do
            width: contentWidth
            height: contentHeight
            transform: 'scale(' + @scaleFactor + ')'
            marginLeft: -(contentWidth / 2 - @contentWidth_scaled / 2)
            marginTop: -(contentHeight / 2 - @contentHeight_scaled / 2)

        # Scroll wrapper
        @wrapperHeight = @getScrollHeight()
        @el.wrapper.css do
            height: @wrapperHeight

        # Scroll bar
        @viewportHeight = $(window).height()
        @viewportHeight_scaled = @viewportHeight * @scaleFactor

        @el.scrollBar.css do
            height: @viewportHeight

        $(window).scroll()

    # On scroll event:
    onScroll: (event) ~>
        if not @dragActive
            @el.scrollBar.css do
                transform: 'translateY(' + $(window).scrollTop() + 'px)'

        if @contentHeight_scaled > @wrapperHeight
            y = @el.scrollBar.position().top * @scaleFactor

            ch = @contentHeight_scaled - @viewportHeight_scaled

            max_margin = ch - @wrapperHeight
            
            factor = y / ch

            viewportFactor = @viewportHeight_scaled / ch

            margin = -(factor * max_margin + viewportFactor * y)
        else
            margin = 0

        @el.iframe.css do
            transform: 'translateY(' + margin + 'px) scale(' + @scaleFactor + ')'

        return @

    # On drag end event:
    onDragEnd: (event) ~>
        event.preventDefault()

        @el.overlay.css do
            width: @getScrollWidth()

        $(window).off('mousemove.sublimeScroll', @onDrag)

        @dragActive = false

    # On drag event:
    onDrag: (event) ~>
        @dragActive = true
        if not (event.target is @el.overlay[0])
            return false

        offsetY = event.offsetY or event.originalEvent.layerY
        if @contentHeight_scaled > @wrapperHeight
            _scaleFactor = @wrapperHeight / @getContentHeight()
        else
            _scaleFactor = @scaleFactor

        y = (offsetY / _scaleFactor - @viewportHeight / 2)

        max_pos = @getContentHeight() - @viewportHeight

        if y < 0
            y = 0
        if y > max_pos
            y = max_pos

        @el.scrollBar.css do
            transform: 'translateY(' + y + 'px)'

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

var _sublime_scroll_object

$.sublimeScroll = (options) ->
    if _sublime_scroll_object? and options?
        return _sublime_scroll_object.update(options)

    else if _sublime_scroll_object?
        return _sublime_scroll_object

    else
        _sublime_scroll_object := new SublimeScroll(options)

        return _sublime_scroll_object
