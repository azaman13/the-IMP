import processing.core.*; 
import processing.xml.*; 

import processing.opengl.*; 
import codeanticode.gsvideo.*; 
import processing.video.*; 
import processing.serial.*; 
import fullscreen.*; 
import deadpixel.keystone.*; 
import java.util.Random; 
import roombacomm.*; 
import edu.bard.drab.PCLT.*; 

import java.applet.*; 
import java.awt.*; 
import java.awt.image.*; 
import java.awt.event.*; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class Graffiti extends PApplet {

// The Graffiti sketch is a virtual graffiti wall. Users can draw with
// colored spraypaint on the surface of a virtual wall. Moving towards
// the edge of the screen will make the roomba go forwards or
// backwards. If the roomba is directed parallel to the wall, and the
// projected faced towards the wall, this makes it seem like the
// "drawings" stay in one place while the canvas moves to a new empty
// piece of wall. Moving back in the opposite direction will reveal what
// was drawn previously.


     


 






// CONFIGURATION PARAMETERS
boolean USE_KEYSTONE = false;
boolean USE_GSCAPTURE = false;
boolean USE_ROOMBA = false;

Keystone ks;
CornerPinSurface surface;
PGraphics offscreen;
PGraphics wall;
int position;

FullScreen fs;
// Needed for the movement of the servos
Serial port;

PCLT lt;

// This determines the size of the user's paint brush size
float paintSize = 5;
float SB  = 25;
int menuSize = 75;
int c = 848;
Random r;

String roombacommPort = "/dev/ttyS4"; // Port may need to be changed based on the user's settings
RoombaCommSerial roombacomm = new RoombaCommSerial();

public void setup() {
  if (USE_KEYSTONE){
    size(848, 480, P3D);
  }
  else{
    //size(848, 480, P2D);
    size(1024, 768, P2D);
  }

  r = new Random();
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

  wall = createGraphics(width*20, height, P2D);
  position = wall.width/2;

  try{  
  }
  catch(Exception e){
    e.printStackTrace();
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
    lt = new PCLT(this, surface, video);
  }

  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }
  wall.beginDraw();
  
  offscreen.smooth();
  offscreen.colorMode(HSB);
  offscreen.background(0);

  wall.smooth();
  wall.colorMode(HSB);
  wall.background(0);

  if (USE_KEYSTONE){
    offscreen.endDraw();
  }  
  wall.endDraw();

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
}

public void keyPressed(){
  if (key == ' ') {
    offscreen.background(0);
    wall.background(0);
  }
  else if (key == 'l') ks.load(System.getProperty("user.home")+"/keystone.xml");
}

PImage last;

public void laserPressed(LaserPoint p){
}

public void drawColorBar(){
  offscreen.noStroke();
  offscreen.fill(0);
  offscreen.rect(0, height - menuSize/2, width, menuSize/2);
  for (int i = 0; i < 256; i++){
    offscreen.fill(i, 255, 255);
    float x = map(i, 0, 255, 0, width);
    offscreen.rect(x, height - menuSize/2, width/255+1, menuSize/2);
  }
}

int speed = 0;

public void draw() {
  if ((frameCount % 20) == 0) println("frameRate:" + frameCount/(1+(millis()/1000)));

  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }

  int command = 0;
  // This loop checks where the Laser is in the screen and see whether it 
  // needs to move based on the laser's position in the projector coordinate
  for (int i = 0; i < lt.numOfPoints; i++){
    if (lt.points[i].y < (height - menuSize/2) &&  (lt.points[i].x < 300 || lt.points[i].x > width - 300)){
      command +=(lt.points[i].x - width/2); //+  (lt.points[i].x - lt.points[i].px);
    }
  }

  if (command > 350){
    speed = 75;
  }
  else if (command < -350){
    speed = -75;
  }
  else if (abs(speed) > 0){
    speed *= .3f;
  }

  // for debugging
  //println("speed:" + speed  + "," + position);
  // go as straigt as as possible, this particular  
  // speed of 1000000 is interesting becasue if the
  // user change this value even by 1 zero the robot 
  // do not move forward/backward in straight line

  if (USE_ROOMBA){

    roombacomm.drive(-speed,1000000); 

    // It takes data from the robot's odometry and  
    // moves the virtual wall based in the position
    position -= 1.8f*roombacomm.distance();
  }

  wall.beginDraw();    
  wall.pushMatrix();
  wall.translate(
  position, 0);
  wall.colorMode(HSB);
  for (int i = 0; i < lt.numOfPoints; i++){

    LaserPoint p = lt.points[i];
    if (p.y >= (height - menuSize/2))
    {
      c = p.x;
    }

    // This makes the random pattern of the spray paint
    if ((p.duration > 50) &&  (p.y < (height - menuSize/2))){
      int paints = PApplet.parseInt(random(250, 500));
      for (int j = 0; j < paints; j++){
        float s = (float)r.nextGaussian() + paintSize; 
        
        int col = color(map(c, 0, width, 0, 255), // H 
        (float)(200+r.nextGaussian()*SB),          // S
        255,                                       // B
        (float)(2*s + r.nextGaussian()*SB));       // A
        
        wall.noStroke();
        wall.fill(col);
        wall.ellipse(p.x + (float)(10*r.nextGaussian()), 
                     p.y + (float)(10*r.nextGaussian()), s, s) ;
      }
    }
  }
  wall.popMatrix();
  wall.endDraw();
  offscreen.background(0);
  offscreen.image(wall, -position, 0);

  drawColorBar();
  
  if (USE_KEYSTONE){
    offscreen.endDraw();
    background(0);
    surface.render(offscreen);
  }
}

public void stop (){
  if (USE_ROOMBA) roombacomm.stop();
}















































  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "Graffiti" });
  }
}
