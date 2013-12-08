sublime-scroll
====================

"Sublime Text 2"-style scroll bars. Renders a visual scroll bar on right side of the webpage using css scaling.

Working demo: http://django.is

![django.is screenshot](docs/django.is.png)

## Installation

###Requires:

* jQuery (http://jquery.com/)

### Settings:
##### Available settings:
Option:                    | Type:  | Value: | Default:
-------------------------- | ------ | ------ | --------
__top__                    | int    |        | 0
__bottom__                 | int    |        | 0
__fixedElements__          | string | List of css selectors seperated by comma | `''`
__scrollWidth__            | int    |        | 150
__scrollHeight__           | int    |        | `function() {return $(window).height() - this.getTop() - this.getBottom();}`)
__contentWidth__           | int    |        | `function() {return $('body').width();}`)  
__contentWeight__          | int    |        | `function() {return $('body').outerHeight(true);}`)


See example.html for example code.
