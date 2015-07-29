// A simple example using the laser tracker to draw lines.

import processing.video.*;
import codeanticode.gsvideo.*;      
import fullscreen.*; 
import edu.bard.drab.PCLT.*;

// CONFIGURATION PARAMETERS
boolean USE_GSCAPTURE = false;

FullScreen fs; 
PCLT lt;

void setup() {
  size(1024, 768, P2D);
  fs = new FullScreen(this); 

  //This section gets video from the camera and applies the homography matrix to the laser points found.
  if (USE_GSCAPTURE){
    GSCapture video = new GSCapture(this, 640/4, 480/4, "/dev/video1");
    lt = new PCLT(this,  null, video);
  }
  else{
    Capture video = new Capture(this, 640/4, 480/4);
    lt = new PCLT(this, null, video);
  }

  background(0);
  fill(255);
  stroke(255);
  fs.enter(); 
}

void keyPressed(){
  background(0);
}

void draw() {
  if (lt.pressed()){
    line(lt.px(), lt.py(), lt.x(), lt.y());
  }
}














