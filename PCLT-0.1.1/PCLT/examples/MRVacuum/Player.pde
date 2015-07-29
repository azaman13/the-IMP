/* Player class is displayed as a vacuum (display), moves through the world (move)
 is controlled by green lasers (assignPlayer), and has an animation to simulate real vacuums (particle)
 
 
 */
class Player {
  color c;
  float xpos;
  float ypos;
  float xspeed;
  float yspeed;
  int onscreenX,onscreenY;
  float direction;
  float heading;
  float totaldis;
  int points;
  int v, r;
  LaserPoint laserController;


  Player() {
    c= color(255);
    xpos= width/2;

    ypos= height-60;
    xspeed= 0;
    yspeed= 0;
    direction=0;
    points= 0;
    onscreenX= width/2;
    onscreenY= height-60;
  }

  //run handles all other functions and is called in the main sketch rather than each individually.
  void run(){
    avoid();
    assignPlayer();
    move();
    display();
    dirtArrow();
  }


  void display() {
    offscreen.fill(0);
    offscreen.noStroke();
    offscreen.translate(p1.xpos ,p1.ypos);
    offscreen.rotate(heading);
    offscreen.translate(-p1.xpos ,-p1.ypos);
    offscreen.pushMatrix();

    offscreen.translate(xpos ,ypos);
    offscreen.rotate(p1.direction);
    offscreen.rectMode(CENTER);
    offscreen.rect(0, 0, 150,40);
    offscreen.translate(0, 20);
    offscreen.rect(0, 0, 40, 40);
    offscreen.translate(0, 20);
    offscreen.ellipse(0, 0 ,20 ,20);
    for (float i= 4; i>= 0; i-=.25 ){
      offscreen.translate(0, 9);
      offscreen.ellipse(0, 0, 10, 10);
      offscreen.rotate( sign(direction)*.1 + .01);
    }
    offscreen.popMatrix();
  }

  void assignPlayer(){
    laserController=null;
    for(int i = 0; i < lt.numOfPoints; i++){
      color laserColor= lt.points[i].c;
      if (green(laserColor)>= 255 && red(laserColor) < 255 ){
        laserController= lt.points[i];
        println("Player Assigned");
      }
    }
  }

  void move(){
    if (laserController!= null){

      float laserX = laserController.x; 
      float laserY = laserController.y;
      float speed = sqrt(dist(onscreenX,onscreenY, laserX,laserY)/3);
      if (speed> 10){
        speed= 10;

        if (speed <1){
          speed=0;
        }
      }
      heading = atan2((laserX-onscreenX),(-laserY+onscreenY));

      // The movement of the roomba is based on the changes in laser position/path of the player.
      // when the game path is changed dramatically, the robot makes a sharper turn, when it 
      // stays on a relatively straight path, so does the robot. the drive fct takes vel. in mm/sec, and rad. in mm.
      v = int(25*speed);
      r = int(-sign(heading)*300/sq(heading));


      if( speed == 5 && v>0){
        v-= 10;
        if( v< 0){
          v=0;
        }
      }
    }
    else{
      if( v>0){
        v-= 10;
        if( v< 0){
          v=0;
        }
      }
    }
    println(v+ " " + r);
    float dis = 0;
    float a = 0;
    if (USE_ROOMBA){
      roombacomm.drive(v,r);
      if( roombacomm.bump()){
        background(255,0,0);
      }
      dis= roombacomm.distance();
      a = roombacomm.angleInDegrees();
      direction -= radians(a);
    }
    else
    {
      dis = abs(v)/70.0;
      direction = heading;
    }

    totaldis += dis;
    println("Roomba angle " + a +  " wheel difference "+ roombacomm.angle() +" dis "+ dis+ " "+ totaldis+ " direction " + degrees(direction));

    xpos += .7*dis*sin(direction);
    ypos -= .7*dis*cos(direction);
  }

  void avoid(){
    if (USE_ROOMBA){
      if( roombacomm.bump()){
        background(255,0,0);
        roombacomm.goBackward(100);
        roombacomm.spin( int(sign(random(-1,1)))*135);  
      }
    }
  }

  void dirtArrow(){
    offscreen.stroke(200);
    offscreen.strokeWeight(3);
    float avX= 0;
    float avY= 0;
    for (int i = 0; i < amountOfDirt; i = i + 1){
      avX= dirts[i].x+ avX;
      avY= dirts[i].y+ avY;
    }
    avX= avX/amountOfDirt;
    avY= avY/amountOfDirt;
    offscreen.pushMatrix();
    offscreen.translate(xpos, ypos);
    offscreen.rotate(atan2(avY-ypos,avX-xpos) );
    offscreen.fill(color(180,130,90));
    offscreen.stroke(color(180,130,90));
    offscreen.strokeWeight(4);
    offscreen.line( 20, 10, 170, 10);
    offscreen.text( "points: " + str(p1.points),20, 0);
    offscreen.popMatrix();
  }   
}

//sign fct needed for display()
float sign(float a){
  if (a >= 0){
    return 1;
  }
  else{
    return -1;
  }
}



class Particle{
  float x, y;
  float r;

  Particle(){
    x = random(p1.xpos-80, p1.xpos+80);
    y = random(p1.xpos-100, p1.xpos+30);
    r = random (1,5);

  }

  void display(){
    offscreen.noFill();
    offscreen.stroke(255, 100);
    offscreen.strokeWeight(2);
    offscreen.ellipse (x,y,r,r);
  }

  void suck(){
    x+= 30/(p1.xpos-x);
    y+= 30/(p1.ypos-y);
    if( abs(p1.xpos-x) >= 80){
      x= p1.xpos;
    }
    if( abs(p1.ypos-y) >= 100){
      y=p1.ypos;
    }
  }

  boolean dead(){
    if (dist(p1.xpos, p1.ypos, x, y)<30) {
      return true;
    }
    else{
      return false;
    }
  }
}















