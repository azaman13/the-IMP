int NUMFINALLINES = 4;
// From the list of all the possible hough transformed lines we take into 
// account the NUMLINES (it can be any number) with the highest frequency 
// to find NUMFINALLINES
int NUMLINES = 8;
float Deg_Per_Row = 6;
float R_Per_Cell = 1.4/75;
// This is the threshold value that we later use in the threshold image to find the 
// projector blob. This value can be changed based on the brightness of the environment 
// ( always between 0-1) higer for brighter place and lower for darker places
float BRIGHTNESS = .0001;

// laplacian kernel for edge detection
float[][] kernel = {
  { 
    0, -1,  0      }
  ,
  {
    -1,  4, -1                                                                                              }
  ,
  { 
    0, -1,  0                                                                                              }
};

// It finds the edges of the fgImage based on the laplacian kernel edge detection matrix 
PImage findEdges(PImage fgImage){
  // Create an opaque image of the same size as the original
  PImage edgeImage = createImage(fgImage.width, fgImage.height, RGB);
  // Loop through every pixel in the image.
  for (int y = 1; y < fgImage.height-1; y++) { 
    // Skip top and bottom edges
    for (int x = 1; x < fgImage.width-1; x++) { 
      // Skip left and right edges
      float sum = 0; 
      // Kernel sum for this pixel
      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          // Calculate the adjacent pixel for this kernel point
          int pos = (y + ky)*fgImage.width + (x + kx);
          // Image is grayscale, red/green/blue are identical
          float val = red(fgImage.pixels[pos]);
          // Multiply adjacent pixels based on the kernel values
          sum += kernel[ky+1][kx+1] * val;
        }
      }
      // For this pixel in the new image, set the gray value
      // based on the sum from the kernel
      edgeImage.pixels[y*fgImage.width + x] = color(sum);
    }
  }
  //changes to edgeImage.pixels[]
  edgeImage.updatePixels();

  return edgeImage;
}

// This funciton returns a list of the 
// found corner point from an image
PVector [] autoCalibrate(PImage fgImage){
  // These three lines define the size of the bucket and the array for the hough transform 
  int numOfRows = int(360/Deg_Per_Row);
  int numOfCol = int(1.4/ R_Per_Cell);
  // This is a 2D array of radius as columns and angle in rows
  int[][] rTheta = new int[numOfRows][numOfCol]; 
  offscreen.strokeWeight(1);
  offscreen.image(fgImage, 0, 0);
  // the fgImage is then thresholded using the BRIGHTNESS value1
  fgImage.filter(THRESHOLD, BRIGHTNESS);
  offscreen.image(fgImage, 0, 0 + fgImage.height);
  // Makes the pixels of the fgImage available
  fgImage.loadPixels();
  // egdeImage now beomes fgImage
  PImage edgeImage = findEdges(fgImage);
  // Determine the size of the edgeImage
  offscreen.image(edgeImage, fgImage.width, 0);

  edgeImage.loadPixels();
  // Creates the size of the rTheta table based on the predefines numOfRows and numOfCol values
  for( int i = 0; i < numOfRows; i++){
    for( int j = 0; j < numOfCol; j++){
      rTheta[i][j] = 0;
    }
  }
  // Hough Transform
  int index = 0;
  // Iterates through every pixels of the edgeImage  
  // and map every i and j values between -1 to 1
  for(int j = 0; j < edgeImage.height; j++){
    for(int i = 0; i < edgeImage.width; i++){
      float x = map(i, 0, edgeImage.width, -1, 1);
      float y = map(j, 0, edgeImage.height, 1, -1);
      
      // if the brightness value of a particular pixel is > 0 ( i.e white in thi case)
      // we increase the the frequency of that line by 1
      if (brightness(edgeImage.pixels[index]) > 0)
      {
        for( int a = 0; a < numOfRows; a++){
          float angle = Deg_Per_Row * a;
          int r = int((x*cos(radians(angle)) + y*sin(radians(angle)))/R_Per_Cell);
          if (r > 0 && r < numOfCol){
            rTheta[a][r]+= 1;  
          }  
        }

      }
      index= index + 1;
    }
  }

  // Finds some number of lines (those with the maximum votes)
  float[] drMax= new float[NUMLINES];
  float[] rrMax = new float[NUMLINES];
  int[] rMax = new  int[NUMLINES];
  rMax[0] = 0;
  for (int i = 0; i < numOfRows; i++){
    for (int j = 0; j < numOfCol; j++){
      boolean maxf = true;
      for(int k = 0; k < NUMLINES; k++){

        if (rTheta[i][j] > rMax[k]  && maxf){
          for(int l = NUMLINES - 1; l > k; l--){
            rMax[l] = rMax[l-1];
            drMax[l] = drMax[l-1];
            rrMax[l]= rrMax[l-1];
          }
          rMax[k] = rTheta[i][j]; 
          //println("votes: " + rMax +",   " + "Deg/Row:  " + Deg_Per_Row*i +",   " + "R/Cell*j: " + R_Per_Cell*j);
          drMax[k] = Deg_Per_Row*i;
          rrMax[k]=  R_Per_Cell*j;

          maxf = false;
        }

      }
    }
  }
  // For Debugging
  for(int i = 0; i < NUMLINES; i++){
    println( "votes: " + rMax[i] + ", " + "angle: " + drMax[i] + ",  " + "radius: " + rrMax[i]);
  }


  // Finds sufficiently different lines  and merges similar lines
  float [] fAngle = new float[NUMFINALLINES];
  float [] fRadius = new float[NUMFINALLINES];
  fAngle[0] = drMax[0];
  fRadius[0] = rrMax[0];
  int lines = 1;
  for(int i = 0; i < NUMLINES; i++){
    int indx = -1;
    for(int j = 0; j < lines; j++){
      float deltaAngle = abs(fAngle[j] - drMax[i]);
      float deltaRadius = abs(fRadius[j] - rrMax[i]);
      if ((deltaAngle < 15 || deltaAngle > 345)  && deltaRadius < .1){
        indx = j;
        break;
      }
    }
    if(indx == -1 && lines < NUMFINALLINES){
      fAngle[lines] = drMax[i];
      fRadius[lines] = rrMax[i];
      lines++;
    }
  } 

  // draw lines based on tha fAngle[i] value
  for(int i = 0; i < NUMFINALLINES; i++){
    offscreen.stroke(255);
    float x1, y1, x2, y2;
    if (fAngle[i] < 0.001){
      
      y1 = map(0, 0, fgImage.height, 1, -1);
      x1 = fRadius[i];
      y2 = map(fgImage.height, 0, fgImage.height, 1, -1);
      x2 = fRadius[i];
    }
    else if ((fAngle[i] <= 30) || (fAngle[i] >= 330)  || (fAngle[i] >=150 && fAngle[i] <= 210)){ 
      
      y1 = map(0, 0, fgImage.height , 1, -1);
      x1 = (y1 - (fRadius[i]/sin(radians(fAngle[i])))) * -tan(radians(fAngle[i]));
      y2 = map(fgImage.height, 0, fgImage.height, 1, -1);
      x2 = (y2 - (fRadius[i]/sin(radians(fAngle[i])))) * -tan(radians(fAngle[i]));
      
    }
    else{
      x1 = map(0, 0, fgImage.width, -1, 1);      
      y1 = ((-1/tan(radians(fAngle[i])))*x1) + (fRadius[i]/sin(radians(fAngle[i])));
      x2 = map(fgImage.width, 0, fgImage.width, -1, 1);
      y2 = ((-1/tan(radians(fAngle[i])))*x2) + (fRadius[i]/sin(radians(fAngle[i])));
    }


    offscreen.line(map(x1, -1, 1, 0, fgImage.width), 
    map(y1, 1, -1, 0, fgImage.height),
    map(x2, -1, 1, 0, fgImage.width), 
    map(y2, 1, -1, 0, fgImage.height));
  }

  // store lines as PVectors
  PVector [] fLines = new PVector[NUMFINALLINES];
  for( int i = 0; i < NUMFINALLINES; i++){
    fLines[i] = new PVector(cos(radians(fAngle[i])) , sin(radians(fAngle[i])), -fRadius [i]);
  }
  // creats an array for storing the corners in a PVector
  PVector [] corner = new PVector[NUMFINALLINES*(NUMFINALLINES - 1) / 2];
  int cornersFound = 0;

  // compute corners by intersecting lines
  for(int i = 0; i < fLines.length; i++){
    for(int j= i+1; j < fLines.length; j++){
      PVector u = fLines[i].cross(fLines[j]);
      if(abs(u.z) > .1){
        offscreen.stroke(235,123,124);
        float x = map(u.x/u.z, -1, 1, 0, edgeImage.width);
        float y = map(u.y/u.z, 1, -1, 0, edgeImage.height);
        if (x >= -20 && x < edgeImage.width+20 && y >= -20 && y < edgeImage.height+20){
          offscreen.ellipse(x, y, 20,20);
          corner[cornersFound] = new PVector(x, y, 1);
          println("corner found: " + corner[cornersFound]);
          cornersFound++;
        }
      }
    }
  }

  // assign corners to certain positions (e.g. upper left, lower right)
  float avgX;
  float avgY;
  float rSumX = 0;
  float rSumY = 0;
  for(int i = 0; i < cornersFound; i++){
    rSumX = rSumX + corner[i].x;
    rSumY = rSumY + corner[i].y;
  }
  avgX = rSumX / cornersFound;
  avgY = rSumY / cornersFound;

  PVector cam[] = new PVector[4];
  // Feed the PVectors of the cam to the homography function
  for(int i = 0; i < cornersFound; i ++){
    float angle = degrees(atan2((corner[i].y - avgY), (corner[i].x - avgX))); 
    println(angle);
    if (angle > 90 && angle < 180){
      cam[3] = corner[i];
    }
    if ( angle > 0 && angle < 90){
      cam[2] = corner[i];
    }

    if ( angle <0 && angle > -90){
      cam[1] = corner[i];
    }

    if (angle < -90 && angle > -180)
    {
      cam[0] = corner[i];
    }
  }

  for (int i = 0; i < cam.length; i++){
    println("corner " + i + ": " + cam[i]);
  }    

  return cam;
}







