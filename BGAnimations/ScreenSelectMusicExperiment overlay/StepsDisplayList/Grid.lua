local num_rows    = 5
local num_columns = 20
local GridZoomX = IsUsingWideScreen() and 0.435 or 0.39
local BlockZoomY = 0.275
local StepsToDisplay, SongOrCourse, StepsOrTrails

local GetStepsToDisplay = LoadActor("./StepsToDisplay.lua")

local t = Def.ActorFrame{
	Name="StepsDisplayList",
	InitCommand=cmd(vertalign, top; xy, _screen.cx-170, _screen.cy + 70),
	-- - - - - - - - - - - - - -

	OnCommand=cmd(queuecommand, "RedrawStepsDisplay"),
	CurrentSongChangedMessageCommand=cmd(queuecommand, "RedrawStepsDisplay"),
	CurrentCourseChangedMessageCommand=cmd(queuecommand, "RedrawStepsDisplay"),
	StepsHaveChangedCommand=cmd(queuecommand, "RedrawStepsDisplay"),

	-- - - - - - - - - - - - - -

	RedrawStepsDisplayCommand=function(self)

		SongOrCourse = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()

		if SongOrCourse then
			StepsOrTrails = (GAMESTATE:IsCourseMode() and SongOrCourse:GetAllTrails()) or SongUtil.GetPlayableSteps( SongOrCourse )

			if StepsOrTrails then

				StepsToDisplay = GetStepsToDisplay(StepsOrTrails)

				for RowNumber=1,num_rows do
					if StepsToDisplay[RowNumber] then
						-- if this particular song has a stepchart for this row, update the Meter
						-- and BlockRow coloring appropriately
						local chart = StepsToDisplay[RowNumber]
						local meter = chart:GetMeter()
						local difficulty = chart:GetDifficulty()
						self:GetChild("Grid"):GetChild("Meter_"..RowNumber):playcommand("Set", {Meter=meter, Difficulty=difficulty, Chart=chart})
						if not ThemePrefs.Get("ShowExtraSongInfo") then
							self:GetChild("Grid"):GetChild("Blocks_"..RowNumber):playcommand("Set", {Meter=meter, Difficulty=difficulty, Chart=chart})
						end
					else
						-- otherwise, set the meter to an empty string and hide this particular colored BlockRow
						self:GetChild("Grid"):GetChild("Meter_"..RowNumber):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Blocks_"..RowNumber):playcommand("Unset")

					end
				end
			end
		else
			StepsOrTrails, StepsToDisplay = nil, nil
			self:playcommand("Unset")
		end
	end,

	-- - - - - - - - - - - - - -

	-- background
	Def.Quad{
		Name="Background",
		InitCommand=function(self)
			if ThemePrefs.Get("ShowExtraSongInfo") then
				self:diffuse(color("#1e282f")):zoomto(36, 96):x(-142)
			else
				self:diffuse(color("#1e282f")):zoomto(320, 96)
			end 
			if ThemePrefs.Get("RainbowMode") then
				self:diffusealpha(0.75)
			end
		end
	},
}


local Grid = Def.ActorFrame{
	Name="Grid",
	InitCommand=cmd(horizalign, left; vertalign, top; xy, 8, -52 ),
}


-- A grid of decorative faux-blocks that will exist
-- behind the changing difficulty blocks.
Grid[#Grid+1] = Def.Sprite{
	Name="BackgroundBlocks",
	Texture=THEME:GetPathB("ScreenSelectMusic", "overlay/StepsDisplayList/_block.png"),

	InitCommand=cmd(diffuse, color("#182025") ),
	OnCommand=function(self)
		local width = self:GetWidth()
		local height= self:GetHeight()
		self:zoomto(width * num_columns * GridZoomX, height * num_rows * BlockZoomY)
		self:y( 3 * height * BlockZoomY )
		self:customtexturerect(0, 0, num_columns, num_rows)
		if ThemePrefs.Get("ShowExtraSongInfo") then
			self:diffusealpha(0)
		end
	end
}

for RowNumber=1,num_rows do

	Grid[#Grid+1] =	Def.Sprite{
		Name="Blocks_"..RowNumber,
		Texture=THEME:GetPathB("ScreenSelectMusic", "overlay/StepsDisplayList/_block.png"),

		InitCommand=cmd(diffusealpha,0),
		OnCommand=function(self)
			local width = self:GetWidth()
			local height= self:GetHeight()
			self:y( RowNumber * height * BlockZoomY)
			self:zoomto(width * num_columns * GridZoomX, height * BlockZoomY)
		end,
		SetCommand=function(self, params)
			-- our grid only supports charts with up to a 20-block difficulty meter
			-- but charts can have higher difficulties
			-- handle that here by clamping the value to be between 1 and, at most, 20
			local meter = clamp( params.Meter, 1, num_columns )

			self:customtexturerect(0, 0, num_columns, 1)
			self:cropright( 1 - (meter * (1/num_columns)) )

			-- diffuse and set each chart's difficulty meter
			if ValidateChart(GAMESTATE:GetCurrentSong(),params.Chart) then self:diffuse( DifficultyColor(params.Difficulty) )
			else self:diffuse(.5,.5,.5,1) end
		end,
		UnsetCommand=function(self)
			self:customtexturerect(0,0,0,0)
		end
	}

	Grid[#Grid+1] = Def.BitmapText{
		Name="Meter_"..RowNumber,
		Font="_wendy small",

		InitCommand=function(self)
			local height = self:GetParent():GetChild("Blocks_"..RowNumber):GetHeight()
			self:horizalign(right)
			self:y(RowNumber * height * BlockZoomY)
			self:x( IsUsingWideScreen() and -140 or -126 )
			self:zoom(0.3)
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			if ValidateChart(GAMESTATE:GetCurrentSong(),params.Chart) then self:diffuse( DifficultyColor(params.Difficulty) )
			else self:diffuse(.5,.5,.5,1) end
			self:settext(params.Meter)
		end,
		UnsetCommand=cmd(settext, ""; diffuse,color("#182025")),
	}
end

t[#t+1] = Grid

return t