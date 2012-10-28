class BranchGame
  constructor: (@doc, @win) ->
    @canvas  = @doc.getElementById("game_canvas")
    @context = @canvas.getContext("2d")
    @buttons =
      start: @doc.getElementById("start")
      pause: @doc.getElementById("pause")

    @buttons.start.onclick = @play
    @buttons.pause.onclick = @pause

    @key = new Key
    @win.onkeyup = (e) =>
      @key.onKeyUp e
    @win.onkeydown = (e) =>
      @key.onKeyDown e

    @radius = 0
    @bigger = true

  drawTestCircle: () ->
    @context.beginPath()
    @context.arc @canvas.width / 2, @canvas.height / 2, @radius, 0, Math.PI * 2, false
    @context.closePath()
    @context.strokeStyle = "#000"
    @context.stroke()
    @context.fillStyle = "orange"
    @context.fill()

    if @bigger then @radius++ else @radius--

    if @radius > 100
      @bigger = false
    else if @radius < 1
      @bigger = true

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawFrame: =>
    @resetCanvas()

    @drawTestCircle()

    requestAnimationFrame @drawFrame if @running

  play: =>
    return if @running

    @running = true

    requestAnimationFrame @drawFrame

  pause: =>
    @running = !@running

    requestAnimationFrame @drawFrame if @running


# Inspired by http://nokarma.org/2011/02/27/javascript-game-development-keyboard-input/index.html
class Key
  pressed: {}

  codes:
    "LEFT": 37
    "UP": 38
    "RIGHT": 39
    "DOWN": 40
    "SPACE": 32

  isDown: (keyCode) =>
    return @pressed[keyCode]

  onKeyDown: (event) =>
    @pressed[event.keyCode] = true

  onKeyUp: (event) =>
    delete @pressed[event.keyCode]

window.BranchGame = BranchGame