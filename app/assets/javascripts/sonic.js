/*
 * Sonic 0.2
 * --
 * https://github.com/padolsey/Sonic
 * --
 * This program is free software. It comes without any warranty, to
 * the extent permitted by applicable law. You can redistribute it
 * and/or modify it under the terms of the Do What The Fuck You Want
 * To Public License, Version 2, as published by Sam Hocevar. See
 * http://sam.zoy.org/wtfpl/COPYING for more details. */ 

(function(){

  var emptyFn = function(){};

  function Sonic(d) {

    this.converter = d.converter;

    this.data = d.path || d.data;
    this.imageData = [];

    this.multiplier = d.multiplier || 1;
    this.padding = d.padding || 0;

    this.fps = d.fps || 25;

    this.stepsPerFrame = ~~d.stepsPerFrame || 1;
    this.trailLength = d.trailLength || 1;
    this.pointDistance = d.pointDistance || .05;

    this.domClass = d.domClass || 'sonic';

    this.backgroundColor = d.backgroundColor || 'rgba(0,0,0,0)';
    this.fillColor = d.fillColor;
    this.strokeColor = d.strokeColor;

    this.stepMethod = typeof d.step == 'string' ?
      stepMethods[d.step] :
      d.step || stepMethods.square;

    this._setup = d.setup || emptyFn;
    this._teardown = d.teardown || emptyFn;
    this._preStep = d.preStep || emptyFn;

    this.pixelRatio = d.pixelRatio || null;

    this.width = d.width;
    this.height = d.height;

    this.fullWidth = this.width + 2 * this.padding;
    this.fullHeight = this.height + 2 * this.padding;

    this.domClass = d.domClass || 'sonic';

    this.setup();

  }

  var argTypes = Sonic.argTypes = {
    DIM: 1,
    DEGREE: 2,
    RADIUS: 3,
    OTHER: 0
  };

  var argSignatures = Sonic.argSignatures = {
    arc: [1, 1, 3, 2, 2, 0],
    bezier: [1, 1, 1, 1, 1, 1, 1, 1],
    line: [1,1,1,1]
  };

  var pathMethods = Sonic.pathMethods = {
    bezier: function(t, p0x, p0y, p1x, p1y, c0x, c0y, c1x, c1y) {
      
        t = 1-t;

        var i = 1-t,
            x = t*t,
            y = i*i,
            a = x*t,
            b = 3 * x * i,
            c = 3 * t * y,
            d = y * i;

        return [
            a * p0x + b * c0x + c * c1x + d * p1x,
            a * p0y + b * c0y + c * c1y + d * p1y
        ]

    },
    arc: function(t, cx, cy, radius, start, end) {

        var point = (end - start) * t + start;

        var ret = [
            (Math.cos(point) * radius) + cx,
            (Math.sin(point) * radius) + cy
        ];

        ret.angle = point;
        ret.t = t;

        return ret;

    },
    line: function(t, sx, sy, ex, ey) {
      return [
        (ex - sx) * t + sx,
        (ey - sy) * t + sy
      ]
    }
  };

  var stepMethods = Sonic.stepMethods = {
    
    square: function(point, i, f, color, alpha) {
      this._.fillRect(point.x - 3, point.y - 3, 6, 6);
    },

    fader: function(point, i, f, color, alpha) {

      this._.beginPath();

      if (this._last) {
        this._.moveTo(this._last.x, this._last.y);
      }

      this._.lineTo(point.x, point.y);
      this._.closePath();
      this._.stroke();

      this._last = point;

    }

  }

  Sonic.prototype = {

    calculatePixelRatio: function(){

      var devicePixelRatio = window.devicePixelRatio || 1;
      var backingStoreRatio = this._.webkitBackingStorePixelRatio
          || this._.mozBackingStorePixelRatio
          || this._.msBackingStorePixelRatio
          || this._.oBackingStorePixelRatio
          || this._.backingStorePixelRatio
          || 1;

      return devicePixelRatio / backingStoreRatio;
    },

    setup: function() {

      var args,
        type,
        method,
        value,
        data = this.data;

      this.canvas = document.createElement('canvas');
      this._ = this.canvas.getContext('2d');

      if(this.pixelRatio == null){
        this.pixelRatio = this.calculatePixelRatio();
      }

      this.canvas.className = this.domClass;

      if(this.pixelRatio != 1){

        this.canvas.style.height = this.fullHeight + 'px';
        this.canvas.style.width = this.fullWidth + 'px';

        this.fullHeight *= this.pixelRatio;
        this.fullWidth  *= this.pixelRatio;

        this.canvas.height = this.fullHeight;
        this.canvas.width = this.fullWidth;

        this._.scale(this.pixelRatio, this.pixelRatio);

      }   else{

        this.canvas.height = this.fullHeight;
        this.canvas.width = this.fullWidth;

      }

      this.points = [];

      for (var i = -1, l = data.length; ++i < l;) {

        args = data[i].slice(1);
        method = data[i][0];

        if (method in argSignatures) for (var a = -1, al = args.length; ++a < al;) {

          type = argSignatures[method][a];
          value = args[a];

          switch (type) {
            case argTypes.RADIUS:
              value *= this.multiplier;
              break;
            case argTypes.DIM:
              value *= this.multiplier;
              value += this.padding;
              break;
            case argTypes.DEGREE:
              value *= Math.PI/180;
              break;
          };

          args[a] = value;

        }

        args.unshift(0);

        for (var r, pd = this.pointDistance, t = pd; t <= 1; t += pd) {
          
          // Avoid crap like 0.15000000000000002
          t = Math.round(t*1/pd) / (1/pd);

          args[0] = t;

          r = pathMethods[method].apply(null, args);

          this.points.push({
            x: r[0],
            y: r[1],
            progress: t
          });

        }

      }

      this.frame = 0;

      if (this.converter && this.converter.setup) {
        this.converter.setup(this);
      }

    },

    prep: function(frame) {

      if (frame in this.imageData) {
        return;
      }

      this._.clearRect(0, 0, this.fullWidth, this.fullHeight);
      this._.fillStyle = this.backgroundColor;
      this._.fillRect(0, 0, this.fullWidth, this.fullHeight);

      var points = this.points,
        pointsLength = points.length,
        pd = this.pointDistance,
        point,
        index,
        frameD;

      this._setup();

      for (var i = -1, l = pointsLength*this.trailLength; ++i < l && !this.stopped;) {

        index = frame + i;

        point = points[index] || points[index - pointsLength];

        if (!point) continue;

        this.alpha = Math.round(1000*(i/(l-1)))/1000;

        this._.globalAlpha = this.alpha;

        if (this.fillColor) {
          this._.fillStyle = this.fillColor;
        }
        if (this.strokeColor) {
          this._.strokeStyle = this.strokeColor;
        }

        frameD = frame/(this.points.length-1);
        indexD = i/(l-1);

        this._preStep(point, indexD, frameD);
        this.stepMethod(point, indexD, frameD);

      } 

      this._teardown();

      this.imageData[frame] = (
        this._.getImageData(0, 0, this.fullWidth, this.fullWidth)
      );

      return true;

    },

    draw: function() {
      
      if (!this.prep(this.frame)) {

        this._.clearRect(0, 0, this.fullWidth, this.fullWidth);

        this._.putImageData(
          this.imageData[this.frame],
          0, 0
        );

      }

      if (this.converter && this.converter.step) {
        this.converter.step(this);
      }

      if (!this.iterateFrame()) {
        if (this.converter && this.converter.teardown) {
          this.converter.teardown(this);
          this.converter = null;
        }
      }

    },

    iterateFrame: function() {
      
      this.frame += this.stepsPerFrame;
      
      if (this.frame >= this.points.length) {
        this.frame = 0;
        return false;
      }

      return true;

    },

    play: function() {

      this.stopped = false;

      var hoc = this;

      this.timer = setInterval(function(){
        hoc.draw();
      }, 1000 / this.fps);

    },
    stop: function() {

      this.stopped = true;
      this.timer && clearInterval(this.timer);

    }
  };

  window.Sonic = Sonic;

}());