MySliderListener mySliderListener;

class MySliderListener implements ControlListener
{
  public boolean sliderBeingDragged = false;
  
  public void controlEvent(ControlEvent theEvent)
  {
    //mapEventDispatcher.unregister(map, "pan");
    
    
    sliderBeingDragged = true;
    
    int  val = Math.round( theEvent.getController().getValue() );
    println("i got an event from mySlider, gotvalue: " + val);
    
    long mappedTime = Math.round( map(val, 0, 259, minUnixTime, maxUnixTime) );
    
    // This is in the main sketch
    sliderUnixTime = mappedTime;
    
    println("Mapped unix time is: " + mappedTime);
    
    getAccidentsByCondition("UNIX_TIME", mappedTime);
  }

}
