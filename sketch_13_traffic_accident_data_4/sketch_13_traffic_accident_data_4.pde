import java.util.List;
import java.util.Map;
import java.util.Iterator;
import java.util.Random;

// UnfoldingMaps library imports
import de.fhpotsdam.unfolding.UnfoldingMap;
import de.fhpotsdam.unfolding.geo.Location;
import de.fhpotsdam.unfolding.utils.MapUtils;
import de.fhpotsdam.unfolding.events.EventDispatcher;
import de.fhpotsdam.unfolding.events.MapEventBroadcaster;
import de.fhpotsdam.unfolding.interactions.MouseHandler;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.marker.MarkerManager;

// UnfoldingMaps library map providers
import de.fhpotsdam.unfolding.providers.Google;
//import de.fhpotsdam.unfolding.providers.Microsoft;

// giCentre library imports
import org.gicentre.utils.gui.TextPopup;

// Import SQL database connectivity library
import de.bezier.data.sql.*;

// import GUI controls lib
import controlP5.*;

// Our connection to the database
MySQL dbConnection;

// Our controlP5 object used for GUI widgets
ControlP5 cp5;


TextPopup textPopup;
PFont popupFont = createFont("ArialUnicodeMS-16.vlw", 16);


// Define the latitude and longitude (in that order!) of Ballarat
Location ballaratLocation = new Location(-37.5621071f, 143.85614929999997f);

// Our map - wow! much geography! very important! ;-)
UnfoldingMap map;
EventDispatcher mapEventDispatcher;
MouseHandler mapMouseHandler;
//MarkerManager<ImageMarker> markerManager = new MarkerManager<ImageMarker>();
MarkerManager markerManager = new MarkerManager();

float minUnixTime = 0;
float maxUnixTime = 0;

// Keep a HashMap of all our ImageMarkers
Map<String, ImageMarker> markerData = new HashMap<String, ImageMarker>();

// The image for our markers
PImage markerImage;

//MySliderListener mySliderListener;

// We'll keep track of whether the mouse is being dragged (i.e. LMB down + mouse movement)
boolean mouseIsDragging = false;

int currentWeek = 0;

// This is the list of our markers
//List<Location> locationList = new ArrayList<Location>();


// Set up our sketch - runs once at start of execution
void setup()
{
    // Set the window size and use the OpenGL renderer
    // Note: If we want this fullscreen we can use displayWidth and displayHeight.
    //size(displayWidth, displayHeight, OPENGL);
    size(800, 600, OPENGL);

    
    // Enable resizing the sketch window
    frame.setResizable(true);
    
    // Connect to DB
    String user = "root";
    String pass = "testing123";
    String host = "localhost";
    String database = "govhack2015";  
    dbConnection = new MySQL(this, host, database, user, pass);
    dbConnection.connect();
    
    dbConnection.query("SELECT MIN(`UNIX_TIME`) AS `min`FROM `accidents` WHERE `UNIX_TIME` != ''");
    dbConnection.next();
    minUnixTime = Long.parseLong( dbConnection.getString("min") );
    println("min unix: " + minUnixTime);
    
    dbConnection.query("SELECT MAX(`UNIX_TIME`) AS `max` FROM `accidents` WHERE `UNIX_TIME` != ''");
    dbConnection.next();
    maxUnixTime = Long.parseLong( dbConnection.getString("max") );
    println("max unix: " + maxUnixTime);
 
     // Instantiate our cp5 GUI controls object
     cp5 = new ControlP5(this);
     
     // Add our time slider
     cp5.addSlider("Time (weeks)")
     .setPosition(150, 560)
     .setWidth(500)
     .setRange(0, 259)                // Week number (260 weeks in 5 years)
     .setValue(130)                   // Default we'll start half way
     .setNumberOfTickMarks(26)
     .setSliderMode(Slider.FLEXIBLE)
     ;
     
    
    
    // Setup a text popup to experiment with...
//    textPopup = new TextPopup(this, popupFont, width / 4, height / 4);
//    textPopup.setTextSize(16);
//    textPopup.setInternalMargin(10, 10);
//    textPopup.addText("Foobar! Woop-woop! =P");
//    textPopup.setIsActive(true);
    
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
    
    markerManager = new MarkerManager();
    map.addMarkerManager(markerManager);
    
    // Specify our initial location and zoom level. Note: Higher zoom values are more zoomed in.
    map.zoomAndPanTo(8, ballaratLocation);
    
    // Enable tweening so we animate the map rather than jumping to location. Note: Default tweening flag value is false.
    map.setTweening(true);
    
    // Specify that we cannot pan to more than 20km away from this point
    //map.setPanningRestriction(ballaratLocation, 20.0f);
    
    // Dispatch events from this sketch to our map object as appropriate
    //MapUtils.createDefaultEventDispatcher(this, map);
    
    //EventDispatcher mapEventDispatcher = MapUtils.createDefaultEventDispatcher(this, map);
    
    //MapEventBroadcaster myMapEventBroadcaster = new MapEventBroadcaster(mapEventDispatcher, map); 
    
    //myMapEventBroadcaster.setEventDispatcher(mapEventDispatcher);
    
    //EventDispatcher mapEventDispatcher = MapUtils.createDefaultEventDispatcher(this, map); 
    mapEventDispatcher = new EventDispatcher();
    // Add mouse interaction to both maps
    mapMouseHandler = new MouseHandler(this, map);
    mapEventDispatcher.addBroadcaster(mapMouseHandler);
    
    mapEventDispatcher.register(map, "pan", map.getId());
    //mapEventDispatcher.unregister(map, "pan", map.getId() ); // THIS WILL WORK NOW!
    mapEventDispatcher.register(map, "zoom");
    
    mySliderListener = new MySliderListener();//mapEventDispatcher, map);  
    cp5.getController("Time (weeks)").addListener(mySliderListener);
    
    // Create a marker for Ballarat
    // Note: ui marker options are "ui/marker.png", "ui/marker_red.png" or "ui/marker_gray.png"
    //ImageMarker ballaratMarker = new ImageMarker(ballaratLocation, loadImage("ui/marker_red.png") );
    
   
    
    // Add our ballarat marker to the map
    // Note: We can use map.addMarkers(marker1, marker2, marker3, ..., markerX); if we want to add a bunch at once
    //map.addMarker(ballaratMarker);
    
    // ------ Load accident table -----
    
    //latitudesTable = new Table("LATITUDE.txt");
    
    //println("Number of rows in lattitudes: " + latitudesTable.getRowCount() );
    //String test = latitudesTable.getString(0);
    
    //latValues = loadStrings("LATITUDE.txt");
    //lonValues = loadStrings("LONGITUDE.txt");
    
    //int latCount = latValues.length;
    //int lonCount = lonValues.length;
    
    // Load our marker image
    markerImage = loadImage("ui/marker_red.png");
    
           
            //locationList.add(l);  
            
            // Create an ImageMarker at this location, with the id value of loop, and using our red marker image
            //ImageMarker im = new ImageMarker(l, loop, markerImage );
            
            // Add the marker image to the map
            //map.addMarker(im);
        //}
    
    //println(latitudesTable.getString(0));
//    println(latitudesTable.getString(1));
//    float foo = latitudesTable.getFloat(1);
//    println("Foo is: " + foo);
//    
    
}

// Runs once per frame
void draw()
{
    //mySliderListener.sliderBeingDragged = false;
  
  map.addMarker( new ImageMarker(ballaratLocation, "1", markerImage) );
  
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


void getAccidentsByCondition(String field, long value)
{
  long oneWeekAhead = value + (60L * 60L * 24L * 7L);
  
  // Query the database
  String queryString = "SELECT `ACCIDENT_NO`, `LONGITUDE`, `LATITUDE` FROM `accidents` WHERE `" + field + "`>" + value + " AND `" + field + "` < " + oneWeekAhead;
  dbConnection.query(queryString);
  
  // Clear existing markers on the map
  markerData.clear();
  
  int count = 0;
  
  markerManager.clearMarkers();    //removeMarkers();
  
  while (dbConnection.next() )
  {  
      // Create a location object fromthe longitude and latitude  
      float lon = parseFloat( dbConnection.getString("LONGITUDE") );
      float lat = parseFloat( dbConnection.getString("LATITUDE")  );
      Location loc = new Location(lat, lon);
      
      String accidentNum = dbConnection.getString("ACCIDENT_NO");
      
      
       ImageMarker m = new ImageMarker(loc, accidentNum, markerImage);
       
        //map.addMarker( new ImageMarker(loc, "1", markerImage) );
       
      //ScreenPosition screenPos = map.getScreenPosition(loc);
      //ellipse(loc, 5, 5);
      
      //ImageMarker im = new ImageMarker(loc, connection.getString("ACCIDENT_NO"), markerImage);
      
      println("Creating marker " + count + " at: " + loc.toString() );
      
      //Marker m = new SimplePointMarker(loc);
      //m.draw();
      
      //m.setRadius(5.0f);
      
      map.addMarker(m);
    
      // Create the hashmap entry with the accident number as the key
      markerData.put(dbConnection.getString("ACCIDENT_NO"), m);
      
      count++;
     
  }
   println("Got record count: " + count);
  //return data;
}

// ----- Mouse handler functions -----

// Mouse dragged fires when a mouse button is held down and the mouse is moved while the button is still down
void mouseDragged()
{
    if (mouseButton == LEFT)
    {
        // Set our flag
        mouseIsDragging = true;
        
        if (mySliderListener.sliderBeingDragged)
        {
          println("WHHHHHHHHHHHYYYYYYYYYYYYYYYYY?!?!?!");
          //mapEventDispatcher.unregister(map, "pan", "1");
          //mapEventDispatcher.unregister(map, "pan");
          //mapEventDispatcher.unregister(map, "zoom");
          //mapEventDispatcher.removeBroadcaster(mapMouseHandler);
        }
        
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
       println("Mouse is no longer dragging!");
        mouseIsDragging = false;
    }
}

void mousePressed()
{
    // Add a marker if it's the right mouse button
    if (mouseButton == RIGHT)
    { 
      /*
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
        */
    }   
}

void mouseMoved()
{
    // Deselect all marker
  for (Marker marker : map.getMarkers()) {
    marker.setSelected(false);
  }

  // Select hit marker
  // Note: Use getHitMarkers(x, y) if you want to allow multiple selection.
  Marker marker = map.getFirstHitMarker(mouseX, mouseY);
  if (marker != null)
  {
    marker.setSelected(true);
  }
}
