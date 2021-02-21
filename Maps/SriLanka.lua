-- SriLanka
-- Author: blkbutterfly74
-- DateCreated: 10/7/2017 7:29:20 PM
-- Creates a Tiny/dual sized map shaped like real-world Sri Lanka (and South India).
-- based off Scrambled South America & Australia map scripts
-- Thanks to Firaxis
-----------------------------------------------------------------------------

include "MapEnums"
include "MapUtilities"
include "MountainsCliffs"
include "RiversLakes"
include "FeatureGenerator"
include "TerrainGenerator"
include "NaturalWonderGenerator"
include "ResourceGenerator"
include "AssignStartingPlots"

local g_iW, g_iH;
local g_iFlags = {};
local g_continentsFrac = nil;
local g_iNumTotalLandTiles = 0; 
local g_CenterX = 37;
local g_CenterY = 13;

-------------------------------------------------------------------------------
function GenerateMap()
	print("Generating South America Map");
	local pPlot;

	-- Set globals
	g_iW, g_iH = Map.GetGridSize();
	g_iFlags = TerrainBuilder.GetFractalFlags();
	local temperature = 0;
	
	plotTypes = GeneratePlotTypes();
	terrainTypes = GenerateTerrainTypesSriLanka(plotTypes, g_iW, g_iH, g_iFlags, true);

	for i = 0, (g_iW * g_iH) - 1, 1 do
		pPlot = Map.GetPlotByIndex(i);
		if (plotTypes[i] == g_PLOT_TYPE_HILLS) then
			terrainTypes[i] = terrainTypes[i] + 1;
		end
		TerrainBuilder.SetTerrainType(pPlot, terrainTypes[i]);
	end

	-- Temp
	AreaBuilder.Recalculate();
	local biggest_area = Areas.FindBiggestArea(false);
	print("After Adding Hills: ", biggest_area:GetPlotCount());
	
	-- Place lakes before rivers so that they may act as sources
	local numLargeLakes = math.floor(GameInfo.Maps[Map.GetMapSize()].Continents * 0.3);
	AddLakes(numLargeLakes);

	-- River generation is affected by plot types, originating from highlands and preferring to traverse lowlands.
	AddRivers();

	AddFeatures();
	
	print("Adding cliffs");
	AddCliffs(plotTypes, terrainTypes);
	
	local args = {
		numberToPlace = GameInfo.Maps[Map.GetMapSize()].NumNaturalWonders,
	};

	local nwGen = NaturalWonderGenerator.Create(args);

	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
	TerrainBuilder.StampContinents();
	
	local resourcesConfig = MapConfiguration.GetValue("resources");
	local startConfig = MapConfiguration.GetValue("start");-- Get the start config
	local args = {
		resources = resourcesConfig,
		LuxuriesPerRegion = 7,
		START_CONFIG = startConfig,
	}
	local resGen = ResourceGenerator.Create(args);

	print("Creating start plot database.");
	-- START_MIN_Y and START_MAX_Y is the percent of the map ignored for major civs' starting positions.
	local startConfig = MapConfiguration.GetValue("start");-- Get the start config
	local args = {
		MIN_MAJOR_CIV_FERTILITY = 150,
		MIN_MINOR_CIV_FERTILITY = 50, 
		MIN_BARBARIAN_FERTILITY = 1,
		START_MIN_Y = 15,
		START_MAX_Y = 15,
		WATER = true,
		START_CONFIG = startConfig,
	};
	local start_plot_database = AssignStartingPlots.Create(args)

	local GoodyGen = AddGoodies(g_iW, g_iH);
end

-- Input a Hash; Export width, height, and wrapX
function GetMapInitData(MapSize)
	local Width = 49;
	local Height = 44;
	local WrapX = false;
	return {Width = Width, Height = Height, WrapX = WrapX,}
end
-------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types");
	local plotTypes = {};

	-- Start with it all as water
	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			plotTypes[i] = g_PLOT_TYPE_OCEAN;
			TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
		end
	end

	-- Each land strip is defined by: Y, X Start, X End
	local xOffset = 0;
	local yOffset = 1;
	local landStrips = {
		{1, 32, 36},
		{2, 30, 39},
		{3, 30, 41},
		{4, 29, 42},
		{5, 29, 43},
		{6, 29, 44},
		{7, 28, 45},
		{8, 28, 45},
		{9, 28, 46},
		{10, 27, 46},
		{11, 27, 46},
		{12, 27, 46},
		{13, 27, 46},
		{14, 27, 45},
		{15, 27, 45},
		{16, 27, 45},
		{17, 27, 45},
		{18, 27, 44},
		{19, 27, 43},
		{20, 6, 7},
		{20, 26, 26},
		{20, 28, 43},
		{21, 5, 9},
		{21, 26, 26},
		{21, 28, 42},
		{22, 4, 10},
		{22, 26, 26},
		{22, 28, 42},
		{23, 3, 11},
		{23, 28, 42},
		{24, 2, 12},
		{24, 27, 41},
		{25, 1, 12},
		{25, 28, 40},
		{26, 0, 12},
		{26, 29, 40},
		{27, 0, 12},
		{27, 29, 39},
		{28, 0, 13},
		{28, 28, 38},
		{29, 0, 14},
		{29, 27, 28},
		{29, 30, 37},
		{30, 0, 17},
		{30, 30, 37},
		{31, 0, 19},
		{31, 23, 23},
		{31, 31, 36},
		{32, 0, 20},
		{32, 30, 36},
		{33, 0, 19},
		{33, 26, 26},
		{33, 31, 31},
		{33, 33, 35},
		{34, 0, 19},
		{34, 29, 29},
		{34, 33, 34},
		{35, 0, 20},
		{35, 28, 33},
		{36, 0, 21},
		{36, 29, 32},
		{37, 0, 21},
		{38, 0, 22},
		{39, 0, 22},
		{40, 0, 23},
		{40, 26, 27},
		{41, 0, 28},
		{42, 0, 28}};
		
	for i, v in ipairs(landStrips) do
		local y = v[1] + yOffset; 
		local xStart = v[2] + xOffset;
		local xEnd = v[3] + xOffset; 
		for x = xStart, xEnd do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			plotTypes[i] = g_PLOT_TYPE_LAND;
			TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_GRASS);  -- temporary setting so can calculate areas
			g_iNumTotalLandTiles = g_iNumTotalLandTiles + 1;
		end
	end
		
	AreaBuilder.Recalculate();
		
	--	world_age
	local world_age_new = 6;
	local world_age_normal = 4;
	local world_age_old = 3;

	local world_age = MapConfiguration.GetValue("world_age");
	if (world_age == 1) then
		world_age = world_age_new;
	elseif (world_age == 2) then
		world_age = world_age_normal;
	elseif (world_age == 3) then
		world_age = world_age_old;
	else
		world_age = 2 + TerrainBuilder.GetRandomNumber(4, "Random World Age - Lua");
	end
	
	local args = {};
	args.world_age = world_age;
	args.iW = g_iW;
	args.iH = g_iH
	args.iFlags = g_iFlags;
	args.blendRidge = 10;
	args.blendFract = 1;
	args.extra_mountains = 7;
	plotTypes = ApplyTectonics(args, plotTypes);

	return plotTypes;
end

function InitFractal(args)

	if(args == nil) then args = {}; end

	local continent_grain = args.continent_grain or 2;
	local rift_grain = args.rift_grain or -1; -- Default no rifts. Set grain to between 1 and 3 to add rifts. - Bob
	local invert_heights = args.invert_heights or false;
	local polar = args.polar or true;
	local ridge_flags = args.ridge_flags or g_iFlags;

	local fracFlags = {};
	
	if(invert_heights) then
		fracFlags.FRAC_INVERT_HEIGHTS = true;
	end
	
	if(polar) then
		fracFlags.FRAC_POLAR = true;
	end
	
	if(rift_grain > 0 and rift_grain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_iH, rift_grain, {}, 6, 5);
		g_continentsFrac = Fractal.CreateRifts(g_iW, g_iH, continent_grain, fracFlags, riftsFrac, 6, 5);
	else
		g_continentsFrac = Fractal.Create(g_iW, g_iH, continent_grain, fracFlags, 6, 5);	
	end

	-- Use Brian's tectonics method to weave ridgelines in to the continental fractal.
	-- Without fractal variation, the tectonics come out too regular.
	--
	--[[ "The principle of the RidgeBuilder code is a modified Voronoi diagram. I 
	added some minor randomness and the slope might be a little tricky. It was 
	intended as a 'whole world' modifier to the fractal class. You can modify 
	the number of plates, but that is about it." ]]-- Brian Wade - May 23, 2009
	--
	local MapSizeTypes = {};
	for row in GameInfo.Maps() do
		MapSizeTypes[row.MapSizeType] = row.PlateValue;
	end
	local sizekey = Map.GetMapSize();

	local numPlates = MapSizeTypes[sizekey] or 4

	-- Blend a bit of ridge into the fractal.
	-- This will do things like roughen the coastlines and build inland seas. - Brian

	g_continentsFrac:BuildRidges(numPlates, {}, 1, 2);
end

function AddFeatures()
	print("Adding Features");

	-- Get Rainfall setting input by user.
	local rainfall = MapConfiguration.GetValue("rainfall");
	if rainfall == 4 then
		rainfall = 1 + TerrainBuilder.GetRandomNumber(3, "Random Rainfall - Lua");
	end

	local args = {rainfall = rainfall, iJunglePercent = 55, iMarshPercent = 7, iForestPercent = 15, iReefPercent = 12}	-- jungle & marsh max coverage
	local featuregen = FeatureGenerator.Create(args);

	featuregen:AddFeatures();

	-- add extra rainforest more densely at center
	for iX = 0, g_iW - 1 do
		for iY = 0, g_iH - 1 do
			local index = (iY * g_iW) + iX;
			local plot = Map.GetPlot(iX, iY);
			local iDistanceFromCenter = Map.GetPlotDistance (iX, iY, g_CenterX, g_CenterY);

			-- inverse of Australia floolplain logic
			if (TerrainBuilder.GetRandomNumber(25, "Resource Placement Score Adjust") >= iDistanceFromCenter) then
				featuregen:AddJunglesAtPlot(plot, iX, iY);
			end
		end
	end
end
------------------------------------------------------------------------------
function GenerateTerrainTypesSriLanka(plotTypes, iW, iH, iFlags, bNoCoastalMountains)
	print("Generating Terrain Types");
	local terrainTypes = {};

	local fracXExp = -1;
	local fracYExp = -1;
	local grain_amount = 3;

	grass = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
									
	iGrassTop = grass:GetHeight(100);

	plains = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
																		
	iPlainsTop = grass:GetHeight(100);
	iPlainsBottom = grass:GetHeight(10);

	deserts = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
									
	iDesertTop = deserts:GetHeight(75);

	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;
			if (plotTypes[index] == g_PLOT_TYPE_OCEAN) then
				if (IsAdjacentToLand(plotTypes, iX, iY)) then
					terrainTypes[index] = g_TERRAIN_TYPE_COAST;
				else
					terrainTypes[index] = g_TERRAIN_TYPE_OCEAN;
				end
			end
		end
	end

	if (bNoCoastalMountains == true) then
		plotTypes = RemoveCoastalMountains(plotTypes, terrainTypes);
	end

	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;

			local iDistanceFromCenter = Map.GetPlotDistance (iX, iY, g_CenterX, g_CenterY);
			local lat = (iY - (iH/2))/(iH/2);	
			local long = (iX - (iW/2))/(iW/2);

			local grassVal = grass:GetHeight(iX, iY);
			local plainsVal = plains:GetHeight(iX, iY);
			local desertVal = deserts:GetHeight(iX, iY);

			-- Sri Lanka
			if (long > 0 and lat < 0.65) then
				local iGrassBottom = grass:GetHeight(iDistanceFromCenter/(iH/2) * 100);

				if (plotTypes[index] == g_PLOT_TYPE_MOUNTAIN) then
					terrainTypes[index] = g_TERRAIN_TYPE_DESERT_MOUNTAIN;

					if ((grassVal >= iGrassBottom) and (grassVal <= iGrassTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_GRASS_MOUNTAIN;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS_MOUNTAIN;
					end

				elseif (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
					terrainTypes[index] = g_TERRAIN_TYPE_DESERT;
		
					if ((grassVal >= iGrassBottom) and (grassVal <= iGrassTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_GRASS;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS;
					end
				end

			-- India
			else 
				local iDesertBottom = deserts:GetHeight((1 - iDistanceFromCenter/(iH/2)) * 100);

				if (plotTypes[index] == g_PLOT_TYPE_MOUNTAIN) then
					terrainTypes[index] = g_TERRAIN_TYPE_GRASS_MOUNTAIN;
				
					if ((desertVal >= iDesertBottom) and (desertVal <= iDesertTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_DESERT_MOUNTAIN;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS_MOUNTAIN;
					end
				elseif (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
					terrainTypes[index] = g_TERRAIN_TYPE_GRASS;
				
					if ((desertVal >= iDesertBottom) and (desertVal <= iDesertTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_DESERT;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS;
					end
				end
			end
		end
	end

	local bExpandCoasts = true;

	if bExpandCoasts == false then
		return
	end

	print("Expanding coasts");
	for iI = 0, 2 do
		local shallowWaterPlots = {};
		for iX = 0, iW - 1 do
			for iY = 0, iH - 1 do
				local index = (iY * iW) + iX;
				if (terrainTypes[index] == g_TERRAIN_TYPE_OCEAN) then
					-- Chance for each eligible plot to become an expansion is 1 / iExpansionDiceroll.
					-- Default is two passes at 1/4 chance per eligible plot on each pass.
					if (IsAdjacentToShallowWater(terrainTypes, iX, iY) and TerrainBuilder.GetRandomNumber(4, "add shallows") == 0) then
						table.insert(shallowWaterPlots, index);
					end
				end
			end
		end
		for i, index in ipairs(shallowWaterPlots) do
			terrainTypes[index] = g_TERRAIN_TYPE_COAST;
		end
	end
	
	return terrainTypes; 
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY)
	return false;
end

------------------------------------------------------------------------------
function FeatureGenerator:AddReefAtPlot(plot, iX, iY)
	--Reef Check. First see if it can place the feature.
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_REEF)) then
		self.iNumReefablePlots = self.iNumReefablePlots + 1;
		if(math.ceil(self.iReefCount * 100 / self.iNumReefablePlots) <= self.iReefMaxPercent) then
				--Weight based on adjacent plots
				local iScore  = 3 * g_iH/2;
				local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_REEF);

				if(iAdjacent == 0 ) then
					iScore = iScore + 100;
				elseif(iAdjacent == 1) then
					iScore = iScore + 125;
				elseif (iAdjacent == 2) then
					iScore = iScore  + 150;
				elseif (iAdjacent == 3 or iAdjacent == 4) then
					iScore = iScore + 175;
				else
					iScore = iScore + 10000;
				end

				if(TerrainBuilder.GetRandomNumber(200, "Resource Placement Score Adjust") >= iScore) then
					TerrainBuilder.SetFeatureType(plot, g_FEATURE_REEF);
					self.iReefCount = self.iReefCount + 1;
				end
		end
	end
end
