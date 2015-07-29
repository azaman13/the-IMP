
// This sketch contains the most important function of the IMP. 
// Calibrate's purpose is to find the homography that relates
// camera coordinates to the on-screen coordinates. It does this by using
// 4 known points from the projector in the camera's images. These four
// points are then used to find the homography. This allows us to find
// points (like lasers) in the camera, and accurately place them in the
// processing sketch. This information is stored in a file called
// calib.txt.
//
// Manual Calibration:
//
// * Press "c" to enter manual-calibration mode. 
//   ** In this mode, one must click (hover over a point for ~1 second
//      then turn off the laser) the designated corners in the order the
//      program asks for them.
//   ** It is often helpful to press "q" in this mode to see the camera
//      image and make sure the camera's field of view covers the entire
//      projection. If the camera cannot see a corner, you cannot click
//      it!
//   ** Once all four corners have been designated, "Calibration
//      Complete" will appear onscreen.
//   ** Press the spacebar to clear the screen and enter a test mode. In
//      this mode, try drawing with the laser and see how well the white
//      line tracks it.
//   ** If the line and the laser's path stay similar, press "w" to
//      write this calibration to a file and save it for your next
//      sketches.
//   ** If the laser and line do not seem to stay close, press "c" to
//      calibrate manulally again, or try the next method.
//
// Autmatic Calibration:
//
// * Press "a" to enter auto-calibtation mode. This mode will try to
//   automatically find the corners of the projection by projecting
//   white, taking a picture, using a blob(to find the projection),
//   difference finder (to find it's edges), Hough transform (to turn
//   the edges into lines), and line intersection(to turn the lines into
//   points).
// 
//   ** Once "a" is pressed, three images will appear onscreen. 
//   ** One shows the blobs found, one shows the edges of that region,
//      and a third shows the camera image overlayed with the line and
//      point guesses as to where the projectors edges/corners are.
//   ** This mode is extremely dependent on lighting conditions as well
//      as projection surface. The BRIGHTNESS variable in the
//      autoCalibrate file (inside Calibrate) can be raised or lowered
//      ( must be >0 and <1) based on lighting conditions to better
//      detect the projected white blob.
//   ** If the corners seem right, press space to enter the test mode
//      and "w" to save.
//
// Keystone Calibration
//
// * Once you have calibrated the comera and projector you can correct
//   for projector keystoning. Press 'k' to toggle keystone
//   calibration. Drag with the laser pointer, the four corners to their
//   desired locations.

import codeanticode.gsvideo.*;
import processing.video.*;
import processing.serial.*;
import deadpixel.keystone.*;
import fullscreen.*; 
import edu.bard.drab.PCLT.*;

// CONFIGURATION PARAMETERS
boolean USE_KEYSTONE = false;
boolean USE_GSCAPTURE = false;

FullScreen fs;
PCLT lt;

boolean showImage = false;

Keystone ks;
CornerPinSurface surface;
PGraphics offscreen, temp;

final int OFF_MODE = 0;
final int DRAW_MODE = 1;
final int AUTO_MODE = 2;
final int CALIB_MODE = 3;
final int KEY_MODE = 4;

// Initially the calibration mode is off mode becasue when the user runs the program he/she has to 
// pick which mode to use
int calibrateMode = OFF_MODE;
int autoTimer;
// Creates two array of PVectors that has all the four corners from camera image and projector image
PVector []cam = new PVector[4];
PVector []proj = new PVector[4];

// This section is used as manual calibration guide to calibrate
int calibPoint = 0;
String [] calibMessages = {
  "Click on the upper left", 
  "Click on the upper right", 
  "Click on the lower right", 
  "Click on the lower left", 
  "Calibration complete"};


void setup() {
  // We used 848X480 resolution because the projector we are using has this weired resolution
  if (USE_KEYSTONE){
    size(848, 480, P3D);
  }
  else{
    size(1024, 768, P2D);
  }

  fs = new FullScreen(this); 

  // This enables us to draw to an offscreen window becasue of the keystone library,
  // the offscreen drawing is desplayed by keystone later on a distorted surface
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

  if (this.g != offscreen){
    offscreen.beginDraw();
  }
  offscreen.stroke(0);
  offscreen.fill(0);
  offscreen.strokeWeight(10);
  offscreen.smooth();
  offscreen.textFont(createFont("Cortoba", 48));
  offscreen.background(255);
  if (this.g != offscreen){
    offscreen.endDraw();
  }

  // Creates an array of PVectors for projector which we later feed to the computerhomography() function
  proj[0] = new PVector(0, 0, 1);
  proj[1] = new PVector(width, 0, 1);
  proj[2] = new PVector(width, height, 1); 
  proj[3] = new PVector(0, height, 1);
  fs.enter(); 
}

void keyPressed(){
  // takes a screen shot of the running program, which can be used for making posters/ presentations
  if (key == 'p'){
    saveFrame("screenshot.png");
  }
  // key "a" of keyboard turn on auto calibration
  if (key == 'a'){
    offscreen.background(255);
    autoTimer = millis();
    calibrateMode = AUTO_MODE;
  }
  // key "c" of keyboard toggles manual calibration
  if (key == 'c') {
    startCalibration();
  }
  else if (calibrateMode == CALIB_MODE){
    stopCalibration();
  }

  // key "w" of keyboard saves the calibration points after the manual/auto calibration.  
  // Later on we read from this file and avoid constant calibration 
  if (key == 'w') {
    lt.getHomography().writeFile(System.getProperty("user.home")+"/calib.txt");
    offscreen.background(255);
    offscreen.fill(0);
    offscreen.text("Calibration saved", 50, 50);
  }
  // key "q" is for showing the camera image
  if (key == 'q') {
    showImage = !showImage;
    if (!showImage) offscreen.background(255);
  }

  // key "k" switches to keystone mode
  if (key == 'k'){
    ks.toggleCalibration();
    calibrateMode = KEY_MODE;
  }
  // Saves the keystone information to a file  
  if (key == 's'){
    ks.save("/home/bard360/theimp/keystone.xml");
    offscreen.background(255);
    offscreen.fill(0);
    offscreen.text("Keystone saved", 50, 50);
  }
  // Load the keyston informations from the saved files
  if (key == 'l'){
    ks.load(System.getProperty("user.home")+"/keystone.xml");
  }

  // Once calibration and keystoning are done hit "space" to see how well the camera senses the laser pointer
  if (key == ' '){
    offscreen.background(0);
    offscreen.stroke(255);
    offscreen.strokeWeight(3);
    calibrateMode = DRAW_MODE;
  }
}

void draw() {
  // Prints out the frame rate of the processing sketch
  if ((frameCount % 20) == 0) println("frameRate:" + frameCount/(1+(millis()/1000)));

  // if there is an offscreen buffer start drawing to it (used for keystone correction)
  if (USE_KEYSTONE){
    offscreen.beginDraw();
  }

  if (showImage){
    PImage img = lt.getImage();
    if (img != null) {
      offscreen.image(lt.getImage(), 50, 50, width-100, height-100);
    }
  }

  // Enables the user to draw
  if (calibrateMode == DRAW_MODE){
    for (int i = 0; i < lt.numOfPoints; i++){
      if (lt.points[i].duration > 50){
        offscreen.line(lt.points[i].px, lt.points[i].py, lt.points[i].x, lt.points[i].y);
      }
    }
  }

  // Runs auto calibrate
  else if (calibrateMode == AUTO_MODE || calibrateMode == OFF_MODE){
    offscreen.fill(255);
    offscreen.stroke(255);
    offscreen.rect(0, height-300, width, 100);
    offscreen.fill(0);
    BRIGHTNESS = mouseY/(2.5*height);
    offscreen.text("threshold:" + BRIGHTNESS, 50, height-200);
    // Runs auto calibrate
    if (calibrateMode == AUTO_MODE && millis() - autoTimer > 500){
      cam = autoCalibrate(lt.getImage());
      int numGoodPoints = 0;
      for (int i = 0; i < cam.length; i++){
        if (cam[i] != null) numGoodPoints ++;
      }
      // sends the list of PVectors of camera and projector to compute the homography matrix 
      if (numGoodPoints == 4){
        lt.computeHomography(cam, proj);
      } 
      calibrateMode = OFF_MODE;
    }
  }
  // Checks if you are in keystone mode. If you are, it then creates  
  // four circles at four corners so that it is easier to drag the cornrs
  else if (calibrateMode == KEY_MODE){
    offscreen.ellipse(width/2, height/2, 200, 200);
    for (int i = 0; i < lt.numOfPoints; i++){
      if (lt.points[i].duration > 0){
        float x = lt.points[i].ux;
        float y = lt.points[i].uy;
        Draggable dragged = surface.select(x, y);
        if (dragged != null){
          dragged.moveTo(x, y);
        }
      }
    }
  }

  // this is true when we are not in Keystone mode
  if (USE_KEYSTONE){
    offscreen.endDraw();
    background(0);
    surface.render(offscreen);
  }
}

// The laser pressed method is only called when there is an active laser point
void laserPressed(LaserPoint p){

  if (calibrateMode == CALIB_MODE){
    // save this calibration point and move on to the next. At the same time it guides the user during  
    // manual calibration by printing out in the screen in which corners he/she should point the laser 
    cam[calibPoint] = new PVector(p.cx, p.cy, 1);
    calibPoint = calibPoint + 1;
    offscreen.background(255);
    offscreen.fill(0);
    offscreen.text(calibMessages[calibPoint], 50, 45);
    // If we have four suitable points then we compute the homography
    if (calibPoint > 3){
      lt.getHomography().computeHomography(cam, proj);
      stopCalibration();
    }
  }
}
// This method prints out the calibration messages only if the user is in calibration mode
void startCalibration(){
  calibPoint = 0;
  calibrateMode = CALIB_MODE;
  showImage = true;
  offscreen.background(255);
  offscreen.fill(0);
  offscreen.text(calibMessages[calibPoint], 50, 45);
}

// If we have four points in our PVector array (the corners) while calibrating then stop the calibration mode
void stopCalibration(){
  calibPoint = 0;
  calibrateMode = DRAW_MODE;
  showImage = false;
  offscreen.background(0);
}


















