
import controlP5.*;

static final int APP_WIDTH = 700;
static final int APP_HEIGHT = 400;

ControlP5 cp5;

Filter fCrash, fCrime;
Group gCrash, gCrime;
CheckBox cbCrash, cbCrime;

void setup() {
  size(APP_WIDTH, APP_HEIGHT);
  smooth();
  cp5 = new ControlP5(this);
  cp5.getTooltip().setDelay(500);

  fCrash = new Filter();
  fCrime = new Filter();
  populateFilterData();
  
  gCrash = cp5.addGroup("gCrash")
                .setPosition(50,13)
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
    for (int i=0; i<fCrash.getSize(); i++){
      cbCrash.addItem(fCrash.getColumnNameByIndex(i), i);
//      cp5.getTooltip().register(fCrash.getColumnNameByIndex(i), fCrash.getColumnDescByIndex(i));
    }

  
  gCrime = cp5.addGroup("gChrime")
                .setPosition(APP_WIDTH-250,13)
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
    for (int i=0; i<fCrime.getSize(); i++){
      cbCrime.addItem(fCrime.getColumnNameByIndex(i), i);
//      cp5.getTooltip().register(fCrime.getColumnNameByIndex(i), fCrime.getColumnDescByIndex(i));
    }
}

void draw() {
  background(100);
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(cbCrash)) {
    for (int i=0;i<cbCrash.getArrayValue().length;i++) {
      int n = (int)cbCrash.getArrayValue()[i];
      if (n > 0){
        fCrash.setCheckByIndex(i, true);
      }
      else{
        fCrash.setCheckByIndex(i, false);
      }        
    }
  }
  if (theEvent.isFrom(cbCrime)) {
    for (int i=0;i<cbCrime.getArrayValue().length;i++) {
      int n = (int)cbCrime.getArrayValue()[i];
      if (n > 0){
        fCrime.setCheckByIndex(i, true);
      }
      else{
        fCrime.setCheckByIndex(i, false);
      }        
    }
  }
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

//test
void keyPressed() {
  if (key==' ') {
    ArrayList<Column> l = fCrash.getColumnList();
    for (int i=0; i<l.size(); i++){
      println(l.get(i).isChecked());
    }
  } 
  
}

