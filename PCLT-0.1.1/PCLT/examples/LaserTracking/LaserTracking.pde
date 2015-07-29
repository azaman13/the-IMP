// The LaserTracking sketch is a painting demo.  LaserTracking is a demo
// that allows users to draw with lines, circles,and rectangles in
// varying colors and strokes.
//
// * The menu on the top-left selects the drawing tool:
//   ** The top lets the user draw with free lines
//   ** The second box is point-to-point lines (unclick laser to set)
//   ** The third is circles
//   ** Fourth is rectangles
//   ** Bottom clears screen
// * Clicking the bottom color bar selects a new color to draw in.
// * Clicking the right bar sets the stroke width.


import processing.opengl.*;
import processing.video.*;
import codeanticode.gsvideo.*;      
import processing.serial.*;
import fullscreen.*; 
import deadpixel.keystone.*;
import edu.bard.drab.PCLT.*;

// CONFIGURATION PARAMETERS
boolean USE_KEYSTONE = false;
boolean USE_GSCAPTURE = false;

// Keystone correction
Keystone ks;
CornerPinSurface surface;
PGraphics offscreen;

FullScreen fs; 

PCLT lt;
Serial port;

PImage last; // last image drawn

int menuSize = 75;
int mode = 0;         //current mode
int options = 0;      // number of options

final int PEN = options++;
final int LINE = options++;
final int CIRCLE = options++;
final int RECT = options++;
final int CLEAR = options++;

// the stroke weight control parameterssw =

float sbc=270;

int c = color(255, 255, 255); // color of the pen

int centerx, centery; // center of current shape being drawn

void setup() {
  if (USE_KEYSTONE){
    size(848, 480, P3D);
  }
  else{
    size(1024, 768, P2D);
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

  //This section gets video from the camera and applies the homography matrix to the laser points found.
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


  // open serial port to control pan/tilt arduino program
  try{
    //port = new Serial(this, Serial.list()[0], 9600);  
  }
  catch(Exception e){
    e.printStackTrace();
  }

  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }
  offscreen.stroke(0);
  offscreen.fill(0);
  offscreen.smooth();
  offscreen.textFont(createFont("Cortoba", 48));
  offscreen.colorMode(HSB);
  offscreen.fill(255);
  offscreen.stroke(255);
  offscreen.background(0);
  offscreen.rectMode(CENTER);

  if (USE_KEYSTONE){
    offscreen.endDraw();
  }

  fs.enter(); 
}

// if space is pressed, clear the screen, l to load keystone settings
void keyPressed(){
  if (key == ' ')      offscreen.background(0);
  else if (key == 'l') ks.load(System.getProperty("user.home")+"/keystone.xml");
}


//this function is only called when a laser is found.
void laserPressed(LaserPoint p){
  if (p.x < menuSize && p.y < height - menuSize/2){
    // Checks if laser is in the menu, changes modes according to y position.
    int omode = (p.y - menuSize/2) / menuSize;
    println("Switching modes to " + omode);
    if (omode == CLEAR){        
      offscreen.background(0);
    }
    else if (omode < options){
      mode = omode;
    }
  }
  else if (p.y >= height - menuSize)
  {
    //Checks if laser is in the color bar, and sets the color.
    c = p.x;
  }
  else if (p.y>=menuSize && p.y <= height-menuSize && p.x >=width-menuSize){
    //checks if laser is in the stroke weight bar, and maps the stroke weight based on y position.sw
    sbc = p.y;
  }
}

void drawMenu(){

  offscreen.strokeWeight(2);

  offscreen.fill(24);
  offscreen.stroke(24);
  offscreen.rect(menuSize/2, menuSize/2 + (menuSize*options)/2, menuSize, menuSize*options);

  for (int i = 0; i < options; i++){
    int x = menuSize/2 + 3;
    int y = menuSize + i * menuSize;

    offscreen.stroke(255);
    if (i == mode){
      offscreen.fill(map(c, 0, width, 0, 255), 255, 255, 128);
    } 
    else{
      offscreen.noFill();
    }

    offscreen.rect(x, y, menuSize, menuSize);
    offscreen.noFill();

    // free pen
    if (i == PEN){
      offscreen.line(x + menuSize/3, y - menuSize/3, x - menuSize/5, y - menuSize/5);
      offscreen.line(x, y, x + menuSize/5, y + menuSize/5);
      offscreen.line(x, y, x + menuSize/3, y - menuSize/3);
    }
    // line
    else if (i == LINE){
      offscreen.noFill();
      offscreen.line(x - menuSize/3, y + menuSize/3, x + menuSize/3, y - menuSize/3);
    }
    // circle
    else if (i == CIRCLE){
      offscreen.noFill();
      offscreen.ellipse(x, y, menuSize/2, menuSize/2);
    }
    // rectangle
    else if (i == RECT){
      offscreen.noFill();
      offscreen.rect(x, y, menuSize/2, menuSize/2);
    }

  }

  //offscreen.strokeWeight(5);
}


void drawColorBar(){
  offscreen.noStroke();
  offscreen.fill(0);
  offscreen.rect(0, height - menuSize/2, width, menuSize/2);
  for (int i = 0; i < 256; i++){
    offscreen.fill(i, 255, 255);
    float x = map(i, 0, 255, 0, width);
    offscreen.rect(x, height - menuSize/2, width/255+1, menuSize/2);
  }
}

void drawWeightBar(){
  pushMatrix();
  translate(width-menuSize, 0);
  offscreen.fill(0);
  offscreen.rectMode(CORNERS);
  offscreen.rect(-menuSize, 0, menuSize, height); 
  offscreen.strokeWeight(3);
  offscreen.stroke(255);
  offscreen.noFill();
  offscreen.beginShape();
  offscreen.vertex(0, menuSize);
  offscreen.vertex(40, menuSize);
  offscreen.vertex(24, height-menuSize);
  offscreen.vertex(16, height-menuSize);
  offscreen.vertex(00, menuSize);
  offscreen.endShape();
  offscreen.rectMode(CENTER);
  offscreen.rect(menuSize/4, int(sbc), menuSize, menuSize/4);

  popMatrix();
}

void draw() {
  // for debugging
  if ((frameCount % 20) == 0) println("frameRate:" + frameCount/(1+(millis()/1000)));

  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }

  drawMenu();
  drawColorBar();
  drawWeightBar();

  // Required for the movement of the servos in response to the mouse position
  if (key == 's'){
    offscreen.background(0);
    offscreen.stroke(255);
    offscreen.line(width/2, 0, width/2, height);
    offscreen.line(0, .9*height, width, .9*height);
    if (mousePressed){
      if (port != null){
        port.write(int(map(mouseX, 0, width, 127, 0)));
        port.write(int(map(mouseY, 0, height, 255, 128)));
      }
    }
  }

  offscreen.stroke(map(c, 0, width, 0, 255), 255, 255);
  offscreen.noFill();
  offscreen.strokeWeight(int(map(sbc, menuSize, height-menuSize, 25, 1)));

  // Loops through all the points and draws based on what mode is selected like free pen, line, rectangle etc.
  for (int i = 0; i < lt.numOfPoints; i++){
    LaserPoint p = lt.points[i];
    if ((p.duration > 50) && (p.x > menuSize) && (p.y < (height - menuSize/2))){
      if (mode == PEN){
        offscreen.line(p.px, p.py, p.x, p.y);
      }
      else if (p.duration < 300){
        // new shape: save the center location and grab a snapshot of what the screen looks like
        centerx = p.x;
        centery = p.y;
        last = get(0, 0, width, height);
      }
      else{
        if (last != null) offscreen.image(last, 0, 0, last.width, last.height);
        if (mode == LINE){
          offscreen.line(centerx, centery, p.x, p.y);
        }
        if (mode == CIRCLE){
          offscreen.ellipse(centerx, centery, 2*abs(p.x - centerx), 2*abs(p.y - centery));
        }
        if (mode == RECT){
          offscreen.rect(centerx, centery, 2*abs(p.x - centerx), 2*abs(p.y - centery));
        }
      }
    }
  }

  if (USE_KEYSTONE){
    offscreen.endDraw();
    background(0);
    surface.render(offscreen);
  }
}











