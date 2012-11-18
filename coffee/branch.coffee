class window.BranchGame
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
    @wsp    = new Workspace @context, @canvas

    @grid.activated = true

    @frame = 0

  update: ->
    if @key.pressed[@key.codes.SPACE] and (new Date()).getTime() - lastActivated > 200
      lastActivated  = (new Date()).getTime()

      if @wsp.activated
        @wsp.activated  = false
        @grid.activated = true
      else
        @wsp.activate()
        @grid.activated = false

    if @key.pressed[@key.codes.DOWN] and @grid.activated
      @wsp.addBranch @grid.getSelection()

    if @key.pressed[@key.codes.UP] and @grid.activated and @wsp.hasBranch()
      @grid.putSelection @wsp.getBranch()

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawFrame: =>
    @frame++

    @update()
    @sel.update @key
    @wsp.update @key

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

class Board
  size: 45
  origX: 0
  origY: 0
  activated: false

  constructor: (canvas) ->
    @spotsPerLine = Math.floor(canvas.width / @size)

  getSpots: (length) ->
    spots     = []
    rows      = Math.ceil length / @spotsPerLine
    remainder = length % @spotsPerLine

    for row in [1..rows]
      rowLength = if row == rows && remainder > 0 then remainder else @spotsPerLine
      for col in [1..rowLength]
        x = @origX + (col * @size - (@size/2))
        y = @origY + (row * @size - (@size/2))
        spots.push [ x, y ]
    spots

  drawPieces: (piecelist) ->
    # Note: draws pieces in reverse
    if piecelist.pieces.length > 0
      spots = @getSpots(piecelist.pieces.length)

      for num in [0..spots.length - 1]
        piecelist.pieces[piecelist.pieces.length - num - 1].draw @context, spots[num][0], spots[num][1]

  drawSel: () ->
    coords = @spotsToCoords [@sel.index..@sel.index + @sel.length - 1]

    for coord in coords
      @context.fillStyle = 'rgba(246,255,0,.5)'
      @context.fillRect coord[0], coord[1], @size, @size

  spotsToCoords: (spots) ->
    for spot in spots
      row = Math.floor spot / @spotsPerLine
      col = if spot >= @spotsPerLine then spot % @spotsPerLine else spot
      [@origX + (col * 45), @origY + (row * 45)]

class PieceList
  colors: ["red", "blue", "green", "yellow", "orange"]
  pieces: []

  constructor: (initialPieces)->
    @pieces = initialPieces ? []

  nextColor: (color) ->
    index = @colors.indexOf color
    console.log color

    if index == @colors.length - 1
      @colors[0]
    else
      @colors[index + 1]

class Stream extends PieceList
  constructor: ->
    super()
    @addPiece() for i in [1..7]

  addPiece: ->
    color = Math.floor(Math.random() * @colors.length)
    @pieces.push(new Piece @colors[color])

class Grid extends Board
  constructor: (@context, canvas, stream, @sel) ->
    super canvas
    @height    = canvas.height - @size * 2
    @piecelist = stream

  draw: (canvas) ->
    @context.beginPath()

    for x in [@size..(canvas.width - @size)] by @size
      @context.moveTo x, 0
      @context.lineTo x, @height

    for y in [@size..@height] by @size
      @context.moveTo 0, y
      @context.lineTo canvas.width, y

    @context.closePath()
    @context.strokeStyle = "black"
    @context.stroke()

    @drawSel() if @activated
    @drawPieces @piecelist

  getSelection: ->
    # Our selection is indexed from the point where the stream grows,
    # so it's indexed in the oppisite way from the stream
    startIndex = (@sel.index + @sel.length) * -1
    endIndex   = @sel.index * -1

    pieces = []
    if @sel.index > 0
      pieces = @piecelist.pieces.slice startIndex, endIndex
    else
      pieces = @piecelist.pieces.slice startIndex

    new Branch(new Piece piece.color for piece in pieces)

  putSelection: (branch) ->
    endIndex = (@sel.index + @sel.length) * -1
    @piecelist.pieces.splice.apply @piecelist.pieces, [endIndex, branch.pieces.length].concat(branch.pieces)

class Workspace extends Board
  origX: 0
  origY: 337.5
  piecelist: null

  constructor: (@context, canvas, @sel) ->
    super canvas

  activate: ->
    @activated = true
    @sel = new Selector 1, @piecelist if @hasBranch()

  cycleDown: ->
    index        = @piecelist.pieces.length - @sel.index - 1
    currentColor = @piecelist.pieces[index].color
    newPiece     = new Piece @piecelist.nextColor currentColor
    @piecelist.pieces.splice index, 1, newPiece

  update: (key) ->
    if @hasBranch() and @sel? and @activated
      @sel.update key

      if key.pressed[key.codes.DOWN]
        @cycleDown()

      if key.pressed[key.codes.UP]
        console.log 'up'

  hasBranch: -> @piecelist?

  addBranch: (branch) ->
    @piecelist = branch

  getBranch: ->
    branchCopy = @piecelist
    @piecelist = null
    @sel       = null
    branchCopy

  draw: () ->
    if @piecelist then @drawPieces @piecelist

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

      @drawSel() if @sel?

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

  constructor: (@length, @stream, @parent) ->
    @index = 0

  update: (key) ->
    if key.pressed[key.codes.RIGHT] and (@index + @length) < @stream.pieces.length
      @index = @index + 1

    if key.pressed[key.codes.LEFT] and @index > 0
      @index = @index - 1

class Branch extends PieceList
