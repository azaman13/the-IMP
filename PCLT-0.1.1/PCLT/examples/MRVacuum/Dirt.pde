// Dirt should be dropped in a range around the player, be sucked up by the player,
// give the player points, and be moved by otherplayers

class Dirt {
  color c;
  color colors[]= {
    color(190,165,150), 
    color(215,190,165), 
    color(230,195,160)                                    };
  float x, y; 
  float dirtSize;
  float dirtSizes[]={
    27,37,33                                            };
  float dirtscreenX, dirtscreenY;
  LaserPoint laserController = null;


  Dirt() { 
    c = colors[int(random(3))];
    dirtSize = dirtSizes[int(random(3))];
    x = random (p1.xpos-500, 500+p1.xpos); //when constructed, dirt is placed in this random area around the player
    y = random (p1.ypos-400, p1.ypos+100 );
    dirtscreenX = scrX(x,y);
    dirtscreenY = scrY(x,y);
  }

  void display() {
    offscreen.noStroke();
    offscreen.fill(c);
    offscreen.pushMatrix();
    offscreen.translate(x,y);
    offscreen.ellipse(0,0, dirtSize, dirtSize);
    offscreen.popMatrix();
  }

  void suck(){
    //move closer to player when close, speed inversly proportional to distance 
    //(close means fast), after, dirt is made in new position
    if (dist(p1.xpos, p1.ypos, x, y)<dirtSize+15) {
      x = random (p1.xpos-500, p1.xpos+500);
      y = random (p1.ypos-400, p1.ypos+400);
      p1.points=p1.points + int(dirtSize);
    }

    if (dist(p1.xpos, p1.ypos, x, y)<150){
      x= 30/(p1.xpos-x)+x;
      y= 30/(p1.ypos-y)+y;
    }
  }
  void move(){
    offscreen.stroke(255,0,0);
    offscreen.noFill();
    offscreen.ellipse(worX(dirtscreenX, dirtscreenY),worY(dirtscreenX, dirtscreenY),dirtSize+5,dirtSize+5);
    x = worX(laserController.x, laserController.y); 
    y = worY(laserController.x, laserController.y);
    dirtscreenX = scrX(x,y);
    dirtscreenY = scrY(x,y); 


  }
  boolean selected(LaserPoint l){
    if (dist(l.x, l.y, dirtscreenX, dirtscreenY) < dirtSize*1.1) {
      return true;    
    }
    else{
      return false;    
    }
  }

}






//these functions can change the coordinates of an object from the "screen" to the "world" and back.

float scrX(float x, float y){
  return (((x- p1.xpos) * cos(-p1.direction))
    - ((y - p1.ypos) * sin(-p1.direction))+ p1.onscreenX);
}

float scrY(float x, float y){
  return   (((x- p1.xpos) * sin(-p1.direction))
    +((y - p1.ypos) * cos(-p1.direction))+ p1.onscreenY);
}

float worX(float x, float y){
  return((( x - p1.onscreenX) * cos(p1.direction))
    - ((y - p1.onscreenY) * sin(p1.direction))) + p1.xpos ;
}

float worY(float x, float y){
  return(((x -p1.onscreenX) * sin(p1.direction))
    + ((y - p1.onscreenY) * cos(p1.direction))) + p1.ypos;
}





