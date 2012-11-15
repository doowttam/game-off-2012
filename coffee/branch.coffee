class BranchGame
  lastActivated = (new Date()).getTime()

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
    @sel    = new Selector 7, @stream
    @grid   = new Grid @context, @canvas, @stream, @sel
    @wsp    = new Workspace @context

    @frame = 0

  update: ->
    if @key.pressed[@key.codes.SPACE] and (new Date()).getTime() - lastActivated > 200
      lastActivated  = (new Date()).getTime()
      @wsp.activated = !@wsp.activated

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawFrame: =>
    @frame++

    @update()
    @grid.update @key
    @sel.update @key

    @resetCanvas()

    if @frame % 120 == 0
      @stream.addPiece()

    @grid.draw @canvas
    @wsp.draw()

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

  constructor: ->
    @addPiece() for i in [1..7]

  addPiece: ->
    color = Math.floor(Math.random() * @colors.length)
    @pieces.push(new Piece @colors[color])

class Grid
  size = 45

  constructor: (@context, canvas, @stream, @sel) ->
    @spotsPerLine = Math.floor(canvas.width / size)
    @height       = canvas.height - size * 2

  update: (key) ->
    if key.pressed[key.codes.DOWN]
      @sel.getSelection()

    if key.pressed[key.codes.UP] and @sel.hasSelection()
      @sel.putSelection()

  drawPieces: () ->
    if @stream.pieces.length > 0
      spots = @getSpots(@stream.pieces.length)

      for num in [0..spots.length - 1]
        @stream.pieces[@stream.pieces.length - num - 1].draw @context, spots[num][0], spots[num][1]

  drawSel: () ->
    coords = @spotsToCoords [@sel.index..@sel.index + @sel.length - 1]

    for coord in coords
      @context.fillStyle = 'rgba(246,255,0,.5)'
      @context.fillRect coord[0], coord[1], size, size

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

    @drawSel()
    @drawPieces()

    if @sel.hasSelection()
      @sel.selection.draw(@context)

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

class Workspace
  lastActivated = 0
  size          = 0

  constructor: (@context) ->
    @activated = false

  draw: () ->
    if @activated
      @context.beginPath()

      @context.moveTo 0, 315
      @context.lineTo 675, 315
      @context.lineTo 745, 405
      @context.lineTo 0, 405
      @context.lineTo 0, 315

      @context.closePath()
      @context.strokeStyle = "red"
      @context.lineWidth = 5
      @context.stroke()

class Piece
  radius = 15

  constructor: (@color) ->

  draw: (context, x, y) ->
    context.beginPath()
    context.arc x, y, radius, 0, Math.PI * 2
    context.closePath()

    context.strokeStyle = "black"
    context.lineWidth = 1

    context.stroke()
    context.fillStyle = @color
    context.fill()

class Selector
  selection: null

  constructor: (@length, @stream) ->
    @index = 0

  hasSelection: -> @selection != null

  getSelection: ->
    # Our selection is indexed from the point where the stream grows,
    # so it's indexed in the oppisite way from the stream
    startIndex = (@index + @length) * -1
    endIndex   = @index * -1

    pieces = []
    if @index > 0
      pieces = @stream.pieces.slice startIndex, endIndex
    else
      pieces = @stream.pieces.slice startIndex

    @selection = new Branch (new Piece piece.color for piece in pieces.reverse())

  putSelection: ->
    endIndex = (@index + @length) * -1
    @stream.pieces.splice.apply @stream.pieces, [endIndex, @selection.pieces.length].concat(@selection.pieces.reverse())
    @selection = null

  update: (key) ->
    if key.pressed[key.codes.RIGHT] and (@index + @length) < @stream.pieces.length
      @index = @index + 1

    if key.pressed[key.codes.LEFT] and @index > 0
      @index = @index - 1

class Branch
    constructor: (@pieces) ->

    draw: (context) ->
      x = 22.5
      y = 360
      for piece in @pieces
        piece.draw context, x, y
        x = x + 45

window.BranchGame = BranchGame
