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

    @pattern = ['red', 'blue', 'green']

    @points   = 0
    @position = 0

    @stream = new Stream 7, @pattern
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
    if removedPiece.color is @calculatePatternAtPos()
      @points++
    else
      console.log "Needed #{@calculatePatternAtPos()} but had #{removedPiece.color}!"
      @points = @points - 2;

    @position++

  calculatePatternAtPos: -> @pattern[@position % @pattern.length]

  resetCanvas: ->
    @canvas.width = @canvas.width

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
  # maxLength: 98
  maxLength: 15

  constructor: (starterPieces, @pattern) ->
    super()
    @patternIndex = 0
    @addPiece() for i in [1..starterPieces]

  addPiece: ->
    color = @pattern[ @patternIndex % @pattern.length ]

    # bugs
    if Math.random() < 0.3 then color = 'black'

    @patternIndex++
    @pieces.push(new Piece color)

  addNewPiece: ->
    @addPiece()
    @checkOverFlow()

  checkOverFlow: -> if @pieces.length > @maxLength then removedPiece = @pieces.shift() else null

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

  cycle: (direction) ->
    index        = @piecelist.pieces.length - @sel.index - 1
    currentColor = @piecelist.pieces[index].color
    newPiece     = new Piece @piecelist.cycleColor currentColor, direction
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

    if @piecelist then @drawPieces @piecelist

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

class Branch extends PieceList
