(($) ->
	$.fn.sublimeScroll = (options) ->
		$el = @

		settings =
			top: 59
			zIndex: 50
			width: 150
			height: null
			opacity: 0.1
			color: 'white'
			content: $el[0].outerHTML
			content_width: null
			content_height: null
			content_padding: 30
			onResize: ($el, settings, $scroll_wrapper) ->
				settings.content_width = $el.width() + settings.content_padding * 2
				settings.content_height = $el.outerHeight(true)
				return true

		settings.height = $(window).height()

		# Merge default settings with options.
		settings = $.extend settings, options

		# Canvas
		$scroll_wrapper = $ '<div>',
			id: "sublime-scroll"
		.css
			position: 'fixed'
			zIndex: settings.zIndex
			width: settings.width
			height: settings.height
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
			$(window).off('mousemove', onDrag)
			drag_active = false

		onDrag = (event) ->
			drag_active = true
			if not (event.target is $scroll_overlay[0])
				return false

			y = event.offsetY - scroll_bar_height / 2

			max_pos = Math.round(settings.content_height * scale_factor - scroll_bar_height)

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

			$(window).on('mousemove', onDrag).one('mouseup', onDragEnd)
			onDrag(event)


		doit = null
		$(window).resize ->
			clearTimeout(doit)

			if not settings.onResize($el, settings, $scroll_wrapper)
				return false

			doit = setTimeout ->
				# Draw content on canvas
				canvas.width  = settings.content_width
				canvas.height = settings.content_height

				scale_factor = settings.width / settings.content_width

				context.scale(scale_factor, scale_factor)

				rasterizeHTML.drawHTML settings.content,
					width: settings.content_width
					height: settings.content_height
				, (image) ->
					context.drawImage(image, settings.content_padding * scale_factor, 0)

				# Scroll bar
				scroll_bar_height = $(window).height() * scale_factor

				$scroll_bar.css
					height: scroll_bar_height

				$(window).scroll()
			, 100
		.resize()
		
		$(window).scroll ->
			if not drag_active
				$scroll_bar.css
					top: $(window).scrollTop() * scale_factor

			scroll_height = settings.content_height * scale_factor
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
)(jQuery)