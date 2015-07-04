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

static final int APP_WIDTH = 800;
static final int APP_HEIGHT = 600;

// Our connection to the database
MySQL dbConnection;

// Our controlP5 object used for GUI widgets
ControlP5 cp5;

Filter fCrash, fCrime;
Group gCrash, gCrime;
CheckBox cbCrash, cbCrime;

CrimeStalker_DropDown crashDropdown;
CrimeStalker_DropDown crimeDropdown;

HashMap<String, String> toggleCrashData;

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
void setup() {
    // Set the window size and use the OpenGL renderer
    // Note: If we want this fullscreen we can use displayWidth and displayHeight.
    //size(displayWidth, displayHeight, OPENGL);
    size(APP_WIDTH, APP_HEIGHT, OPENGL);

    
    // Enable resizing the sketch window
    frame.setResizable(true);
    
    // Connect to DB
    String user = "root";
//    String pass = "testing123";
    String pass = "";
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

  smooth();
  cp5.getTooltip().setDelay(500);

  // crash drop down list
  crashDropdown = new CrimeStalker_DropDown(cp5);
  crashDropdown.setPosition(0, 13);
  crashDropdown.setLabel("Crash Records");
  crashDropdown.setCheckBoxList(generateCrashDropDownData());
  crashDropdown.setSize(120, 20);
  crashDropdown.initialize();
  
  // crime drop down list
  crimeDropdown = new CrimeStalker_DropDown(cp5);
  crimeDropdown.setPosition(APP_WIDTH - 300, 13);
  crimeDropdown.setLabel("Crime Records");
  crimeDropdown.setCheckBoxList(generateCrimeDropDownData(dbConnection));
  crimeDropdown.setSize(270, 20);
  crimeDropdown.initialize();



/*
  fCrash = new Filter();
  fCrime = new Filter();
  populateFilterData();
  
  gCrash = cp5.addGroup("gCrash")
                .setPosition(0,13)
                .setBackgroundColor(color(0,76,153,180))
                .close()
                ;
  gCrash.captionLabel().set("Crashes Records");
  cbCrash = cp5.addCheckBox("cbCrash")
                .setColorForeground(color(150))
                .setColorBackground(color(255))
                .setColorActive(color(150))
                .setColorLabel(color(255))
                .setSize(20, 20)
                .setItemWidth(10)
                .setItemHeight(10)
                .setItemsPerRow(1)
                .setSpacingColumn(10)
                .setSpacingRow(5)
                .setGroup(gCrash)
                ;
 int backgroundHeight = 0; 
 for (int i=0; i<fCrash.getSize(); i++){ 
   cbCrash.addItem(fCrash.getColumnNameByIndex(i), i); 
   backgroundHeight += 15;  
 } 
 gCrash.setBackgroundHeight(backgroundHeight-3);

  
  gCrime = cp5.addGroup("gChrime")
                .setPosition(APP_WIDTH-250,13)
                .setBackgroundColor(color(0))
                .setWidth(250)
                .close()
                ;
  gCrime.captionLabel().set("Chrime By Location");
  cbCrime = cp5.addCheckBox("cbCrime")
                .setColorForeground(color(150))
                .setColorBackground(color(255))
                .setColorActive(color(150))
                .setColorLabel(color(255))
                .setSize(20, 20)
                .setItemWidth(10)
                .setItemHeight(10)
                .setItemsPerRow(1)
                .setSpacingColumn(10)
                .setSpacingRow(5)
                .setGroup(gCrime)
                ;
 backgroundHeight = 0; 
 for (int i=0; i<fCrime.getSize(); i++){ 
   cbCrime.addItem(fCrime.getColumnNameByIndex(i), i); 
   backgroundHeight += 15;  
 } 
 gCrime.setBackgroundHeight(backgroundHeight-3);
*/
}

// Runs once per frame
void draw()
{
    //mySliderListener.sliderBeingDragged = false;
  
  //map.addMarker( new ImageMarker(ballaratLocation, "1", markerImage) );
  
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

// draw an individual marker
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
       mapEventDispatcher.register(map, "pan", map.getId());
       println("Mouse is no longer dragging!");
        mouseIsDragging = false;
    }
}

void mousePressed()
{
    if (mouseButton == LEFT)
    {
      if (cp5.getController("Time (weeks)").isMousePressed())
      {
          mapEventDispatcher.unregister(map, "pan", map.getId());
      }
    }
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

void populateFilterData(){
  fCrash.addColumn("ACCIDENT_TYPE");
  fCrash.addColumn("HIT_RUN_FLAG");
  fCrash.addColumn("SEVERITY");
  fCrash.addColumn("FATALITY");
  fCrash.addColumn("SERIOUS_INJURY");
  fCrash.addColumn("MALES");
  fCrash.addColumn("FEMALES");
  fCrash.addColumn("BYCYCLIST");
  fCrash.addColumn("PEDESTRIAN");
  fCrash.addColumn("OLD_DRIVER");
  fCrash.addColumn("YOUNG_DRIVER");
  fCrash.addColumn("ALCOHOL_RELATED");
  fCrime.addColumn("A10 Homicide and related offences");
  fCrime.addColumn("A20 Assault and related offences");
  fCrime.addColumn("A30 Sexual offences");
  fCrime.addColumn("A40 Abduction and related offences");
  fCrime.addColumn("A50 Robbery");
  fCrime.addColumn("A60 Blackmail and extortion");
  fCrime.addColumn("A70 Stalking, harassment and threatening behaviour");
  fCrime.addColumn("A80 Dangerous and negligent acts endangering people");
  fCrime.addColumn("B10 Arson");
  fCrime.addColumn("B20 Property damage");
  fCrime.addColumn("B30 Burglary/Break and enter");
  fCrime.addColumn("B40 Theft");
  fCrime.addColumn("B50 Deception");
  fCrime.addColumn("C10 Drug dealing and trafficking");
  fCrime.addColumn("C20 Cultivate or manufacture drugs");
  fCrime.addColumn("C30 Drug use and possession");
  fCrime.addColumn("D10 Weapons and explosives offences");
  fCrime.addColumn("D20 Disorderly and offensive conduct");
  fCrime.addColumn("D30 Public nuisance offences");
  fCrime.addColumn("D40 Public security offences");
  fCrime.addColumn("E10 Justice procedures");
  fCrime.addColumn("E20 Breaches of orders");
  fCrime.addColumn("F20 Transport regulation offences");
  fCrime.addColumn("F30 Other government regulatory offences");
  fCrime.addColumn("F90 Miscellaneous offences");
}
