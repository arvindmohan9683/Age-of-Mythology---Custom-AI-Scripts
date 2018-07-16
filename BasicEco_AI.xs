//Basic Aom economy AI


void main (void)
{
	// Create aiEcho script header
	aiEcho("Age of Mythology: The Titans");
    	aiEcho("Learn Scripting for Singleplayer Scenarios");
	aiEcho("Computer Player 1, AI Script");

	// Perform standard system calls
    	kbLookAtAllUnitsOnMap();
    	kbAreaCalculate(1200.0);
		aiRandSetSeed();

    	// Sample scouting plan - making a Pharaoh explore
    	int planID = aiPlanCreate("Explore Land", cPlanExplore);
    	aiPlanAddUnitType(planID, cUnitTypePharaoh, 1, 1, 1);
    	aiPlanSetVariableBool(planID, cExplorePlanDoLoops, 0, false);
    	aiPlanSetEscrowID(planID, cEconomyEscrowID);
    	aiPlanSetActive(planID);
		
		// Send all herdable animals found on the scout back to the base
		int herdPlanID = aiPlanCreate("Gather Herdable Plan", cPlanHerd);
		aiPlanAddUnitType(herdPlanID, cUnitTypeHerdable, 0, 100, 100);
		aiPlanSetVariableInt(herdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeSettlementLevel1);
		aiPlanSetActive(herdPlanID);
		
		// ----- CREATING A BASIC ECONOMY -----

		kbBaseDestroyAll(1);
		int myMainBase = kbBaseCreate(1, "Main Base", kbGetBlockPosition("736"), 75.0);

	


		kbEscrowSetPercentage(cEconomyEscrowID, cAllResources, 0.0);
		kbEscrowSetPercentage(cMilitaryEscrowID, cAllResources, 0.0);
		kbEscrowAllocateCurrentResources();

		aiSetAutoGatherEscrowID(cRootEscrowID);
		aiSetAutoFarmEscrowID(cRootEscrowID);
		aiSetResourceGathererPercentageWeight(cRGPScript, 1);
		aiSetResourceGathererPercentageWeight(cRGPCost, 0);

		
		kbSetAICostWeight(cResourceFood, 1.00);
		kbSetAICostWeight(cResourceWood, 0.75);
		kbSetAICostWeight(cResourceGold, 0.75);
		kbSetAICostWeight(cResourceFavor, 2.00);

		
		aiSetResourceGathererPercentage(cResourceFood, 0.4, false, cRGPScript);
		aiSetResourceGathererPercentage(cResourceWood, 0.2, false, cRGPScript);
		aiSetResourceGathererPercentage(cResourceGold, 0.2, false, cRGPScript);
		aiSetResourceGathererPercentage(cResourceGold, 0.2, false, cRGPScript);
		aiNormalizeResourceGathererPercentages(cRGPScript);

		
		aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, 1, 50, 1.0, myMainBase);
		aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, 1, 50, 1.0, myMainBase);
		aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, 1, 50, 1.0, myMainBase);
		aiSetResourceBreakdown(cResourceFavor, cAIResourceSubTypeEasy, 1, 50, 1.0, myMainBase);
		
		
    
    	aiEcho("Script operations are now complete or active.");
}