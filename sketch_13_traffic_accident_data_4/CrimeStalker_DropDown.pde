class CrimeStalker_DropDown {
  private ControlP5 parent;
  private int positionX;
  private int positionY;
  private String label;
  private String[] checkboxList;
  private int sizeX;
  private int sizeY;
  private ControlListener listener;
  private Group g;
  private CheckBox cb;
  
  public CrimeStalker_DropDown(ControlP5 cp5) {
    this.parent = cp5;
    this.checkboxList = new String[0];
  }
  
  public void setPosition(int x, int y) {
    this.positionX = x;
    this.positionY = y;
  }
  
  public void setLabel(String label) {
    this.label = label;
  }
  
  public void setSize(int x, int y) {
    this.sizeX = x;
    this.sizeY = y;
  }
  
  public void setCheckBoxList(String[] list) {
    this.checkboxList = list;
  }
  
  public void setControlListener(ControlListener l) {
    this.listener = l;
  }
  
  public CheckBox getCheckBox() {
    return this.cb;
  }
  
  public void initialize() {
    PFont font;
    font = createFont("Aaargh.ttf", 10);
    
    this.parent.setFont(font);
    
    this.g = this.parent.addGroup(this.label + "_group")
                  .setPosition(this.positionX, this.positionY)
                  .setWidth(this.sizeX)
                  .setBarHeight(this.sizeY)
                  .setBackgroundColor(color(0,0,0, 225))
                  .close();
    this.g.captionLabel().set(this.label);
    this.g.setBackgroundHeight(17 * this.checkboxList.length);
    this.cb = this.parent.addCheckBox(this.label + "_checkbox")
                  .setColorForeground(color(150))
                  .setColorBackground(color(202, 225, 255))
                  .setColorActive(color(0, 151, 35))
                  .setColorLabel(color(255, 255, 255))
                  .setColorValue(color(150, 0, 0))
                  .setSize(20, 20)
                  .setItemWidth(10)
                  .setItemHeight(12)
                  .setItemsPerRow(1)
                  .setSpacingColumn(10)
                  .setSpacingRow(5)
                  .setGroup(this.g);
    // add data into checkbox
    for (int i = 0; i < this.checkboxList.length; i++) {
      this.cb.addItem(this.checkboxList[i], float(i));
    }
  }
}

