//Obstacles are dropped by players, rectangular, and "hurt" the player when sucked up.

class Obstacle{
  color c;
  color colors[] = {
    color(230), color(230), color(230)                               } 
  ;
  float xpos,ypos;
  float obstaclescreenX, obstaclescreenY;
  LaserPoint laserController = null;

  Obstacle(float x,float y){
    c = colors[int(random(3))];
    xpos = x;
    ypos=y;
    obstaclescreenX = scrX(xpos,ypos);
    obstaclescreenY = scrY(xpos,ypos);
  }

  void display(){

    offscreen.pushMatrix();
    offscreen.stroke(c);
    offscreen.strokeWeight(3);
    offscreen.fill(100,20,20);
    offscreen.rectMode(CENTER);
    offscreen.rect(xpos,ypos,40,40);
    offscreen.popMatrix();
  }

  void suck(){
    //move closer to player when close, speed inversly proportional to distance 
    //(close means fast), after, remove dirt from dirts
    if (dist(p1.xpos, p1.ypos, xpos, ypos)<60) {
      xpos = random (p1.xpos-200, p1.xpos+200);
      ypos = random (p1.ypos-200, p1.ypos+200);
      p1.points = p1.points - 50;
      background(100,20,20);
    }

    if (dist(p1.xpos, p1.ypos, xpos, ypos)<150){
      xpos= 30/(p1.xpos-xpos)+xpos;
      ypos= 30/(p1.ypos-ypos)+ypos;

    }
  }


  void move(){
    stroke(255,0,0);
    noFill();
    ellipse(worX(obstaclescreenX, obstaclescreenY),worY(obstaclescreenX, obstaclescreenY),
    44,44);
    xpos = worX(laserController.x, laserController.y); 
    ypos = worY(laserController.x, laserController.y);
    obstaclescreenX = scrX(xpos,ypos);
    obstaclescreenY = scrY(xpos,ypos);

  }
  boolean selected(LaserPoint l){
    if (dist(l.x, l.y, obstaclescreenX, obstaclescreenY)< 60) {
      return true;    
    }
    else{
      return false;    
    }
  }
}









