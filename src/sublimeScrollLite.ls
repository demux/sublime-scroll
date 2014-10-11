/* Copyright 2013-present Arnar Yngvason
 * Licensed under MIT License */

class SublimeScrollLite
    el:
        wrapper:    null
        scrollPane: null
        scrollBar:  null
        overlay:    null

    dragActive:     false
    scaleFactor:    null
    wrapperHeight:  null
    viewportHeight: null
    settings:       null

    update: (options) ->
        @settings = $.extend(@settings, options)
        return @

    # Settings getters:
    _setting_getter: (key) -> ->
        if typeof(@settings[key]) is "function"
            return @settings[key].call(this)
        else
            return @settings[key]

    # Constructor:
    ($el, options) ->
        @$el = $el

        # Default settings:
        @settings =
            top: 0
            bottom: 0
            fixedElements: ''
            removeElements: ''
            scrollWidth: 100
            scrollHeight: -> @getContentHeight() - @getTop() - @getBottom()
            contentWidth: -> @$el.innerWidth()
            contentHeight: -> @$el[0].scrollHeight
            minWidth: null
            render: true
            include: []

        # Create getters:
        capFirst = (string) ->
            string.charAt(0).toUpperCase() + string.slice(1)

        for setting, _v of @settings
            this['get' + capFirst(setting)] = @_setting_getter(setting)

        # Update default settings Width options:
        @update(options)

        # Create events:
        $el.bind('scroll.sublimeScroll', @onScroll)

        # Render scroll bar:
        @render() if @getRender()

        # Events for rendered elements:
        @el.overlay.on 'mousedown.sublimeScroll', @onMousedown
        return @

    onMousedown: (event) ~>
        event.preventDefault()

        @el.overlay.css do
            width: '100%'

        @el.overlay.on('mousemove.sublimeScroll', @onDrag)
        $(window).one('mouseup.sublimeScroll', @onDragEnd)

        @onDrag(event)

    # Render scroll bar:
    render: ->
        # Content Wrapper:
        @el.contentWrapper = $ '<div>', do
            class: "sublime-scroll-wrapper"

        @el.contentWrapper = @$el.wrap(@el.contentWrapper).parent()

        # Wrapper:
        @el.wrapper = $ '<div>', do
            class: "sublime-scroll"
        .css do
            width: @getScrollWidth()
            height: @getScrollHeight()
            top: @getTop()
        .appendTo(@el.contentWrapper)

        # Scroll pane:
        @el.scrollPane = $ '<div>', do
            class: 'sublime-scroll-pane'
        .appendTo(@el.wrapper)

        @el.scrollPane.html @$el.html!

        # Scroll bar:
        @el.scrollBar = $ '<div>', do
            class: 'sublime-scroll-bar'
        .appendTo(@el.scrollPane)

        # Move fixed elements:
        @el.scrollPane.find(@getFixedElements()).remove().addClass('sublime-scroll-fixed-element').appendTo(@el.scrollBar)
        @el.scrollPane.find(@getRemoveElements()).remove()

        @el.overlay = $ '<div>', do
            class: 'sublime-scroll-overlay'
        .css do
            top: @getTop()
            width: @getScrollWidth()
            height: @$el.height()
        .appendTo(@el.wrapper)

        @onResize!

        return @

    # On resize event:
    onResize: (event) ~>
        contentWidth = @getContentWidth()
        contentHeight = @getContentHeight()

        if @getMinWidth() and @$el.width() < @getMinWidth()
            @el.wrapper.hide()
        else
            @el.wrapper.show()

        @scaleFactor = @getScrollWidth() / contentWidth

        @contentWidth_scaled = contentWidth * @scaleFactor
        @contentHeight_scaled = contentHeight * @scaleFactor

        @el.scrollPane.css do
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
        @viewportHeight = @$el.innerHeight()
        @viewportHeight_scaled = @viewportHeight * @scaleFactor

        @el.scrollBar.css do
            height: @viewportHeight

        @$el.scroll()

        return @

    # On scroll event:
    onScroll: (event) ~>
        if not @dragActive
            @el.scrollBar.css do
                transform: 'translateY(' + @$el.scrollTop() + 'px)'

        if @contentHeight_scaled > @wrapperHeight
            y = @el.scrollBar.position().top * @scaleFactor

            ch = @contentHeight_scaled - @viewportHeight_scaled

            max_margin = ch - @wrapperHeight

            factor = y / ch

            viewportFactor = @viewportHeight_scaled / ch

            margin = -(factor * max_margin + viewportFactor * y)
        else
            margin = 0

        @el.scrollPane.css do
            transform: 'translateY(' + margin + 'px) scale(' + @scaleFactor + ')'

        return @

    # On drag end event:
    onDragEnd: (event) ~>
        event.preventDefault()

        @el.overlay.css do
            width: @getScrollWidth()

        @el.overlay.off('mousemove.sublimeScroll', @onDrag)

        @dragActive = false

        return @

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

        @$el.scrollTop(y)

        return @

    # Destroy the scroll bar
    destroy: ->
        # Unbind events:
        @$el
            .off('resize.sublimeScroll', @onResize)
            .off('scroll.sublimeScroll', @onScroll)

        return @


$.fn.sublimeScroll = (options) ->
    objects = []
    this.each ->
        objects.push(new SublimeScrollLite($(this), options))
    return objects
