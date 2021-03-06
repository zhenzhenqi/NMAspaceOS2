import controlP5.*;
import java.awt.Robot;
import javax.swing.JFileChooser;

/////////////////////////// SETTINGS, CHANGE AS YOU NEEDED /////////////
int n = 3;//number of projects that needs to be scheduled by this app
//int intervalValue = 10; //how long does each project run [seconds]
boolean AUTO_RUN = false; //if run the projects automatically when this application starts
////////////////////////////////////////////////////////////////////////



Timer[] timers = new Timer[n];

//cp5 elements
ControlP5 cp5;
ArrayList<Textarea> filePathTextAreas;
ArrayList<Button> chooseFileButtons;
ArrayList<RadioButton> fileTypeButtons;
ArrayList<Slider> intervalSliders;
ArrayList<Type> allTypes;
Button saveSettings;
ButtonListener choosePathListener;
TypeListener chooseTypeListener;
SliderListener chooseIntervalListener;
Toggle runToggle;
boolean justStarted;
boolean loadingSettings;
Slider intervalSlider;

//colors
color bgColor = color(0, 0, 0);
color runningBGColor = color(19, 103, 0);
color defaultBGColor = color(10);

//items
Executable[] exes = new Executable[n];

//String[] filePaths = new String[n];

Textarea console;
String consoleContent = "";

int index;
int buttonTypedId = -1;

boolean running;

//layout
int gPadding = 20;
int inputFieldH = 30;
int inputFieldW = 400;  
int chooseFileBtnW = 100;
int padding = 20;
int runToggleHeight = 30;
int userprefButtonWidth = 150; 
int consoleHeight = 100;

public enum Type {
  UNITY, PROCESSING, VIDEO, WEB
}

JSONObject userpref;
String dataFileName = "userpref.json";

void setup() {
  size(900, 600);
  pixelDensity(2);
  cp5 = new ControlP5(this);

  filePathTextAreas = new ArrayList<Textarea>();
  chooseFileButtons = new ArrayList<Button>();
  fileTypeButtons = new ArrayList<RadioButton>();
  intervalSliders = new ArrayList<Slider>();

  choosePathListener = new ButtonListener();
  chooseTypeListener = new TypeListener();
  chooseIntervalListener = new SliderListener();

  loadingSettings = true;

  for (int i=0; i < n; i++) {
    //exes
    exes[i] = new Executable();
    //input field
    Textarea tl = cp5.addTextarea("filePath"+i);
    tl.setHeight(inputFieldH);
    tl.setWidth(inputFieldW);
    //tl.enableColorBackground();
    tl.setColorBackground(color(30));
    tl.setPosition(gPadding, (inputFieldH+padding) * i + gPadding);
    filePathTextAreas.add(tl);
    //choose file buttons
    Button btn = cp5.addButton("chooseFilePath"+i);
    btn.setHeight(inputFieldH);
    btn.addListener(choosePathListener);
    btn.setPosition(gPadding+inputFieldW+padding, (inputFieldH+padding) * i + gPadding);
    btn.setLabel("Choose File Path");
    btn.setWidth(chooseFileBtnW);
    chooseFileButtons.add(btn);
    //radio buttons
    RadioButton rb = cp5.addRadioButton("fileType"+i);
    rb.setValue(-1);
    rb.addListener(chooseTypeListener);
    rb.setPosition(gPadding+inputFieldW+padding*2+chooseFileBtnW, (inputFieldH+padding) * i + gPadding);
    for (int i2 =0; i2<Type.values().length; i2++) {
      rb.addItem(Type.values()[i2] + "_" + i, i2);
    }
    fileTypeButtons.add(rb);
    //interval sliders
    intervalSlider = cp5.addSlider("interval"+i)
      .setPosition(gPadding+inputFieldW+padding*2+chooseFileBtnW+90, (inputFieldH+padding) * i + gPadding)
      .setRange(1, 180)
      .setNumberOfTickMarks(180)
      .snapToTickMarks(true)
      //.setSliderMode(0)
      .setValue(exes[i].intervalValue)
      .addListener(chooseIntervalListener)
      .setLabel("(second)")
      .setSize(180, padding);
    intervalSliders.add(intervalSlider);

    timers[i] = new Timer(exes[i].intervalValue*1000);//define a timer for 1 to 10 seconds long
  }



  runToggle = cp5.addToggle("toggleRun")
    .setPosition(gPadding, (inputFieldH+padding) * (n+1) + gPadding)
    .setValue(false)
    .setSize(runToggleHeight, runToggleHeight);

  saveSettings = cp5.addButton("saveSettings")
    .setPosition(gPadding + runToggleHeight + padding, (inputFieldH+padding) * (n+1) + gPadding)
    .setSize(userprefButtonWidth, runToggleHeight);

  cp5.addButton("loadSettings")
    .setPosition(gPadding + runToggleHeight + userprefButtonWidth + padding*2, (inputFieldH+padding) * (n+1) + gPadding)
    .setSize(userprefButtonWidth, runToggleHeight);

  cp5.addTextlabel("ConsoleLabel").setText("Console").setPosition(gPadding, height-consoleHeight-gPadding-20);
  console = cp5.addTextarea("console");
  console.setSize(width-gPadding*2, consoleHeight)
    .setColorBackground(30)
    .setLineHeight(10)
    .setPosition(gPadding, height-consoleHeight-gPadding);

  index = 0;

  loadSettings();

  for (int i=0; i < n; i++) {
    (intervalSliders.get(i)).setValue(exes[i].intervalValue);
  }
  runToggle.setValue(AUTO_RUN);
}


void draw() {
  //println(timer.totalTime);
  background(0);
  if (running) {
    run();
    drawRunningIndicator();
  }
}

void drawRunningIndicator() {
  noStroke();
  fill(60, 255, 0);
  ellipse(width - gPadding, gPadding, 10, 10);
}

void execute(String path, boolean isProcessing) {
  if (isProcessing) {
    String sketchFolderPath = path.substring(0, path.lastIndexOf('/')+1);
    try {
      Runtime.getRuntime().exec("/Downloads/Processing/processing-java --sketch=" + sketchFolderPath + " --run");
    }
    catch(Exception e) {
      println(e);
    }
  } else {
    launch(path);
  }
}


void run() {

  String noTypeSetErrorMsg = ":    type hasn't been set.";
  String noPathErrorMsg = ":    file path isn't set.";

  //log2console("" + index);

  if (timers[index].isFinished()) {
    int previousIndex = index==0 ? n-1 : index-1;
    Type previousType = exes[previousIndex].TYPE;

    //quit the last executed program
    if (exes[previousIndex] != null
      && exes[previousIndex].filepath != null
      && previousType != null
      && !justStarted) {
      try {
        Robot r = new Robot();
        println("COMMAND + Q");
        r.keyPress(java.awt.event.KeyEvent.VK_META);
        r.keyPress(java.awt.event.KeyEvent.VK_Q);
        r.keyRelease(java.awt.event.KeyEvent.VK_META);
        r.keyRelease(java.awt.event.KeyEvent.VK_Q);
      }
      catch(Throwable e) {
        println(e);
        // println("Quitting Program Failed. Terminating Program...");
        exit();
      }
    }

    justStarted = false;
    delay(1500);

    //execute the new program
    if (exes[index].TYPE != null && exes[index].filepath != null) {
      switch(exes[index].TYPE) {
      case UNITY:
        //println(index + processingOnlyTypeErrorMsg);
        timers[index].updateSavedTime();
        execute(exes[index].filepath, false);
        break;
      case PROCESSING:
        timers[index].updateSavedTime();
        execute(exes[index].filepath, true);
        break;
      case VIDEO:
        //println(index + processingOnlyTypeErrorMsg);  
        timers[index].updateSavedTime();
        execute(exes[index].filepath, false);
        log2console("executing video");
        break;
      case WEB:
        timers[index].updateSavedTime();
        execute(exes[index].filepath, false);
        log2console("executing web");
        break;
      default:
        println(index + noTypeSetErrorMsg);        
        break;
      }
      log2console("" + exes[index].filepath);
    } else {
      if (exes[index].TYPE == null) {
        println(index + noTypeSetErrorMsg);
      }
      if (exes[index].filepath == null) {
        println(index + noPathErrorMsg);
      }
    }

    //progress index
    if (!justStarted) {
      if (index < n - 1) {
        index++;
      } else {
        index = 0;
      }
    }
  }
}

void turnOn() {
  index = 0;
  timers[index].updateSavedTime();

  running = true;
  bgColor = runningBGColor;
  justStarted = true;
}

void turnOff() {
  index = 0;
  running = false;
  bgColor = defaultBGColor;
}

//button action
void toggleRun(boolean value) {
  if (value) {
    turnOn();
  } else {
    turnOff();
  }
}

void log2console(String s) {
  consoleContent += s;
  console.setText(consoleContent);
}

//Select Type
class TypeListener implements ControlListener {
  public void controlEvent(ControlEvent theEvent) {
    println(theEvent.getController());
    println("!!!");
  }
}

//Set type when type is selected
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) {
    String name = theEvent.getName();
    int groupID = Integer.parseInt(name.replaceAll("[\\D]", ""));
    exes[groupID].TYPE =  Type.values()[ (int)theEvent.getGroup().getValue() ];
  }
}

//Select Button
class ButtonListener implements ControlListener {
  public void controlEvent(ControlEvent theEvent) {
    Controller ctl = theEvent.getController();

    buttonTypedId = -1;
    for (int i = 0; i < chooseFileButtons.size(); i++) {
      if (ctl == chooseFileButtons.get(i)) {
        buttonTypedId = i;
      }
    }

    if (buttonTypedId != -1) {
      if (exes[buttonTypedId].TYPE != null) {
        if (exes[buttonTypedId].TYPE == Type.UNITY) {
          selectFolder("Select Unity Build", "execfileSelected");
          println("is unity");
        } else {
          selectInput("Select Processing .pde file or video file or web file", "execfileSelected");
        }
      } else {
        log2console("Please select TYPE first\n");
      }
    } else {
      log2console("opened failed, type is not set correctly. id:  " + buttonTypedId);
    }
  }
}

//Select interval
class SliderListener implements ControlListener {
  public void controlEvent(ControlEvent theEvent) {
    //println(theEvent.getController());
    //println("!!!");
    for (int i=0; i < intervalSliders.size(); i++) {

      Slider activeSlider = intervalSliders.get(i);

      if (activeSlider != null) {
        if (theEvent.getController().getName() == activeSlider.getName()) {
          timers[i].updateTotalTime(exes[i].intervalValue * 1000);
          exes[i].intervalValue = parseInt(activeSlider.getValue());
          if (!loadingSettings) {
            println("Update time for exe " + i + " to: " + exes[i].intervalValue);
          }
        }
      }
    }
  }
}


//void interval (int input) {
//  for (int i=0; i < n; i++) {
//    if (timers[i]!=null) {
//      timers[i].updateTotalTime(input * 1000);
//      exes[i].intervalValue = input;
//      println("interval is set to: " + input  + " sec");
//    }
//  }
//}


void execfileSelected(File selection) {
  if (selection == null) {
    log2console("No file selected\n");
  } else {
    if (buttonTypedId != -1) {
      String filepath = selection.getAbsolutePath();
      println(filepath);
      Textarea tf =  (Textarea)filePathTextAreas.get(buttonTypedId);
      tf.setText(filepath);
      exes[buttonTypedId].filepath = filepath;
    } else {
      log2console("\nopened failed, type is not set correctly. id:  " + buttonTypedId);
    }
  }
}
