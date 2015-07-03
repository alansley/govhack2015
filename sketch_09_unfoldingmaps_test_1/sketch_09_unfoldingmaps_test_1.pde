import java.util.List;

// UnfoldingMaps library imports
import de.fhpotsdam.unfolding.UnfoldingMap;
import de.fhpotsdam.unfolding.geo.Location;
import de.fhpotsdam.unfolding.utils.MapUtils;

// UnfoldingMaps library map providers
import de.fhpotsdam.unfolding.providers.Google;
//import de.fhpotsdam.unfolding.providers.Microsoft;

// giCentre library imports
import org.gicentre.utils.gui.TextPopup;
import java.util.Random;

TextPopup textPopup;
PFont popupFont = createFont("ArialUnicodeMS-16.vlw", 16);


// Define the latitude and longitude (in that order!) of Ballarat
Location ballaratLocation = new Location(-37.5621071f, 143.85614929999997f);

// Our map - wow! much geography! very important! ;-)
UnfoldingMap map;

// Keep a list of all our ImageMarkers
List<ImageMarker> markerList = new ArrayList<ImageMarker>();

// We'll keep track of whether the mouse is being dragged (i.e. LMB down + mouse movement)
boolean mouseIsDragging = false;

// Set up our sketch - runs once at start of execution
void setup()
{
    // Set the window size and use the OpenGL renderer
    // Note: If we want this fullscreen we can use displayWidth and displayHeight.
    size(800, 600, OPENGL);
    
    // Enable resizing the sketch window
    frame.setResizable(true);
    
    // Setup a text popup to experiment with...
    textPopup = new TextPopup(this, popupFont, width / 4, height / 4);
    textPopup.setTextSize(16);
    textPopup.setInternalMargin(10, 10);
    textPopup.addText("Foobar! Woop-woop! =P");
    textPopup.setIsActive(true);
    
    // ----- Map setup -----    
    
    /* Map providers:
      OpenStreetMap.OpenStreetMapProvider();
      OpenStreetMap.CloudmadeProvider(API KEY, STYLE ID);
      StamenMapProvider.Toner();
      Google.GoogleMapProvider();
      Google.GoogleTerrainProvider();
      Microsoft.RoadProvider();
      Microsoft.AerialProvider();
      Yahoo.RoadProvider();
      Yahoo.HybridProvider();
      
      Further reading about switching map styles / providers dynamically:
          http://unfoldingmaps.org/tutorials/mapprovider-and-tiles.html#map-styles
      */
  
    // Create our map
    // Nopte: the Unfolding maps API can be found here: http://unfoldingmaps.org/javadoc/index.html
    map = new UnfoldingMap( this, new Google.GoogleMapProvider() );
    
    // Specify our initial location and zoom level. Note: Higher zoom values are more zoomed in.
    map.zoomAndPanTo(13, ballaratLocation);
    
    // Enable tweening so we animate the map rather than jumping to location. Note: Default tweening flag value is false.
    map.setTweening(true);
    
    // Specify that we cannot pan to more than 20km away from this point
    map.setPanningRestriction(ballaratLocation, 20.0f);
    
    // Dispatch events from this sketch to our map object as appropriate
    MapUtils.createDefaultEventDispatcher(this, map);
    
    // Create a marker for Ballarat
    // Note: ui marker options are "ui/marker.png", "ui/marker_red.png" or "ui/marker_gray.png"
    ImageMarker ballaratMarker = new ImageMarker(ballaratLocation, loadImage("ui/marker_red.png") );
    
    // Add our ballarat marker to the map
    // Note: We can use map.addMarkers(marker1, marker2, marker3, ..., markerX); if we want to add a bunch at once
    map.addMarker(ballaratMarker);
}

// Runs once per frame
void draw()
{
    // Draw our map
    map.draw();
  
    // Only draw our target lines if the mouse is not being dragged
    if (!mouseIsDragging)
    {
        drawTargetOverlay();
    }
}

void drawTargetOverlay()
{
    // Set stroke to red
    stroke(255,0,0);  
    
    line(mouseX, 0, mouseX, height);  // Vertical line centred on mouseY
    line(0, mouseY, width, mouseY);   // Horizontal line centred on mouseX
  
    // Draw an ellipse in the centre of the window
    fill(255,255,255,128);
    ellipse(mouseX, mouseY, 10, 10); 
}

// ----- Mouse handler functions -----

// Mouse dragged fires when a mouse button is held down and the mouse is moved while the button is still down
void mouseDragged()
{
    if (mouseButton == LEFT)
    {
        // Set our flag
        mouseIsDragging = true;
        
        // Change the mouse cursor to the MOVE cursor while the mouse is being dragged 
         cursor(MOVE);
    }
    
    // Can also get the LMB like this if req'd:
    // else if (mouseButton != RIGHT) { }
  
   //textPopup.draw();
}

// Mouse clicked fires when a mouse button is released
void mouseReleased()
{
    // Return the mouse cursor to a standard arrow when a mouse button is released
    cursor(ARROW);
  
    // When the LMB is released then we reset the mouseIsDraggingFlag to false so we draw our target lines
    if (mouseButton == LEFT)
    {
        mouseIsDragging = false;
    }
}

void mousePressed()
{
    // Add a marker if it's the right mouse button
    if (mouseButton == RIGHT)
    { 
        // Get the location of the mouse click on the map as a geographic location   
        Location clickLatLon = map.getLocation(mouseX, mouseY);
      
        // Create a marker at this location
        ImageMarker clickMarker = new ImageMarker(clickLatLon, loadImage("ui/marker_red.png") );
        
        // Add the new marker to our list of markers
        markerList.add(clickMarker);
      
        // Also add the new marker to the map
        map.addMarker(clickMarker);
      
        // Pan to the location of the click
        // Note: tweening must be enabled on the map via "map.setTweening(true);" for this to animate - if tweening is off we will immediately snap to the location.   
        map.panTo(mouseX, mouseY);
    }   
}

void mouseMoved()
{
    // Do stuff!
}
