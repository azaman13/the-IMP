package edu.bard.drab.PCLT;
import processing.core.PApplet;

/**
 * LaserPoint describes a laser point both in terms of camera and screen coordinates. 
 * @author Keith O'Hara
 *
 */
public class LaserPoint {

	/**
	 *  camera coordinates of this laser point
	 */
	public int cx, cy;

	/**
	 *  previous camera coordinates of this laser point
	 */
	public int pcy, pcx;      

	/**
	 *  screen coordinates of this laser point
	 */
	public int x, y;

	/**
	 * previous screen coordinates of this laser point
	 */
	public int px, py;

	/**
	 * unwarped screen coordinates of this laser point
	 */
	public int ux, uy;
	
	/**
	 * previous unwarped screen coordinates of this laser point
	 */
	public int upx, upy; // unwarped screen coordintes
	
	/**
	 * when this laser point was first created (in milliseconds since start of the sketch)
	 */
	public int start_t;
	
	/**
	 * when this laser point was last detected (in milliseconds since start of the sketch)
	 */
	public int last_t;
	
	/**
	 * how long this laser point has been active (in milliseconds) 
	 */
	public int duration;
	 
    /**
     * the color of this laser point
     */
	public int c;
	
	/**
	 * whether this laser point was detected in the previous frame
	 */
	public boolean active;
	
	/**
	 * the processing parent
	 */
	PApplet parent;
	
	/**
	 *  candidate camera coordinates 
	 */
	public int ccx, ccy;    

	/**
	 * LaserPoint constructor
	 * @param ccx candidate camera x location
	 * @param ccy candidate camera y location
	 * @param c   color of laser point
	 * @param p   processing parent
	 */
	public LaserPoint(int ccx, int ccy, int c, PApplet p){
		parent= p;
		this.ccx = ccx;
		this.ccy = ccy;
		this.c = c;
		this.start_t = parent.millis();
		this.active = true;
	}

	public String toString(){
		return ("cx:" + cx + ", " + 
				"cy:" + cy + "; "  +
				"pcx:" + pcx + ", " + 
				"pcy:" + pcy + "; "  +
				"ux:" + ux + ", " +
				"uy:" + uy + ", " + 
				"x:" + x + ", " + 
				"y:" + y + "; " +  
				"px:" + px + ", " + 
				"py:" + py + "; " + 
				"st:"  + start_t + " " + 
				"lt:"  + last_t + " " + 
				"d:" + duration);
	}
}


