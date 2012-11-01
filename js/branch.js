(function() {
  var BranchGame, Grid, Key, Piece,
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
      this.grid = new Grid(this.canvas);
      this.pieces = [];
      this.frame = 0;
      this.colors = ["red", "blue", "green", "yellow", "orange"];
    }

    BranchGame.prototype.resetCanvas = function() {
      return this.canvas.width = this.canvas.width;
    };

    BranchGame.prototype.drawFrame = function() {
      var color, num, spots, _ref;
      this.frame++;
      this.resetCanvas();
      if (this.frame % 120 === 0) {
        color = Math.floor(Math.random() * this.colors.length);
        this.pieces.push(new Piece(this.colors[color]));
      }
      if (this.pieces.length > 0) {
        spots = this.grid.getSpots(this.pieces.length);
        for (num = 0, _ref = spots.length - 1; 0 <= _ref ? num <= _ref : num >= _ref; 0 <= _ref ? num++ : num--) {
          this.pieces[this.pieces.length - num - 1].draw(this.context, spots[num][0], spots[num][1]);
        }
      }
      this.grid.draw(this.context, this.canvas);
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

  Grid = (function() {
    var size;

    size = 45;

    function Grid(canvas) {
      this.spotsPerLine = Math.floor(canvas.width / size);
    }

    Grid.prototype.draw = function(context, canvas) {
      var x, y, _ref, _ref2;
      context.beginPath();
      for (x = size, _ref = canvas.width - size; size <= _ref ? x <= _ref : x >= _ref; x += size) {
        context.moveTo(x, 0);
        context.lineTo(x, canvas.height);
      }
      for (y = size, _ref2 = canvas.height - size; size <= _ref2 ? y <= _ref2 : y >= _ref2; y += size) {
        context.moveTo(0, y);
        context.lineTo(canvas.width, y);
      }
      context.closePath();
      context.strokeStyle = "black";
      return context.stroke();
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

  window.BranchGame = BranchGame;

}).call(this);
