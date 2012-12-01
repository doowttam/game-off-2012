(function() {
  var Board, EmptyPiece, Grid, Key, MeteredMover, Piece, PieceList, Selector, Stream, Workspace,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  MeteredMover = (function() {

    MeteredMover.prototype.maxFreqMS = 150;

    function MeteredMover() {
      this.lastActed = {};
    }

    MeteredMover.prototype.isPressed = function(keyCode, actionKey, key, id) {
      var actionAllowed;
      actionAllowed = !(this.lastActed[actionKey] != null) || (new Date()).getTime() - this.lastActed[actionKey] > this.maxFreqMS;
      if (key.pressed[keyCode] && actionAllowed) {
        this.lastActed[actionKey] = (new Date()).getTime();
        return true;
      } else {
        return false;
      }
    };

    return MeteredMover;

  })();

  window.BranchGame = (function(_super) {

    __extends(BranchGame, _super);

    BranchGame.prototype.points = 0;

    BranchGame.prototype.position = 0;

    BranchGame.prototype.frame = 0;

    function BranchGame(doc, win) {
      var _this = this;
      this.doc = doc;
      this.win = win;
      this.pause = __bind(this.pause, this);
      this.play = __bind(this.play, this);
      this.drawFrame = __bind(this.drawFrame, this);
      BranchGame.__super__.constructor.call(this);
      this.canvas = this.doc.getElementById('game_canvas');
      this.context = this.canvas.getContext('2d');
      this.buttons = {
        start: this.doc.getElementById('start'),
        pause: this.doc.getElementById('pause')
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
      this.drawOpener();
    }

    BranchGame.prototype.drawOpener = function() {
      this.context.drawImage(this.doc.getElementById('opener-img'), 6, 54);
      this.context.fillStyle = 'black';
      this.context.font = 'bold 48px sans-serif';
      this.context.textAlign = 'center';
      return this.context.fillText('QA Simulator 2012', this.canvas.width / 2, 50);
    };

    BranchGame.prototype.update = function() {
      if (this.isPressed(this.key.codes.SPACE, 'activateWSP', this.key)) {
        if (this.wsp.activated) {
          this.wsp.activated = false;
          this.grid.activated = true;
        } else {
          this.wsp.activate();
          this.grid.activated = false;
        }
      }
      if (this.isPressed(this.key.codes.DOWN, 'getGridSelection', this.key) && this.grid.activated) {
        this.wsp.addBranch(this.grid.getSelection());
      }
      if (this.isPressed(this.key.codes.UP, 'putWSPSelection', this.key) && this.grid.activated && this.wsp.hasBranch()) {
        return this.grid.putSelection(this.wsp.getBranch());
      }
    };

    BranchGame.prototype.adjustScore = function(removedPiece) {
      if (!(removedPiece.color != null)) this.gameOver();
      if (!removedPiece.committed) return;
      if (removedPiece.bugged) {
        return this.points = this.points - 1;
      } else if (removedPiece.origBug) {
        return this.points++;
      }
    };

    BranchGame.prototype.gameOver = function() {
      var message;
      this.running = false;
      this.context.fillStyle = 'rgba(0,0,0,.7)';
      this.context.fillRect(0, 0, this.canvas.width, this.canvas.height);
      this.context.fillStyle = 'white';
      this.context.font = 'bold 48px sans-serif';
      this.context.textAlign = 'center';
      this.context.fillText('Day complete!', this.canvas.width / 2, 125);
      this.context.fillStyle = 'white';
      this.context.font = 'bold 36px sans-serif';
      this.context.textAlign = 'center';
      this.context.fillText("Score: " + this.points, this.canvas.width / 2, 200);
      message = 'Try harder!';
      if (this.points >= 30) {
        message = 'Perfect score!';
      } else if (this.points >= 20) {
        message = 'Pretty good!';
      } else if (this.points >= 10) {
        message = 'Not bad!';
      }
      this.context.fillStyle = 'white';
      this.context.font = 'bold 32px sans-serif';
      this.context.textAlign = 'center';
      this.context.fillText(message, this.canvas.width / 2, 300);
      this.context.fillStyle = 'white';
      this.context.font = 'bold 24px sans-serif';
      this.context.textAlign = 'center';
      return this.context.fillText('(Refresh to restart)', this.canvas.width / 2, 350);
    };

    BranchGame.prototype.resetCanvas = function() {
      return this.canvas.width = this.canvas.width;
    };

    BranchGame.prototype.drawScore = function() {
      this.context.fillStyle = 'black';
      this.context.font = 'bold 30px sans-serif';
      this.context.textAlign = 'right';
      return this.context.fillText(this.points, 650, 370);
    };

    BranchGame.prototype.drawFrame = function() {
      var removedPiece;
      this.frame++;
      this.update();
      this.sel.update(this.key);
      this.wsp.update(this.key);
      this.resetCanvas();
      this.grid.draw(this.canvas);
      this.wsp.draw();
      this.drawScore();
      if (this.frame % 120 === 0) {
        removedPiece = this.stream.addNewPiece();
        if (removedPiece != null) this.adjustScore(removedPiece);
      }
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

  })(MeteredMover);

  Key = (function() {

    function Key() {
      this.onKeyUp = __bind(this.onKeyUp, this);
      this.onKeyDown = __bind(this.onKeyDown, this);
      this.isDown = __bind(this.isDown, this);
    }

    Key.prototype.pressed = {};

    Key.prototype.codes = {
      'LEFT': 37,
      'UP': 38,
      'RIGHT': 39,
      'DOWN': 40,
      'SPACE': 32
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

  Board = (function(_super) {

    __extends(Board, _super);

    Board.prototype.size = 45;

    Board.prototype.origX = 0;

    Board.prototype.origY = 0;

    Board.prototype.activated = false;

    function Board(canvas) {
      Board.__super__.constructor.call(this);
      this.spotsPerLine = Math.floor((canvas.width - this.size * 2) / this.size);
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
        this.context.fillStyle = '#96cc00';
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

  })(MeteredMover);

  PieceList = (function() {

    PieceList.prototype.colors = ["red", "blue", "green", "yellow", "orange"];

    PieceList.prototype.pieces = null;

    function PieceList(initialPieces) {
      this.pieces = initialPieces != null ? initialPieces : [];
    }

    PieceList.prototype.cycleColor = function(color, direction) {
      var index, newIndex;
      index = this.colors.indexOf(color);
      newIndex = (index + direction + this.colors.length) % this.colors.length;
      return this.colors[newIndex];
    };

    return PieceList;

  })();

  Stream = (function(_super) {

    __extends(Stream, _super);

    Stream.prototype.starterBugsPossible = 20;

    Stream.prototype.maxLength = 48;

    Stream.prototype.totalBugs = 30;

    Stream.prototype.position = 0;

    function Stream() {
      var i, _ref, _ref2;
      Stream.__super__.constructor.call(this);
      this.pattern = this.randomizePattern();
      for (i = 1, _ref = this.maxLength - this.starterBugsPossible; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        this.addPiece(true);
      }
      for (i = 1, _ref2 = this.starterBugsPossible; 1 <= _ref2 ? i <= _ref2 : i >= _ref2; 1 <= _ref2 ? i++ : i--) {
        this.addPiece(false);
      }
    }

    Stream.prototype.addPiece = function(starter) {
      var bugged, color;
      color = this.pattern[this.position % this.pattern.length];
      bugged = Math.random() < 0.3 && !starter;
      this.pieces.push(new Piece(color, bugged, bugged));
      if (bugged) this.totalBugs--;
      return this.position++;
    };

    Stream.prototype.addEmptyPiece = function() {
      this.pieces.push(new EmptyPiece);
      return this.position++;
    };

    Stream.prototype.addNewPiece = function() {
      if (this.totalBugs > 0) {
        this.addPiece();
      } else {
        this.addEmptyPiece();
      }
      return this.checkOverFlow();
    };

    Stream.prototype.checkOverFlow = function() {
      if (this.pieces.length > this.maxLength) {
        return this.pieces.shift();
      } else {
        return null;
      }
    };

    Stream.prototype.randomizePattern = function() {
      var i, _results;
      _results = [];
      for (i = 1; i <= 3; i++) {
        _results.push(this.colors[Math.floor(Math.random() * this.colors.length)]);
      }
      return _results;
    };

    return Stream;

  })(PieceList);

  Grid = (function(_super) {

    __extends(Grid, _super);

    Grid.prototype.origY = 90;

    Grid.prototype.origX = 45;

    Grid.prototype.height = 135;

    function Grid(context, canvas, piecelist, sel) {
      this.context = context;
      this.piecelist = piecelist;
      this.sel = sel;
      Grid.__super__.constructor.call(this, canvas);
    }

    Grid.prototype.draw = function(canvas) {
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
      return new PieceList((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = pieces.length; _i < _len; _i++) {
          piece = pieces[_i];
          _results.push(new Piece(piece.color, piece.bugged, piece.origBug));
        }
        return _results;
      })());
    };

    Grid.prototype.putSelection = function(branch) {
      var branchPiece, endIndex, i, streamPiece, _len, _ref, _results;
      endIndex = (this.sel.index + this.sel.length) * -1;
      _ref = this.piecelist.pieces.slice(endIndex, (endIndex + branch.pieces.length - 1) + 1 || 9e9);
      _results = [];
      for (i = 0, _len = _ref.length; i < _len; i++) {
        streamPiece = _ref[i];
        streamPiece.committed = true;
        branchPiece = branch.pieces[i];
        if (branchPiece.bugged || branchPiece.color !== streamPiece.color) {
          _results.push(streamPiece.bugged = true);
        } else {
          if (streamPiece.bugged) streamPiece.bugFixed = true;
          _results.push(streamPiece.bugged = false);
        }
      }
      return _results;
    };

    return Grid;

  })(Board);

  Workspace = (function(_super) {

    __extends(Workspace, _super);

    Workspace.prototype.origX = 180;

    Workspace.prototype.origY = 325;

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

    Workspace.prototype.cycle = function(direction) {
      var currentColor, index, newPiece;
      index = this.piecelist.pieces.length - this.sel.index - 1;
      currentColor = this.piecelist.pieces[index].color;
      newPiece = new Piece(this.piecelist.cycleColor(currentColor, direction), false);
      return this.piecelist.pieces.splice(index, 1, newPiece);
    };

    Workspace.prototype.update = function(key) {
      if (this.hasBranch() && (this.sel != null) && this.activated) {
        this.sel.update(key);
        if (this.isPressed(key.codes.DOWN, "cycleDown", key)) this.cycle(-1);
        if (this.isPressed(key.codes.UP, "cycleUp", key)) return this.cycle(1);
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
      if ((this.sel != null) && this.activated) this.drawSel();
      this.context.beginPath();
      this.context.moveTo(this.origX, this.origY);
      this.context.lineTo(this.origX + 315, this.origY);
      this.context.lineTo(this.origX + 315, this.origY + 45);
      this.context.lineTo(this.origX, this.origY + 45);
      this.context.lineTo(this.origX, this.origY);
      this.context.closePath();
      this.context.strokeStyle = this.activated ? 'black' : 'gray';
      this.context.lineWidth = 5;
      this.context.stroke();
      if (this.piecelist) return this.drawPieces(this.piecelist);
    };

    return Workspace;

  })(Board);

  Piece = (function() {
    var radius;

    radius = 15;

    Piece.prototype.committed = false;

    Piece.prototype.bugFixed = false;

    function Piece(color, bugged, origBug) {
      this.color = color;
      this.bugged = bugged;
      this.origBug = origBug != null ? origBug : false;
    }

    Piece.prototype.draw = function(context, x, y) {
      var bgColor;
      if (!(this.color != null)) return;
      context.beginPath();
      context.arc(x, y, radius, 0, Math.PI * 2);
      context.closePath();
      if ((this.committed && this.bugged) || (this.bugFixed && this.origBug)) {
        bgColor = this.bugged ? 'red' : 'green';
        context.fillStyle = bgColor;
        context.fillRect(x - 17.5, y - 17.5, 35, 35);
      }
      context.strokeStyle = 'black';
      context.lineWidth = 1;
      context.stroke();
      context.fillStyle = this.bugged ? 'black' : this.color;
      return context.fill();
    };

    return Piece;

  })();

  EmptyPiece = (function(_super) {

    __extends(EmptyPiece, _super);

    function EmptyPiece() {
      EmptyPiece.__super__.constructor.apply(this, arguments);
    }

    EmptyPiece.prototype.committed = false;

    EmptyPiece.prototype.bugged = false;

    EmptyPiece.prototype.origBug = false;

    EmptyPiece.prototype.color = null;

    return EmptyPiece;

  })(Piece);

  Selector = (function(_super) {

    __extends(Selector, _super);

    Selector.prototype.selection = null;

    Selector.prototype.index = 0;

    function Selector(length, stream) {
      this.length = length;
      this.stream = stream;
      Selector.__super__.constructor.call(this);
    }

    Selector.prototype.update = function(key) {
      if (this.isPressed(key.codes.RIGHT, "moveSelRight", key) && (this.index + this.length) < this.stream.pieces.length) {
        this.index = this.index + 1;
      }
      if (this.isPressed(key.codes.LEFT, "moveSelLeft", key) && this.index > 0) {
        return this.index = this.index - 1;
      }
    };

    return Selector;

  })(MeteredMover);

}).call(this);
