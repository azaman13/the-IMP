package edu.bard.drab.PCLT;

import java.lang.reflect.Method;

import processing.core.*;
import processing.video.*;
import codeanticode.gsvideo.*;
import deadpixel.keystone.*;

/**
 * The PCLT object is used to track laser points in a video source such as a webcam
 * and transform them into the coordinate system of the processing sketch. This
 * way the laser pointers can act like mouse pointers.
 * 
 * @author Keith O'Hara, Anis Zaman, Aaron Strauss
 */

public class PCLT{

	/**
	 * maximum number of points that can be tracked at one time
	 */
	final static int MAX_LASER_POINTS=100;

	/**
	 * threshold for how many pixels a laser can be from its previous location to be 
	 * considered the same track
	 */
	final static int MAX_DISTANCE = 35;

	/**
	 * threshold in milliseconds for a laser track to be considered dead
	 */
	final static int OFF_TIME = 150;

	/**
	 * minimum threshold for deciding if the laser has been "clicked"
	 */
	final static int MIN_CLICK_TIME = 300;

	/**
	 * maximum threshold for deciding if the laser has been "clicked"
	 */
	final static int MAX_CLICK_TIME = 2000;

	/**
	 * whether the PCLT will display debug messages
	 */
	public boolean DEBUG = false;

	/**
	 * array of laser points being tracked
	 */
	public LaserPoint[] points = new LaserPoint[MAX_LASER_POINTS];

	/**
	 * number of lasers currently being tracked
	 */
	public int numOfPoints = 0;

	/**
	 * processing parent
	 */
	private PApplet parent;
	
	/**
	 * surface used for keystone correction
	 */
	private CornerPinSurface surface;
	
	/**
	 * GSCapture video source
	 */
	private GSCapture video;
	
	/**
	 * capture video source
	 */
	private Capture macVideo;
	
	/**
	 * last image being analyzed
	 */
	private PImage img;
	
	/**
	 * laserPressed callback
	 */
	private Method laserEventMethod;

	/**
	 * the screen width
	 */
	private int screenWidth = 848;

	/**
	 * the screen height
	 */
	private int screenHeight = 480;

	/**
	 * FakeLaserTracker variables
	 */
	int c;
	boolean state= false;
	boolean FAKETRACKING = false;

	/**
	 * the laser tracking homography - relates camera coordinates to screen coordinates
	 */
	private Homography h;

	/**
	 * Create a Laser Tracker using a GSCapture device (linux)
	 * @param p the processing parent
	 * @param s the keystone surface
	 * @param v the video capture device
	 */
	public PCLT(PApplet p, CornerPinSurface s, GSCapture v) {
		startup(p,s);
		video = v;
		try {
			h.loadFile(System.getProperty("user.home")+"/calib.txt");
			//h.loadFile("calib.txt");

		}
		catch(Exception e){
			System.out.println("calibration file not found" + e);
		}


	}

	/**
	 * Create a Laser Tracker using a Capture device (mac and windows)
	 * @param p the processing parent
	 * @param s the keystone surface
	 * @param v the video capture device
	 */	public PCLT(PApplet p, CornerPinSurface s, Capture v) {
		 startup(p,s);
		 macVideo = v;
		 try {
			 h.loadFile(System.getProperty("user.home")+"/calib.txt");
			 //h.loadFile("calib.txt");

		 }
		 catch(Exception e){
			 System.out.println("calibration file not found" + e);
		 }
	 }

	 /**
	  * Create a (fake) Laser Tracker using the mouse
	  * @param p the processing parent
	  * @param s the keystone surface
	  * @param c the color of the fake laser
	  */	
	 public PCLT(PApplet p, CornerPinSurface s, int c) {
		 startup(p,s);
		 this.c = c;
		 FAKETRACKING = true;
	 }


	 /**
	  * Method is called before every draw() call
	  * Analyze the video frame; looking for laser pointers
	  */
	 public void pre(){
		 if (macVideo != null){
			 if (macVideo.available()) {
				 macVideo.read();
				 img = macVideo.get();
			 }
		 }
		 else if (video != null){
			 if (video.available()){
				 video.read();
				 img = video.get();
			 }
		 }
		 if (img != null) findLaser(img);
		 else if (FAKETRACKING) fakeFindLaser();

	 }

	 /**
	  * Helper method for constructors; sets up the laserPressed callback
	  * @param p
	  * @param s
	  */
	 void startup(PApplet p, CornerPinSurface s){
		 parent = p;
		 surface = s;
		 screenWidth = parent.width;
		 screenHeight = parent.height;
		 h = new Homography(parent);
		 try {
			 laserEventMethod = parent.getClass().getMethod("laserPressed", new Class[]{
					 LaserPoint.class 
			 });
		 }
		 catch( Exception e){
			 System.out.println("Couldn't register laserPressed callback method " + e);
		 }
		 parent.registerPre(this);

	 }

	 /**
	  * 
	  * @return the last image processed
	  */
	 public PImage getImage(){
		 return img;
	 }

	 /**
	  * call the callback if one exists
	  * @param p laser point
	  */
	 public void laserPressed(LaserPoint p){
		 if(laserEventMethod != null){
			 try{
				 laserEventMethod.invoke(parent, new Object[]{
						 p
				 });
			 }
			 catch(Exception e){
				 System.err.println("No laserPressed method");
				 laserEventMethod= null;
			 }
		 }
	 }

	 /**
	  * @return first laser point's x coordinate
	  */
	 public int x(){
		 return points[0].x;
	 }
	 
	 /**
	  * @return first laser point's y coordinate
	  */
	 public int y(){
		 return points[0].y;
	 }
	 
	 /**
	  * @return first laser point's previous x coordinate
	  */
	 public int px(){
		 return points[0].px;
	 }
	 
	 /**
	  * @return first laser point's previous y coordinate
	  */
	 public int py(){
		 return points[0].py;
	 }
	 
	 /**
	  * @return first laser point's color
	  */
	 public int c(){
		 return points[0].c;
	 }
	 
	 /**
	  * @return milliseconds the first laser point has been active
	  */
	 public int duration(){
		 return points[0].duration;
	 }

	 /**
	  * @return whether the first laser point is active
	  */
	 public boolean pressed(){
		 if (points[0] != null){
			 return points[0].active;
		 }
		 else{
			 return false;
		 }
	 }

	 /**
	  * Load a homography calibration file
	  * @param f the filename of the calibration file
	  */
	 public void loadFile(String f){
		 h.loadFile(f);
	 }
	 /**
	  * Save a homography calibration file
	  * @param f the filename of the calibration file
	  */	 
	 public void writeFile(String f){
		 h.writeFile(f);
	 }
	 
	 /**
	  * Find the homography that relates camera to screen coordinates by using
	  * a set of known correspondences.
	  * @param cam an array of points in camera coordinates
	  * @param proj an array of points in screen coordinates
	  */
	 public void computeHomography(PVector[] cam, PVector[] proj){
		 h.computeHomography( cam, proj);
	 }

	 /**
	  * @return the homography for this laser tracker
	  */
	 public Homography getHomography(){
		 return h;
	 }

	 /**
	  * 
	  * @param h the homography for this laser tracker
	  */
	 public void setHomography( Homography h){
		 this.h = h;
	 }


	 /**
	  * Search the image for laser points and associate them with known tracks.
	  * @param video the image to be processed
	  */
	 void findBrightestPoints(PImage video){
		 // Search for the brightest pixel: For each row of pixels in the video image and
		 // for each pixel in the yth row, compute each pixel's index in the video
		 video.loadPixels();
		 int index = 0;

		 // at the start all the lasers are missing
		 for (int i = 0; i < numOfPoints; i++){ 
			 points[i].active = false;
		 }

		 // go through the image looking for laser points and associate them with
		 // the closest track or create a new track
		 for (int y = 0; y < video.height; y++) {
			 for (int x = 0; x < video.width; x++) {
				 // Get the color stored in the pixel
				 int pixelValue = video.pixels[index];
				 // the lasers have a brightness of 255
				 if (parent.brightness(pixelValue) == 255){
					 // find the closest track to this laser detection
					 float min_dist = 100000000;
					 int min_i = 0;
					 for (int i = 0; i < numOfPoints; i++){
						 float d = parent.dist(x, y, points[i].ccx, points[i].ccy);
						 if ((d < min_dist)){
							 min_dist =  d;
							 min_i = i;
						 }
					 }

					 if (min_dist > MAX_DISTANCE){

						 if (numOfPoints < MAX_LASER_POINTS){
							 // new laser point
							 points[numOfPoints] = new LaserPoint(x, y, pixelValue, parent);
							 numOfPoints = numOfPoints + 1;
							 // for debugging
							 if (DEBUG) parent.println("New Point Created");
						 }
						 else{
							 // for debugging
							 if (DEBUG) parent.println("!!! TOO MANY LASERS DETECTED!!!");
						 }
					 }
					 else{
						 // update closest laser point
						 points[min_i].ccx = x;
						 points[min_i].ccy = y;
						 points[min_i].active = true;
						 points[min_i].last_t = parent.millis();
					 }
				 }
				 index = index + 1;
			 }
		 }
	 }
	 
	 /**
	  * If there is a keystone surface then this method will 
	  * translate the laser coordinate onto that surface
	  * @param lt the laser point
	  */
	 void warpLaserPosition(LaserPoint lt){
		 if (surface != null){
			 PVector now = surface.getTransformedPoint(new PVector (lt.x, lt.y));
			 lt.ux = lt.x;
			 lt.uy = lt.y;
			 lt.x = (int)(now.x);
			 lt.y = (int)(now.y);
		 }
	 }

	 /**
	  * Updates x,y locations in the camera to screen camera coordinates. 
	  * Also decide if the laser was "clicked" and call the event handler if it exists
	  */
	 void updatePoints(){
		 for (int i = 0; i < numOfPoints; i++){
			 points[i].pcx = points[i].cx;
			 points[i].pcy = points[i].cy;
			 points[i].cx = points[i].ccx;
			 points[i].cy = points[i].ccy;
			 points[i].duration = parent.millis() - points[i].start_t;
			 h.computeLaserPosition(points[i]);
			 warpLaserPosition(points[i]);
			 // Checks whether the laser is clicked based on the  MAX_CLICK_TIME and  MIM_CLICK_TIME
			 if (!points[i].active && (parent.millis() - points[i].last_t) > OFF_TIME){
				 if (points[i].duration > MIN_CLICK_TIME && points[i].duration < MAX_CLICK_TIME){
					 laserPressed(points[i]);
				 }
				 // move the last point into this empty slot
				 numOfPoints = numOfPoints - 1;
				 points[i] = points[numOfPoints];
				 if (DEBUG) parent.println("deleted point");
			 }
		 }
	 }

	 /**
      * find laser tracks in the image using either the real for fake laser tracker
	  * @param img the image to be processed
	  */
	 public void findLaser(PImage img){
			 findBrightestPoints(img);
			 updatePoints();
	 }


	 /**
	  * emulate a laser point on a sketch with the mouse
	  */
	 public void fakeFindLaser(){
		 if (parent.mousePressed){
			 if (numOfPoints>0){
				 points[0].last_t = parent.millis();
				 points[0].ccx= parent.mouseX;
				 points[0].ccy= parent.mouseY;
			 }
			 else{
				 points[0] = new LaserPoint(parent.mouseX, parent.mouseY, c, parent);
				 points[0].last_t = parent.millis();
				 numOfPoints++;
			 }
			 state = true;
		 }
		 else{
			 if (numOfPoints>0){
				 points[0].active = false;
			 }
			 if (state){

				 laserPressed(points[0]);
			 }
			 state = false;
		 }
		 updatePoints();
	 }
}




