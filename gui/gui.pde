/** Modified from ControlP5 frame **/
 
import java.awt.*;
import java.awt.event.*;
import controlP5.*;
import processing.serial.*;
import codeanticode.gsvideo.*;

// IMPORTANT: DECLARING A GLOBAL REFERENCE TO THE MAIN PAPPLET 
PApplet main_frame; 

// DECLARING A CONTROLP5 OBJECT
private ControlP5 cp5;

// HEMI AND QUAD VARIABLES
int quad_state[][] = {{1, 1}, {1, 1}, {1, 1}, {1, 1}};    // 1 means the quad has not been done yet, 2 means it has already been done, 3 means it is presently going on, negative means it is being hovered upon
int hemi_state[][] = {{1, 1}, {1, 1}, {1, 1}, {1, 1}};    // the same thing is used for the hemis
color quad_colors[][] = {{#eeeeee, #00ff00, #ffff22, #0000ff}, {#dddddd, #00ff00, #ffff22, #0000ff}};
color hover_color = #0000ff;
int quad_center[] = {700, 320}; 
int hemi_center[] = {935, 320};
int quad_diameter[] = {90, 60};
int hemi_hover_code[][] = {{0, 3}, {1, 2}};

// ISOPTER VARIABLES
// 24 meridians and their present state of testing
int meridians[] = {28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28};    // negative value means its being hovered over
color meridian_text_color[] = {};
int isopter_center[] = {820, 150};
int isopter_diameter = 250;
int current_sweep_meridian;

// VARIABLES THAT KEEP TRACK OF WHAT OBJECT (HEMI, QUAD OR ISOPTER) WE ARE HOVERING OVER AND WHICH COUNT IT IS
// THIS WILL ENABLE SENDING A SERIAL COMM TO THE ARDUINO VERY EASILY ON A MOUSE PRESS EVENT
char hovered_object;
int hovered_count;    // the current meridian which has been hovered over

// SERIAL OBJECT/ARDUINO
Serial arduino;                 // create serial object

// VIDEO FEED AND VIDEO SAVING VARIABLES
GSCapture cam;        // GS Video Capture Object
GSMovieMaker video_recording;      // GS Video Movie Maker Object
int fps = 30;          // The Number of Frames per second Declaration (used for the processing sketch framerate as well as the video that is recorded

// PATIENT INFORMATION VARIABLES - THESE ARE GLOBAL
String textName, textAge, textMR, textDescription;

/**********************************************************************************************************************************/
// THIS IS THE MAIN FRAME
void setup() {
  main_frame = this;
  cp5 = new ControlP5(this);
  // DECLARE THE CONTROLFRAME, WHICH IS THE OTHER FRAME
  ControlFrame cf1 = addControlFrame( "Patient Information", 200, 480, 40, 40, color(100));
  cf1.setVisible(true);  // set it to be invisible, so we can give it focus later
  
  // INITIATE SERIAL CONNECTION
  println(Serial.list()[Serial.list().length - 1]);
  if (Serial.list().length != 0) {
    String port = Serial.list()[Serial.list().length - 1];
    println("Arduino MEGA connected succesfully.");
    
    // then we open up the port.. 115200 bauds
    arduino = new Serial(this, port, 115200);
    arduino.buffer(1);
  } else {
    println("Arduino not connected or detected, please replug"); 
    // exit();
  }
  
  // default background colour
  size(1000, 480);  // the size of the video feed + the side bar with the controls
  frameRate(fps);
  
  // CONNECT TO THE CAMERA
  String[] cameras = GSCapture.list(); //The avaliable Cameras
  println(cameras);
     
  // We check if the right camera is plugged in, and if so only then do we proceed, otherwise we exit the program.
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    //exit();
  } else {
    println("Checking if correct camera has been plugged in ...");
    
    for (int i = 0; i < cameras.length; i++) {  //Listing the avalibale Cameras
      println(cameras[i]);
      
      println(cameras[i].length());
      println(cameras[i].substring(3,6));
      // if (cameras[i].length() == 13 && cameras[i].substring(3,6).equals("USB")) {
        println("...success!");
        cam = new GSCapture(this, 640, 480, cameras[i]);      // Camera object will capture in 640x480 resolution
        cam.start();      // shall start acquiring video feed from the camera
        break; 
      // }
      // println("...NO. Please check the camera connected and try again."); 
      // exit();
    }  
  }
}
  
void draw() {
  // plain and simple background color
  background(#cccccc);
  
  // draw the video capture here
  fill(0);
  rect(0, 0, 640, 480);
  if (cam.available() == true) {
    cam.read();    // read only if available, otherwise interpolate with previous frame
  } else {
  }
  image(cam, 0, 0);    // display the image, interpolate with the previous image if this one was a dropped frame
  
  // draw the crosshair at the center of the video feed
  stroke(#ff0000);
  line(315, 240, 325, 240);
  line(320, 235, 320, 245);
  
  // draw the hemis and quads in their present state
  colorQuads(quad_state, quad_center[0], quad_center[1], 2.5, 2.5);    // quads
  colorQuads(hemi_state, hemi_center[0], hemi_center[1], 2.5, 0);      // hemis
  
  // check if the mouse is hovering over the hemis, quads or isopter - if so, change to hover colour
  hover(mouseX, mouseY);
  
  // draw the isopter/meridians
  drawIsopter(meridians, isopter_center[0], isopter_center[1], isopter_diameter);
}

// DRAW FOUR QUADRANTS - THE MOST GENERAL FUNCTION
void colorQuads(int[][] quad_state, int x, int y, float dx, float dy) {
  // float quad_positions[][] = {{52.5, 52.5}, {50, 52.5}, {50, 50}, {52.5, 50}};
  byte quad_positions[][] = {{1, 1}, {0, 1}, {0, 0}, {1, 0}};
  
  for (int i = 0; i < 4; i++) {  // 4 quadrants
    for (int j = 0; j < 2; j++) {  // inner and outer
      if (quad_state[i][j] > 0) {
        fill(quad_colors[j][quad_state[i][j] - 1]);    // filling the corresponding quadrant
      } else {
        fill(hover_color);  // fill the hover colour
        quad_state[i][j] = abs(quad_state[i][j]);  // revert to earlier thing
      } 
      noStroke();
      // finally, we draw the actual quads x4
      arc(x + dx*quad_positions[i][0], y + dy*quad_positions[i][1], quad_diameter[j], quad_diameter[j], i*HALF_PI, HALF_PI + i*HALF_PI);
    }
  }
}

// DRAW THE ISOPTER WITH THE UPDATED POSITIONS OF THE RED DOTS
void drawIsopter(int[] meridians, int x, int y, int diameter) {
  // first draw the background circle
  stroke(0);
  fill(#eeeeee);
  ellipse(x, y, diameter, diameter);    // the outer circle of the isopter, representing the projection of the whole dome
  ellipse(x, y, 0.25*diameter, 0.25*diameter);  // the inner daisy chain
  
  // we draw the two curves representing the isopter extent
  // second curve
  noFill();
  beginShape();
  curveVertex(736,235);
  curveVertex(785,214);
  curveVertex(802,210);
  curveVertex(818,217);
  curveVertex(839,211);
  curveVertex(856,213);
  curveVertex(908,237);
  endShape();
  
  beginShape();
  curveVertex(734,55);
  curveVertex(735,64);
  curveVertex(769,58);
  curveVertex(802,77);
  curveVertex(820,79);
  curveVertex(838,76);
  curveVertex(875,57);
  curveVertex(904,64);
  curveVertex(909,51);
  endShape();
  
  // Then draw the 24 meridians
  for (int i = 0; i < 24; i++) {
    // first calculate the location of the points on the circumference of this circle, given that meridians are at 15 degree (PI/12) intervals
    stroke(#bbbbbb);
    float xm = cos(radians(i*15))*diameter/2 + x;
    float ym = sin(radians(i*15))*diameter/2 + y; 
    
    // draw a line from the center to the meridian points (xm, ym)
    line(x, y, xm, ym);
    
    // draw the text at a location near the edge, which is along an imaginary circle of larger diameter - at point (xt, yt)
    float xt = cos(radians(-i*15))*(diameter + 30)/2 + x - 10;
    float yt = sin(radians(-i*15))*(diameter + 20)/2 + y + 5;
    if (meridians[i] < 0) {
      fill(#ff0000);
    } else {
      fill(0); 
    }
    text(str(i*15), xt, yt);  // draw the label of the meridian (in degrees)
    
    // NOW WE DRAW THE RED DOTS FOR THE REALTIME FEEDBACK
    fill(#ff0000);  // red colour
    if (abs(meridians[i]) < 28) {
      float xi = cos(radians(-i*15))*(10 + (diameter - 10)*abs(meridians[i])/(2*28)) + x;
      float yi = sin(radians(-i*15))*(10 + (diameter - 10)*abs(meridians[i])/(2*28)) + y;
      ellipse(xi, yi, 10, 10);
    }
  }
}

// CHECK IF THE MOUSE IS OVER ANYTHING IMPORTANT
// DO THIS BY FINDING IF THE RADIAL DISTANCE FROM ANY OF THE HEMI, QUAD OR ISOPTER IS SIGNIFICANT
void hover(float x, float y) {
  cursor(ARROW);
  hovered_object = 'c';    // random character which has no meaning to the arduino API
  if (x > 640) {  // otherwise it's over the video and therefore none of our concern
    float r_isopter = sqrt(sq(x - isopter_center[0]) + sq(y - isopter_center[1]));
    float r_quad = sqrt(sq(x - quad_center[0]) + sq(y - quad_center[1]));
    float r_hemi = sqrt(sq(x - hemi_center[0]) + sq(y - hemi_center[1]));
    
    // CHECK FOR ISOPTER, HEMI OR QUAD
    if (r_isopter < 0.5*(isopter_diameter + 30)) {    // larger diameter, so that the text surrounding the isopter can also be selected
      hovered_object = 's';
      // calculate angle at which mouse is from the center
      float angle = degrees(angleSubtended(x, y, isopter_center[0], isopter_center[1]));
      
      meridians[hovered_count] = abs(meridians[hovered_count]);    // clear out the previously hovered one
      hovered_count = int((angle + 5)/15)%24;    // this is the actual angle on which you are hovering
      meridians[hovered_count] = -1*abs(meridians[hovered_count]);      // set the presently hovered meridian to change state
      cursor(HAND);     // change cursor to indicate that this thing can be clicked on
      
     } else if (r_quad < 0.5*quad_diameter[0]) {
      hovered_object = 'q';
      // calculate angle at which mouse is from the center
      float angle = angleSubtended(x, y, quad_center[0], quad_center[1]);
      cursor(HAND);
      
      if (r_quad < 0.5*quad_diameter[1]) {
        // inner quads
        hovered_count = 4 + int((angle + HALF_PI)/HALF_PI);
        quad_state[abs(8 - hovered_count)][1] *= -1;
      } else {
        // outer quads
        hovered_count = int((angle + HALF_PI)/HALF_PI);
        quad_state[abs(4 - hovered_count)][0] *= -1;
      }
      
    } else if (r_hemi < 0.5*quad_diameter[0]) {
      hovered_object = 'h';
      // calculate angle at which mouse is from the center
      float angle = angleSubtended(x, y, hemi_center[0], hemi_center[1]);
      cursor(HAND);
            
      // choose inner or outer hemis
      if (r_hemi < 0.5*quad_diameter[1]) {
        // inner quads
        hovered_count = 2 + int((angle + HALF_PI)/PI)%2;
        hemi_state[hemi_hover_code[hovered_count - 2][0]][1] *= -1;
        hemi_state[hemi_hover_code[hovered_count - 2][1]][1] *= -1;
      } else {
        // outer quads
        hovered_count = int((angle + HALF_PI)/PI)%2;
        hemi_state[hemi_hover_code[hovered_count][0]][0] *= -1;
        hemi_state[hemi_hover_code[hovered_count][1]][0] *= -1;
      }      
    }
  }
}

// QUICK FUNCTION TO CALCULATE HTE ANGLE SUBTENDED
float angleSubtended(float x, float y, int c1, int c2) {
  // angle subtended by (x,y) to fixed point (c1,c2)
  float angle = atan((x - c1)/(y - c2));
  if (y >= c2) {  // if the reference point is in the 3rd or 4th quadrant w.r.t. a circle with (c1,c2) as center
    angle = PI + angle; 
  }
  return angle + HALF_PI;
}

void mousePressed() {
  // println(str(mouseX) + "," + str(mouseY));
  // really simple - just send the instruction to the arduino via serial
  // it will be of the form (hovered_object, hovered_count\n)
  // print(str(hovered_object) + ",");
  // println(str(hovered_count));
  arduino.write(hovered_object);
  arduino.write(',');
  if (hovered_object == 's') {
   arduino.write(str(hovered_count + 1)); 
  } else {
    arduino.write(str(hovered_count));    // this makes the char get converted into a string form, which over serial, is readable as the same ASCII char back again by the arduino [HACK]
  }
  arduino.write('\n');   
    
  // clear the hemis and quads which were "being done"
  clearHemisQuads();
  
  // change colour of the object to "presently being done"
  switch(hovered_object) {
    case 'q': {      
      if (hovered_count <= 4) {
         quad_state[abs(4 - hovered_count)][0] = 3;
         break;
      } else {
         quad_state[abs(8 - hovered_count)][1] = 3;
         break;
      }
    }
    case 'h': {
      if (hovered_count < 2) {
        hemi_state[hemi_hover_code[hovered_count][0]][0] = 3;
        hemi_state[hemi_hover_code[hovered_count][1]][0] = 3;
      } else {
        hemi_state[hemi_hover_code[hovered_count - 2][0]][1] = 3;
        hemi_state[hemi_hover_code[hovered_count - 2][1]][1] = 3;
      }
    }
    case 's':
        current_sweep_meridian = hovered_count;  // this needs to be stored in a seperate variable    
  }
}

void clearHemisQuads() {
 // checks if any hemi_state or quad_state values are == 3, and makes them into 2 (done)
   for (int i = 0; i < 4; i++) {  // 4 quadrants
      for (int j = 0; j < 2; j++) {  // inner and outer
        if (quad_state[i][j] == 3) {
           quad_state[i][j] = 2;
        }
        if (hemi_state[i][j] == 3) {
           hemi_state[i][j] = 2;
        }
      }
   }
}


// KEYPRESS TO STOP A TEST WHICH IS ONGOING
void keyPressed() {
  Stop();
  println("stopped");
}

// ALL THE STUFF THAT HAPPENS WHEN YOU STOP A TEST
// 1. REACTION TIME CALCULATION
// 2. SEND SIGNAL TO ARDUINO TO "STOP" ('x\n')
// 3. DRAW/UPDATE ISOPTER
public void Stop() {
  // SIGNAL ARDUINO TO STOP
  arduino.write('x');
  arduino.write('\n'); 
  
  // UI UPDATE - MAKE QUADS/HEMIS PRESENTLY IN ACTIVE STATE TO 'DONE' STATE
  clearHemisQuads();
  
  // CALCULATE REACTION TIME
}

// GET FEEDBACK FROM THE ARDUINO ABOUT THE ISOPTER
void serialEvent(Serial arduino) { 
  String inString = arduino.readStringUntil('\n');
  if (inString != null && inString.length() <= 4) {
    // string length four because it would be a 2-digit or 1-digit number with a \r\n at the end 
    // print(inString);
    
    meridians[current_sweep_meridian] = parseInt(inString.substring(0, inString.length() - 2));
    printArray(meridians[current_sweep_meridian]);
  } 
}
/**********************************************************************************************************************************/

/* who ya gonna call? These functions..
void keyPressed() {
  switch(key) {
    case('1'):
    getFrame("hello").setVisible( true );
    break;
    case('4'):
    getFrame("hello").setVisible( false );
    break;
    case('5'):
    removeFrame("hello");
    break;
  }
}
*/

/* FUNCTIONS BELOW ARE REGARDING CREATING AND DESTROYING CONTROLFRAMES*/

HashMap<String, ControlFrame> frames = new HashMap<String, ControlFrame>();

ControlFrame addControlFrame(String theName, int theWidth, int theHeight) {
  return addControlFrame(theName, theWidth, theHeight, 100, 100, color( 0 ) );
}

ControlFrame addControlFrame(final String theName, int theWidth, int theHeight, int theX, int theY, int theColor ) {
  if (frames.containsKey(theName)) {
    /* if frame already exist, a RuntimeException is thrown, please adjust to your needs if necessary. */
    throw new RuntimeException(String.format( "Sorry frame %s already exist.", theName ) );
  }
  final Frame f = new Frame( theName );
  final ControlFrame p = new ControlFrame( this, f, theName, theWidth, theHeight, theColor );
  f.add( p );
  p.init();
  f.setTitle(theName);
  f.setSize( p.w, p.h );
  f.setLocation( theX, theY );
  f.addWindowListener( new WindowAdapter() {
    @Override
      public void windowClosing(WindowEvent we) {
      removeFrame( theName );
    }
  });
  
  f.setResizable( false );
  f.setVisible( false );
  // sleep a little bit to allow p to call setup.
  // otherwise a nullpointerexception might be caused.
  try {
    Thread.sleep( 20 );
  } 
  catch(Exception e) {
  }
  frames.put( theName, p );
  return p;
}

void removeFrame( String theName ) {
  getFrame( theName ).dispose();
  frames.remove( theName );
}

ControlFrame getFrame( String theName ) {
  if (frames.containsKey( theName )) {
    return frames.get( theName );
  }  
  /* if frame does not exist anymore, a RuntimeException is thrown, please adjust to your needs if necessary. */
  throw new RuntimeException(String.format( "Sorry frame %s does not exist.", theName ) );
}


// the ControlFrame class extends PApplet, so we are creating a new processing applet inside a new frame with a controlP5 object loaded
// herein we define our new object
public class ControlFrame extends PApplet {
  int w, h;

  public void setup() {
    size(w, h);
    frameRate(30);
    cp5 = new ControlP5( this );
    
    // ADDING CP5 ELEMENTS
    cp5.addTextfield("Name") //Text Field Name and the Specifications
    .setPosition(20, 50)
      .setSize(150, 30)
        .setFocus(true)
          .setFont(createFont("arial", 12))
            .setAutoClear(false);
    cp5.addTextfield("MR No")
    .setPosition(20, 100)
      .setSize(150, 30)
          .setFont(createFont("arial", 12))
            .setAutoClear(false)
              ;
    cp5.addTextfield("Age")
    .setPosition(20, 150)
      .setSize(150, 30)
          .setFont(createFont("arial", 12))
            .setAutoClear(false)
              ;
    cp5.addTextfield("Description")
    .setPosition(20, 200)
      .setSize(150, 30)
          .setFont(createFont("arial", 12))
            .setAutoClear(false)
              ;
    cp5.addBang("Save")  //The Bang Save and the Specifications
    .setPosition(20, 250)
      .setSize(150, 40)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
          ; 
  
  }

  public void draw() {
    background(0);
  }
    
  public void Save() {
    // save function for the cp5.Bang object "Save"
    textName = cp5.get(Textfield.class, "Name").getText();
    textAge = cp5.get(Textfield.class, "Age").getText();
    textDescription = cp5.get(Textfield.class, "Description").getText();
    // println("Name, Age, Description = " + textName + ", " + textAge + ", " + textDescription);
    
    // TODO: Save patient details to a file in the same folder, along with isopter angles
    
    // CREATE A NEW MOVIEMAKER OBJECT (GLOBAL)
    video_recording = new GSMovieMaker(main_frame, width, height, "./" + year() + "" + month() + "" + day() + "_" + textName + ".avi", GSMovieMaker.MJPEG, GSMovieMaker.HIGH, fps);
    this.setVisible(false);
  }

  public ControlFrame(Object theParent, Frame theFrame, String theName, int theWidth, int theHeight, int theColor) {
    parent = theParent;
    frame = theFrame;
    name = theName;
    w = theWidth;
    h = theHeight;
  }


  public ControlP5 control() {
    return this.cp5;
  }  
  
  
  @Override
    public void dispose() {
    frame.dispose();
    super.dispose();
  }
  
  public void setVisible( boolean b) {
    frame.setVisible(b);
  }
  
  
  final Object parent;
  final Frame frame;
  final String name;
  private ControlP5 cp5;
  private boolean isUndecorated;
}
