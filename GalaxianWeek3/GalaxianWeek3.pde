import sprites.utils.*;
import sprites.maths.*;
import sprites.*;

// Game Configuration Varaibles
int monsterCols = 10;
int monsterRows = 5;
long mmCounter = 0;
int mmStep = 1;
int pointsPerKill = 10;
int pointsPerBoard = 100;

//Game Operational Variables
Sprite rocket;
Sprite ship;
Sprite monster;
Sprite monsters[][] = new Sprite[monsterCols][monsterRows];
boolean cheat = false;
int points = 0;
Sprite flyingMonster;
int timeToAdd = -1;
int DELAY = 2000;
double fmRightAngle = 0.3490; // 20 degrees
double fmLeftAngle = 2.79253; // 160 degrees
double fmSpeed = 150;
int difficulty = 150;
int timer = 0;
KeyboardController kbController = new KeyboardController(this);
StopWatch stopWatch = new StopWatch();

SoundPlayer sound;
SoundPlayer soundE;

public void setup()
{
  size(700, 500);
  frameRate(50);

  sound = new SoundPlayer(this);
  buildSprites();
  resetMonsters();
  registerMethod("pre", this);
  timeToAdd = millis();
}

void buildSprites()
{
  ship = buildShip();
  buildMonsterGrid();
  rocket = buildRocket();
}

Sprite buildShip()
{ 
  ship = new Sprite(this, "ship.png", 1, 1, 50);
  ship.setXY(width/2, height - 30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(.75);
  ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);
  return ship;
}

Sprite buildRocket() {
  rocket = new Sprite(this, "rocket.png", 1, 1, 50);
  rocket.setXY(width/2,height-30);
  rocket.setDead(true);
  return rocket;
}

void buildMonsterGrid()
{
   for (int idx = 0; idx < monsterCols; idx++ )
   {
    for (int idy = 0; idy < monsterRows; idy++ )
    {
      monsters[idx][idy] = buildMonster();
    }
  }
}

Sprite buildMonster()
{
  monster = new Sprite(this, "monster.png", 1, 1, 30);
  monster.setScale(0.5);
  monster.setDead(false);
  return monster;
}

void resetMonsters() 
{
  for (int idx = 0; idx < monsterCols; idx++ ) {
    for (int idy = 0; idy < monsterRows; idy++ ) {
      Sprite monster = monsters[idx][idy];
      double mwidth = monster.getWidth() + 20;
      double totalWidth = mwidth * monsterCols;
      double start = (width - totalWidth)/2 - 25;
      double mheight = monster.getHeight();  
      monster.setXY((idx*mwidth)+start, (idy*mheight)+50);
      // Re-enable monsters that were previously marked dead.
      monster.setDead(false);
    }
  }
  mmCounter = 0;
  mmStep = 1;
}

void pre()
{
  timer--;
  checkKeys();
  S4P.updateSprites(stopWatch.getElapsedTime());
  moveMonsters();
  processCollisions();
  if ((flyingMonster == null || flyingMonster.isDead()) && millis() > (timeToAdd + DELAY)) {
    flyingMonster = pickNonDead();
    if (flyingMonster == null) {
      buildMonsterGrid();
      resetMonsters();
      timeToAdd = millis();
    } else {
      flyingMonster.setSpeed(fmSpeed, SetRightOrLeft());
      flyingMonster.setDomain(0, 0, width, height+100, Sprite.REBOUND);
      timeToAdd = millis();
    }
  }
}

double SetRightOrLeft()
{
  double direction;
  if(int (random(2)) ==1)
    direction = fmRightAngle;
  else
    direction = fmLeftAngle;
  return direction;
}

void moveMonsters() 
{
  if((++mmCounter % 100) == 0)
  mmStep *= -1;

  for(int idx = 0; idx<monsterCols; idx++)
  {
    for(int idy = 0; idy<monsterRows; idy++)
    {
      Sprite monster = monsters[idx][idy];
      if (!monster.isDead() && monster != flyingMonster)
      {
        monster.setXY(monster.getX()+mmStep, monster.getY());
      }
    }
  }
  
  if(flyingMonster != null)
  {
    if(int(random(difficulty))== 1)
    {
     //Changes Speed. Change Random values either higher or lower as needed.
     flyingMonster.setSpeed(flyingMonster.getSpeed() +random(-25,25));
      
     //Changes direction.
      if(flyingMonster.getDirection() == fmRightAngle)
        flyingMonster.setDirection(fmLeftAngle);
      else
        flyingMonster.setDirection(fmRightAngle);
    }
  }
}
void fireRocket() {
  if (rocket.isDead()) {
    sound.playPop();
    rocket.setXY(ship.getX(), ship.getY() - 10);
    rocket.setVelXY(0.0f, -300.0f);
    rocket.setDead(false);
  } else {
    // Do nothing. rocket launched already
  }
}

void checkKeys()
{
  if (focused) {
      if (kbController.leftArrow.pressed()) {
        ship.setX(ship.getX()-10);
      }
      if (kbController.rightArrow.pressed()) {
        ship.setX(ship.getX()+10);
      }
      if (kbController.spaceBtn.pressed()) {
        fireRocket();
      }
      if (kbController.upArrow.pressed()) {
        if (timer < 0) {
          if (pickNonDead() != null) {
            pickNonDead().setDead(true);
            timer = 5;
          }
        }
      }
  }
}
void draw() {
  background(0);
  S4P.drawSprites();
  text(points + " pts.", 10, 10);
}

void explodingShip() {
    PImage img;
    img = loadImage("explosion_strip16.png");
    soundE.playExplosion();  
}

void processCollisions() {
  if (! rocket.isDead()) {
     if (! rocket.isOnScreem()) {
       rocket.setDead(true);
     }

    outerloop1:
    for (int idx = 0; idx < monsterCols; idx++)
    {
      for (int idy = 0; idy < monsterRows; idy++)
      {
        monster = monsters[idx][idy];
        if (!monster.isDead() && rocket.cc_collision(monster))   
        {
          points += pointsPerKill;
          monster.setDead(true);
          rocket.setDead(true);
          break outerloop1;
        }
        else if (!monster.isDead() && ship.cc_collision(monster))
        {
           monster.setDead(true);
           ship.setDead(true);
           explodingShip();
           break outerloop1;
        }

      }
    }
  }
  // if flying monster is off screen
  if(flyingMonster != null && !flyingMonster.isOnScreem()) {
    flyingMonster.setDead(true);
    flyingMonster = null;
  }
}

Sprite pickNonDead() {
  for (int idy = monsterRows - 1; idy >= 0; idy--) {
    for (int idx = monsterCols - 1; idx >= 0; idx--) {
      if (! monsters[idx][idy].isDead()) {
        return monsters[idx][idy];
      }
    }
  }
  return null;
}
