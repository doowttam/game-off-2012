class MeteredMover
  maxFreqMS: 150

  constructor: -> @lastActed = {}

  isPressed: (keyCode, actionKey, key, id) ->
    actionAllowed = !@lastActed[actionKey]? or (new Date()).getTime() - @lastActed[actionKey] > @maxFreqMS

    if key.pressed[keyCode] and actionAllowed
      @lastActed[actionKey] = (new Date()).getTime()
      true
    else
      false

class window.BranchGame extends MeteredMover
  points: 0
  position: 0
  frame: 0

  constructor: (@doc, @win) ->
    super()

    @canvas  = @doc.getElementById 'game_canvas'
    @context = @canvas.getContext '2d'
    @buttons =
      start: @doc.getElementById 'start'
      pause: @doc.getElementById 'pause'

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

    @drawOpener()

  drawOpener: ->
    @context.drawImage (@doc.getElementById 'opener-img'), 6, 54
    @context.fillStyle = 'black'
    @context.font      = 'bold 48px sans-serif'
    @context.textAlign = 'center'
    @context.fillText 'QA Simulator 2012', @canvas.width / 2, 50

  update: ->
    if @isPressed @key.codes.SPACE, 'activateWSP', @key
      if @wsp.activated
        @wsp.activated  = false
        @grid.activated = true
      else
        @wsp.activate()
        @grid.activated = false

    if @isPressed(@key.codes.DOWN, 'getGridSelection', @key) and @grid.activated
      @wsp.addBranch @grid.getSelection()

    if @isPressed(@key.codes.UP, 'putWSPSelection', @key) and @grid.activated and @wsp.hasBranch()
      @grid.putSelection @wsp.getBranch()

  adjustScore: (removedPiece) ->
    # Empty pieces have no color
    if !removedPiece.color? then @gameOver()

    # No score for pieces the user didn't affect
    return if !removedPiece.committed

    if removedPiece.bugged
      @points = @points - 1;
    # Only give points for bugs fixed that were original
    else if removedPiece.origBug
      @points++

  gameOver: ->
    @running = false

    @context.fillStyle = 'rgba(0,0,0,.7)'
    @context.fillRect 0, 0, @canvas.width, @canvas.height

    @context.fillStyle = 'white'
    @context.font      = 'bold 48px sans-serif'
    @context.textAlign = 'center'
    @context.fillText 'Day complete!', @canvas.width / 2, 125

    @context.fillStyle = 'white'
    @context.font      = 'bold 36px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Score: #{@points}", @canvas.width / 2, 200

    message = 'Try harder!'

    if ( @points >= 30 )
      message = 'Perfect score!'
    else if ( @points >= 20 )
      message = 'Pretty good!'
    else if ( @points >= 10 )
      message = 'Not bad!'

    @context.fillStyle = 'white'
    @context.font      = 'bold 32px sans-serif'
    @context.textAlign = 'center'
    @context.fillText message, @canvas.width / 2, 300

    @context.fillStyle = 'white'
    @context.font      = 'bold 24px sans-serif'
    @context.textAlign = 'center'
    @context.fillText '(Refresh to restart)', @canvas.width / 2, 350

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawScore: ->
    @context.fillStyle = 'black'
    @context.font      = 'bold 30px sans-serif'
    @context.textAlign = 'right'
    @context.fillText @points , 650, 370

  drawFrame: =>
    @frame++

    # Update objects that interact with the controls
    @update()
    @sel.update @key
    @wsp.update @key

    # Wipe canvas so we can draw on it
    @resetCanvas()

    # Draw main parts of UI
    @grid.draw @canvas
    @wsp.draw()
    @drawScore()

    # Add a new piece to the stream
    if @frame % 120 == 0
      removedPiece = @stream.addNewPiece()
      if removedPiece? then @adjustScore removedPiece

    # Continue running if we should
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
    'LEFT': 37
    'UP': 38
    'RIGHT': 39
    'DOWN': 40
    'SPACE': 32

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
    @spotsPerLine = Math.floor( (canvas.width - @size * 2) / @size)

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
    spots # return spots

  drawPieces: (piecelist) ->
    # Note: draws pieces in reverse
    if piecelist.pieces.length > 0
      spots = @getSpots(piecelist.pieces.length)

      for num in [0..spots.length - 1]
        piecelist.pieces[piecelist.pieces.length - num - 1].draw @context, spots[num][0], spots[num][1]

  drawSel: () ->
    coords = @spotsToCoords [@sel.index..@sel.index + @sel.length - 1]

    for coord in coords
      @context.fillStyle = '#96cc00'
      @context.fillRect coord[0], coord[1], @size, @size

  spotsToCoords: (spots) ->
    for spot in spots
      row = Math.floor spot / @spotsPerLine
      col = if spot >= @spotsPerLine then spot % @spotsPerLine else spot
      [@origX + (col * 45), @origY + (row * 45)]

class PieceList
  colors: ["red", "blue", "green", "yellow", "orange"]
  pieces: null

  constructor: (initialPieces)->
    @pieces = initialPieces ? []

  cycleColor: (color, direction) ->
    index    = @colors.indexOf color
    newIndex = (index + direction + @colors.length) % @colors.length

    @colors[newIndex]

class Stream extends PieceList
  starterBugsPossible: 20
  maxLength: 48
  totalBugs: 30
  position: 0

  constructor: () ->
    super()
    @pattern = @randomizePattern()
    @addPiece true  for i in [1..@maxLength - @starterBugsPossible]
    @addPiece false for i in [1..@starterBugsPossible]

  addPiece: (starter) ->
    color = @pattern[ @position % @pattern.length ]

    # bugs
    bugged = Math.random() < 0.3 and !starter

    @pieces.push new Piece color, bugged, bugged

    @totalBugs-- if bugged

    @position++

  addEmptyPiece: ->
    @pieces.push new EmptyPiece
    @position++

  addNewPiece: ->
    if @totalBugs > 0 then @addPiece() else @addEmptyPiece()
    @checkOverFlow()

  checkOverFlow: -> if @pieces.length > @maxLength then @pieces.shift() else null

  randomizePattern: -> (@colors[Math.floor(Math.random() * @colors.length)] for i in [1..3])

class Grid extends Board
  origY: 90
  origX: 45
  height: 135

  constructor: (@context, canvas, @piecelist, @sel) ->
    super canvas

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

    new PieceList(new Piece piece.color, piece.bugged, piece.origBug for piece in pieces)

  putSelection: (branch) ->
    endIndex = (@sel.index + @sel.length) * -1

    # For each piece we're merging, update set its properties
    for streamPiece, i in @piecelist.pieces[endIndex..(endIndex + branch.pieces.length - 1)]
      streamPiece.committed = true

      branchPiece = branch.pieces[i]
      if branchPiece.bugged or branchPiece.color != streamPiece.color
        streamPiece.bugged = true
      else
        streamPiece.bugFixed = true if streamPiece.bugged
        streamPiece.bugged   = false

class Workspace extends Board
  origX: 180
  origY: 325
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
    @drawSel() if @sel? and @activated

    @context.beginPath()

    @context.moveTo @origX, @origY
    @context.lineTo @origX + 315, @origY
    @context.lineTo @origX + 315, @origY + 45
    @context.lineTo @origX, @origY + 45
    @context.lineTo @origX, @origY

    @context.closePath()
    @context.strokeStyle = if @activated then 'black' else 'gray'
    @context.lineWidth   = 5
    @context.stroke()

    if @piecelist then @drawPieces @piecelist

class Piece
  radius = 15

  committed: false
  bugFixed: false

  constructor: (@color, @bugged, @origBug = false) ->

  draw: (context, x, y) ->
    return if !@color?
    context.beginPath()
    context.arc x, y, radius, 0, Math.PI * 2
    context.closePath()

    if (@committed and @bugged) or (@bugFixed and @origBug)
      bgColor = if @bugged then 'red' else 'green'
      context.fillStyle = bgColor
      context.fillRect x - 17.5, y - 17.5, 35, 35 # NO GOOD: magic numbers

    context.strokeStyle = 'black'
    context.lineWidth   = 1

    context.stroke()
    context.fillStyle = if @bugged then 'black' else @color
    context.fill()

class EmptyPiece extends Piece
    committed: false
    bugged: false
    origBug: false
    color: null

class Selector extends MeteredMover
  selection: null
  index: 0

  constructor: (@length, @stream) ->
    super()

  update: (key) ->
    if @isPressed(key.codes.RIGHT, "moveSelRight", key) and (@index + @length) < @stream.pieces.length
      @index = @index + 1

    if @isPressed(key.codes.LEFT, "moveSelLeft", key) and @index > 0
      @index = @index - 1
