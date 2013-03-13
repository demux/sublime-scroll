(($) ->
	$.sublimeScroll = (options) ->
		if not (window.top is window)
			return this

		settings =
			top: 0
			bottom: 0
			zIndex: 200
			width: 150
			height: (settings, $scroll_wrapper) ->
				return $(window).height() - settings.top - settings.bottom
			opacity: 0.9
			color: 'rgba(255, 255, 255, 0.1)'
			transparent: true
			fixed_elements: ''
			
			content_width: (settings, $scroll_wrapper) ->
				return $('body').width()

			content_height: (settings, $scroll_wrapper) ->
				return $('body').outerHeight(true)
			
			onResize: (settings, $scroll_wrapper) ->
				return true

		# Merge default settings with options.
		settings = $.extend settings, options

		_get_setting = (setting) ->
			if typeof(settings[setting]) is "function"
				return settings[setting](settings, $scroll_wrapper)
			else
				return settings[setting]

		get_height = -> _get_setting('height')
		get_content_width = -> _get_setting('content_width')
		get_content_height = -> _get_setting('content_height')

		# Canvas
		$scroll_wrapper = $ '<div>',
			id: "sublime-scroll"
		.css
			position: 'fixed'
			zIndex: settings.zIndex
			width: settings.width
			height: get_height()
			top: settings.top
			right: 0
			overflow: 'hidden'
			opacity: 0
		.appendTo($('body'))

		$iframe = $ '<iframe>',
			id: 'sublime-scroll-iframe'
			frameBorder: '0'
			scrolling: 'no'
			allowTransparency: true
		.css
			position: 'absolute'
			border:0
			margin:0
			padding:0
			overflow:'hidden'
			top:0
			left:0
			zIndex: settings.zIndex + 1
		.appendTo($scroll_wrapper)
		iframe_document = $iframe[0].contentDocument or $iframe.contentWindow.document

		# Scroll bar
		drag_active = false
		scale_factor = null
		scroll_bar_height = null

		$scroll_bar = $ '<div>',
			id: 'sublime-scroll-bar'
		.css
			position: 'absolute'
			right: 0
			width: '100%'
			backgroundColor: settings.color
			opacity: settings.opacity
			zIndex:99999

		$html = $('html').clone()
		$html.find('body').addClass('sublime-scroll-window')
		$html.find('#sublime-scroll').remove()
		$scroll_bar.appendTo($html.find('body'))

		# Transparent scroll pane background:
		if settings.transparent
			$html.find('body').css
				backgroundColor: 'transparent'

		# Move fixed elements:
		$html.find(settings.fixed_elements).remove().css
			position: 'absolute'
		.appendTo($scroll_bar)

		$iframe.load ->
			$scroll_bar = $('#sublime-scroll-bar', iframe_document)
			$(window).resize().scroll()
			$scroll_wrapper.animate({opacity: 1}, 100)

		iframe_document.write($html.html())
		iframe_document.close()

		$scroll_overlay = $ '<div>',
			id: 'sublime-scroll-overlay'
		.css
			position: 'fixed'
			top: settings.top
			right: 0
			width: settings.width
			height:'100%'
			zIndex:settings.zIndex + 3
		.appendTo($scroll_wrapper)

		onDragEnd = (event) ->
			event.preventDefault()
			$scroll_overlay.css({width: settings.width})
			$(window).off('mousemove.sublimeScroll', onDrag)
			drag_active = false

		onDrag = (event) ->
			drag_active = true
			if not (event.target is $scroll_overlay[0])
				return false

			offsetY = event.offsetY or event.originalEvent.layerY

			y = (offsetY / scale_factor - scroll_bar_height / 2)

			max_pos = Math.round(get_content_height() - scroll_bar_height)

			if y < 0
				y = 0
			if y > max_pos
				y = max_pos

			$scroll_bar.css
				top: y

			$(window).scrollTop(y)

		$scroll_overlay.on 'mousedown', (event) ->
			event.preventDefault()

			$scroll_overlay.css({width:'100%'})

			$(window).on('mousemove.sublimeScroll', onDrag).one('mouseup', onDragEnd)
			onDrag(event)


		$(window).bind 'resize.sublimeScroll', ->
			if not settings.onResize(settings, $scroll_wrapper)
				return false

			width = get_content_width()
			height = get_content_height()

			scale_factor = settings.width / width

			$iframe.css
				width: width
				height: height
				transform: 'scale(' + scale_factor + ')'
				marginLeft: -(width / 2 - width * scale_factor / 2)
				marginTop: -(height / 2 - height * scale_factor / 2)

			# Scroll wrapper
			$scroll_wrapper.css
				height: get_height()

			# Scroll bar
			scroll_bar_height = $(window).height()

			$scroll_bar.css
				height: scroll_bar_height

			$(window).scroll()
		
		$(window).bind 'scroll.sublimeScroll', ->
			if not drag_active
				$scroll_bar.css
					top: $(window).scrollTop()

			scroll_height = get_content_height() * scale_factor
			window_height = get_height()

			if scroll_height > window_height
				y = $scroll_bar.position().top * scale_factor
				
				f = (scroll_bar_height / scroll_height) * y * scale_factor

				margin = (y / scroll_height) * (window_height - scroll_height) - f
			else
				margin = 0

			$iframe.css
				top: margin

			$iframe.css
				top: margin

		return this
)(jQuery)