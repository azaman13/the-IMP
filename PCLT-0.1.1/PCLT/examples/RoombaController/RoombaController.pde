// The RoombaController sketch contains a simple interface for interaction 
// with the iRobotCreate.
//
// * The four green blocks display the status of the robot's cliff and
//   bump sensors. They will turn red when activated.
// * The four arrows move the roomba
// * The central circle stops the roomba.
// * The right scale of rectangles will make the roomba beep
// * The left rectangle will change the roomba's current
//   speed. Clicking higher will make it faster, lower slower.
// * This sketch will only track one laser pointer at a time, any
//   others will be ignored.
//

import roombacomm.*;
import roombacomm.net.*;
import fullscreen.*; 
import deadpixel.keystone.*;
import processing.video.*;

import codeanticode.gsvideo.*;      
import edu.bard.drab.PCLT.*;


// CONFIGURATION PARAMETERS
boolean USE_KEYSTONE = false;
boolean USE_GSCAPTURE = false;
boolean USE_ROOMBA = false;

FullScreen fs; 

GSCapture video;
PCLT lt;

// connects to the robot
String roombacommPort = "/dev/ttyS4";
Keystone ks;
PGraphics offscreen;
CornerPinSurface surface;

RoombaCommSerial roombacomm = new RoombaCommSerial();

// The following block of codes assigns several 
// constant values to the robot movement
int DEFAULT_SPEED = 75;
int STRAIGHT = 1000000;
int RIGHT_TURN = -100;
int LEFT_TURN  = 100;
int speed = 0;
int radius = 0;
int Y;

void setup(){

  if (USE_KEYSTONE){
    size(848, 480, P3D);
  }
  else{
    size(848, 480);
  }

  fs = new FullScreen(this); 

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
    lt = new PCLT(this, surface, video);
  }

  if (USE_ROOMBA){

    // Connect to the robot
    if( ! roombacomm.connect( roombacommPort ) ) {
      println("couldn't connect. goodbye.");  
      System.exit(1);
    }

    roombacomm.startup();
    roombacomm.control();
    roombacomm.startAutoUpdate();
  }

  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }
  offscreen.background(200);
  offscreen.smooth();
  offscreen.textFont(createFont("LucidaSans", 16));
  if (this.g != offscreen){
    offscreen.endDraw();
  }

  //fs.enter(); 
}

void drawArrow(){
  offscreen.fill(0);
  offscreen.noStroke();
  offscreen.beginShape();
  offscreen.vertex(0,-14);
  offscreen.vertex(8, 0);
  offscreen.vertex(4,0);
  offscreen.vertex(4, 8);
  offscreen.vertex(-4, 8);
  offscreen.vertex(-4,0);
  offscreen.vertex( -8,0);
  offscreen.endShape();
}


int arrowSize = 8;

void draw(){

  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }

  // Prints the texts on the controller window
  offscreen.background(255);
  offscreen.fill(0);
  offscreen.text("left bump \nsensor", width/4, (height/2 - 160)+ 60 );
  offscreen.text("right bump \nsensor", 2.6*(width/4), (height/2 - 160)+ 60 );
  offscreen.text("Cliff-left", width/4 + 10, height-60);
  offscreen.text("Cliff-right", 2.6*(width/4) + 8, height-60);
  offscreen.text("Battery", width-250, 60);
  offscreen.text("Beeping Scale", width-125, 475);
  offscreen.text("speed scale", 25, 470);


  // for debugging
  if ((frameCount % 20) == 0) println("frameRate:" + frameCount/(1+(millis()/1000)));

  if (this.g != offscreen){
    offscreen.beginDraw();
  }

  // forward
  offscreen.pushMatrix();
  offscreen.scale(arrowSize,arrowSize);
  offscreen.translate(width/2/arrowSize, 1*height/4/arrowSize);
  offscreen.rotate(radians(0));
  drawArrow();
  offscreen.popMatrix();

  // backward
  offscreen.pushMatrix();
  offscreen.scale(arrowSize,arrowSize);
  offscreen.translate(width/2/arrowSize, 3*height/4/arrowSize);
  offscreen.rotate(radians(180));
  drawArrow();
  offscreen.popMatrix();

  // turn Right
  offscreen.pushMatrix();
  offscreen.scale(arrowSize,arrowSize);
  offscreen.translate(11*width/16/arrowSize, 2*height/4/arrowSize);
  offscreen.rotate(radians(90));
  drawArrow();
  offscreen.popMatrix();

  // Turn left
  offscreen.pushMatrix();
  offscreen.scale(arrowSize,arrowSize);
  offscreen.translate(5*width/16/arrowSize, 2*height/4/arrowSize);
  offscreen.rotate(radians(270));
  drawArrow();
  offscreen.popMatrix();


  // Draw the stop sign
  offscreen.fill(255, 12,12);
  offscreen.ellipse(width/2,height/2, 150, 100);

  //check forward
  if(lt.numOfPoints > 0){
    // Checks whether laser is pressed in the region of   
    // the window where the robot will move forward 
    if((lt.points[0].x > width/2 - 37 && lt.points[0].x < width/2 + 37)
      &&(lt.points[0].y> height/4 - 82 && lt.points[0].y < height/4 + 55)){
      println("moving forward");
      speed = DEFAULT_SPEED;
      radius = STRAIGHT;
    }

    // Checks whether laser is pressed in the region of   
    // the window where the robot will move backward 
    else if((lt.points[0].x > width/2 - 37 && lt.points[0].x < width/2 + 37) 
      &&(lt.points[0].y > 3*height/4 - 61 && lt.points[0].y < 3*height/4 + 80)){
      println("moving backward" + width/2 + height/4);
      speed = -DEFAULT_SPEED;
      radius = STRAIGHT;
    }

    // check right
    else if((lt.points[0].x > 11*width/16 - 69 && lt.points[0].x < 11*width/16 + 80) 
      &&(lt.points[0].y > 2*height/4 - 30 && lt.points[0].y < 2*height/4 + 30)){
      println("turining right");
      speed = DEFAULT_SPEED;
      radius = RIGHT_TURN;
    }

    //check left
    else if((lt.points[0].x > 5*width/16 - 69  && lt.points[0].x < 5*width/16 + 80 ) 
      &&(lt.points[0].y > 2*height/4 - 30 && lt.points[0].y < 2*height/4 + 30)){
      println("turning left"); 
      speed = DEFAULT_SPEED;
      radius = LEFT_TURN;
    } 
    else {
      // default speed
      speed *= 0.5;
    }

    // stop check 
    if((lt.points[0].x > width/2 - 75 && lt.points[0].x <  width/2 + 75) 
      && (lt.points[0].y > height/2 -50 && lt.points[0].y < height/2 + 50)){    
      println("stop pressed");
      offscreen.fill(0, 255, 0);
      offscreen.ellipse(width/2,height/2, 150, 100);
      speed *= 0.5;
    }
  }
  else {
    speed *= 0.5;
  }

  if (USE_ROOMBA){
    roombacomm.drive(speed, radius);
  }
 
  offscreen.stroke(0, 0, 255);
  offscreen.fill(200);
  offscreen.rect(25,50,50, 390 );
  offscreen.stroke(255);


  if(lt.numOfPoints > 0){
    Y = lt.points[0].y;
    offscreen.rect(20, Y, 60, 20);
    if((lt.points[0].x > 25) && (lt.points[0].x < 50 ) &&( lt.points[0].y >50) && (lt.points[0].y<390)){      
      int s = int(map(Y, 50, 390, 500, 50));
      DEFAULT_SPEED = s;
      // YOU HAVE TO CLICK ON THE SPEED MANUE TO SEE YOUR SPEED
      // Speed selection indicator
      offscreen.fill(255,0,0);
    }
  }

  // battery
  offscreen.stroke(0, 0, 255);
  offscreen.noFill();
  offscreen.strokeWeight(5);
  offscreen.rect(width-250, 15, 200, 25); // 4*width/2/arrowSize, 6*height/2/arrowSize
  offscreen.strokeWeight(1);
  float g = map(roombacomm.charge(), 0, 65535, 255,0);
  float r = map(roombacomm.charge(), 0, 65535, 0,255);
  offscreen.fill(int(r),int( g), 0);
  // draws the green rectangle of the battery depending on 
  // the remaining battery in the real robot  
  offscreen.rect(map(roombacomm.charge(), 0, 65535, width-250, width-50), 18,
  (width-52 - map(roombacomm.charge(), 0, 65535, width-250, width-50)), 20);
  offscreen.fill(0);
  offscreen.stroke(255);

  // Checks left bump
  offscreen.stroke(255,0,0);
  offscreen.fill(5, 20, 255);
  offscreen.noStroke();
  if(roombacomm.bumpLeft()){
    offscreen.fill(255, 0,0);
    // Debugging
    println("ops did I bump to my right?");
  }
  else{
    offscreen.fill(0, 255,0);

  }
  offscreen.rect(width/4, height/2 - 160, 80, 40);

  // Check right bump 
  offscreen.stroke(255,0,0);
  offscreen.fill(5, 20, 255);
  offscreen.fill(255);
  offscreen.stroke(255);
  if(roombacomm.bumpRight()){
    offscreen.fill(255, 0,0);
    // for debugging
    println("ops did I bump to my right?");
  }
  else{
    offscreen.fill(0, 255,0);
  }
  offscreen.rect(2.6*(width/4), height/2 - 160, 80, 40);


  // check left cliff sensor
  offscreen.stroke(255,0,0);
  offscreen.fill(5, 20, 255);
  offscreen.fill(255);
  offscreen.stroke(0);
  if(roombacomm.cliffLeft()){
    offscreen.fill(255,0,0);
  }
  else{
    offscreen.fill(0, 255,0);
  }
  offscreen.rect(width/4, height-150, 70, 70);



  // check right cliff sensor
  offscreen.stroke(255,0,0);
  offscreen.fill(0, 20, 255);
  offscreen.fill(255);
  offscreen.stroke(255);
  if(roombacomm.cliffRight()){
    offscreen.fill(255,0,0);
  }
  else{
    offscreen.fill(0, 255,0);
  }
  offscreen.rect(2.6*(width/4), height-150, 70, 70);
  offscreen.stroke(255);
  for(int j = 50; j < 420; j = j+10){
    offscreen.fill(map(j, 50, 420, 0, 225));
    offscreen.rect(width-75, j, 50, 30);
  }

  // check beeping scale
  if(lt.numOfPoints > 0){
    if((lt.points[0].x > width-75 && lt.points[0].x < width-75 + 50) &&( lt.points[0].y >50 && lt.points[0].y<420)){
      int duration = 4;
      int note = int(map(lt.points[0].y, 52, 443, 31, 127));
      roombacomm.playNote(note, duration); 
    }

    fill(255);
    stroke(255);
    ellipse(lt.points[0].x, lt.points[0].y, 10, 10);
  }

  if (USE_KEYSTONE){
    offscreen.endDraw();
    background(0);
    surface.render(offscreen);
  }

}









