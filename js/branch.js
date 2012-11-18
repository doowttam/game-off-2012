(function() {
  var Board, Branch, Grid, Key, Piece, PieceList, Selector, Stream, Workspace,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  window.BranchGame = (function() {
    var lastActivated;

    lastActivated = (new Date()).getTime();

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
      this.sel = new Selector(7, this.stream);
      this.grid = new Grid(this.context, this.canvas, this.stream, this.sel);
      this.wsp = new Workspace(this.context, this.canvas);
      this.grid.activated = true;
      this.frame = 0;
    }

    BranchGame.prototype.update = function() {
      if (this.key.pressed[this.key.codes.SPACE] && (new Date()).getTime() - lastActivated > 200) {
        lastActivated = (new Date()).getTime();
        if (this.wsp.activated) {
          this.wsp.activated = false;
          this.grid.activated = true;
        } else {
          this.wsp.activate();
          this.grid.activated = false;
        }
      }
      if (this.key.pressed[this.key.codes.DOWN] && this.grid.activated) {
        this.wsp.addBranch(this.grid.getSelection());
      }
      if (this.key.pressed[this.key.codes.UP] && this.grid.activated && this.wsp.hasBranch()) {
        return this.grid.putSelection(this.wsp.getBranch());
      }
    };

    BranchGame.prototype.resetCanvas = function() {
      return this.canvas.width = this.canvas.width;
    };

    BranchGame.prototype.drawFrame = function() {
      this.frame++;
      this.update();
      this.sel.update(this.key);
      this.wsp.update(this.key);
      this.resetCanvas();
      if (this.frame % 120 === 0) this.stream.addPiece();
      this.grid.draw(this.canvas);
      this.wsp.draw();
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

  Board = (function() {

    Board.prototype.size = 45;

    Board.prototype.origX = 0;

    Board.prototype.origY = 0;

    Board.prototype.activated = false;

    function Board(canvas) {
      this.spotsPerLine = Math.floor(canvas.width / this.size);
    }

    Board.prototype.getSpots = function(length) {
      var col, remainder, row, rowLength, rows, spots, x, y;
      spots = [];
      rows = Math.ceil(length / this.spotsPerLine);
      remainder = length % this.spotsPerLine;
      for (row = 1; 1 <= rows ? row <= rows : row >= rows; 1 <= rows ? row++ : row--) {
        rowLength = row === rows && remainder > 0 ? remainder : this.spotsPerLine;
        for (col = 1; 1 <= rowLength ? col <= rowLength : col >= rowLength; 1 <= rowLength ? col++ : col--) {
          x = this.origX + (col * this.size - (this.size / 2));
          y = this.origY + (row * this.size - (this.size / 2));
          spots.push([x, y]);
        }
      }
      return spots;
    };

    Board.prototype.drawPieces = function(piecelist) {
      var num, spots, _ref, _results;
      if (piecelist.pieces.length > 0) {
        spots = this.getSpots(piecelist.pieces.length);
        _results = [];
        for (num = 0, _ref = spots.length - 1; 0 <= _ref ? num <= _ref : num >= _ref; 0 <= _ref ? num++ : num--) {
          _results.push(piecelist.pieces[piecelist.pieces.length - num - 1].draw(this.context, spots[num][0], spots[num][1]));
        }
        return _results;
      }
    };

    Board.prototype.drawSel = function() {
      var coord, coords, _i, _j, _len, _ref, _ref2, _results, _results2;
      coords = this.spotsToCoords((function() {
        _results = [];
        for (var _i = _ref = this.sel.index, _ref2 = this.sel.index + this.sel.length - 1; _ref <= _ref2 ? _i <= _ref2 : _i >= _ref2; _ref <= _ref2 ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this));
      _results2 = [];
      for (_j = 0, _len = coords.length; _j < _len; _j++) {
        coord = coords[_j];
        this.context.fillStyle = 'rgba(246,255,0,.5)';
        _results2.push(this.context.fillRect(coord[0], coord[1], this.size, this.size));
      }
      return _results2;
    };

    Board.prototype.spotsToCoords = function(spots) {
      var col, row, spot, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = spots.length; _i < _len; _i++) {
        spot = spots[_i];
        row = Math.floor(spot / this.spotsPerLine);
        col = spot >= this.spotsPerLine ? spot % this.spotsPerLine : spot;
        _results.push([this.origX + (col * 45), this.origY + (row * 45)]);
      }
      return _results;
    };

    return Board;

  })();

  PieceList = (function() {

    PieceList.prototype.colors = ["red", "blue", "green", "yellow", "orange"];

    PieceList.prototype.pieces = [];

    function PieceList(initialPieces) {
      this.pieces = initialPieces != null ? initialPieces : [];
    }

    PieceList.prototype.nextColor = function(color) {
      var index;
      index = this.colors.indexOf(color);
      console.log(color);
      if (index === this.colors.length - 1) {
        return this.colors[0];
      } else {
        return this.colors[index + 1];
      }
    };

    return PieceList;

  })();

  Stream = (function(_super) {

    __extends(Stream, _super);

    function Stream() {
      var i;
      Stream.__super__.constructor.call(this);
      for (i = 1; i <= 7; i++) {
        this.addPiece();
      }
    }

    Stream.prototype.addPiece = function() {
      var color;
      color = Math.floor(Math.random() * this.colors.length);
      return this.pieces.push(new Piece(this.colors[color]));
    };

    return Stream;

  })(PieceList);

  Grid = (function(_super) {

    __extends(Grid, _super);

    function Grid(context, canvas, stream, sel) {
      this.context = context;
      this.sel = sel;
      Grid.__super__.constructor.call(this, canvas);
      this.height = canvas.height - this.size * 2;
      this.piecelist = stream;
    }

    Grid.prototype.draw = function(canvas) {
      var x, y, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      this.context.beginPath();
      for (x = _ref = this.size, _ref2 = canvas.width - this.size, _ref3 = this.size; _ref <= _ref2 ? x <= _ref2 : x >= _ref2; x += _ref3) {
        this.context.moveTo(x, 0);
        this.context.lineTo(x, this.height);
      }
      for (y = _ref4 = this.size, _ref5 = this.height, _ref6 = this.size; _ref4 <= _ref5 ? y <= _ref5 : y >= _ref5; y += _ref6) {
        this.context.moveTo(0, y);
        this.context.lineTo(canvas.width, y);
      }
      this.context.closePath();
      this.context.strokeStyle = "black";
      this.context.stroke();
      if (this.activated) this.drawSel();
      return this.drawPieces(this.piecelist);
    };

    Grid.prototype.getSelection = function() {
      var endIndex, piece, pieces, startIndex;
      startIndex = (this.sel.index + this.sel.length) * -1;
      endIndex = this.sel.index * -1;
      pieces = [];
      if (this.sel.index > 0) {
        pieces = this.piecelist.pieces.slice(startIndex, endIndex);
      } else {
        pieces = this.piecelist.pieces.slice(startIndex);
      }
      return new Branch((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = pieces.length; _i < _len; _i++) {
          piece = pieces[_i];
          _results.push(new Piece(piece.color));
        }
        return _results;
      })());
    };

    Grid.prototype.putSelection = function(branch) {
      var endIndex;
      endIndex = (this.sel.index + this.sel.length) * -1;
      return this.piecelist.pieces.splice.apply(this.piecelist.pieces, [endIndex, branch.pieces.length].concat(branch.pieces));
    };

    return Grid;

  })(Board);

  Workspace = (function(_super) {

    __extends(Workspace, _super);

    Workspace.prototype.origX = 0;

    Workspace.prototype.origY = 337.5;

    Workspace.prototype.piecelist = null;

    function Workspace(context, canvas, sel) {
      this.context = context;
      this.sel = sel;
      Workspace.__super__.constructor.call(this, canvas);
    }

    Workspace.prototype.activate = function() {
      this.activated = true;
      if (this.hasBranch()) return this.sel = new Selector(1, this.piecelist);
    };

    Workspace.prototype.cycleDown = function() {
      var currentColor, index, newPiece;
      index = this.piecelist.pieces.length - this.sel.index - 1;
      currentColor = this.piecelist.pieces[index].color;
      newPiece = new Piece(this.piecelist.nextColor(currentColor));
      return this.piecelist.pieces.splice(index, 1, newPiece);
    };

    Workspace.prototype.update = function(key) {
      if (this.hasBranch() && (this.sel != null) && this.activated) {
        this.sel.update(key);
        if (key.pressed[key.codes.DOWN]) this.cycleDown();
        if (key.pressed[key.codes.UP]) return console.log('up');
      }
    };

    Workspace.prototype.hasBranch = function() {
      return this.piecelist != null;
    };

    Workspace.prototype.addBranch = function(branch) {
      return this.piecelist = branch;
    };

    Workspace.prototype.getBranch = function() {
      var branchCopy;
      branchCopy = this.piecelist;
      this.piecelist = null;
      this.sel = null;
      return branchCopy;
    };

    Workspace.prototype.draw = function() {
      if (this.piecelist) this.drawPieces(this.piecelist);
      if (this.activated) {
        this.context.beginPath();
        this.context.moveTo(0, 315);
        this.context.lineTo(675, 315);
        this.context.lineTo(745, 405);
        this.context.lineTo(0, 405);
        this.context.lineTo(0, 315);
        this.context.closePath();
        this.context.strokeStyle = "red";
        this.context.lineWidth = 5;
        this.context.stroke();
        if (this.sel != null) return this.drawSel();
      }
    };

    return Workspace;

  })(Board);

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
      context.strokeStyle = "black";
      context.lineWidth = 1;
      context.stroke();
      context.fillStyle = this.color;
      return context.fill();
    };

    return Piece;

  })();

  Selector = (function() {

    Selector.prototype.selection = null;

    function Selector(length, stream, parent) {
      this.length = length;
      this.stream = stream;
      this.parent = parent;
      this.index = 0;
    }

    Selector.prototype.update = function(key) {
      if (key.pressed[key.codes.RIGHT] && (this.index + this.length) < this.stream.pieces.length) {
        this.index = this.index + 1;
      }
      if (key.pressed[key.codes.LEFT] && this.index > 0) {
        return this.index = this.index - 1;
      }
    };

    return Selector;

  })();

  Branch = (function(_super) {

    __extends(Branch, _super);

    function Branch() {
      Branch.__super__.constructor.apply(this, arguments);
    }

    return Branch;

  })(PieceList);

}).call(this);
