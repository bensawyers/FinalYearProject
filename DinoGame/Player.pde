import java.util.Arrays;

class Player {
  float fitness;
  Genome brain;
  boolean replay = false;

  float unadjustedFitness;
  int lifespan = 0;//how long the player lived for fitness
  int bestScore =0;//stores the score achieved used for replay
  boolean dead;
  int score;
  int gen = 0;

  int genomeInputs = 7;
  int genomeOutputs = 3;

  float[] vision = new float[genomeInputs];//t he input array fed into the neuralNet 
  float[] decision = new float[genomeOutputs]; //the out put of the NN 
  //-------------------------------------
  float posY = 0;
  float velY = 0;
  float gravity =1.2;
  int runCount = -5;
  int size = 20;

  ArrayList<Obstacle> replayObstacles = new ArrayList<Obstacle>();
  ArrayList<Bird> replayBirds = new ArrayList<Bird>();
  ArrayList<Integer> localObstacleHistory = new ArrayList<Integer>();
  ArrayList<Integer> localRandomAdditionHistory = new ArrayList<Integer>();
  int historyCounter = 0;
  int localObstacleTimer = 0;
  float localSpeed = 10;
  int localRandomAddition = 0;
  boolean duck= false;
  //-------------------------------------- For Reinforcement Learning
  private HashMap<float[], Float> playerQTable; //Q-table
  private float[] currentState;
  private float prevAction;
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //constructor

  Player() {
    brain = new Genome(genomeInputs, genomeOutputs);
  }
  
  Player(HashMap<float[], Float> table) {
    brain = new Genome(genomeInputs, genomeOutputs);
    playerQTable = table;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //show the dino
  void show() {
    if (duck && posY == 0) {
      if (runCount < 0) {

        image(dinoDuck, playerXpos - dinoDuck.width/2, height - groundHeight - (posY + dinoDuck.height));
      } else {

        image(dinoDuck1, playerXpos - dinoDuck1.width/2, height - groundHeight - (posY + dinoDuck1.height));
      }
    } else
      if (posY ==0) {
        if (runCount < 0) {
          image(dinoRun1, playerXpos - dinoRun1.width/2, height - groundHeight - (posY + dinoRun1.height));
        } else {
          image(dinoRun2, playerXpos - dinoRun2.width/2, height - groundHeight - (posY + dinoRun2.height));
        }
      } else {
        image(dinoJump, playerXpos - dinoJump.width/2, height - groundHeight - (posY + dinoJump.height));
      }
    runCount++;
    if (runCount > 5) {
      runCount = -5;
    }
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  
  void incrementCounters() {
    lifespan++;
    if (lifespan % 3 ==0) {
      score+=1;
    }
  }


  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //checks for collisions and if this is a replay move all the obstacles
  void move() {
    posY += velY;
    if (posY >0) {
      velY -= gravity;
    } else {
      velY = 0;
      posY = 0;
    }

    if (!replay) {

      for (int i = 0; i< obstacles.size(); i++) {
        if (obstacles.get(i).collided(playerXpos, posY +dinoRun1.height/2, dinoRun1.width*0.5, dinoRun1.height)) {
          dead = true;
        }
      }

      for (int i = 0; i< birds.size(); i++) {
        if (duck && posY ==0) {
          if (birds.get(i).collided(playerXpos, posY + dinoDuck.height/2, dinoDuck.width*0.8, dinoDuck.height)) {
            dead = true;
          }
        } else {
          if (birds.get(i).collided(playerXpos, posY +dinoRun1.height/2, dinoRun1.width*0.5, dinoRun1.height)) {
            dead = true;
          }
        }
      }
    } else {//if replayign then move local obstacles
      for (int i = 0; i< replayObstacles.size(); i++) {
        if (replayObstacles.get(i).collided(playerXpos, posY +dinoRun1.height/2, dinoRun1.width*0.5, dinoRun1.height)) {
          dead = true;
        }
      }


      for (int i = 0; i< replayBirds.size(); i++) {
        if (duck && posY ==0) {
          if (replayBirds.get(i).collided(playerXpos, posY + dinoDuck.height/2, dinoDuck.width*0.8, dinoDuck.height)) {
            dead = true;
          }
        } else {
          if (replayBirds.get(i).collided(playerXpos, posY +dinoRun1.height/2, dinoRun1.width*0.5, dinoRun1.height)) {
            dead = true;
          }
        }
      }
    }
  }


  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  void jump(boolean bigJump) {
    if (posY ==0) {
      if (bigJump) {
        gravity = 1;
        velY = 20;
      } else {
        gravity = 1.2;
        velY = 16;
      }
    }
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //if parameter is true and is in the air increase gravity
  void ducking(boolean isDucking) {
    if (posY != 0 && isDucking) {
      gravity = 3;
    }
    duck = isDucking;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //called every frame
  void update() {
    incrementCounters();
    move();
  }
  //----------------------------------------------------------------------------------------------------------------------------------------------------------
  //get inputs for Neural network
  void look() {
    if (!replay) {
      float temp = 0;
      float min = 10000;
      int minIndex = -1;
      boolean berd = false; 
      for (int i = 0; i< obstacles.size(); i++) {
        if (obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {//if the distance between the left of the player and the right of the obstacle is the least
          min = obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2);
          minIndex = i;
        }
      }

      for (int i = 0; i< birds.size(); i++) {
        if (birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {//if the distance between the left of the player and the right of the obstacle is the least
          min = birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2);
          minIndex = i;
          berd = true;
        }
      }
      vision[4] = speed;
      vision[5] = posY;


      if (minIndex == -1) {//if there are no obstacles
        vision[0] = 0; 
        vision[1] = 0;
        vision[2] = 0;
        vision[3] = 0;
        vision[6] = 0;
      } else {

        vision[0] = 1.0/(min/10.0);
        if (berd) {
          vision[1] = birds.get(minIndex).h;
          vision[2] = birds.get(minIndex).w;
          if (birds.get(minIndex).typeOfBird == 0) {
            vision[3] = 0;
          } else {
            vision[3] = birds.get(minIndex).posY;
          }
        } else {
          vision[1] = obstacles.get(minIndex).h;
          vision[2] = obstacles.get(minIndex).w;
          vision[3] = 0;
        }




        //vision 6 is the gap between the this obstacle and the next one
        int bestIndex = minIndex;
        float closestDist = min;
        min = 10000;
        minIndex = -1;
        for (int i = 0; i< obstacles.size(); i++) {
          if ((berd || i != bestIndex) && obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {//if the distance between the left of the player and the right of the obstacle is the least
            min = obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2);
            minIndex = i;
          }
        }

        for (int i = 0; i< birds.size(); i++) {
          if ((!berd || i != bestIndex) && birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {//if the distance between the left of the player and the right of the obstacle is the least
            min = birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2);
            minIndex = i;
          }
        }

        if (minIndex == -1) {//if there is only one obejct on the screen
          vision[6] = 0;
        } else {
          vision[6] = 1/(min - closestDist);
        }
      }
    } else {//if replaying then use local shit
      float temp = 0;
      float min = 10000;
      int minIndex = -1;
      boolean berd = false; 
      for (int i = 0; i< replayObstacles.size(); i++) {
        if (replayObstacles.get(i).posX + replayObstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  replayObstacles.get(i).posX + replayObstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {//if the distance between the left of the player and the right of the obstacle is the least
          min = replayObstacles.get(i).posX + replayObstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2);
          minIndex = i;
        }
      }

      for (int i = 0; i< replayBirds.size(); i++) {
        if (replayBirds.get(i).posX + replayBirds.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  replayBirds.get(i).posX + replayBirds.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {//if the distance between the left of the player and the right of the obstacle is the least
          min = replayBirds.get(i).posX + replayBirds.get(i).w/2 - (playerXpos - dinoRun1.width/2);
          minIndex = i;
          berd = true;
        }
      }
      vision[4] = localSpeed;
      vision[5] = posY;


      if (minIndex == -1) {//if there are no replayObstacles
        vision[0] = 0; 
        vision[1] = 0;
        vision[2] = 0;
        vision[3] = 0;
        vision[6] = 0;
      } else {

        vision[0] = 1.0/(min/10.0);
        if (berd) {
          vision[1] = replayBirds.get(minIndex).h;
          vision[2] = replayBirds.get(minIndex).w;
          if (replayBirds.get(minIndex).typeOfBird == 0) {
            vision[3] = 0;
          } else {
            vision[3] = replayBirds.get(minIndex).posY;
          }
        } else {
          vision[1] = replayObstacles.get(minIndex).h;
          vision[2] = replayObstacles.get(minIndex).w;
          vision[3] = 0;
        }




        //vision 6 is the gap between the this obstacle and the next one
        int bestIndex = minIndex;
        float closestDist = min;
        min = 10000;
        minIndex = -1;
        for (int i = 0; i< replayObstacles.size(); i++) {
          if ((berd || i != bestIndex) && replayObstacles.get(i).posX + replayObstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  replayObstacles.get(i).posX + replayObstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {//if the distance between the left of the player and the right of the obstacle is the least
            min = replayObstacles.get(i).posX + replayObstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2);
            minIndex = i;
          }
        }

        for (int i = 0; i< replayBirds.size(); i++) {
          if ((!berd || i != bestIndex) && replayBirds.get(i).posX + replayBirds.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  replayBirds.get(i).posX + replayBirds.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {//if the distance between the left of the player and the right of the obstacle is the least
            min = replayBirds.get(i).posX + replayBirds.get(i).w/2 - (playerXpos - dinoRun1.width/2);
            minIndex = i;
          }
        }

        if (minIndex == -1) {//if there is only one obejct on the screen
          vision[6] = 0;
        } else {
          vision[6] = 1/(min - closestDist);
        }
       
      }
    }
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  // Get the current environment state
  float[] getState(){
    float[] state = new float[5];
    float temp = 0;
    float min = 500;
    int minIndex = -1;
    boolean berd = false; 
    for (int i = 0; i< obstacles.size(); i++) {
      //Check if the distance between the player and the object is less than the minimum distance
      if (obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {
        min = obstacles.get(i).posX + obstacles.get(i).w/2 - (playerXpos - dinoRun1.width/2);
        minIndex = i;
      }
    }
    
    for (int i = 0; i< birds.size(); i++) {
      //Check if the distance between the player and the object is less than the minimum distance
      if (birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2) < min &&  birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2) > 0) {
        min = birds.get(i).posX + birds.get(i).w/2 - (playerXpos - dinoRun1.width/2);
        minIndex = i;
        berd = true;
      }
    }
    
    // player y
    if(posY > 0){
      state[4] = (float)(Math.round(posY*100d)/100d);
    }else{
      state[4] = 0;
    }


    if (minIndex == -1) {//if there are no obstacles
      state[0] = 0; 
      state[1] = 0;
      state[2] = 0;
      state[3] = 0;
    } else {
      float dis = min/1000;
      dis = (float)(Math.round(dis*100d)/100d);
      state[0] = dis;
      if (berd) {
        state[1] = birds.get(minIndex).h;
        state[2] = birds.get(minIndex).w;
        if (birds.get(minIndex).typeOfBird == 0) {
          state[3] = 0;
        } else {
          state[3] = birds.get(minIndex).posY;
        }
      } else {
        state[1] = obstacles.get(minIndex).h;
        state[2] = obstacles.get(minIndex).w;
        state[3] = 0;
      }
    }
    return state;
  }





  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //gets the output of the brain then converts them to actions
  void think() {

    float max = 0;
    int maxIndex = 0;
    //get the output of the neural network
    decision = brain.feedForward(vision);

    for (int i = 0; i < decision.length; i++) {
      if (decision[i] > max) {
        max = decision[i];
        maxIndex = i;
      }
    }
 
    if (max < 0.7) {
      ducking(false);
      return;
    }

    switch(maxIndex) {
    case 0:
      jump(false);
      break;
    case 1:
      jump(true);
      break;
    case 2:
      ducking(true);
      break;
    }
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------  
  //returns a clone of this player with the same brian
  Player clone() {
    Player clone = new Player();
    clone.brain = brain.clone();
    clone.fitness = fitness;
    clone.brain.generateNetwork(); 
    clone.gen = gen;
    clone.bestScore = score;
    return clone;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  //since there is some randomness in games sometimes when we want to replay the game we need to remove that randomness
  //this fuction does that

  Player cloneForReplay() {
    Player clone = new Player();
    clone.brain = brain.clone();
    clone.fitness = fitness;
    clone.brain.generateNetwork();
    clone.gen = gen;
    clone.bestScore = score;
    clone.replay = true;
    if (replay) {
      clone.localObstacleHistory = (ArrayList)localObstacleHistory.clone();
      clone.localRandomAdditionHistory = (ArrayList)localRandomAdditionHistory.clone();
    } else {
      clone.localObstacleHistory = (ArrayList)obstacleHistory.clone();
      clone.localRandomAdditionHistory = (ArrayList)randomAdditionHistory.clone();
    }

    return clone;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //fot Genetic algorithm
  void calculateFitness() {
    fitness = score*score;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  // Get Q-value from Q-table
  float getQVal(float[] state, float action){
    int arrLength = 6;
    float[] tableData = new float[arrLength];
    
    for(int i = 0; i < state.length; i++){
      tableData[i] = state[i];
    }
    
    tableData[arrLength-1] = action;
    
    if(playerQTable.isEmpty()){
      return 0;
    }
    
    for(float[] key : playerQTable.keySet()){
      if(Arrays.equals(tableData, key)){
        return playerQTable.get(key);
      }
    }
    return 0;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  // Set Q-value in Q-table
  void setQVal(float[] state, float action, float qVal){
    boolean exists = false;
    int arrLength = 6;
    float[] tableData = new float[arrLength];
    
    for(int i = 0; i < state.length; i++){
      tableData[i] = state[i];
    }
    
    tableData[arrLength-1] = action;
    
    for(float[] key : playerQTable.keySet()){
      if(Arrays.equals(tableData, key)){
        exists = true;
        tableData = key;
      }
    }
    
    float newQ = (float)(Math.round(qVal*100d)/100d);
    playerQTable.put(tableData, newQ);
    
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  // choose an action for a given state
  float chooseAction(float[] state){
    float[] rewards = new float[4];
    
    for (int i = 0; i < rewards.length; i++){
      rewards[i] = getQVal(state, i);
      //println("Action: "+i+"reward: "+rewards[i]);
    }
    
    int action = 0;
    float rndVal = random(1);
    println("random value = "+rndVal);
    
    if(rndVal <= epsilon){
      action = (int)random(4);
    }else{
      for (int i = 1; i < rewards.length; i++){
        if( rewards[i] > rewards[action] ){
          action = i;
        }
      }
    }
    
    
    return action;
    
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  void act(int action){
    
    switch(action) {
    case 0:
      ducking(false);
      break;
    case 1:
      ducking(true);
      break;
    case 2:
      jump(true);
      break;
    case 3:
      jump(false);
      break;
    }
    
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  // Update the Q-value for the state-action pair
  void rewardPlayer(float[] state, float action){
    float gamma = 0.99;
    float rewardForState = 0;
    float[] nextState = getState();
    
    if (dead){
      rewardForState = -1000;
      deadState(nextState);
    } else {
      rewardForState = 1;
    }
    
    float[] rewards = new float[4];
    
    for (int i = 0; i < rewards.length; i++){
      rewards[i] = getQVal(nextState, i);
    }
    
    float reward = rewards[0];
    
    for (int i = 1; i < rewards.length; i++){
      if( rewards[i] > reward ){
        reward = rewards[i];
      }
    }
    
    float updatedVal = getQVal(state, action);
    updatedVal += alpha*(rewardForState+(gamma*reward)-getQVal(state, action));

    if(state[4] == 1){
      updatedVal = reward;
      for(int i = 0; i < 4; i++){
        setQVal(state, i, updatedVal);
      }
    } else {
      setQVal(state, action, updatedVal);
    }
    
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  // If the state causes the agent to die
  void deadState(float[] state){
    if(getQVal(state, 0) == 0){
      for (int i = 0; i < 4; i++){
        setQVal(state, (float)i, -1000);
      }
    }
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  HashMap<float[], Float> getQTable(){
    return playerQTable;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  void setCurrentState(float[] state){
    currentState = state;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  float[] getCurrentState(){
    return currentState;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  void setPrevAction(float a){
    prevAction = a;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  float getPrevAction(){
    return prevAction;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  Player crossover(Player parent2) {
    Player child = new Player();
    child.brain = brain.crossover(parent2.brain);
    child.brain.generateNetwork();
    return child;
  }
  //--------------------------------------------------------------------------------------------------------------------------------------------------------
  //if replaying then the dino has local obstacles
  void updateLocalObstacles() {
    localObstacleTimer ++;
    localSpeed += 0.002;
    if (localObstacleTimer > minimumTimeBetweenObstacles + localRandomAddition) {
      addLocalObstacle();
    }
    groundCounter ++;
    if (groundCounter > 10) {
      groundCounter =0;
      grounds.add(new Ground());
    }

    moveLocalObstacles();
    showLocalObstacles();
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  void moveLocalObstacles() {
    for (int i = 0; i< replayObstacles.size(); i++) {
      replayObstacles.get(i).move(localSpeed);
      if (replayObstacles.get(i).posX < -100) {
        replayObstacles.remove(i);
        i--;
      }
    }

    for (int i = 0; i< replayBirds.size(); i++) {
      replayBirds.get(i).move(localSpeed);
      if (replayBirds.get(i).posX < -100) {
        replayBirds.remove(i);
        i--;
      }
    }
    for (int i = 0; i < grounds.size(); i++) {
      grounds.get(i).move(localSpeed);
      if (grounds.get(i).posX < -100) {
        grounds.remove(i);
        i--;
      }
    }
  }
  //------------------------------------------------------------------------------------------------------------------------------------------------------------
  void addLocalObstacle() {
    int tempInt = localObstacleHistory.get(historyCounter);
    localRandomAddition = localRandomAdditionHistory.get(historyCounter);
    historyCounter ++;
    if (tempInt < 3) {
      replayBirds.add(new Bird(tempInt));
    } else {
      replayObstacles.add(new Obstacle(tempInt -3));
    }
    localObstacleTimer = 0;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  void showLocalObstacles() {
    for (int i = 0; i< grounds.size(); i++) {
      grounds.get(i).show();
    }
    for (int i = 0; i< replayObstacles.size(); i++) {
      replayObstacles.get(i).show();
    }

    for (int i = 0; i< replayBirds.size(); i++) {
      replayBirds.get(i).show();
    }
  }
}
