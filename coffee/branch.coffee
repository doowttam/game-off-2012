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

    @stream = new Stream
    @sel    = new Selector 7, @stream.length
    @grid   = new Grid @context, @canvas, @stream, @sel

    @frame = 0

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawFrame: =>
    @frame++

    @sel.update @key

    @resetCanvas()

    if @frame % 120 == 0
      @stream.addPiece()

    @grid.draw @canvas

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

class Stream
  colors: ["red", "blue", "green", "yellow", "orange"]
  pieces: []
  length: 105 # FIXME: This needs to be calculated, not hard coded

  addPiece: () =>
    color = Math.floor(Math.random() * @colors.length)
    @pieces.push(new Piece @colors[color])

class Grid
  size = 45

  constructor: (@context, canvas, @stream, @sel) ->
    @spotsPerLine = Math.floor(canvas.width / size)
    @height       = canvas.height - size * 2

  drawPieces: () ->
    if @stream.pieces.length > 0
      spots = @getSpots(@stream.pieces.length)

      for num in [0..spots.length - 1]
        @stream.pieces[@stream.pieces.length - num - 1].draw @context, spots[num][0], spots[num][1]

  drawSel: () ->
    coords = @spotsToCoords [@sel.index..@sel.index + @sel.length - 1]

    for coord in coords
      @context.beginPath()

      @context.moveTo coord[0], coord[1]
      @context.lineTo coord[0] + size, coord[1]

      @context.closePath()

      @context.strokeStyle = "red"
      @context.lineWidth = 5
      @context.stroke()

  draw: (canvas) ->
    @context.beginPath()

    for x in [size..(canvas.width - size)] by size
      @context.moveTo x, 0
      @context.lineTo x, @height

    for y in [size..@height] by size
      @context.moveTo 0, y
      @context.lineTo canvas.width, y

    @context.closePath()
    @context.strokeStyle = "black"
    @context.stroke()

    @drawPieces()
    @drawSel()

  getSpots: (length) ->
    spots     = []
    rows      = Math.ceil length / @spotsPerLine
    remainder = length % @spotsPerLine

    for row in [1..rows]
      rowLength = if row == rows && remainder > 0 then remainder else @spotsPerLine
      for col in [1..rowLength]
        spots.push [ col * size - (size/2),  row * size - (size/2) ]

    spots

  spotsToCoords: (spots) ->
    for spot in spots
      row = Math.floor spot / @spotsPerLine
      col = if spot >= @spotsPerLine then spot % @spotsPerLine else spot
      [col * 45, row * 45]

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
  constructor: (@length, @end) ->
    @index = 0

  update: (key) ->
    if key.pressed[key.codes.RIGHT] and (@index + @length) < @end
      @index = @index + 1

    if key.pressed[key.codes.LEFT] and @index > 0
      @index = @index - 1


window.BranchGame = BranchGame
