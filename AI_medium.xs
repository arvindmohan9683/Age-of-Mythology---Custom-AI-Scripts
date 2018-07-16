//==============================================================================
float goldPercent = 0.30;     // Target gatherer allocation for gold
float woodPercent = 0.20;     // Same for wood
float foodPercent = 0.5;      // Same for food

int   gathererTypeID = -1;    // Unit type ID for culture's gatherer
int   maxVills = -1;          // Set based on difficulty level
int   mainBaseID = -1;        // Will hold the ID for the CP's starting base.



// getUnit( int unitType, int action, vector center)
// 
// Returns a unit of the specified type, doing the specified action.
// Defaults = any unit, any action.
// Searches units owned by this player only, can include buildings.
// If a location is specified, the nearest matching unit is returned.

int   getUnit( int unitType = -1, int action = -1, vector center = vector(-1,-1,-1) )
{

  	int   retVal = -1;
    int   count = -1;
	int   unitQueryID = kbUnitQueryCreate("unit");

	// Define a query to get all matching units
	if (unitQueryID != -1)
	{
		kbUnitQuerySetPlayerID(unitQueryID, cMyID);         // only my units
      if (unitType != -1)
   		kbUnitQuerySetUnitType(unitQueryID, unitType);   // only if specified
      if (action != -1)
   		kbUnitQuerySetActionType(unitQueryID, action);   // only if specified
      if (center != vector(-1,-1,-1))
      {
         kbUnitQuerySetPosition(unitQueryID, center);
         kbUnitQuerySetAscendingSort(unitQueryID, true);
      }
		kbUnitQuerySetState(unitQueryID, cUnitStateAlive);
	}
	else
   {
      return(-1);
   }

	kbUnitQueryResetResults(unitQueryID);
	count = kbUnitQueryExecute(unitQueryID);
   kbUnitQuerySetState(unitQueryID, cUnitStateBuilding);     // Add buildings in process
   count = kbUnitQueryExecute(unitQueryID);

	// Pick a unit and return its ID, or return -1.
	if ( count > 0 )
      if (center != vector(-1,-1,-1))
         retVal = kbUnitQueryGetResult(unitQueryID, 0);   // closest unit
      else
   		retVal = kbUnitQueryGetResult(unitQueryID, aiRandInt(count));	// get the ID of a random unit
	else
		retVal = -1;

	return(retVal);
}




// maintainUnit
//
// Maintain a total of qty units of type unitID, optionally gathering at gatherPoint and 
// training at a minimum of interval seconds apart.  Returns the planID, or -1 on failure.


int   maintainUnit( int unitID=-1, int qty=1, vector gatherPoint=vector(-1,-1,-1), int interval=-1)
{
   if (unitID == -1)
      return(-1);
   if (qty < 1)
      return(-1);
   int planID = aiPlanCreate("Maintain "+qty+" "+kbGetProtoUnitName(unitID), cPlanTrain);
	if (planID >= 0)
	{
		aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, unitID);
		aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, qty);
      if (interval > 0)
   		aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, interval);
      if (xsVectorGetX(gatherPoint) >= 0)
   		aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, gatherPoint);
		aiPlanSetActive(planID);
      return(planID);
	}
   else
      return(-1);
}




void main()
{
   aiEcho("Hello world!");
   kbAreaCalculate(1200.0);
   kbSetTownLocation(kbUnitGetPosition(getUnit(cUnitTypeSettlementLevel1)));


   switch(aiGetWorldDifficulty())      // Set number of villagers based on difficulty level
   {
   case cDifficultyEasy:
      {
         maxVills = 5;
         break;
      }
   case cDifficultyModerate:
      {
         maxVills = 10;
         break;
      }
   case cDifficultyHard:
      {
         maxVills = 20;
         break;
      }
   case cDifficultyNightmare:
      {
         maxVills = 40;
         break;
      }
   }

   aiSetAttackResponseDistance(20.0);   

   kbEscrowSetPercentage( cEconomyEscrowID, cAllResources, 0.0);
   kbEscrowSetPercentage( cMilitaryEscrowID, cAllResources, 0.0);
   kbEscrowAllocateCurrentResources();

   aiSetAutoGatherEscrowID(cRootEscrowID);
   aiSetAutoFarmEscrowID(cRootEscrowID);
   gathererTypeID = kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionGatherer,0);

   // Create villager maintain plan
   if ( maintainUnit(gathererTypeID, maxVills) < 0)
      aiEcho("Villager maintain plan failed");

   xsEnableRule("gathererCount");      // Periodially aiEchoes the number of gatherers.
   
   int herdPlanID=aiPlanCreate("GatherHerdable Plan", cPlanHerd);
   if (herdPlanID >= 0)
   {
      aiPlanAddUnitType(herdPlanID, cUnitTypeHerdable, 0, 100, 100);
      aiPlanSetVariableInt(herdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeSettlementLevel1);
      aiPlanSetActive(herdPlanID);
   }

   aiSetResourceGathererPercentageWeight(cRGPScript, 1);
   aiSetResourceGathererPercentageWeight(cRGPCost, 0);

   kbSetAICostWeight(cResourceFood, 1.0);
   kbSetAICostWeight(cResourceWood, 0.7);
   kbSetAICostWeight(cResourceGold, 0.8);
   kbSetAICostWeight(cResourceFavor, 7.0);

   aiSetResourceGathererPercentage(cResourceFood, foodPercent, false, cRGPScript);
   aiSetResourceGathererPercentage(cResourceWood, woodPercent, false, cRGPScript);
   aiSetResourceGathererPercentage(cResourceGold, goldPercent, false, cRGPScript);
   aiSetResourceGathererPercentage(cResourceFavor, 0.0, false, cRGPScript);
   aiNormalizeResourceGathererPercentages(cRGPScript);

   int mainBaseID = kbBaseGetMainID(cMyID); 
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeEasy, 1, 50, 1.0, mainBaseID);
   aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, 1, 50, 1.0, mainBaseID);
	aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, 1, 50, 1.0, mainBaseID);
}



rule scout
   active
{
   // just set up an explore plan
   int exploreID = aiPlanCreate("Explore", cPlanExplore);
   if(exploreID >= 0)
   {
      aiPlanSetVariableFloat( exploreID, cExplorePlanLOSMultiplier,  0, 4.0 );
      aiPlanAddUnitType(exploreID, cUnitTypeScout, 1, 1, 1);
      aiPlanSetDesiredPriority(exploreID, 90);
      aiPlanSetActive(exploreID);
   }

   xsDisableSelf();
}



rule gathererCount            // aiEchoes the number of gatherers, stops when target is reached
   inactive
   minInterval 60
{
   int numVills = kbUnitCount(cMyID, gathererTypeID, cUnitStateAlive);
   aiEcho("At time "+xsGetTime()+" I have "+numVills+" gatherers.");
   if (numVills == maxVills)
      xsDisableSelf();
}


rule buildHouse      // Houses whenever they are needed
   minInterval 14
   active
{
   if (kbGetPop()+5 < kbGetPopCap())
      return;
   if (kbUnitCount(cMyID, cUnitTypeHouse, cUnitStateBuilding) > 0)
      return;
   if (kbUnitCount(cMyID, cUnitTypeHouse, cUnitStateAliveOrBuilding) >= 10)
      return;

   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeHouse) > -1)
      return;

   //Over time, we will find out what areas are good and bad to build in.  Use that info here, because we want to protect houses.
	int planID=aiPlanCreate("BuildHouse", cPlanBuild);
   if (planID >= 0)
   {
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeHouse);
      aiPlanSetVariableBool(planID, cBuildPlanInfluenceAtBuilderPosition, 0, true);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluenceBuilderPositionValue, 0, 100.0);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluenceBuilderPositionDistance, 0, 5.0);
      aiPlanSetVariableFloat(planID, cBuildPlanRandomBPValue, 0, 0.99);
      aiPlanSetBaseID(planID, kbBaseGetMainID(cMyID));
      aiPlanSetDesiredPriority(planID, 100);

		int builderTypeID = kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionBuilder,0);

		aiPlanAddUnitType(planID, builderTypeID, 1, 1, 1);
      aiPlanSetEscrowID(planID, cEconomyEscrowID);

      vector backVector = kbBaseGetBackVector(cMyID, kbBaseGetMainID(cMyID));

      float x = xsVectorGetX(backVector);
      float z = xsVectorGetZ(backVector);
      x = x * 30.0;
      z = z * 30.0;

      backVector = xsVectorSetX(backVector, x);
      backVector = xsVectorSetZ(backVector, z);
      backVector = xsVectorSetY(backVector, 0.0);
      vector location = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
      location = location + backVector;
      aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, location);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 20.0);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 1.0);

      aiPlanSetActive(planID);
   }
}