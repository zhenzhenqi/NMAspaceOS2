class Timer {

  int savedTime = 999999999  ; // When Timer started
  int totalTime;// How long Timer should last

  Timer(int tempTotalTime) {
    totalTime = tempTotalTime;
  }

  // Starting the timer
  void updateSavedTime() {
    // When the timer starts it stores the current time in milliseconds.
    savedTime = millis();
    println("updating saved time. current time for exe: " + index + " is " + millis()/1000 + ",  " + "savedTime " + savedTime/1000 + ",  " + "totalTime " + totalTime/1000);
  }


  void updateTotalTime(int tempTotalTime) {
    totalTime = tempTotalTime;
  }

  // The function isFinished() returns true if 5,000 ms have passed. 
  // The work of the timer is farmed out to this method.
  boolean isFinished() { 
    // Check how much time has passed
    int passedTime = millis()- savedTime;
    //if(millis()%1000 == 0)
    println("current time for exe: " + index + " is " + millis()/1000 + ",  " + "savedTime" + savedTime/1000 + ",  " + "  passedTime:  " + passedTime/1000);
    if (passedTime > totalTime) {
      return true;
    } else {
      return false;
    }
  }
}
