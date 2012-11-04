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

    @grid = new Grid @canvas

    @pieces = []

    @frame = 0

    @colors = ["red", "blue", "green", "yellow", "orange"]

    @sel = new Selector 315

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawFrame: =>
    @frame++

    @sel.update @key

    @resetCanvas()

    if @frame % 120 == 0
      color = Math.floor(Math.random() * @colors.length)
      @pieces.push new Piece @colors[color]

    if @pieces.length > 0
      spots = @grid.getSpots(@pieces.length)

      for num in [0..spots.length - 1]
        @pieces[@pieces.length - num - 1].draw @context, spots[num][0], spots[num][1]

    @grid.draw @context, @canvas
    @sel.draw @context

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

class Grid
  size = 45

  constructor: (canvas) ->
    @spotsPerLine = Math.floor(canvas.width / size)
    @height       = canvas.height - size * 2

  draw: (context, canvas) ->
    context.beginPath()

    for x in [size..(canvas.width - size)] by size
      context.moveTo x, 0
      context.lineTo x, @height

    for y in [size..@height] by size
      context.moveTo 0, y
      context.lineTo canvas.width, y

    context.closePath()
    context.strokeStyle = "black"
    context.stroke()

  getSpots: (length) ->
    spots     = []
    rows      = Math.ceil length / @spotsPerLine
    remainder = length % @spotsPerLine

    for row in [1..rows]
      rowLength = if row == rows && remainder > 0 then remainder else @spotsPerLine
      for col in [1..rowLength]
        spots.push [ col * size - (size/2),  row * size - (size/2) ]

    spots

class Piece
  radius = 15

  constructor: (@color) ->

  draw: (context, x, y) ->
    context.beginPath()
    context.arc x, y, radius, 0, Math.PI * 2
    context.closePath()
    context.stroke()
    context.fillStyle = @color
    context.fill()

class Selector
  constructor: (@length) ->
    @x = 0
    @y = 0

  update: (key) ->
    if key.pressed[key.codes.RIGHT]
      @x = @x + 45

    if key.pressed[key.codes.LEFT]
      @x = @x - 45

  draw: (context) ->
    context.beginPath()

    context.moveTo @x, @y + 22.5
    context.lineTo @x, @y + 45
    context.lineTo @x + @length, @y + 45
    context.lineTo @x + @length, @y + 22.5
    context.moveTo @x, @y + 22.5

    context.closePath()
    context.strokeStyle = "red"
    context.lineWidth = 5
    context.stroke()

window.BranchGame = BranchGame
