// A mixed reality vacuuming game. One green laser controls the player
// vacuum's speed and direction. Red lasers can drag dirt object to/away
// from the player, and drop obstacles.


import codeanticode.gsvideo.*;
import processing.video.*;
import fullscreen.*; 
import roombacomm.*;
import deadpixel.keystone.*;
import edu.bard.drab.PCLT.*;

// CONFIGURATION PARAMETERS
boolean USE_KEYSTONE = false;
boolean USE_GSCAPTURE = false;
boolean USE_ROOMBA = false;

Keystone ks;
CornerPinSurface surface;
PGraphics offscreen;

String roombacommPort = "/dev/ttyS4";

RoombaCommSerial roombacomm = new RoombaCommSerial();
Player p1;

int MAXPARTICLES= 20;
int numOfParticles = 0;
Particle[] particles = new Particle[MAXPARTICLES];

int MAXDIRT = 25;
int amountOfDirt = 0;
Dirt[] dirts= new Dirt[MAXDIRT];

int MAXOBSTACLES= 3;
int numOfObstacles = 0;
Obstacle[] obstacles = new Obstacle[MAXOBSTACLES];

FullScreen fs;
Capture video;
PCLT lt;

float lastdrop; 
int l =0;


void setup() {
  if (USE_KEYSTONE){
    size(848, 480, P3D);
  }
  else{
    //size(848, 480, P2D);
    size(1280, 768, P2D);
  }

  p1= new Player();

  fs = new FullScreen(this); 
  fs.enter();

  if (USE_KEYSTONE){
    ks = new Keystone(this);
    surface = ks.createCornerPinSurface(width, height, 40);
    offscreen = createGraphics(width, height, P2D);
  }
  else{
    offscreen = this.g;
  }

  // Connects to the webcam
  if (USE_GSCAPTURE)
  {
    GSCapture video = new GSCapture(this, 640/4, 480/4, "/dev/video1");
    lt = new PCLT(this, surface, video);
  }
  else
  {
    Capture video = new Capture(this, 640/4, 480/4);
    lt = new PCLT(this, surface, color(0, 255, 0));
  }

  if (USE_ROOMBA){
    if( ! roombacomm.connect( roombacommPort ) ) {
      println("couldn't connect. goodbye.");  
      System.exit(1);
    }
    println("Roomba startup");
    roombacomm.startup();
    roombacomm.control();
    roombacomm.startAutoUpdate();
  }

  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }
  offscreen.textFont(createFont("Arial", 24));
  //offscreen.textAlign(CENTER, CENTER);
  if (USE_KEYSTONE){
    offscreen.endDraw();
  }
}

void keyPressed(){
  if (key == 's') saveFrame("roombasuck.jpg"); 

  else if (key == 'l') ks.load(System.getProperty("user.home")+"/keystone.xml");
}


void laserPressed(LaserPoint p)
{
}

void draw(){

  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }

  offscreen.translate(-p1.xpos + p1.onscreenX, -p1.ypos + p1.onscreenY);

  offscreen.translate(p1.xpos, p1.ypos);
  offscreen.rotate(-p1.direction);
  offscreen.translate(-p1.xpos, -p1.ypos);
  offscreen.background(255);
  offscreen.fill(0);
  //offscreen.text( "points: " + str(p1.points), worX(20, 420), worY(20, 420));
  
  //runs all the player functions
  p1.run();


  boolean drop=true;

  //This loops controls dragging dirt/obstacles, and dropping obstacles.
  for(int i=0; i< lt.numOfPoints; i++){
    drop=true;
    if (green(lt.points[i].c) != 255 ){  
      for (int j = 0; j < amountOfDirt; j ++){


        if (dirts[j].laserController != null){
          if(millis()-dirts[j].laserController.last_t > 300){
            dirts[j].laserController = null;
          }
          else{
            drop=false;
            dirts[j].move();
          }
        }
        else if(dirts[j].selected(lt.points[i]) ){
          dirts[j].laserController= lt.points[i];
          dirts[j].move();
          drop=false;
          println("selected "+ dirts[j].dirtscreenX + " "+ dirts[j].dirtscreenY);
        }
      }

      for (int k = 0; k < numOfObstacles; k ++){
        if (obstacles[k].laserController != null){
          if(millis()-obstacles[k].laserController.last_t > 300){
            obstacles[k].laserController = null;
          }
          else {
            drop=false;
            obstacles[k].move();
          }
        }
        else if(obstacles[k].selected(lt.points[i])){
          obstacles[k].laserController= lt.points[i];
          obstacles[k].move();

          drop=false;
        }

      }
      if(drop&& millis()-lastdrop>=2000){
        if (numOfObstacles== MAXOBSTACLES){
          obstacles[l].xpos = worX(lt.points[i].x, lt.points[i].y);
          obstacles[l].ypos = worY(lt.points[i].x, lt.points[i].y);
          l+=1;
          lastdrop= millis();
          if(l==numOfObstacles-1){
            l=0;
          }
        }

        else{
          Obstacle obs =new Obstacle(worX(lt.points[i].x, lt.points[i].y), worY(lt.points[i].x, lt.points[i].y) );
          obstacles[numOfObstacles] = obs;
          numOfObstacles += 1;
          drop= false;
          lastdrop= millis();
        }
      }
    }
  }

  if (numOfParticles < MAXPARTICLES && random(4)<1){
    Particle p =new Particle();
    particles[numOfParticles] = p;
    numOfParticles += 1;
  }
  for (int i = 0; i < numOfParticles; i ++){
    if( particles[i].dead()){
      numOfParticles-= 1;
      particles[i] = particles[numOfParticles];
    } 
    else{
      particles[i].display();
      particles[i].suck();
    }
  }
  //creates and controls Dirt around the player
  if (amountOfDirt < MAXDIRT && random(5)<1){
    Dirt di =new Dirt();
    dirts[amountOfDirt] = di;
    amountOfDirt += 1;
  }

  for (int i = 0; i < amountOfDirt; i ++){
    dirts[i].display();
    dirts[i].suck();
  }
  for (int i = 0; i < numOfObstacles; i ++){
    obstacles[i].display();
    obstacles[i].suck();
  }

  if (USE_KEYSTONE){
    offscreen.endDraw();
    background(0);
    surface.render(offscreen);
  }
}

void stop(){
  if (USE_ROOMBA) roombacomm.stop();
}



















