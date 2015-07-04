class Table {
  String[] data;
  int rowCount;

//  String[] columns = split(rows[0], TAB);
//    columnNames = subset(columns, 1); // upper-left corner ignored
//    scrubQuotes(columnNames);
//    columnCount = columnNames.length;
//    
//  Table() {
//    data = new String[10][10];
//  }
  
  Table(String filename)
  {
    // Load the file into an array of Strings - returns null if loading fails
    String[] data = loadStrings(filename);
    
    if (data == null)
    {
      println("Returned null from attempt to load file: " + filename);
      exit();
    }
    else
    {
      println("File load of " + filename + " successful.");
    }
    
    rowCount = data.length;
    
//    data = new String[rows.length];
//    
//    for (int i = 0; i < rows.length; i++) {
//      if (trim(rows[i]).length() == 0) {
//        continue; // skip empty rows
//      }
//      if (rows[i].startsWith("#")) {
//        continue;  // skip comment lines
//      }
      
      // split the row on the tabs
      //String[] pieces = split(rows[i], TAB);
      // copy to the table array
      //data[rowCount] = pieces;
      //rowCount++;
      
      // this could be done in one fell swoop via:
      //data[rowCount++] = split(rows[i], TAB);
    //}
    // resize the 'data' array as necessary
    //data = (String[][]) subset(data, 0, rowCount);
  }

  int getRowCount() {
    return rowCount;
  }
  
  // find a row by its name, returns -1 if no row found
//  int getRowIndex(String name) {
//    for (int i = 0; i < rowCount; i++) {
//      if (data[i][0].equals(name)) {
//        return i;
//      }
//    }
//    println("No row named '" + name + "' was found");
//    return -1;
//  } 
  
//  String getRowName(int row) {
//    return getString(row, 0);
//  }

  String getString(int row) {
    println("WANG!");
    
    if (data[row] == null) { println("Something is seriously FUCKED!"); }
    
    println("Looking at: " + data[row]);
    
    return data[row];
  }

  
//  String getString(String rowName, int column) {
//    return getString(getRowIndex(rowName), column);
//  }
//  
//  int getInt(String rowName, int column) {
//    return parseInt(getString(rowName, column));
//  }
  
  int getInt(int row) {
    return parseInt(getString(row));
  }

  
//  float getFloat(String rowName, int column) {
//    return parseFloat(getString(rowName, column));
//  }
 
  float getFloat(int row) {
    return parseFloat( getString(row) );
  }
  
//  void setRowName(int row, String what) {
//    data[row][0] = what;
//  }

  void setString(int row, String what) {
    data[row] = what;
  }
//  
//  void setString(String rowName, int column, String what) {
//    int rowIndex = getRowIndex(rowName);
//    data[rowIndex][column] = what;
//  }
 
  void setInt(int row, int what) {
    data[row] = str(what);
  }
// 
//  void setInt(String rowName, int column, int what) {
//    int rowIndex = getRowIndex(rowName);
//    data[rowIndex][column] = str(what);
//  }
 
  void setFloat(int row, float what) {
    data[row] = str(what);
  }
//  
//  void setFloat(String rowName, int column, float what) {
//    int rowIndex = getRowIndex(rowName);
//    data[rowIndex][column] = str(what);
//  }
//  
  // Write this table as a TSV file
//  void write(PrintWriter writer) {
//    for (int i = 0; i < rowCount; i++) {
//      for (int j = 0; j < data[i].length; j++) {
//        if (j != 0) {
//          writer.print(TAB);
//        }
//        if (data[i][j] != null) {
//          writer.print(data[i][j]);
//        }
//      }
//      writer.println();
//    }
//    writer.flush();
//  }



}
