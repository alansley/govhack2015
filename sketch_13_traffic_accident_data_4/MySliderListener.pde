MySliderListener mySliderListener;

class MySliderListener implements ControlListener
{
  public boolean sliderBeingDragged = false;
  
  public void controlEvent(ControlEvent theEvent)
  {
    //mapEventDispatcher.unregister(map, "pan");
    
    
    sliderBeingDragged = true;
    println("i got an event from mySlider, gotvalue: " + theEvent.getController().getValue());
  }

}
