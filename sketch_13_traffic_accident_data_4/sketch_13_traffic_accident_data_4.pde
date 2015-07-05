// CrimeStalkers - visualised customisable car accident data over time and allows for
// comparison with crime data for regions.
// Created at GovHack 2015, Ballarat - 3rd July 2015 to 5th July 2015.
// Authors: Al Lansley, Minh Tuan Nguyen, Wentao Zhang
// This program is made available as a CC-BY licence:
// https://creativecommons.org/licenses/by/4.0/

// Standard java imports
import java.util.List;
import java.util.Map;
import java.util.Iterator;
import java.util.Random;

// Import UnfoldingMaps classes as req'd
import de.fhpotsdam.unfolding.UnfoldingMap;
import de.fhpotsdam.unfolding.geo.Location;
import de.fhpotsdam.unfolding.utils.MapUtils;
import de.fhpotsdam.unfolding.events.EventDispatcher;
import de.fhpotsdam.unfolding.events.MapEventBroadcaster;
import de.fhpotsdam.unfolding.interactions.MouseHandler;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.marker.MarkerManager;

// Import UnfoldingMaps providers
import de.fhpotsdam.unfolding.providers.Google;
//import de.fhpotsdam.unfolding.providers.Microsoft; // Add providers as req'd...

// Import SQL database connectivity library
import de.bezier.data.sql.*;

// Import GUI controls lib
import controlP5.*;

static final int APP_WIDTH = 800;
static final int APP_HEIGHT = 600;

// Our connection to the database
MySQL dbConnection;

// Our controlP5 object used for GUI widgets
ControlP5 cp5;
CrimeStalker_DropDown crashDropdown;
CrimeStalker_DropDown crimeDropdown;

HashMap<String, String> toggleCrashData;

// Define the latitude and longitude (in that order!) of Ballarat
Location ballaratLocation = new Location(-37.5621071f, 143.85614929999997f);

// Declare our map and helper objects
UnfoldingMap map;
EventDispatcher mapEventDispatcher;
MouseHandler mapMouseHandler;
MarkerManager markerManager;

// These will be the minimum and maximum (i.e. earliest and latest) times for our car accident records
// Note: We need these to map the slider values into the range of the accident records themselves
float minUnixTime = 0;
float maxUnixTime = 0;

// Keep a HashMap of all our ImageMarkers
Map<String, ImageMarker> markerData = new HashMap<String, ImageMarker>();

// We'll need to keep track of the sliders mapped-into-unix-time value so we can convert it back into
// a human-readable date to update the frame title.
long sliderUnixTime = 0;

// The image for our markers
PImage markerImage;

// We'll keep track of whether the mouse is being dragged (i.e. LMB down + mouse movement)
boolean mouseIsDragging = false;

// Set up our sketch - runs once at start of execution
void setup() {
    // Set the window size and use the OpenGL renderer
    // Note: If we want this fullscreen we can use displayWidth and displayHeight.
    //size(displayWidth, displayHeight, OPENGL);
    size(APP_WIDTH, APP_HEIGHT, OPENGL);
    
    // Enable resizing the sketch window
    frame.setResizable(true);
    
    // Connect to our database
    String user = "root";
//    String pass = "testing123";
    String pass = "";
    String host = "localhost";
    String database = "govhack2015";  
    dbConnection = new MySQL(this, host, database, user, pass);
    dbConnection.connect();
    // TODO: Need to spit some debug here if the DB connection fails!
    
    // Get the lowest unix time from all our car accident records (i.e. the earliest record)
    dbConnection.query("SELECT MIN(`UNIX_TIME`) AS `min`FROM `accidents` WHERE `UNIX_TIME` != ''");
    dbConnection.next();
    minUnixTime = Long.parseLong( dbConnection.getString("min") );
    println("min unix: " + minUnixTime);
    
    // Get the highest unix time from all our car accident records (i.e. the latest record)
    dbConnection.query("SELECT MAX(`UNIX_TIME`) AS `max` FROM `accidents` WHERE `UNIX_TIME` != ''");
    dbConnection.next();
    maxUnixTime = Long.parseLong( dbConnection.getString("max") );
    println("max unix: " + maxUnixTime);
 
     // Instantiate our cp5 GUI controls object
     cp5 = new ControlP5(this);
     
     // Add our time slider
     cp5.addSlider("Time (weeks)")
     .setPosition(width * 0.1f, height * 0.9f) // Slider starts 10% across, 90% down
     .setWidth( Math.round(width * 0.8f) )     // Slider is 80% width of the screen
     .setRange(0, 259)                         // Week number (260 weeks in 5 years)
     .setValue(130)                            // Default we'll start half way
     .setNumberOfTickMarks(260)
     .snapToTickMarks(true)
     .setSliderMode(Slider.FLEXIBLE)           // Show grabable 'triangle' on slider
     ;
    
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
    // Note: the Unfolding maps API can be found here: http://unfoldingmaps.org/javadoc/index.html
    map = new UnfoldingMap( this, new Google.GoogleMapProvider() );
    
    // Instantiate our event dispatcher and mouse handler, tie the mouse handler to this sketch and this map,
    // then add the mouse handler to the map event dispatcher 
    mapEventDispatcher = new EventDispatcher();
    mapMouseHandler = new MouseHandler(this, map);
    mapEventDispatcher.addBroadcaster(mapMouseHandler);
    
    // Instantiate our marker manager and add it to the map
    // Note: We need a specific, named marker manager to be able to clear all the markers on the map
    // when the slider value changes
    markerManager = new MarkerManager();
    map.addMarkerManager(markerManager);
    
    // Specify our initial location and zoom level. Note: Higher zoom values are more zoomed in.
    map.zoomAndPanTo(8, ballaratLocation);
    
    // Enable tweening so we animate the map rather than jumping to location. Note: Default tweening flag value is false.
    map.setTweening(true);
    
    // Specify that we cannot pan to more than 20km away from this point
    //map.setPanningRestriction(ballaratLocation, 20.0f);
    
    // Register panning and zooming of the map
    mapEventDispatcher.register(map, "pan", map.getId());
    mapEventDispatcher.register(map, "zoom");
    
    // Load our marker image
    markerImage = loadImage("ui/marker_red.png");
    
    // Instantiate our slider listener and add it to the time slider
    mySliderListener = new MySliderListener();  
    cp5.getController("Time (weeks)").addListener(mySliderListener);

  smooth();
  cp5.getTooltip().setDelay(500);

  // crash drop down list
  crashDropdown = new CrimeStalker_DropDown(cp5);
  crashDropdown.setPosition(20, 13);
  crashDropdown.setLabel("Crash Records");
  crashDropdown.setCheckBoxList(generateCrashDropDownData());
  crashDropdown.setSize(120, 13);
  crashDropdown.initialize();
  
  // crime drop down list
  crimeDropdown = new CrimeStalker_DropDown(cp5);
  crimeDropdown.setPosition(APP_WIDTH - 320, 13);
  crimeDropdown.setLabel("Crime Records");
  crimeDropdown.setCheckBoxList(generateCrimeDropDownData(dbConnection));
  crimeDropdown.setSize(300, 13);
  crimeDropdown.initialize();
}

// Runs once per frame
void draw()
{
    // Draw our map
    map.draw();
  
    // Only draw our target lines if the mouse is not being dragged
    if (!mouseIsDragging) { drawTargetOverlay(); }
}

void drawTargetOverlay()
{
    // Set stroke to red
    stroke(255,0,0);  
    
    // Draw a vertical line centred on mouseY and a horizontal line centred on mouseX
    line(mouseX, 0, mouseX, height);  
    line(0, mouseY, width, mouseY);
  
    // Draw an ellipse in the centre of the window in semi-transparent white
    fill(255,255,255,128);
    ellipse(mouseX, mouseY, 10, 10); 
}

void drawMarker(String accidentNo, Float lon, Float lat) {
  Location loc = new Location(lat, lon);
  ImageMarker m = new ImageMarker(loc, accidentNo, markerImage);
  map.addMarker(m);
  markerData.put(accidentNo, m);
}

// draw a list of marker data
int drawMarkerList(HashMap<String, Float[]> data) {
  int count = 0;
  Iterator it = data.entrySet().iterator();
  while (it. hasNext()) {
    Map.Entry pair = (Map.Entry)it.next();
    Float[] coord = (Float[])pair.getValue();
    drawMarker((String)pair.getKey(), coord[0], coord[1]);
    count++;
  }
  return count;
}

// if timestamp = -1 => use current slider time 
HashMap<String, Float[]> getAccidentsByCondition(String field, String value, long timestamp) {
  if (timestamp == -1) {
    int val = Math.round( cp5.getController("Time (weeks)").getValue() ); 
    timestamp = Math.round( map(val, 0, 259, minUnixTime, maxUnixTime) );
  }
  long oneWeekAhead = timestamp + (60L * 60L * 24L * 7L);
  
  // Query the database
  String queryString = "SELECT `ACCIDENT_NO`, `LONGITUDE`, `LATITUDE` FROM `accidents` WHERE `UNIX_TIME`>" + timestamp + " AND `UNIX_TIME` < " + oneWeekAhead;
  if (field != "UNIX_TIME") { queryString += " AND `" + field + "`='" + value + "'"; }
  dbConnection.query(queryString);

  HashMap<String, Float[]> data = new HashMap<String, Float[]>(); 
  while (dbConnection.next()) {
    Float[] coord = new Float[2];
    coord[0] = parseFloat( dbConnection.getString("LONGITUDE") );
    coord[1] = parseFloat( dbConnection.getString("LATITUDE") );
    data.put(dbConnection.getString("ACCIDENT_NO"), coord);
  }
  
  return data;
}

HashMap<String, Float[]> getAccidentsByAccidentSelection(ArrayList<String> columns) {
  int val = Math.round( cp5.getController("Time (weeks)").getValue() ); 
  long timestamp = Math.round( map(val, 0, 259, minUnixTime, maxUnixTime) );
  long oneWeekAhead = timestamp + (60L * 60L * 24L * 7L);
  
  // Query the database
  String queryString = "SELECT `ACCIDENT_NO`, `LONGITUDE`, `LATITUDE` FROM `accidents` WHERE `UNIX_TIME`>" + timestamp + " AND `UNIX_TIME` < " + oneWeekAhead;
  if (columns.size() > 0) {
    queryString += " AND (`" + columns.get(0) + "`"+toggleCrashData.get(columns.get(0));
    for (int i = 1; i < columns.size(); i++) {
      queryString += " OR `" + columns.get(i) + "`"+toggleCrashData.get(columns.get(i));
    }
    queryString += ")";
  }
  println(queryString);
  dbConnection.query(queryString);

  HashMap<String, Float[]> data = new HashMap<String, Float[]>(); 
  while (dbConnection.next()) {
    Float[] coord = new Float[2];
    coord[0] = parseFloat( dbConnection.getString("LONGITUDE") );
    coord[1] = parseFloat( dbConnection.getString("LATITUDE") );
    data.put(dbConnection.getString("ACCIDENT_NO"), coord);
  }
  
  return data;
}

void getAccidentsByTimePeriod(long timestamp) {
  // Clear existing markers on the map
  markerData.clear();
  // remove all existing markers
  markerManager.clearMarkers();
  
  HashMap<String, Float[]> data = getAccidentsByCondition("UNIX_TIME", "", timestamp);
  int count = drawMarkerList(data);
  println("Got record count: " + count);
} // End of getAccidentsByCondition method

// ----- Mouse handler functions -----
// Mouse dragged fires when a mouse button is held down and the mouse is moved while the button is still down
void mouseDragged()
{
    if (mouseButton == LEFT)
    {
        // Update the window title with the date (converted back from the unix time of the slider)
        // TODO: Make sure this is Australia/Melbourne timezone correct!!!
        java.util.Date dateTime = new java.util.Date((long)sliderUnixTime * 1000);
        frame.setTitle("Current date range: " + dateTime + " to +7 days");
        
        // Set our flag
        mouseIsDragging = true;
        
        if (mySliderListener.sliderBeingDragged)
        {
          //
        }
        
        // Change the mouse cursor to the MOVE cursor while the mouse is being dragged 
        cursor(MOVE);
    }
    
    // Can also get the LMB like this if req'd:
    // else if (mouseButton != RIGHT) { }
}

// Mouse clicked fires when a mouse button is released
void mouseReleased()
{
    // Return the mouse cursor to a standard arrow when a mouse button is released
    cursor(ARROW);
  
    // When the LMB is released then we reset the mouseIsDraggingFlag to false so we draw our target lines
    if (mouseButton == LEFT)
    {
        // Regist the map panning handler again when we release the LMB
        mapEventDispatcher.register(map, "pan", map.getId());
        mouseIsDragging = false;
    }
}

void mousePressed()
{
    if (mouseButton == LEFT)
    {
      // If we have pressed the mouse over the slider then unregister panning on the map
      if (cp5.getController("Time (weeks)").isMousePressed())
      {
          mapEventDispatcher.unregister(map, "pan", map.getId());
      }
    }
    
    // We can do stuff with the RMB if we want to...
    //if (mouseButton == RIGHT)
    //{ 
    //  // Do stuff...
    //}   
}

// We can do stuff if the mouse moves if we want to...
//void mouseMoved()
//{
// 
//}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) {
    if (theEvent.isFrom(crashDropdown.getCheckBox())) {
      crashCheckBoxHandler(crashDropdown.getCheckBox(), dbConnection);
      print("crash");
    } else if (theEvent.isFrom(crimeDropdown.getCheckBox())) {
      print("crime");
    }
  }
  //println(crashDropdown);

}

void crashCheckBoxHandler(CheckBox cb, MySQL connection) {
  List items = cb.getItems();
  ArrayList<String> selectedData = new ArrayList<String>();
  
  for (int i = 0; i < items.size(); i++) {
    Toggle t = (Toggle)items.get(i);
    if (t.getState()) {
      selectedData.add(t.getName());
    }
  }
  
  // Clear existing markers on the map
  markerData.clear();
  // remove all existing markers
  markerManager.clearMarkers();

  HashMap<String, Float[]> data = getAccidentsByAccidentSelection(selectedData);
  drawMarkerList(data);
}

String[] generateCrashDropDownData() {
  String[] names = {"HIT_RUN_FLAG", "RUN_OFFROAD", "FATALITY", "SERIOUSINJURY", "MALES", "FEMALES", "BICYCLIST", "MOTORIST", "PEDESTRIAN", "OLD_DRIVER", "YOUNG_DRIVER", "ALCOHOL_RELATED"};
  toggleCrashData = new HashMap<String, String>();
  toggleCrashData.put("HIT_RUN_FLAG", "='YES'");
  toggleCrashData.put("RUN_OFFROAD", "='YES'");
  toggleCrashData.put("FATALITY", ">0");
  toggleCrashData.put("SERIOUSINJURY", ">0");
  toggleCrashData.put("MALES", ">0");
  toggleCrashData.put("FEMALES", ">0");
  toggleCrashData.put("BICYCLIST", ">0");
  toggleCrashData.put("MOTORIST", ">0");
  toggleCrashData.put("PEDESTRIAN", ">0");
  toggleCrashData.put("OLD_DRIVER", ">0");
  toggleCrashData.put("YOUNG_DRIVER", ">0");
  toggleCrashData.put("ALCOHOL_RELATED", "='YES'");
  
  return names;
}

String[] generateCrimeDropDownData(MySQL dbConnection) {
  String query = "SELECT DISTINCT `CSA Offence Subdivision` FROM `crimes`";
  ArrayList<String> data = new ArrayList<String>();
  dbConnection.query(query);
  while (dbConnection.next()) {
    data.add(dbConnection.getString("CSA Offence Subdivision"));
  }
  String[] result = new String[data.size()];
  for (int i = 0; i < data.size(); i++) {
    result[i] = data.get(i);
  }
  return result;
}
