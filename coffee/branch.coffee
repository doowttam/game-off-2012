class MeteredMover
  maxFreqMS: 200

  constructor: -> @lastActed = {}

  isPressed: (keyCode, actionKey, key, id) ->
    actionAllowed = !@lastActed[actionKey]? or (new Date()).getTime() - @lastActed[actionKey] > @maxFreqMS

    if key.pressed[keyCode] and actionAllowed
      @lastActed[actionKey] = (new Date()).getTime()
      true
    else
      false

class window.BranchGame extends MeteredMover
  constructor: (@doc, @win) ->
    super()

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

    @points   = 0
    @position = 0

    @stream = new Stream
    @sel    = new Selector 7, @stream
    @grid   = new Grid @context, @canvas, @stream, @sel
    @wsp    = new Workspace @context, @canvas

    @grid.activated = true

    @frame = 0

  update: ->
    if @isPressed @key.codes.SPACE, "activateWSP", @key
      if @wsp.activated
        @wsp.activated  = false
        @grid.activated = true
      else
        @wsp.activate()
        @grid.activated = false

    if @isPressed(@key.codes.DOWN, "getGridSelection", @key) and @grid.activated
      @wsp.addBranch @grid.getSelection()

    if @isPressed(@key.codes.UP, "putWSPSelection", @key) and @grid.activated and @wsp.hasBranch()
      @grid.putSelection @wsp.getBranch()

  adjustScore: (removedPiece) ->
    if removedPiece.bugged
      @points = @points - 2;
    else
      @points++

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawScore: ->
    @context.fillStyle = 'black'
    @context.font = 'bold 30px sans-serif'
    @context.textAlign = 'right'
    @context.fillText @points , 650, 370

  drawFrame: =>
    @frame++

    @update()
    @sel.update @key
    @wsp.update @key

    @resetCanvas()

    if @frame % 120 == 0
      removedPiece = @stream.addNewPiece()
      if removedPiece? then @adjustScore removedPiece

    @grid.draw @canvas
    @wsp.draw()

    @drawScore()

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

class Board extends MeteredMover
  size: 45
  origX: 0
  origY: 0
  activated: false

  constructor: (canvas) ->
    super()
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

  cycleColor: (color, direction) ->
    index    = @colors.indexOf color
    newIndex = (index + direction + @colors.length) % @colors.length

    @colors[newIndex]

class Stream extends PieceList
  maxLength: 45

  constructor: () ->
    super()
    @pattern  = @randomizePattern()
    @position = 0
    @addPiece true  for i in [1..@maxLength - 15]
    @addPiece false for i in [1..15]

  addPiece: (starter) ->
    color = @pattern[ @position % @pattern.length ]

    # bugs
    bugged = Math.random() < 0.3 and !starter

    @pieces.push new Piece color, bugged

    @position++

  addNewPiece: ->
    @addPiece()
    @checkOverFlow()

  checkOverFlow: -> if @pieces.length > @maxLength then @pieces.shift() else null

  randomizePattern: -> (@colors[Math.ceil(Math.random() * 3)] for i in [1..3])

class Grid extends Board
  origY: 90

  constructor: (@context, canvas, stream, @sel) ->
    super canvas
    @height    = 135
    @piecelist = stream

  draw: (canvas) ->
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

    new PieceList(new Piece piece.color, piece.bugged for piece in pieces)

  putSelection: (branch) ->
    endIndex = (@sel.index + @sel.length) * -1

    for streamPiece, i in @piecelist.pieces[endIndex..(endIndex + branch.pieces.length - 1)]
      branchPiece = branch.pieces[i]
      if branchPiece.bugged or branchPiece.color != streamPiece.color
        streamPiece.bugged = true
      else
        streamPiece.bugged = false

    true # lame return statement

class Workspace extends Board
  origX: 0
  origY: 337.5
  piecelist: null

  constructor: (@context, canvas, @sel) ->
    super canvas

  activate: ->
    @activated = true
    @sel = new Selector 1, @piecelist if @hasBranch()

  cycle: (direction) ->
    index        = @piecelist.pieces.length - @sel.index - 1
    currentColor = @piecelist.pieces[index].color
    newPiece     = new Piece @piecelist.cycleColor(currentColor, direction), false
    @piecelist.pieces.splice index, 1, newPiece

  update: (key) ->
    if @hasBranch() and @sel? and @activated
      @sel.update key

      if @isPressed key.codes.DOWN, "cycleDown", key
        @cycle -1

      if @isPressed key.codes.UP, "cycleUp", key
        @cycle 1

  hasBranch: -> @piecelist?

  addBranch: (branch) ->
    @piecelist = branch

  getBranch: ->
    branchCopy = @piecelist
    @piecelist = null
    @sel       = null
    branchCopy

  draw: () ->
    if @activated
      @context.beginPath()

      @context.moveTo 0, 335
      @context.lineTo 315, 335
      @context.lineTo 315, 385
      @context.lineTo 0, 385
      @context.lineTo 0, 335

      @context.closePath()
      @context.strokeStyle = "yellow"
      @context.lineWidth = 5
      @context.stroke()

      @drawSel() if @sel?

    if @piecelist then @drawPieces @piecelist

class Piece
  radius = 15

  constructor: (@color, @bugged) ->

  draw: (context, x, y) ->
    context.beginPath()
    context.arc x, y, radius, 0, Math.PI * 2
    context.closePath()

    context.strokeStyle = "black"
    context.lineWidth = 1

    context.stroke()
    context.fillStyle = if @bugged then 'black' else @color
    context.fill()

class Selector extends MeteredMover
  selection: null

  constructor: (@length, @stream) ->
    super()
    @index = 0

  update: (key) ->
    if @isPressed(key.codes.RIGHT, "moveSelRight", key) and (@index + @length) < @stream.pieces.length
      @index = @index + 1

    if @isPressed(key.codes.LEFT, "moveSelLeft", key) and @index > 0
      @index = @index - 1
