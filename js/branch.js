(function() {
  var BranchGame, Key,
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
      this.radius = 0;
      this.bigger = true;
    }

    BranchGame.prototype.drawTestCircle = function() {
      this.context.beginPath();
      this.context.arc(this.canvas.width / 2, this.canvas.height / 2, this.radius, 0, Math.PI * 2, false);
      this.context.closePath();
      this.context.strokeStyle = "#000";
      this.context.stroke();
      this.context.fillStyle = "orange";
      this.context.fill();
      if (this.bigger) {
        this.radius++;
      } else {
        this.radius--;
      }
      if (this.radius > 100) {
        return this.bigger = false;
      } else if (this.radius < 1) {
        return this.bigger = true;
      }
    };

    BranchGame.prototype.resetCanvas = function() {
      return this.canvas.width = this.canvas.width;
    };

    BranchGame.prototype.drawFrame = function() {
      this.resetCanvas();
      this.drawTestCircle();
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

  window.BranchGame = BranchGame;

}).call(this);
