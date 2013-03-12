(($) ->
	$.fn.sublimeScroll = (options) ->
		$el = @

		settings =
			top: 0
			bottom: 0
			zIndex: 50
			width: 150
			opacity: 0.1
			color: '#FFFFFF'

			content: ($el, settings, $scroll_wrapper) ->
				$content = $el.clone()

				$content.css
					paddingTop: parseInt($el.css('padding-top')) - settings.top
					paddingBottom: parseInt($el.css('padding-bottom')) - settings.bottom

				# Remove all javascript from content:
				$content.find('script').remove()

				# Remove all foreign stylesheets:
				$content.find('link[href^="http"]')

				return $content[0].outerHTML

			content_padding: parseInt($el.css('padding-left'))
			
			content_width: ($el, settings, $scroll_wrapper) ->
				return $el.width() + get_content_padding() * 2

			content_height: ($el, settings, $scroll_wrapper) ->
				return $el.outerHeight(true)
			
			onResize: ($el, settings, $scroll_wrapper) ->
				return true

		# Merge default settings with options.
		settings = $.extend settings, options

		_get_setting = (setting) ->
			if typeof(settings[setting]) is "function"
				return settings[setting]($el, settings, $scroll_wrapper)
			else
				return settings[setting]

		get_content = -> _get_setting('content')
		get_content_padding = -> _get_setting('content_padding')
		get_content_width = -> _get_setting('content_width')
		get_content_height = -> _get_setting('content_height')

		# Canvas
		$scroll_wrapper = $ '<div>',
			id: "sublime-scroll"
		.css
			position: 'fixed'
			zIndex: settings.zIndex
			width: settings.width
			height: $(window).height() - settings.top - settings.bottom
			top: settings.top
			right: 0
		.appendTo($('body'))

		$canvas = $ '<canvas>',
			id: 'sublime-scroll-canvas'
		.css
			position: 'absolute'
			top:0
			left:0
			zIndex: settings.zIndex + 1
		.appendTo($scroll_wrapper)

		canvas = $canvas[0]
		context = canvas.getContext("2d")

		# Scroll bar
		drag_active = false
		window_height = null
		scale_factor = null
		scroll_height = null
		scroll_bar_height = null

		$scroll_bar = $ '<div>',
			id: 'sublime-scroll-bar'
		.css
			position: 'absolute'
			right: 0
			width: '100%'
			backgroundColor: settings.color
			opacity: settings.opacity
			zIndex:settings.zIndex + 3
		.appendTo($scroll_wrapper)

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

			y = offsetY - scroll_bar_height / 2

			max_pos = Math.round(get_content_height() * scale_factor - scroll_bar_height)

			if y < 0
				y = 0
			if y > max_pos
				y = max_pos

			$scroll_bar.css
				top: y

			$(window).scrollTop(y / scale_factor)

		$scroll_overlay.on 'mousedown', (event) ->
			event.preventDefault()

			$scroll_overlay.css({width:'100%'})

			$(window).on('mousemove.sublimeScroll', onDrag).one('mouseup', onDragEnd)
			onDrag(event)


		doit = null
		$(window).bind 'resize.sublimeScroll', ->
			clearTimeout(doit)

			if not settings.onResize($el, settings, $scroll_wrapper)
				return false

			doit = setTimeout ->
				# Draw content on canvas
				canvas.width  = get_content_width()
				canvas.height = get_content_height()

				scale_factor = settings.width / get_content_width()

				context.scale(scale_factor, scale_factor)

				rasterizeHTML.drawHTML get_content($el, settings, $scroll_wrapper),
					width: get_content_width()
					height: get_content_height()
				, (image) ->
					context.drawImage(image, get_content_padding() * scale_factor, 0)

				# Scroll bar
				scroll_bar_height = $(window).height() * scale_factor

				$scroll_bar.css
					height: scroll_bar_height

				$(window).scroll()
			, 100
		.resize()
		
		$(window).bind 'scroll.sublimeScroll', ->
			if not drag_active
				$scroll_bar.css
					top: $(window).scrollTop() * scale_factor

			scroll_height = get_content_height() * scale_factor
			window_height = $(window).height()
			if scroll_height > window_height
				y = $scroll_bar.position().top
				
				f = (scroll_bar_height / scroll_height) * y

				margin = (y / scroll_height) * (window_height - scroll_height) - f
			else
				margin = 0

			$scroll_wrapper.css
				marginTop: margin

			$scroll_overlay.css
				marginTop: margin
		.scroll()

		return @
)(jQuery)