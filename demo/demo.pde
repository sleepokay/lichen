// simulation variables
int cellSize = 6;  // display size of cells in sq. pixels
boolean saveFrame = false;  // save rendered frame as images
boolean showVectors = true;
boolean showCells = true;
boolean noDeath = true;
boolean paused = true;
boolean wave = false;
boolean gridlines = false;
boolean noVec = false;

// growth parameters
float constrainingAngle = radians(55);
float newGrowthPerturbation = (PI/9.0);
float growthPerturbation = (PI/58.0);
float excitedNeighborsParameter = 3;

int maxGrowth = 63;
int growth = 0;

// cell states
static final float MAXSTATE = 10;
static final float ALIVE = 1;
static final float EMPTY = 0;

Cell[][] cells; 
Cell[][] cellsBuffer;

void setup() {
  size (800, 800);
  frameRate(24);
  noSmooth();
  background(0);
  textSize(11);
  
  cells = new Cell[width/cellSize][height/cellSize];
  cellsBuffer = new Cell[width/cellSize][height/cellSize];
  
  reset();
}

void reset() {
  // initialization of cells
  for (int x=0; x < width/cellSize; x++) {
    for (int y=0; y < height/cellSize; y++) {
      cells[x][y] = new Cell();
      cellsBuffer[x][y] = new Cell();
    }
  }
  
  growth = 0;

  // set four cells adjacent to center of grid to MAXSTATE
  // and initialize flow vectors
  int widthCenter = (width/cellSize)/2;
  int heightCenter = (height/cellSize)/2;
  
  cells[widthCenter-1][heightCenter].state = MAXSTATE;
  cells[widthCenter+1][heightCenter].state = MAXSTATE;
  cells[widthCenter][heightCenter-1].state = MAXSTATE;
  cells[widthCenter][heightCenter+1].state = MAXSTATE;
  
  cells[widthCenter-1][heightCenter].vector.set(1, 0);
  cells[widthCenter+1][heightCenter].vector.set(-1, 0);
  cells[widthCenter][heightCenter-1].vector.set(0, 1);
  cells[widthCenter][heightCenter+1].vector.set(0, -1);
}


void draw() {
  background(0);
  
  // draw cells layer
  if (showCells) {
    
    
    noStroke();
    for (int x = 0; x < width/cellSize; x++) {
      for (int y = 0; y < height/cellSize; y++) {
        if (cells[x][y].state > EMPTY) {
          fill(color(0, 185 * cells[x][y].state / MAXSTATE + 70, 70 * cells[x][y].state / MAXSTATE + 50));    
          rect (x*cellSize, y*cellSize, cellSize, cellSize);
        }
        else if (gridlines) {
          strokeWeight(1);
          stroke(80);
          fill(0);
          rect (x*cellSize, y*cellSize, cellSize, cellSize);
        }
      }
    }
  }
  
  // draw vectors layer
  if (showVectors) {
    for (int x = 0; x < width/cellSize; x++) {
      for (int y = 0; y < height/cellSize;y++) {
        if (cells[x][y].state > EMPTY) {
          strokeWeight(2);
          stroke(color(0, 100 * cells[x][y].state / MAXSTATE + 155, 100 * cells[x][y].state / MAXSTATE + 70));
          int xCenter = x*cellSize + cellSize/2;
          int yCenter = y*cellSize + cellSize/2;
          line(xCenter, yCenter, xCenter + 12*cells[x][y].vector.x, yCenter + 12*cells[x][y].vector.y);
        }
      }
    }
  }
  
  if (paused)
    drawPaused();
  else {
    if (saveFrame)
      saveFrame("lichen-###.png");
    update();
  }
}

void drawPaused() {
  noCursor();

  // translate mouse position to cell position
  int xCellOver = int(map(mouseX, 0, width, 0, width/cellSize));
  xCellOver = constrain(xCellOver, 0, width/cellSize-1);
  int yCellOver = int(map(mouseY, 0, height, 0, height/cellSize));
  yCellOver = constrain(yCellOver, 0, height/cellSize-1);

  // show hovered cell vector
  stroke(255, 255, 100);
  int xCenter = xCellOver*cellSize + cellSize/2;
  int yCenter = yCellOver*cellSize + cellSize/2;
  line(xCenter, yCenter, xCenter + 12*cells[xCellOver][yCellOver].vector.x, yCenter + 12*cells[xCellOver][yCellOver].vector.y);
  
  // outline hovered cell
  stroke(255, 30, 30);
  noFill();
  rect(xCellOver*cellSize - 1, yCellOver*cellSize - 1, cellSize+1, cellSize+1);

  // show cell info
  fill(255, 255, 255);
  text("[" + xCellOver + ", " + yCellOver + "]  " + cells[xCellOver][yCellOver].state, 10, 20);
}

void update() {
  if (growth >= maxGrowth)
    return;
  
  // copy current cell states to buffer for updating
  for (int x = 0; x < width/cellSize; x++)
    for (int y = 0; y < height/cellSize; y++)
      cellsBuffer[x][y].copy(cells[x][y]);

  // update cells
  for (int x=0; x < width/cellSize; x++) {
    for (int y=0; y < height/cellSize; y++) {    
      if (cells[x][y].state == EMPTY) {
        updateEmpty(x, y);
      } 
      else if (cells[x][y].state > EMPTY) { 
        updateAlive(x, y);
      }
    }
  }
  
  growth++;

  // copy updated buffer back into original
  for (int x = 0; x< width/cellSize; x++)
    for (int y = 0; y < height/cellSize; y++)
      cells[x][y].copy(cellsBuffer[x][y]);
}

void updateEmpty(int x, int y) {  
  float maxAngle = Float.NEGATIVE_INFINITY;  //largest angle within the neighborhood of the empty cell
  int excitedNeighbors = 0;  //number of excited neighbors of the empty cell 
  PVector temp = new PVector(0, 0, 0);  //used to calculate a new vector if the empty cell becomes excited
  
  // consider the neighborhood of each empty cell
  for (int xx = x-1; xx <= x+1; xx++) {
    for (int yy = y-1; yy <= y+1; yy++) {
      if (xx < 0 || xx >= width/cellSize || yy < 0 || yy >= height/cellSize)
        continue;
       
      if (cells[xx][yy].state >= MAXSTATE * 0.97)
        excitedNeighbors++;
      
      if (!wave) {
        // calculate the largest angle within the neighborhood of the empty cell
        for (int xxx = x-1; xxx <= x+1; xxx++) {
          for (int yyy = y-1; yyy < y+1; yyy++) {
            if (xxx < 0 || xxx >= width/cellSize || yyy < 0 || yyy >= height/cellSize)
              continue;
            float angleBetween = PVector.angleBetween(cellsBuffer[xx][yy].vector, cellsBuffer[xxx][yyy].vector);
            maxAngle = (angleBetween > maxAngle) ? angleBetween : maxAngle;
          }
        }
        
        // calculate vector of current x,y cell based on vectors of neighbors
        if (cells[xx][yy].state != EMPTY) {
          PVector cameFrom = new PVector(xx-x, yy-y).normalize();            
          temp.x += (cells[xx][yy].state/MAXSTATE) * ((cells[xx][yy].vector.x + cameFrom.x)/2.0);
          temp.y += (cells[xx][yy].state/MAXSTATE) * ((cells[xx][yy].vector.y + cameFrom.y)/2.0);
        }              
      }
    }
  }

  /* Finished checking neighborhood of empty cell
     Excite empty cell if it has sufficient excited neighbors
     and largest angle conditions are met, with a little randomness thrown in
     Angle condition affect the amount of branching and likelihood of propagation 
  */
  if (random(1.0) * excitedNeighborsParameter < excitedNeighbors && maxAngle < constrainingAngle) {
    cellsBuffer[x][y].state = MAXSTATE;
    temp.normalize();
    temp.rotate(random(-newGrowthPerturbation, newGrowthPerturbation));  //introduce some perturbation to the growth
    cellsBuffer[x][y].vector = temp;
  }
}

void updateAlive(int x, int y) {
  cellsBuffer[x][y].state--; 
  cellsBuffer[x][y].vector.rotate(random(-growthPerturbation, growthPerturbation));
  
  if (noDeath)
    cellsBuffer[x][y].state = constrain(cellsBuffer[x][y].state, ALIVE, MAXSTATE);
  else
    cellsBuffer[x][y].state = constrain(cellsBuffer[x][y].state, EMPTY, MAXSTATE);
}

void keyPressed() {  
  if (key == ' ')
    paused = !paused;
    
  if (key == 'v' || key == 'V')
    showVectors = !showVectors;
    
  if (key == 'c' || key == 'C')
    showCells = !showCells;
  
  if (key == 'r' || key == 'R')
    reset();
    
  if (paused && (key == 's' || key == 'S'))
    update();
    
  if (key == 'w' || key == 'W')
    wave();
    
  if (key == 'g' || key == 'G')
    gridlines = !gridlines;
    
  if (key =='o' || key == 'O')
    if (constrainingAngle == radians(55))
      constrainingAngle = radians(180);
    else
      constrainingAngle = radians(55);
}

void wave() {
  wave = !wave;
  noDeath = !noDeath;
}

class Cell {
  float state;
  PVector vector;
  
  Cell() {
    state = 0;
    vector = new PVector(0,0);
  }
  
  Cell(float state, PVector vector) {
    this.state = state;
    this.vector = vector.copy();
  }
  
  void copy(Cell target) {
    this.state = target.state;
    this.vector = target.vector.copy();
  }
}