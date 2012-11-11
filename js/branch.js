(function() {
  var BranchGame, Grid, Key, Piece, Selector, Stream,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  BranchGame = (function() {

    function BranchGame(doc, win) {
      var _this = this;
      this.doc = doc;
      this.win = win;
      this.pause = __bind(this.pause, this);
      this.play = __bind(this.play, this);
      this.drawFrame = __bind(this.drawFrame, this);
      this.canvas = this.doc.getElementById("game_canvas");
      this.context = this.canvas.getContext("2d");
      this.buttons = {
        start: this.doc.getElementById("start"),
        pause: this.doc.getElementById("pause")
      };
      this.buttons.start.onclick = this.play;
      this.buttons.pause.onclick = this.pause;
      this.key = new Key;
      this.win.onkeyup = function(e) {
        return _this.key.onKeyUp(e);
      };
      this.win.onkeydown = function(e) {
        return _this.key.onKeyDown(e);
      };
      this.stream = new Stream;
      this.sel = new Selector(7, this.stream.length);
      this.grid = new Grid(this.context, this.canvas, this.stream, this.sel);
      this.frame = 0;
    }

    BranchGame.prototype.resetCanvas = function() {
      return this.canvas.width = this.canvas.width;
    };

    BranchGame.prototype.drawFrame = function() {
      this.frame++;
      this.sel.update(this.key);
      this.resetCanvas();
      if (this.frame % 120 === 0) this.stream.addPiece();
      this.grid.draw(this.canvas);
      if (this.running) return requestAnimationFrame(this.drawFrame);
    };

    BranchGame.prototype.play = function() {
      if (this.running) return;
      this.running = true;
      return requestAnimationFrame(this.drawFrame);
    };

    BranchGame.prototype.pause = function() {
      this.running = !this.running;
      if (this.running) return requestAnimationFrame(this.drawFrame);
    };

    return BranchGame;

  })();

  Key = (function() {

    function Key() {
      this.onKeyUp = __bind(this.onKeyUp, this);
      this.onKeyDown = __bind(this.onKeyDown, this);
      this.isDown = __bind(this.isDown, this);
    }

    Key.prototype.pressed = {};

    Key.prototype.codes = {
      "LEFT": 37,
      "UP": 38,
      "RIGHT": 39,
      "DOWN": 40,
      "SPACE": 32
    };

    Key.prototype.isDown = function(keyCode) {
      return this.pressed[keyCode];
    };

    Key.prototype.onKeyDown = function(event) {
      return this.pressed[event.keyCode] = true;
    };

    Key.prototype.onKeyUp = function(event) {
      return delete this.pressed[event.keyCode];
    };

    return Key;

  })();

  Stream = (function() {

    function Stream() {
      this.addPiece = __bind(this.addPiece, this);
    }

    Stream.prototype.colors = ["red", "blue", "green", "yellow", "orange"];

    Stream.prototype.pieces = [];

    Stream.prototype.length = 105;

    Stream.prototype.addPiece = function() {
      var color;
      color = Math.floor(Math.random() * this.colors.length);
      return this.pieces.push(new Piece(this.colors[color]));
    };

    return Stream;

  })();

  Grid = (function() {
    var size;

    size = 45;

    function Grid(context, canvas, stream, sel) {
      this.context = context;
      this.stream = stream;
      this.sel = sel;
      this.spotsPerLine = Math.floor(canvas.width / size);
      this.height = canvas.height - size * 2;
    }

    Grid.prototype.drawPieces = function() {
      var num, spots, _ref, _results;
      if (this.stream.pieces.length > 0) {
        spots = this.getSpots(this.stream.pieces.length);
        _results = [];
        for (num = 0, _ref = spots.length - 1; 0 <= _ref ? num <= _ref : num >= _ref; 0 <= _ref ? num++ : num--) {
          _results.push(this.stream.pieces[this.stream.pieces.length - num - 1].draw(this.context, spots[num][0], spots[num][1]));
        }
        return _results;
      }
    };

    Grid.prototype.drawSel = function() {
      var coord, coords, _i, _j, _len, _ref, _ref2, _results, _results2;
      coords = this.spotsToCoords((function() {
        _results = [];
        for (var _i = _ref = this.sel.index, _ref2 = this.sel.index + this.sel.length - 1; _ref <= _ref2 ? _i <= _ref2 : _i >= _ref2; _ref <= _ref2 ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this));
      _results2 = [];
      for (_j = 0, _len = coords.length; _j < _len; _j++) {
        coord = coords[_j];
        this.context.beginPath();
        this.context.moveTo(coord[0], coord[1]);
        this.context.lineTo(coord[0] + size, coord[1]);
        this.context.closePath();
        this.context.strokeStyle = "red";
        this.context.lineWidth = 5;
        _results2.push(this.context.stroke());
      }
      return _results2;
    };

    Grid.prototype.draw = function(canvas) {
      var x, y, _ref, _ref2;
      this.context.beginPath();
      for (x = size, _ref = canvas.width - size; size <= _ref ? x <= _ref : x >= _ref; x += size) {
        this.context.moveTo(x, 0);
        this.context.lineTo(x, this.height);
      }
      for (y = size, _ref2 = this.height; size <= _ref2 ? y <= _ref2 : y >= _ref2; y += size) {
        this.context.moveTo(0, y);
        this.context.lineTo(canvas.width, y);
      }
      this.context.closePath();
      this.context.strokeStyle = "black";
      this.context.stroke();
      this.drawPieces();
      return this.drawSel();
    };

    Grid.prototype.getSpots = function(length) {
      var col, remainder, row, rowLength, rows, spots;
      spots = [];
      rows = Math.ceil(length / this.spotsPerLine);
      remainder = length % this.spotsPerLine;
      for (row = 1; 1 <= rows ? row <= rows : row >= rows; 1 <= rows ? row++ : row--) {
        rowLength = row === rows && remainder > 0 ? remainder : this.spotsPerLine;
        for (col = 1; 1 <= rowLength ? col <= rowLength : col >= rowLength; 1 <= rowLength ? col++ : col--) {
          spots.push([col * size - (size / 2), row * size - (size / 2)]);
        }
      }
      return spots;
    };

    Grid.prototype.spotsToCoords = function(spots) {
      var col, row, spot, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = spots.length; _i < _len; _i++) {
        spot = spots[_i];
        row = Math.floor(spot / this.spotsPerLine);
        col = spot >= this.spotsPerLine ? spot % this.spotsPerLine : spot;
        _results.push([col * 45, row * 45]);
      }
      return _results;
    };

    return Grid;

  })();

  Piece = (function() {
    var radius;

    radius = 15;

    function Piece(color) {
      this.color = color;
    }

    Piece.prototype.draw = function(context, x, y) {
      context.beginPath();
      context.arc(x, y, radius, 0, Math.PI * 2);
      context.closePath();
      context.stroke();
      context.fillStyle = this.color;
      return context.fill();
    };

    return Piece;

  })();

  Selector = (function() {

    function Selector(length, end) {
      this.length = length;
      this.end = end;
      this.index = 0;
    }

    Selector.prototype.update = function(key) {
      if (key.pressed[key.codes.RIGHT] && (this.index + this.length) < this.end) {
        this.index = this.index + 1;
      }
      if (key.pressed[key.codes.LEFT] && this.index > 0) {
        return this.index = this.index - 1;
      }
    };

    return Selector;

  })();

  window.BranchGame = BranchGame;

}).call(this);
