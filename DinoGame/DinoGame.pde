import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;

//Globals
int nextConnectionNo = 1000;
Population pop;
Population popRF;
int frameSpeed = 60;

int numTries = 1;
int gen = 1;

boolean showBestEachGen = false;
int upToGen = 0;
Player genPlayerTemp;
Player reinforcePlayer;

boolean showNothing = false;
boolean reinforce = false;      // Controls whether Q-learning or Genetic Algorithm runs.
boolean evoReinforce = false;
boolean stopLoop = false;
boolean training = true;       // Controls if Q-Table is read in from file
//images
PImage dinoRun1;
PImage dinoRun2;
PImage dinoJump;
PImage dinoDuck;
PImage dinoDuck1;
PImage smallCactus;
PImage manySmallCactus;
PImage bigCactus;
PImage bird;
PImage bird1;

ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
ArrayList<Bird> birds = new ArrayList<Bird>();
ArrayList<Ground> grounds = new ArrayList<Ground>();


int obstacleTimer = 0;
int minimumTimeBetweenObstacles = 60;
int randomAddition = 0;
int groundCounter = 0;
float speed = 10;

int groundHeight = 250;
int playerXpos = 150;

ArrayList<Integer> obstacleHistory = new ArrayList<Integer>();
ArrayList<Integer> randomAdditionHistory = new ArrayList<Integer>();
HashMap<float[], Float> qTable = new HashMap<float[], Float>();
ArrayList<Integer> outputArray = new ArrayList<Integer>();
float epsilon = 0.9;
float alpha = 0.1;
float minEpsilon = 0.01;
float decayRate = 0.99;
private float[] currState;
private float action;
int frame = 0; // frame of game
long startTime = 0;
long elapsedSeconds = 0;
long appTime = 0;
//--------------------------------------------------------------------------------------------------------------------------------------------------

void setup() {

  frameRate(60);
  fullScreen();
  dinoRun1 = loadImage("dinorun0000.png");
  dinoRun2 = loadImage("dinorun0001.png");
  dinoJump = loadImage("dinoJump0000.png");
  dinoDuck = loadImage("dinoduck0000.png");
  dinoDuck1 = loadImage("dinoduck0001.png");

  smallCactus = loadImage("cactusSmall0000.png");
  bigCactus = loadImage("cactusBig0000.png");
  manySmallCactus = loadImage("cactusSmallMany0000.png");
  bird = loadImage("berd.png");
  bird1 = loadImage("berd2.png");

  if(!training){
    try{
      readInQTable("qtable3.csv");
    }catch(IOException e){
    }
  }

  pop = new Population(500); //<<number of dinosaurs in each generation
  popRF = new Population(50, qTable);
  reinforcePlayer = new Player(qTable);
  
  startTime = System.currentTimeMillis();
  appTime = System.currentTimeMillis();
  if(evoReinforce){
    updateObstacles();
  }
  
  startTime = System.currentTimeMillis();
  appTime = System.currentTimeMillis();
  
}
//--------------------------------------------------------------------------------------------------------------------------------------------------------
void draw() {
  drawToScreen();
  
  long elapsedAppTime = System.currentTimeMillis() - appTime;
  int elapsedMin = (int)(elapsedAppTime/1000)/60;
  long elapsedTime = System.currentTimeMillis() - startTime;
  elapsedSeconds = elapsedTime/1000;

    if(evoReinforce && !reinforce){ // Loop for evolutionary reinforcement
      if(!popRF.done()){
        popRF.updateReinforce();
      }else{
        popRF.populateAvgQTable();
        popRF.averageValues();
        qTable = popRF.getQTable();
        resetObstacles();
        popRF = new Population(50, qTable);
        updateObstacles();
        //if(gen % 500 == 0){
        //    try{
        //      writeQTable("generation"+gen+".csv");
        //    }catch(IOException e){
        //    }
        //  }
        gen++;
        startTime = System.currentTimeMillis();
      }
    } else if (!evoReinforce && reinforce){ // Loop for reinforcement 
      if(!reinforcePlayer.dead){
          updateObstacles();
          if(frame == 0){
            currState = reinforcePlayer.getState();
            action = reinforcePlayer.chooseAction(currState);
            reinforcePlayer.act((int)action);
            reinforcePlayer.update();
            reinforcePlayer.show();
            frame++;
          }else{
            reinforceGame();
          }
        } else {
          reinforceGame();
          //int [] outArr = {elapsedMin, (int)elapsedSeconds};
          //outputArray.add((int)elapsedSeconds);
          numTries++;
          epsilon = epsilon > minEpsilon ? epsilon*decayRate : epsilon;
          startTime = System.currentTimeMillis();
        }
    } else if (!evoReinforce && !reinforce){ // Loop for genetic algo
      if (showBestEachGen) {//show the best of each gen
        if (!genPlayerTemp.dead) {//if current gen player is not dead then update it
          genPlayerTemp.updateLocalObstacles();
          genPlayerTemp.look();
          genPlayerTemp.think();
          genPlayerTemp.update();
          genPlayerTemp.show();
        } else {//if dead move on to the next generation
          upToGen ++;
          if (upToGen >= pop.genPlayers.size()) {//if at the end then return to the start and stop doing it
            upToGen= 0;
            showBestEachGen = false;
          } else {//if not at the end then get the next generation
            genPlayerTemp = pop.genPlayers.get(upToGen).cloneForReplay();
          }
        }
      } else {//if just evolving normally
        if (!pop.done()) {//if any players are alive then update them
          updateObstacles();
          pop.updateAlive();
        } else {//all dead
          //genetic algorithm 
          pop.naturalSelection();
          resetObstacles();
          //outputArray.add((int)elapsedSeconds);
          startTime = System.currentTimeMillis();
          gen++;
        }
      }
    } //<>//
}



//---------------------------------------------------------------------------------------------------------------------------------------------------------
//draws the display screen
void drawToScreen() {
  if (!showNothing) {
    background(250); 
    stroke(0);
    strokeWeight(2);
    line(0, height - groundHeight - 30, width, height - groundHeight - 30);
    writeToScreen();
      
    //drawBrain();
    //writeInfo();
  }
}
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
void drawBrain() {  //show the brain of whatever genome is currently showing
  int startX = 600;
  int startY = 10;
  int w = 600;
  int h = 400;
  if (showBestEachGen) {
    genPlayerTemp.brain.drawGenome(startX, startY, w, h);
  } else {
    for (int i = 0; i< pop.pop.size(); i++) {
      if (!pop.pop.get(i).dead) {
        pop.pop.get(i).brain.drawGenome(startX, startY, w, h);
        break;
      }
    }
  }
}
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//writes info about the current player
void writeInfo() {
  fill(200);
  textAlign(LEFT);
  textSize(40);
  if (showBestEachGen) { //if showing the best for each gen then write the applicable info
    text("Score: " + genPlayerTemp.score, 30, height - 30);
    //text(, width/2-180, height-30);
    textAlign(RIGHT);
    text("Gen: " + (genPlayerTemp.gen +1), width -40, height-30);
    textSize(20);
    int x = 580;
    text("Distace to next obstacle", x, 18+44.44444);
    text("Height of obstacle", x, 18+2*44.44444);
    text("Width of obstacle", x, 18+3*44.44444);
    text("Bird height", x, 18+4*44.44444);
    text("Speed", x, 18+5*44.44444);
    text("Players Y position", x, 18+6*44.44444);
    text("Gap between obstacles", x, 18+7*44.44444);
    text("Bias", x, 18+8*44.44444);

    textAlign(LEFT);
    text("Small Jump", 1220, 118);
    text("Big Jump", 1220, 218);
    text("Duck", 1220, 318);
  } else { //evolving normally 
    text("Score: " + floor(pop.populationLife/3.0), 30, height - 30);
    //text(, width/2-180, height-30);
    textAlign(RIGHT);

    text("Gen: " + (pop.gen +1), width -40, height-30);
    textSize(20);
    int x = 580;
    text("Distace to next obstacle", x, 18+44.44444);
    text("Height of obstacle", x, 18+2*44.44444);
    text("Width of obstacle", x, 18+3*44.44444);
    text("Bird height", x, 18+4*44.44444);
    text("Speed", x, 18+5*44.44444);
    text("Players Y position", x, 18+6*44.44444);
    text("Gap between obstacles", x, 18+7*44.44444);
    text("Bias", x, 18+8*44.44444);

    textAlign(LEFT);
    text("Small Jump", 1220, 118);
    text("Big Jump", 1220, 218);
    text("Duck", 1220, 318);
  }
}


//--------------------------------------------------------------------------------------------------------------------------------------------------

void keyPressed() {
  switch(key) {
  case '+'://speed up frame rate
    frameSpeed += 10;
    frameRate(frameSpeed);
    println(frameSpeed);
    break;
  case '-'://slow down frame rate
    if (frameSpeed > 10) {
      frameSpeed -= 10;
      frameRate(frameSpeed);
      println(frameSpeed);
    }
    break;
  case 'g'://show generations
    showBestEachGen = !showBestEachGen;
    upToGen = 0;
    genPlayerTemp = pop.genPlayers.get(upToGen).cloneForReplay();
    break;
  case 'n'://show absolutely nothing in order to speed up computation
    showNothing = !showNothing;
    break;
  case 'q'://quit the game
    stopLoop = true;
    break;
  case CODED://any of the arrow keys
    switch(keyCode) {
    case RIGHT://right is used to move through the generations
      if (showBestEachGen) {//if showing the best player each generation then move on to the next generation
        upToGen++;
        if (upToGen >= pop.genPlayers.size()) {//if reached the current generation then exit out of the showing generations mode
          showBestEachGen = false;
        } else {
          genPlayerTemp = pop.genPlayers.get(upToGen).cloneForReplay();
        }
        break;
      }
      break;
    }
  }
}
//---------------------------------------------------------------------------------------------------------------------------------------------------------
//called every frame
void updateObstacles() {
  obstacleTimer ++;
  speed += 0.002;
  if (obstacleTimer > minimumTimeBetweenObstacles + randomAddition) { //if the obstacle timer is high enough then add a new obstacle
    addObstacle();
  }
  groundCounter ++;
  if (groundCounter> 10) { //every 10 frames add a ground bit
    groundCounter =0;
    grounds.add(new Ground());
  }

  moveObstacles();//move everything
  if (!showNothing) {//show everything
    showObstacles();
  }
}

//---------------------------------------------------------------------------------------------------------------------------------------------------------
//moves obstacles to the left based on the speed of the game 
void moveObstacles() {
  //println(speed);
  for (int i = 0; i< obstacles.size(); i++) {
    obstacles.get(i).move(speed);
    if (obstacles.get(i).posX < -playerXpos) { 
      obstacles.remove(i);
      i--;
    }
  }

  for (int i = 0; i< birds.size(); i++) {
    birds.get(i).move(speed);
    if (birds.get(i).posX < -playerXpos) {
      birds.remove(i);
      i--;
    }
  }
  for (int i = 0; i < grounds.size(); i++) {
    grounds.get(i).move(speed);
    if (grounds.get(i).posX < -playerXpos) {
      grounds.remove(i);
      i--;
    }
  }
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//every so often add an obstacle 
void addObstacle() {
  int lifespan = pop.populationLife;
  int tempInt;
  if (lifespan > 1000 && random(1) < 0.15) { // 15% of the time add a bird
    tempInt = floor(random(3));
    Bird temp = new Bird(tempInt);//floor(random(3)));
    birds.add(temp);
  } else {//otherwise add a cactus
    tempInt = floor(random(3));
    Obstacle temp = new Obstacle(tempInt);//floor(random(3)));
    obstacles.add(temp);
    tempInt+=3;
  }
  obstacleHistory.add(tempInt);

  randomAddition = floor(random(50));
  randomAdditionHistory.add(randomAddition);
  obstacleTimer = 0;
}
//---------------------------------------------------------------------------------------------------------------------------------------------------------
void showObstacles() {
  for (int i = 0; i< grounds.size(); i++) {
    grounds.get(i).show();
  }
  for (int i = 0; i< obstacles.size(); i++) {
    obstacles.get(i).show();
  }

  for (int i = 0; i< birds.size(); i++) {
    birds.get(i).show();
  }
}

//-------------------------------------------------------------------------------------------------------------------------------------------
//resets all the obstacles after every dino has died
void resetObstacles() {
  randomAdditionHistory = new ArrayList<Integer>();
  obstacleHistory = new ArrayList<Integer>();

  obstacles = new ArrayList<Obstacle>();
  birds = new ArrayList<Bird>();
  obstacleTimer = 0;
  randomAddition = 0;
  groundCounter = 0;
  speed = 10;
}

void reinforceGame(){
  reinforcePlayer.rewardPlayer(currState, action);
  if(!reinforcePlayer.dead){
    // get state and act
    currState = reinforcePlayer.getState();
    
    action = reinforcePlayer.chooseAction(currState);
    reinforcePlayer.act((int)action);
    reinforcePlayer.update();
    reinforcePlayer.show();
  }else{
    // if they are clear obsticles and start again.
    resetObstacles();
    qTable = reinforcePlayer.getQTable();
    reinforcePlayer = new Player(qTable);
  }
}

void writeToScreen() {
  fill(200);
  textSize(35);
  float textX = width - (width*0.4);
  float textY = height - (height*0.9);
  if(reinforce){
    text("Number of tries: "+numTries, textX, textY);
  }else{
    text("Generation: "+gen, textX, textY);
  }
  
  text("Time: "+(int)elapsedSeconds, width - (width*0.4), height - (height*0.8));
}

void writeToFile(String fileName) throws IOException{
  String fileLocation = "C:\\Users\\bensa\\Documents\\FYPV6\\FYP\\DinoGame\\TrainingData\\QData\\alpha09\\"+fileName;
  try{
    BufferedWriter writer = new BufferedWriter(new FileWriter(fileLocation));
    for(int i = 0; i < outputArray.size(); i++){
      String out = "";
      out += i+","+outputArray.get(i);
      writer.write(out);
      writer.newLine();
    }
    writer.close();
  }catch(IOException e){
  }
}

void writeQTable(String fileName) throws IOException{
  String fileLocation = "C:\\Users\\bensa\\Documents\\FYPV6\\FYP\\DinoGame\\qTables\\evoReinforcement\\"+fileName;
  try{
    BufferedWriter writer = new BufferedWriter(new FileWriter(fileLocation));
    for(float[] key : qTable.keySet()){
      String out = "";
      for(float val : key){
        out += val+",";
      }
      out += qTable.get(key);
      writer.write(out);
      writer.newLine();
    }
    writer.close();
  }catch(IOException e){
  }
}

void readInQTable(String str) throws IOException{
  File csv = new File(dataPath("")+"/qtable/"+str);
  if(csv.isFile()){
    BufferedReader csvReader = new BufferedReader(new FileReader(csv));
    String row = "";
    while((row = csvReader.readLine()) != null){
      String[] data = row.split(",");
      float[] qKey = new float[6];
      for(int i = 0; i < 6; i++){
        float val = Float.parseFloat(data[i]);
        qKey[i] = val;
      }
      qTable.put(qKey, Float.parseFloat(data[6]));
    } 
  }else {
    println("CSV not found");
  }
}
