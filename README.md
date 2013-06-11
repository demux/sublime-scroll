sublime-scroll v0.0.5 (alpha)
====================

"Sublime Text 2"-style scroll bars. Renders a visual scroll bar on right side of the webpage using css scaling.

Working demo: http://django.is

![django.is screenshot](docs/django.is.png)

## Installation

###Requires:

* jQuery v1.9.1 (http://jquery.com/)
* ~~rasterizeHTML.js (https://github.com/cburgmer/rasterizeHTML.js)~~ (canvas is no longer being used to render the scroll)

### Settings:
##### Available settings:
Option:                    | Type:  | Value: | Default:
-------------------------- | ------ | ------ | --------
__top__                    | int    |        | 0
__bottom__                 | int    |        | 0
__zIndex__                 | int    |        | 9999
__opacity__                | float  |        | 0.9
__color__                  | string | color css | 'rgba(255, 255, 255, 0.1)'
__transparent_background__ | bool   | true
__fixed_elements__         | string | List of css selectors seperated by comma | `''`
__scroll_width__           | int / callback | | 150
__scroll_height__          | int / callback | | `function() {return $(window).height() - this.settings.top - this.settings.bottom;}`)  
__content_width__          | int / callback | | `function() {return $('body').width();}`)  
__content_height__         | int / callback | | `function() {return $('body').outerHeight(true);}`)

##### CoffeeScript Example:
~~~ coffeescript
$ ->
    $.sublimeScroll
        top: 59
        fixed_elements: 'header.top'

        content_width: ($el, settings, $scroll_wrapper) ->
            return $('#content .wrapper').width() + 60
~~~
