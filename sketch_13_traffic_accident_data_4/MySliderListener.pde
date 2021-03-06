MySliderListener mySliderListener;

class MySliderListener implements ControlListener
{
  public boolean sliderBeingDragged = false;
  private int currentValue = 0;
  
  public void controlEvent(ControlEvent theEvent) {
    sliderBeingDragged = true;
   
    int  val = Math.round( theEvent.getController().getValue() );
    if (val != this.currentValue) {
      this.currentValue = val;
      println("i got an event from mySlider, gotvalue: " + val);
      
      long mappedTime = Math.round( map(val, 0, 259, minUnixTime, maxUnixTime) );
      
    // This is in the main sketch
    sliderUnixTime = mappedTime;
    
      println("Mapped unix time is: " + mappedTime);
      
      getAccidentsByTimePeriod(mappedTime);
      theEvent.getController().getCaptionLabel().setText(mappedTime + " Crash Total: " + 1);
    }
  }
}
