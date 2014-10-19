/* Copyright 2013-present Arnar Yngvason
 * Licensed under MIT License */
(function(){
  var SublimeScroll, _sublime_scroll_object;
  SublimeScroll = (function(){
    SublimeScroll.displayName = 'SublimeScroll';
    var prototype = SublimeScroll.prototype, constructor = SublimeScroll;
    prototype.isTouch = ('ontouchstart' in window);
    if (prototype.isTouch) {
        prototype.eventStart = 'touchstart';
        prototype.startMove = 'touchmove';
        prototype.endMove = 'touchend';
    } else {
        prototype.eventStart = 'mousedown';
        prototype.startMove = 'mousemove';
        prototype.endMove = 'mouseup';
    }
    prototype.el = {
      wrapper: null,
      iframe: null,
      scrollBar: null,
      overlay: null
    };
    prototype.dragActive = false;
    prototype.scaleFactor = null;
    prototype.wrapperHeight = null;
    prototype.viewportHeight = null;
    prototype.settings = null;
    prototype.addEvent = function (evnt, elem, func) {
        // W3C DOM
        if (elem.addEventListener) {
            elem.addEventListener(evnt, func, false);
        } else if (elem.attachEvent) { // IE DOM
            elem.attachEvent('on' + evnt, func);
        } else { // No much to do
            elem[evnt] = func;
        }
    };
    prototype.removeEvent = function (evnt, elem, func) {
        if (elem.removeEventListener) {
            elem.removeEventListener(evnt, func, false);
        } else if (elem.detachEvent) {
            elem.detachEvent('on' + evnt, func);
        } else {
            elem['on' + evnt] = null;
        }
    };
    prototype.fireEvent = function (obj, evt) {
        var fireOnThis = obj,
            evtObj;
        if (document.createEvent) {
            evtObj = document.createEvent('MouseEvents');
            evtObj.initEvent(evt, true, false);
            fireOnThis.dispatchEvent(evtObj);
        } else if (document.createEventObject) {
            evtObj = document.createEventObject();
            fireOnThis.fireEvent('on' + evt, evtObj);
        }
    };
    prototype.update = function(options){
      this.settings = $.extend(this.settings, options);
      return this;
    };
    prototype._setting_getter = function(key){
      return function(){
        if (typeof this.settings[key] === "function") {
          return this.settings[key].call(this);
        } else {
          return this.settings[key];
        }
      };
    };
    function SublimeScroll(options){
      var capFirst, setting, ref$, _v;
      this.onDrag = bind$(this, 'onDrag', prototype);
      this.onDragEnd = bind$(this, 'onDragEnd', prototype);
      this.onScroll = bind$(this, 'onScroll', prototype);
      this.onResize = bind$(this, 'onResize', prototype);
      this.onIframeLoad = bind$(this, 'onIframeLoad', prototype);
      this.onMousedown = bind$(this, 'onMousedown', prototype);
      if (!(top.document === document)) {
        return this;
      }
      this.settings = {
        top: 0,
        bottom: 0,
        fixedElements: '',
        removeElements: '',
        scrollWidth: 150,
        scrollHeight: function(){
          return $(window).height() - this.getTop() - this.getBottom();
        },
        contentWidth: function(){
          return $(document).outerWidth(true);
        },
        contentHeight: function(){
          return $(document).outerHeight(true);
        },
        minWidth: null,
        render: true,
        include: []
      };
      capFirst = function(string){
        return string.charAt(0).toUpperCase() + string.slice(1);
      };
      for (setting in ref$ = this.settings) {
        _v = ref$[setting];
        this['get' + capFirst(setting)] = this._setting_getter(setting);
      }
      this.update(options);
      this.addEvent('resize', window, this.onResize);
      this.addEvent('scroll', window, this.onScroll);
      if (this.getRender()) {
        this.render();
      }
      this.addEvent(this.eventStart, this.el.overlay.get(0), this.onMousedown);
      return this;
    }
    prototype.onMousedown = function(event){
      event.preventDefault();
      this.el.overlay.css({
        width: '100%'
      });
      this.addEvent(this.startMove, window, this.onDrag);
      this.addEvent(this.endMove, window, this.onDragEnd);
      return this.onDrag(event);
    };
    prototype.render = function(){
      var $html, i$, ref$, len$, inc;
      this.el.wrapper = $('<div>', {
        id: "sublime-scroll"
      }).css({
        width: this.getScrollWidth(),
        height: this.getScrollHeight(),
        top: this.getTop()
      }).appendTo($('body'));
      this.el.iframe = $('<iframe>', {
        id: 'sublime-scroll-iframe',
        frameBorder: '0',
        scrolling: 'no',
        allowTransparency: true
      }).appendTo(this.el.wrapper);
      this.iframe_document = this.el.iframe[0].contentDocument || this.el.iframe.contentWindow.document;
      this.el.scrollBar = $('<div>', {
        id: 'sublime-scroll-bar'
      });
      $html = $('html').clone();
      $html.find('body').addClass('sublime-scroll-window');
      $html.find('#sublime-scroll').remove();
      this.el.scrollBar.appendTo($html.find('body'));
      $html.find(this.getFixedElements()).remove().addClass('sublime-scroll-fixed-element').appendTo(this.el.scrollBar);
      $html.find(this.getRemoveElements()).remove();
      for (i$ = 0, len$ = (ref$ = this.getInclude().filter(fn$)).length; i$ < len$; ++i$) {
        inc = ref$[i$];
        $html.find('body').append($('<script>', {
          src: inc,
          type: 'text/javascript'
        }));
      }
      for (i$ = 0, len$ = (ref$ = this.getInclude().filter(fn1$)).length; i$ < len$; ++i$) {
        inc = ref$[i$];
        $html.find('head').append($('<link>', {
          href: inc,
          rel: 'stylesheet',
          type: 'text/css'
        }));
      }
      this.addEvent('load', this.el.iframe.get(0), this.onIframeLoad);
      this.iframe_document.write($html.html());
      this.iframe_document.close();
      this.el.overlay = $('<div>', {
        id: 'sublime-scroll-overlay'
      }).css({
        top: this.getTop(),
        width: this.getScrollWidth()
      }).appendTo(this.el.wrapper);
      return this;
      function fn$(str){
        return /\.js$/.test(str);
      }
      function fn1$(str){
        return /\.css$/.test(str);
      }
    };
    prototype.onIframeLoad = function(event){
      this.el.scrollBar = $('#sublime-scroll-bar', this.iframe_document);
      this.fireEvent(window, 'resize');
      this.fireEvent(window, 'scroll');
      this.el.wrapper.animate({
        opacity: 1
      }, 100);
      return this;
    };
    prototype.onResize = function(event){
      var contentWidth, contentHeight;
      contentWidth = this.getContentWidth();
      contentHeight = this.getContentHeight();
      if (this.getMinWidth() && $(window).width() < this.getMinWidth()) {
        this.el.wrapper.hide();
      } else {
        this.el.wrapper.show();
      }
      this.scaleFactor = this.getScrollWidth() / contentWidth;
      this.contentWidth_scaled = contentWidth * this.scaleFactor;
      this.contentHeight_scaled = contentHeight * this.scaleFactor;
      this.el.iframe.css({
        width: contentWidth,
        height: contentHeight,
        transform: 'scale(' + this.scaleFactor + ')',
        marginLeft: -(contentWidth / 2 - this.contentWidth_scaled / 2),
        marginTop: -(contentHeight / 2 - this.contentHeight_scaled / 2)
      });
      this.wrapperHeight = this.getScrollHeight();
      this.el.wrapper.css({
        height: this.wrapperHeight
      });
      this.viewportHeight = $(window).height();
      this.viewportHeight_scaled = this.viewportHeight * this.scaleFactor;
      this.el.scrollBar.css({
        height: this.viewportHeight
      });
      $(window).scroll();
      return this;
    };
    prototype.onScroll = function(event){
      var y, ch, max_margin, factor, viewportFactor, margin;
      if (!this.dragActive) {
        this.el.scrollBar.css({
          transform: 'translateY(' + $(window).scrollTop() + 'px)'
        });
      }
      if (this.contentHeight_scaled > this.wrapperHeight) {
        y = this.el.scrollBar.position().top * this.scaleFactor;
        ch = this.contentHeight_scaled - this.viewportHeight_scaled;
        max_margin = ch - this.wrapperHeight;
        factor = y / ch;
        viewportFactor = this.viewportHeight_scaled / ch;
        margin = -(factor * max_margin + viewportFactor * y);
      } else {
        margin = 0;
      }
      this.el.iframe.css({
        transform: 'translateY(' + margin + 'px) scale(' + this.scaleFactor + ')'
      });
      return this;
    };
    prototype.onDragEnd = function(event){
      if (!this.isTouch) {
        event.preventDefault();
        this.removeEvent(this.startMove, window, this.onDrag);
      }
      this.el.overlay.css({
        width: this.getScrollWidth()
      });
      this.dragActive = false;
      return this;
    };
    prototype.onDrag = function(event){
      var offsetY, _scaleFactor, y, max_pos;
      this.dragActive = true;
      if (!(event.target === this.el.overlay[0])) {
        this.dragActive = false;
        return false;
      }
      if (this.isTouch) {
        offsetY = event.changedTouches[0].pageY - this.el.overlay.offset().top;
      } else {
        offsetY = event.offsetY || event.clientY;
      }
      if (this.contentHeight_scaled > this.wrapperHeight) {
        _scaleFactor = this.wrapperHeight / this.getContentHeight();
      } else {
        _scaleFactor = this.scaleFactor;
      }
      y = offsetY / _scaleFactor - this.viewportHeight / 2;
      max_pos = this.getContentHeight() - this.viewportHeight;
      if (y < 0) {
        y = 0;
      }
      if (y > max_pos) {
        y = max_pos;
      }
      this.el.scrollBar.css({
        transform: 'translateY(' + y + 'px)'
      });
      $(window).scrollTop(y);
      return this;
    };
    prototype.destroy = function(){
      var _sublime_scroll_object;
      this.removeEvent('resize', window, this.onResize);
      this.removeEvent('scroll', window, this.onScroll);
      _sublime_scroll_object = null;
      return this;
    };
    return SublimeScroll;
  }());
  window.SublimeScroll = SublimeScroll;
  $.sublimeScroll = function(options){
    if (_sublime_scroll_object != null && options != null) {
      return _sublime_scroll_object.update(options);
    } else if (_sublime_scroll_object != null) {
      return _sublime_scroll_object;
    } else {
      _sublime_scroll_object = new SublimeScroll(options);
      return _sublime_scroll_object;
    }
  };
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
}).call(this);
