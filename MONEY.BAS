'
'$$$  We've got to have...  $$$
'$$$         MONEYYYY       $$$
'
'   (c) Stupid Bunny 2009-2025.
'
'A very simple game. You must collect all the $ in the level,
'while avoiding the Enemies who will also be trying to
'collect your money. The game will keep going until the Enemy
'has more cumulative money collected than you do.

' This is a game show where every contestant wins! But some win more than
' others. See how far you can go.

' THE RULES:
' 1. If you run out of lives, the Game is over.
' 2. If you end a round with less cumulative money then the Enemy, the Game
'    is over.
' 3. There is no inventory; any Powerups bought from the Shop will be applied
'    immediately on purchase.
' 4. Touching any Enemy will subtract one Life and return the player to the
'    Home Square, unless a protecting Powerup is applied.
' 5. Enemies cannot touch you on the Home Square.
' 6. The Shop cannot be accessed on the Home Square.

REM $DYNAMIC

DEFINT A-Z

'===============================================================================
' GLOBAL DECLARATIONS
' Includes constants, typedefs, sub/functions, and global variables/arrays
'===============================================================================

'STORE ITEMS. Can be purchased and delivered instantly at any time!
') Tellyport. Jump to a random point on the map.
CONST TELEPT = 2!
') Tele-Direct. Jump to the home square on the map.
CONST HOMTELEPT = 3!
') *MagicShield. Stays with player until next monster touched.
CONST SHIELD = 3.5
') *Tunnel Blaster. Destroy one square of wall.
CONST TUNNEL = 6!
') *No-Clip. Phase through one square of wall.
CONST NOCLIP = 7!
') *Thing-B-Gone. Next enemy touched gets teleported to a random point on the map.
CONST NMETELEPT = 5!
') *0-Bliterate! Instantly destroys next enemy touched including any money
'   they were carrying.
CONST KILLNME = 7.5
') *Touch of Death. Next enemy player touches will get dead. Player gets their
'   whole stash.
CONST TOD = 10!
') Time Freeze. All enemies are frozen in place for X moves.
CONST TIMEFREEZE = 7!
') Bio-Nuke. Obliterates all enemies within a certain radius.
CONST BIONUKE = 10!
') Xtralife. Gives one extra life.
CONST XTRALIFE = 20!

'Dollar type
TYPE Dollar
 amount AS SINGLE 'Can be 0.01, 0.10, 1.00, or 10.00
 char AS STRING * 1
 x AS INTEGER
 y AS INTEGER
 clr AS INTEGER
END TYPE

TYPE StoreItem
 named AS STRING * 16
 desc AS STRING * 48
 cost AS SINGLE
END TYPE

'SPECIES LIST. All species will collect money in some form.
'0 (Diamond Joe): the default. Mills about randomly.
'1 (Hrap): Moves randomly except moves towards the player every 3-5 moves.
'2 (Clubber): Pursues player more closely the nearer player gets.
'3 (magpie): Moves to grab nearest coin (amt <1.0). Mills about if no
' money left.
'4 (Snoodley): Fidgets around like a diamond, but will zero in on any banknotes
'  found within a couple squares of it.
'5 (Spadey Boi): Moves towards and kills nearest enemy, inheriting their stash.
' Will pursue player if no enemies left. Maybe cannot be killed?
'6 (Hunter): Pursues player, stopping only to grab nearby money of any denomination.
'7 (Money Eater): Seeks and devours any money it finds. It doesn't get added to bag
' or Enemy count, but is destroyed forever
'8 (Blaggole): Slowly moves towards and destroys anything nearby, like above but
' for everything. If two touch then they merge. Powerups don't work on it either.
' If I want to be super extra mean it may be an instant lose if you touch it.
'9 (Moneymancer): 
'10 (Chaos Beast): Turns any money it finds into Diamond Joe.

TYPE Enemy
 species AS INTEGER
 char AS STRING * 1
 cool AS INTEGER 'Cooldown for some species
 target AS INTEGER 'Index of targeted thing for some species
 x AS INTEGER
 y AS INTEGER
 clr AS INTEGER
 bag AS SINGLE 'Each enemy carries its own stash that can be looted
END TYPE

'Wish I could just enum this but alas I am writing this in QBASIC
CONST DIAMOND = 0
CONST HEART = 1
CONST CLUB = 2
CONST MAGPIE = 3
CONST SNOODLEY = 4
CONST SPADE = 5
CONST HUNTER = 6

CONST DIAMONDCHR = 4
CONST HEARTCHR = 3
CONST HEARTCOL = 12
CONST SPADECHR = 6
CONST CLUBCHR = 5
CONST CLUBCOL = 2
CONST MAGPIECHR = 227
CONST MAGPIECOL = 15

TYPE Player
 clr AS INTEGER
 x AS INTEGER
 y AS INTEGER
 named AS STRING * 10
 lives AS INTEGER
 power AS INTEGER 'Track player powerup
END TYPE

TYPE Home
 y AS INTEGER
 x AS INTEGER
END TYPE

CONST HOMECHR = 8
CONST HOMECOL = 11

CONST RANGE1 = 55
CONST RANGE2 = 100
CONST RANGE3 = 148
CONST RANGE4 = 150

CONST DENOM1 = .1
CONST DENOM2 = .25
CONST DENOM3 = 1!
CONST DENOM4 = 10!

CONST TRUE = 1
CONST FALSE = 0

'Max numbers of things in a level
CONST DOLLARMAX = 150
CONST ENEMYMAX = 75

'Dimensions of playfield
CONST YMIN = 4
CONST YMAX = 21
CONST XMIN = 6
CONST XMAX = 75

' BIT MASKING! for occupied
CONST BPLR = 1  'The player
CONST BDLR = 2  'Dollar
CONST BNME = 4  'An enemy
CONST BWAL = 8  'A wall
CONST BHOM = 16 'The home square

CONST BGCOL = 0

' Characters and colors used by things
CONST PLAYERCOL = 14
CONST PLRCHR = 1

CONST GROUNDCOL = 1
CONST GROUNDCHR = 250
CONST OUTWALLCHR = 176

CONST BANKNOTE = 36
CONST COIN = 155

'Sound constants
CONST PLRDLRSND = 1
CONST NMEDLRSND = 2
CONST PLRDIESND = 3

DECLARE SUB InitDisplay (DollarInitCount, EnemyNum, LevelNum)
DECLARE SUB InitEnemies (EnemyNum, LevelNum)
DECLARE FUNCTION MovePlr (moveX, MoveY)
DECLARE SUB MoveEnemy (i, DollarInitCount, EnemyNum)
DECLARE SUB InitDollars (DollarInitCount)
DECLARE FUNCTION RandomDir ()
DECLARE SUB PlayerDie ()
DECLARE SUB DlrWin ()
DECLARE SUB PlaySound (SoundConst)
DECLARE SUB OpenShop ()
DECLARE SUB ToggleThing (y, x, ttype, switchtf)
DECLARE SUB UpdateHud ()
DECLARE SUB QuitPrompt ()
DECLARE SUB GameOver ()
DECLARE SUB TitleScreen ()
DECLARE SUB SparklePause ()

' Tracks what, if anything, currently occupies a square using bit flags.
' Enables quick lookup by location
DIM SHARED Occupied(YMIN TO YMAX, XMIN TO XMAX) AS INTEGER

' Tracks the dollar or enemy indexes, respectively, occupying each square.
' Works in tandem with above if more information about occupant is needed
DIM SHARED DlrGrid(YMIN TO YMAX, XMIN TO XMAX) AS INTEGER
DIM SHARED EnemyGrid(YMIN TO YMAX, XMIN TO XMAX) AS INTEGER

DIM SHARED Plr AS Player
DIM SHARED Home AS Home

DIM SHARED DollarCmtv!
DIM SHARED DlrRemCount
DIM SHARED DlrRemVal!
DIM SHARED DollarEnemy!

'===============================================================================
' All declarations above this line
'===============================================================================
' MAIN FLOW BEGINS HERE
'===============================================================================

CALL TitleScreen

Plr.lives = 5
Plr.power = 0
Plr.clr = PLAYERCOL

 'Values at the beginning of the game. Keeping LET here for no reason except posterity
LET LevelNum = 0
LET DollarCmtv! = 0
LET DollarEnemy! = 0
LET EnemyNum = 4
 
'NEW LEVEL INITIALIZATION ------------------------------------------------------
DO ' Level loop - each level initializes here

 'Clear keyboard buffer; don't want inputs from last level carrying over
 WHILE INKEY$ <> "": WEND

 'for safety, reset these tables
 FOR y = YMIN TO YMAX
  FOR x = XMIN TO XMAX
   Occupied(y, x) = 0
   DlrGrid(y, x) = 0
   EnemyGrid(y, x) = 0
  NEXT x
 NEXT y

 RANDOMIZE (TIMER / 3)
 
 LevelNum = LevelNum + 1
 
 HomeY = INT(RND * (YMAX - YMIN + 1)) + YMIN
 HomeX = INT(RND * (XMAX - XMIN + 1)) + XMIN
 'IF INT(HomeX / 2) = HomeX / 2 THEN HomeX = HomeX + 1 'to stick to grid

 Home.y = HomeY
 Home.x = HomeX
 
 Plr.y = HomeY
 Plr.x = HomeX
 
 'Place character and home in initial position
 Occupied(Plr.y, Plr.x) = BPLR OR BHOM
 
 EnemyNum = EnemyNum + 2 'Increase enemies per map
 
 'LET gCol = GROUNDCOL     'color of the ground
 DollarInitCount = INT(RND * (LevelNum * 5)) + (LevelNum * 5)

 'Enforce limit on number of collectible $$$
 IF DollarInitCount > DOLLARMAX THEN DollarInitCount = DOLLARMAX
 DlrRemCount = DollarInitCount

 REDIM SHARED Enemy(EnemyNum) AS Enemy
 REDIM SHARED Dollar(DollarInitCount) AS Dollar

 CALL InitDollars(DollarInitCount)
 CALL InitEnemies(EnemyNum, LevelNum)
 
 CALL InitDisplay(DollarInitCount, EnemyNum, LevelNum)
 
 'Waiting for input loop--------------------------------------------------------
 DO
  MoveEnemies = 0
  PlaySound (0)
  
  kbd$ = INKEY$
  SELECT CASE kbd$
   'Arrow Keys
   CASE CHR$(0) + "H": MoveEnemies = MovePlr(0, -1) 'Up arrow
   CASE CHR$(0) + "P": MoveEnemies = MovePlr(0, 1)  'Down arrow
   CASE CHR$(0) + "K": MoveEnemies = MovePlr(-1, 0) 'Left arrow
   CASE CHR$(0) + "M": MoveEnemies = MovePlr(1, 0)  'Right arrow
   'vim and WASD controls
   CASE "k", "K", "w", "W": MoveEnemies = MovePlr(0, -1) 'Up
   CASE "j", "J", "a", "A": MoveEnemies = MovePlr(0, 1)  'Down
   CASE "h", "H", "s", "S": MoveEnemies = MovePlr(-1, 0) 'Left
   CASE "l", "L", "d", "D": MoveEnemies = MovePlr(1, 0)  'Right
   CASE "y", "Y": MoveEnemies = MovePlr(-1, -1)          'UL
   CASE "u", "U": MoveEnemies = MovePlr(1, -1)           'UR
   CASE "b", "B": MoveEnemies = MovePlr(-1, 1)           'DL
   CASE "n", "N": MoveEnemies = MovePlr(1, 1)            'DR
   'Other key commands
   CASE ".": MoveEnemies = MovePlr(0, 0) 'Wait
   CASE "/" 'Opens the Shop
    CALL OpenShop
    CALL InitDisplay(DollarInitCount, EnemyNum, LevelNum)
   CASE CHR$(27): CALL QuitPrompt 'Esc
   CASE ELSE 'Default; nothing happens
  END SELECT
  
  'This runs if the player was able to move or waited
  IF MoveEnemies THEN
   FOR i = 1 TO EnemyNum
    CALL MoveEnemy(i, DollarInitCount, EnemyNum)
   NEXT i
  END IF
  
 LOOP UNTIL (Plr.lives = 0 OR DlrRemCount = 0) 'End input loop
 IF DollarCmtv! >= DollarEnemy! AND Plr.lives > 0 THEN CALL DlrWin
LOOP UNTIL (Plr.lives = 0 OR DollarCmtv! < DollarEnemy!)       'End level generation loop - the game is over

'Executes when it's time for game to end----------------------------------------
CALL GameOver
END

'===============================================================================
''''''''''''''SUBROUTINES'''''''''''''''''''''''''''''''''''''''''''''''''''''''
'===============================================================================

'You beat the map a winner------------------------------------------------------
SUB DlrWin
 LOCATE 1, 3
 COLOR 15, BGCOL
 PRINT "* A WINNER IS YOU! *"
 PLAY "mft200o2l8cp4>l8cp8<l8d+l8cp4<l8gp4l8a+p4>l8c" 'It's a gas
END SUB

'The game has ended-------------------------------------------------------------
SUB GameOver
 CLS
 LOCATE 10, 29
 COLOR 14, BGCOL
 PRINT "YOU LOSE! GOOD DAY, SIR!"
END SUB

'Initializes graphics at start of level-----------------------------------------
SUB InitDisplay (DollarInitCount, EnemyNum, LevelNum)

 CLS

 COLOR 9, BGCOL
 LOCATE 25, 68
 PRINT "Level "; LevelNum
 CALL UpdateHud
 
 'Draw outer wall
 COLOR 4
 FOR x = XMIN - 1 TO XMAX + 1
  LOCATE 3, x
  PRINT CHR$(OUTWALLCHR)
  LOCATE 22, x
  PRINT CHR$(OUTWALLCHR)
 NEXT x
 FOR y = YMIN - 1 TO YMAX
  LOCATE y, XMIN - 1
  PRINT CHR$(OUTWALLCHR)
  LOCATE y, XMAX + 1
  PRINT CHR$(OUTWALLCHR)
 NEXT y

 'Draw play area
 COLOR GROUNDCOL, BGCOL
 FOR row = YMIN TO YMAX
  LOCATE row, 1
  FOR column = XMIN TO XMAX 'STEP 2
   LOCATE row, column
   PRINT CHR$(GROUNDCHR)
  NEXT column
 NEXT row

 FOR y = YMIN TO YMAX
  FOR x = XMIN TO XMAX
   Space = Occupied(y, x)
   IF Space THEN
    LOCATE y, x
    IF Space = BHOM THEN
     COLOR HOMECOL, BGCOL
     PRINT CHR$(HOMECHR)
    ELSEIF Space AND BPLR THEN
     IF Space AND BHOM THEN
      COLOR BGCOL, HOMECOL
     ELSE
      COLOR Plr.clr, BGCOL
     END IF
     PRINT CHR$(PLRCHR)
    ELSEIF Space AND BDLR THEN
     n = DlrGrid(y, x)
     COLOR Dollar(n).clr, BGCOL
     PRINT Dollar(n).char
    ELSEIF Space AND BNME THEN
     n = EnemyGrid(y, x)
     COLOR Enemy(n).clr, BGCOL
     PRINT Enemy(n).char
    ELSE
    END IF
   END IF
  NEXT x
 NEXT y

END SUB

'Initialize dwolluhs------------------------------------------------------------
SUB InitDollars (DollarInitCount)
 'Set initial x and y positions of $$$---------
 FOR i = 1 TO DollarInitCount
  n = INT(RND * RANGE4) + 1
  IF n < RANGE1 THEN
   Dollar(i).amount = DENOM1
   Dollar(i).char = CHR$(COIN)
   Dollar(i).clr = 6
  ELSEIF n >= RANGE1 AND n < RANGE2 THEN
   Dollar(i).amount = DENOM2
   Dollar(i).char = CHR$(COIN)
   Dollar(i).clr = 14
  ELSEIF n >= RANGE2 AND n < RANGE3 THEN
   Dollar(i).amount = DENOM3
   Dollar(i).char = CHR$(BANKNOTE)
   Dollar(i).clr = 10
  ELSE
   Dollar(i).amount = DENOM4
   Dollar(i).char = CHR$(BANKNOTE)
   Dollar(i).clr = 13
  END IF
  
  'Dollar(i).amount = 1!
  DO
   Dollar(i).x = INT(RND * (XMAX - XMIN + 1)) + XMIN
   Dollar(i).y = INT(RND * (YMAX - YMIN + 1)) + YMIN
  LOOP UNTIL Occupied(Dollar(i).y, Dollar(i).x) = 0 'Nothing else on square
  Occupied(Dollar(i).y, Dollar(i).x) = BDLR
  DlrGrid(Dollar(i).y, Dollar(i).x) = i
  DlrRemVal! = DlrRemVal! + Dollar(i).amount
 NEXT i
END SUB

'Initialize enemies-------------------------------------------------------------
SUB InitEnemies (EnemyNum, LevelNum)
 FOR i = 1 TO EnemyNum
 
  Enemy(i).bag = 0!
  
  species = INT(RND * 4)
  Enemy(i).species = species
  
  SELECT CASE Enemy(i).species 'Assign character
   CASE DIAMOND
    Enemy(i).char = CHR$(DIAMONDCHR)
    Enemy(i).clr = INT(RND * 15) + 1
   CASE HEART
    Enemy(i).char = CHR$(HEARTCHR)
    Enemy(i).clr = HEARTCOL
    Enemy(i).cool = INT(RND * 4) + 1
   CASE CLUB
    Enemy(i).char = CHR$(CLUBCHR)
    Enemy(i).clr = CLUBCOL
    Enemy(i).cool = INT(RND * 12) + 4
   CASE MAGPIE
    Enemy(i).char = CHR$(MAGPIECHR)
    Enemy(i).clr = MAGPIECOL
    Enemy(i).target = -1
   CASE ELSE
    Enemy(i).char = "X" 'Hope this doesn't happen but we can see if it does
  END SELECT
  
  DO
   Enemy(i).x = INT(RND * (XMAX - XMIN + 1)) + XMIN
   Enemy(i).y = INT(RND * (YMAX - YMIN + 1)) + YMIN
  LOOP UNTIL Occupied(Enemy(i).y, Enemy(i).x) = 0 'Nothing else on square
  
  Occupied(Enemy(i).y, Enemy(i).x) = BNME
  EnemyGrid(Enemy(i).y, Enemy(i).x) = i
  
 NEXT i
END SUB

'Handle enemy movement----------------------------------------------------------
SUB MoveEnemy (i, DollarN, EnemyN)
 'BEEP

 ' First thing: Decide which direction the enemy should go
 'Should generate a -1, 0, or 1
 SELECT CASE Enemy(i).species
 
  CASE DIAMOND
   MoveY = RandomDir
   moveX = RandomDir
   
  CASE HEART
   IF Enemy(i).cool = 0 THEN
    IF Enemy(i).y < Plr.y THEN
     MoveY = 1
    ELSEIF Enemy(i).y > Plr.y THEN
     MoveY = -1
    END IF
    IF Enemy(i).x < Plr.x THEN
     moveX = 1
    ELSEIF Enemy(i).x > Plr.x THEN
     moveX = -1
    END IF
    Enemy(i).cool = INT(RND * 4) + 1
   ELSE
    MoveY = RandomDir
    moveX = RandomDir
    Enemy(i).cool = Enemy(i).cool - 1
   END IF
   
  CASE CLUB
   IF Enemy(i).cool = 0 THEN
    IF Enemy(i).y < Plr.y THEN
     MoveY = 1
    ELSEIF Enemy(i).y > Plr.y THEN
     MoveY = -1
    END IF
    IF Enemy(i).x < Plr.x THEN
     moveX = 1
    ELSEIF Enemy(i).x > Plr.x THEN
     moveX = -1
    END IF
    UpperLimit = ABS(INT(((Enemy(i).y - Plr.y) + (Enemy(i).x - Plr.x)) / 2))
    Enemy(i).cool = INT(RND * UpperLimit) + 2
   ELSE
    MoveY = RandomDir
    moveX = RandomDir
    Enemy(i).cool = Enemy(i).cool - 1
   END IF
   
  CASE MAGPIE
  
   IF Enemy(i).target = -1 THEN 'Magpie is in need of a new target index
    Lowest = 666
    Comp = 0
    FOR j = 1 TO DollarN
     IF Dollar(j).amount < 1! THEN
      IF (Occupied(Dollar(j).y, Dollar(j).x) AND BDLR) THEN
       Comp = (Enemy(i).y - Dollar(j).y) ^ 2 + ((Enemy(i).x - Dollar(j).x)) ^ 2
       IF Comp < Lowest THEN
        Lowest = Comp
        Enemy(i).target = j
       END IF
      END IF
     END IF
    NEXT j
    IF Lowest = 666 THEN Enemy(i).target = -2 'This means no more coins left
    
   ELSEIF Enemy(i).target = -2 THEN 'No more coins left, mill about
    MoveY = RandomDir
    moveX = 2 * RandomDir
    
   ELSE                     ' Magpie has target, run directly to it
    n = Enemy(i).target
    IF (Occupied(Dollar(n).y, Dollar(n).x) AND BDLR) = 0 THEN
     Enemy(i).target = -1
    ELSEIF Enemy(i).y < Dollar(n).y THEN
     MoveY = 1
    ELSEIF Enemy(i).y > Dollar(n).y THEN
     MoveY = -1
    END IF
    IF Enemy(i).x < Dollar(n).x THEN
     moveX = 1
    ELSEIF Enemy(i).x > Dollar(n).x THEN
     moveX = -1
    END IF
   END IF
   
  CASE ELSE
 END SELECT
 
 NewY = Enemy(i).y + MoveY
 NewX = Enemy(i).x + moveX
 
 'first, don't change coords if enemy will walk off edge
 IF NewX > XMAX OR NewX < XMIN THEN NewX = Enemy(i).x
 IF NewY > YMAX OR NewY < YMIN THEN NewY = Enemy(i).y
 
 'Wall testing can go here
 
 'Enemy cannot occupy home square
 IF (Occupied(NewY, NewX) AND BHOM) THEN EXIT SUB
 
 'Next, what to do if spot is occupied by another enemy
 IF (Occupied(NewY, NewX) AND BNME) THEN
  SELECT CASE Enemy(i).species
   CASE DIAMOND, HEART, MAGPIE, CLUB
    EXIT SUB
   CASE ELSE
    EXIT SUB
  END SELECT
 END IF
 
 'Otherwise, enemy is on the move
 CALL ToggleThing(Enemy(i).y, Enemy(i).x, BNME, FALSE) 'Switch enemy OFF
 CALL ToggleThing(NewY, NewX, BNME, TRUE) 'Switch enemy ON
 LOCATE Enemy(i).y, Enemy(i).x
 COLOR GROUNDCOL, BGCOL
 PRINT CHR$(GROUNDCHR)
 Enemy(i).y = NewY
 Enemy(i).x = NewX
 EnemyGrid(NewY, NewX) = i
 
 'The enemy has found another thing
 IF (Occupied(NewY, NewX) AND BPLR) THEN
  CALL ToggleThing(NewY, NewX, BPLR, FALSE) 'Switch player OFF
  CALL PlayerDie
  
 ELSEIF (Occupied(NewY, NewX) AND BDLR) THEN
  CALL ToggleThing(NewY, NewX, BDLR, FALSE) 'Switch dollar OFF
  CALL PlaySound(NMEDLRSND)
  
  n = DlrGrid(NewY, NewX)
  DollarEnemy! = DollarEnemy! + Dollar(n).amount
  Enemy(i).bag = Enemy(i).bag + Dollar(n).amount
  IF Enemy(i).species = MAGPIE THEN
   Enemy(i).target = -1
   'Dollar(n).y = 666
   'Dollar(n).x = 666
   'BEEP
  END IF

 ' DollarEnemy! = DollarEnemy! + denom(NewY, NewX)
  DlrRemCount = DlrRemCount - 1
  DlrRemVal! = DlrRemVal! - Dollar(n).amount
  CALL UpdateHud
 END IF

 'Finally, draw enemy at new location
 COLOR Enemy(i).clr, BGCOL
 LOCATE NewY, NewX
' COLOR enColor(enLoop)
 PRINT Enemy(i).char

END SUB

'Move player to new location and do some collision checks-----------------------
FUNCTION MovePlr (moveX, MoveY)
 NewY = Plr.y + MoveY
 NewX = Plr.x + moveX
 MovePlr = 0
 
 'If any of the new coordinates are out of bounds then go no further
 IF NewY < YMIN OR NewY > YMAX OR NewX < XMIN OR NewX > XMAX THEN EXIT FUNCTION
 
 'Can do check for walls in here later, too
 
 'We are free to move, so clear the old player spot
 MovePlr = 1
 CALL ToggleThing(Plr.y, Plr.x, BPLR, FALSE) 'Switch player OFF
 LOCATE Plr.y, Plr.x
 IF Occupied(Plr.y, Plr.x) AND BHOM THEN
  COLOR HOMECOL, BGCOL
  PRINT CHR$(HOMECHR)
 ELSE
  COLOR GROUNDCOL, BGCOL
  PRINT CHR$(GROUNDCHR)
 END IF
 
 'Has player stepped on an enemy?
 IF (Occupied(NewY, NewX) AND BNME) THEN
  CALL PlayerDie
  EXIT FUNCTION
 END IF
 
 'No obstacles or kill by enemy - player can move
 Plr.y = NewY
 Plr.x = NewX
 CALL ToggleThing(Plr.y, Plr.x, BPLR, TRUE)
 
 'Is player on the home square?
 IF Occupied(NewY, NewX) AND BHOM THEN
  COLOR BGCOL, HOMECOL
 ELSE
  COLOR Plr.clr, BGCOL
 END IF
 LOCATE Plr.y, Plr.x
 PRINT CHR$(PLRCHR)
 
 'Lastly, did player get PAID!?
 IF (Occupied(Plr.y, Plr.x) AND BDLR) THEN
  CALL PlaySound(PLRDLRSND)
  CALL ToggleThing(Plr.y, Plr.x, BDLR, FALSE) 'Switch dollar OFF
  
  x = DlrGrid(Plr.y, Plr.x)
  DollarCmtv! = DollarCmtv! + Dollar(x).amount
  DlrRemVal! = DlrRemVal! - Dollar(x).amount

  'DollarCmtv! = DollarCmtv! + denom(Plr.y, Plr.x)
  DlrRemCount = DlrRemCount - 1
  CALL UpdateHud
 END IF
END FUNCTION

'Opens shop---------------------------------------------------------------------
SUB OpenShop

 PLAY "MBT160O4L64CG" 'shop open sound
 
 'Clear menu area
 FOR y = YMIN TO YMAX
  FOR x = XMIN TO XMAX
   PRINT " "
  NEXT x
 NEXT y
 
 CALL UpdateHud
 
 StoreCount = 11
 DIM StoreItems(StoreCount) AS StoreItem
 
 'Initialize the store (probably don't need to do this every time but oh well)
 FOR i = 1 TO StoreCount
  SELECT CASE i
   CASE 1
    StoreItems(i).named = "Tellyport"
    StoreItems(i).desc = "Teleport to a random place in the map."
    StoreItems(i).cost = TELEPT
   CASE 2
    StoreItems(i).named = "Tele-Direct"
    StoreItems(i).desc = "Teleport to the Home Booth."
    StoreItems(i).cost = HOMTELEPT
   CASE 3
    StoreItems(i).named = "MagicShield"
    StoreItems(i).desc = "Shield will take the next hit for you."
    StoreItems(i).cost = SHIELD
   CASE 4
    StoreItems(i).named = "Tunnel Blaster"
    StoreItems(i).desc = "Bore a hole in the next wall you see."
    StoreItems(i).cost = TUNNEL
   CASE 5
    StoreItems(i).named = "No-Clip"
    StoreItems(i).desc = "Has enough energy to phase you through one wall."
    StoreItems(i).cost = NOCLIP
   CASE 6
    StoreItems(i).named = "Thing-B-Gone"
    StoreItems(i).desc = "Teleport away the next enemy tries to touch you."
    StoreItems(i).cost = NMETELEPT
   CASE 7
    StoreItems(i).named = "0-Bliterate"
    StoreItems(i).desc = "Instantly vaporize the next enemy you touch!"
    StoreItems(i).cost = KILLNME
   CASE 8
    StoreItems(i).named = "Touch of Death"
    StoreItems(i).desc = "Whoever you next touch is instantly dead and ready to loot."
    StoreItems(i).cost = TOD
   CASE 9
    StoreItems(i).named = "Time Freeze"
    StoreItems(i).desc = "Everyone except you is frozen for a few critical moves."
    StoreItems(i).cost = TIMEFREEZE
   CASE 10
    StoreItems(i).named = "MicroNuke"
    StoreItems(i).desc = "Everything around you turns to atoms! Except you"
    StoreItems(i).cost = BIONUKE
   CASE 11
    StoreItems(i).named = "Xtralife"
    StoreItems(i).desc = "One extra chance to take a death."
    StoreItems(i).cost = XTRALIFE
  END SELECT
 NEXT i
 
 Selected = 1  'Top item is always initially selected
 Cursor$ = " " 'I don't know if this is necessary
 
 DO
  COLOR 14
  LOCATE YMIN, XMIN + 2
  PRINT StoreItems(Selected).desc
  
  FOR i = 1 TO StoreCount
   IF Selected = i THEN Cursor$ = ">":  ELSE Cursor$ = " "
   COLOR 7
   LOCATE YMIN + 1 + i, XMIN + 2
   PRINT USING "& &.   $##.##"; Cursor$; StoreItems(i).named; StoreItems(i).cost
  NEXT i
  
  kbd$ = INKEY$
  
  IF kbd$ = CHR$(0) + CHR$(72) THEN 'Up arrow
   IF Selected = 1 THEN Selected = StoreCount:  ELSE Selected = Selected - 1
  ELSEIF kbd$ = CHR$(0) + CHR$(80) THEN 'Down arrow
   IF Selected = StoreCount THEN Selected = 1:  ELSE Selected = Selected + 1
  END IF
 LOOP UNTIL (kbd$ = CHR$(13) OR kbd$ = CHR$(27)) 'Enter or Esc key respectively are pressed
 
 IF kbd$ = CHR$(13) THEN 'Something has been selected
  DollarCmtv! = DollarCmtv! - StoreItems(Selected).cost 'Deduct cost of store item
  
  'Actually execute (or assign) the super powers!!
  SELECT CASE Selected
   CASE 1 'Tellyport
    DO
     y = INT(RND * (YMAX - YMIN + 1)) + YMIN
     x = INT(RND * (XMAX - XMIN + 1)) + XMIN
    LOOP UNTIL Occupied(y, x) = 0
    CALL ToggleThing(Plr.y, Plr.x, BPLR, FALSE)
    Plr.y = y
    Plr.x = x
    CALL ToggleThing(y, x, BPLR, TRUE)
   CASE 2 'Tele-Direct
    CALL ToggleThing(Plr.y, Plr.x, BPLR, FALSE)
    Plr.y = Home.y
    Plr.x = Home.x
    CALL ToggleThing(Plr.y, Plr.x, BPLR, TRUE)
   CASE 3 'MagicShield
    Plr.power = Selected
    Plr.clr = 9 'Blue
   CASE 4 'Tunnel Blaster
    Plr.power = Selected
    Plr.clr = 6 'Brown
   CASE 5 'No-Clip
    Plr.power = Selected
    Plr.clr = 10 'Green
   CASE 6 'Thing-B-Gone
    Plr.power = Selected
    Plr.clr = 13 'Magenta
   CASE 7 '0-bliterate
    Plr.power = Selected
    Plr.clr = 12 'Red
   CASE 8 'Touch of Death
    Plr.power = Selected
    Plr.clr = 4 'Dark red
   CASE 9 'Time Freeze
    Plr.power = Selected
   CASE 10 'MicroNuke
    BEEP 'This will be hard to program lol
   CASE 11 'XtraLife
    Plr.lives = Plr.lives + 1 'Most valuable is easiest to program
  END SELECT
 END IF
 
END SUB

'Is the enemy occupying the same position as the player?------------------------
SUB PlayerDie
 Plr.x = Home.x
 Plr.y = Home.y
 CALL ToggleThing(Plr.y, Plr.x, BPLR, TRUE)  'Set new player location
 COLOR BGCOL, Plr.clr
 LOCATE Plr.y, Plr.x
 PRINT CHR$(PLRCHR)
 Plr.lives = Plr.lives - 1
 CALL UpdateHud
 
 CALL PlaySound(PLRDIESND)
END SUB

'Play sounds--------------------------------------------------------------------
SUB PlaySound (n)
 
 'Internally track if a sound is already playing
 STATIC IsPlaying AS INTEGER
 
 IF n = 0 THEN
  IsPlaying = 0
  EXIT SUB
 END IF
 
 'This sound always takes precedence
 IF n = PLRDIESND THEN
  IsPlaying = 1
  FOR i = 10 TO 1 STEP -1
   SOUND (50 * i), .25
  NEXT i
  EXIT SUB
 END IF
 
 'These sounds have about equal precedence so shouldn't stack
 IF IsPlaying = 0 THEN
  SELECT CASE n
   CASE PLRDLRSND
    IsPlaying = 1
    FOR i = 1 TO 10
     SOUND (100 * i), .25
    NEXT i
   CASE NMEDLRSND
    IsPlaying = 1
    FOR i = 1 TO 10
      SOUND (50 * i), .25
    NEXT i
'   CASE PLRDIESND
'    IsPlaying = 1
'    FOR i = 10 TO 1 STEP -1
'     SOUND (50 * i), .25
'    NEXT i
   CASE ELSE 'Hopefully never executes
  END SELECT
 END IF
END SUB

'Ask if you want to quit--------------------------------------------------------
SUB QuitPrompt
 'What displays if the Esc key is pressed
 COLOR BGCOL, 7
 LOCATE 1, 3
 PRINT "Quit?"
 'LOCATE 1, 6
 
 DO
  Quit$ = INKEY$
  Quit$ = LCASE$(Quit$)
  
  'This is what executes if the player quits
  IF Quit$ = "y" THEN
   COLOR 7, BGCOL
   CLS
   END
  END IF
  
 LOOP UNTIL Quit$ = "n"
 
 'Clear quit dialog
 LOCATE 1, 3
 PRINT "     "
END SUB

'Produce random -1, 0, or 1-----------------------------------------------------
FUNCTION RandomDir
 n = INT(RND * 3)
 SELECT CASE n
  CASE 0
   RandomDir = 0
  CASE 1
   RandomDir = 1
  CASE 2
   RandomDir = -1
  CASE ELSE
   RandomDir = 0
 END SELECT
END FUNCTION

'Creates flashing border for intro screen. Courtesy of NIBBLES.BAS--------------
SUB SparklePause

 COLOR 10, 0
 a$ = "$    $    $    $    $    $    $    $    $    $    $    $    $    $    $    $    $    "
 WHILE INKEY$ <> "": WEND 'Clear keyboard buffer

 WHILE INKEY$ = ""
  FOR a = 1 TO 5
   LOCATE 1, 1                             'print horizontal sparkles
   PRINT MID$(a$, a, 80);
   LOCATE 22, 1
   PRINT MID$(a$, 6 - a, 80);

   FOR b = 2 TO 21                         'Print Vertical sparkles
    c = (a + b) MOD 5
    IF c = 1 THEN
     LOCATE b, 80
     PRINT "$";
     LOCATE 23 - b, 1
     PRINT "$";
    ELSE
     LOCATE b, 80
     PRINT " ";
     LOCATE 23 - b, 1
     PRINT " ";
    END IF
   NEXT b
  NEXT a
 WEND

END SUB

'Title screen-------------------------------------------------------------------
SUB TitleScreen

 CLS
 
 PLAY "MBT160O1L8CDE-CDL4E-" 'money money money

 LOCATE 5, 30
 COLOR 14, BGCOL
 PRINT "We've got to have..."
 LOCATE 6, 37
 COLOR 10
 PRINT "MONEY"
 
 CALL SparklePause
 
 'Player has pressed a key - clear title screen and take initial input
 CLS

 LOCATE 11, 30
 PRINT "Name"
 LOCATE 11, 34
 INPUT Plr.named
 LOCATE 13, 30
 COLOR 14
 PRINT "Welcome "; Plr.named; "!"
 LOCATE 14, 30
 PRINT "Press a key to begin!"

 WHILE INKEY$ = "": WEND
 
END SUB

'Toggle thing on or off---------------------------------------------------------
SUB ToggleThing (y, x, ttype, switchtf)
 IF switchtf = TRUE THEN Occupied(y, x) = Occupied(y, x) OR ttype
 IF switchtf = FALSE THEN Occupied(y, x) = Occupied(y, x) AND NOT ttype
END SUB

'Update the HUD-----------------------------------------------------------------
SUB UpdateHud
 COLOR 10, BGCOL
 LOCATE 2, 38
 PRINT USING "Remaining:$$##.##"; DlrRemVal!
 LOCATE 1, 58
 PRINT USING "&:$$###.##"; Plr.named; DollarCmtv!
 LOCATE 2, 58
 PRINT USING "Enemy:$$###.##"; DollarEnemy!
 COLOR 9, BGCOL
 LOCATE 2, 3
 PRINT USING "Lives:##"; Plr.lives
END SUB

