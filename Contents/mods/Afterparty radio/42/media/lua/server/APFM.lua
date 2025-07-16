-- On hold:
-- Super random chatter mechanic
--      Looks like I can't pirate commercial stations. It's against the law in zombie apocalypse :<
-- Channel death mechanics is disabled because I want radios to refer each other: ads, guests, etc. If I enable it, I'll have to add another layer of logic to check if operator doesn't advertise a corpse (which is unneccessary, given the circumstances). Maybe later
-- Non-linear plots! Visual novels in my radio station, Survivor-sempai! This goes well with death logic mechanics.

-- To think:
-- Song concludes the broadcast?

-- CONTENT:
-- Randos
-- Hermit station
-- Gunman station
-- Shoutouts
-- Survivor station
-- Paramilitary frequency
local APFMversion = "b42_0.1"
local radioConfig = require "radioConfig"
local broadcastTexts = require("broadcastTexts_" .. tostring(Translator.getLanguage()))

local function getTableStatus(table)
    local firstKey

    if type(table) ~= "table" then return "not_table" end

    for key, _ in pairs(table) do
        firstKey = key
        break
    end

    if type(firstKey) == "number" then
        return "array"
    else if not firstKey then
        return "empty"
    end
        return "dict"
    end
end

local function drillTable(inputTable, _tableName)
    if type(inputTable) ~= "table" then
        return
    end

    local output = {}
    local tableStatus = getTableStatus(inputTable)
    local isLastLevel = tableStatus == "empty" or (tableStatus == "array" and inputTable[1].text ~= nil)

    for key, subtable in pairs(inputTable) do
        if not isLastLevel then
            -- Drill next level
            output[key] = drillTable(subtable, key)
        elseif isLastLevel and tableStatus == "empty" then
            -- This is an empty table, add empty table to the output:
            output[key] = {}
        elseif isLastLevel and tableStatus == "array" then
            -- This is an array, return array of values:
            for _, _ in pairs(inputTable) do
                output[_tableName] = true  -- Mark as available
            end
        end
    end
    return output
end

function GetBroadcastText(broadcast)
    GetTable(broadcastTexts[broadcast])
end

local function getCurrentStage(_day, _channel)
    local stageDays = _channel.stageDays

    if not stageDays then
        return nil
    end

    local stageNames = _channel.stageNames or {}

    if #stageNames == 0 then
        for i = 1, #stageDays +1 do
            table.insert(stageNames, "stage" .. i)
        end
    end

    for stageID, threshold in ipairs(stageDays) do
        if _day <= threshold then
            return stageNames[stageID]
        end
    end
    return stageNames[#stageDays + 1]
end

local function killTheStation(_channelUUID)
    local APFMdata = ModData.get("APFMdata")
    APFMdata[_channelUUID].isDead = true
end

local function initStation(channel)
    local AEBSfreq = DynamicRadio.channels[1].freq
    channel.scripts = {}
    channel.scripts.channelUUID = channel.channelUUID

    -- If channel frequency overlaps with AEBS, set fallback frequency
    if channel.config.freq == AEBSfreq then
        channel.config.freq = channel.config.freq + 200
    end

    channel.scripts.FormBroadcast = function (_bc, _isRando)
        local broadcastConfig = {
            isRando = _isRando,
        }
        local currentDay = math.floor(getGameTime():getWorldAgeDaysSinceBegin())
        local randomInstance = newrandom()

        -- Get radio progression stage
        broadcastConfig.currentStage = getCurrentStage(currentDay, channel)
        -- Decide if anything out of ordinary happens today instead of a regular broadcast
        
        broadcastConfig.isEvent = SandboxVars.APFM_radio.eventChance > 0 and randomInstance:random() < SandboxVars.APFM_radio.eventChance / 100
        -- Decide if a song is played today
        broadcastConfig.isSong = not broadcastConfig.isEvent and channel.isSings and SandboxVars.APFM_radio.songChance > 0 and randomInstance:random() < SandboxVars.APFM_radio.songChance / 100
        -- Decide if a heli is coming
        if broadcastConfig.heliForecast and currentDay == getGameTime():getHelicopterDay1()-1 then
            broadcastConfig.heli = true
        end
        -- Decide if this is the last broadcast
        broadcastConfig.isDeathBroadcast = channel.deathChance and randomInstance:random() < channel.deathChance

        local broadcastRoster = ModData.get("APFMdata")[channel.channelUUID].broadcastRoster
        local stationTexts = broadcastTexts[channel.channelUUID]
        local broadcastLines = {}

        local function getBroadcastPart(_roster,_texts)
            if not _texts or getTableStatus(_texts) == "empty" then
                print("No texts a broadcast, skipping")
                return
            end
            if getTableStatus(_roster) == "empty" and getTableStatus(_texts) ~= "empty" then
                print("Event roster is empty, repopulating")
                for key, _ in pairs(_texts) do
                    _roster[key] = true
                end
            end

            local rosterKeys = {}
            for key, _ in pairs(_roster) do
                table.insert(rosterKeys, key)
            end

            if #rosterKeys == 0 then
                print("Nothing to roll, skipping")
                return
            end

            local broadcastIndex = randomInstance:random(#rosterKeys)
            local broadcastKey = rosterKeys[broadcastIndex]

            for _, textElement in pairs(_texts[broadcastKey]) do
                table.insert(broadcastLines, textElement)
            end
            _roster[broadcastKey] = nil
        end

        local function getForecastBroadcast(day)
            local forecaster = getClimateManager():getClimateForecaster():getForecast(day)
            -- Decide about temperature
            local meanTemp = math.floor(forecaster:getTemperature():getDayMean() / 5 + 0.5) * 5
            local tempString
            if  meanTemp > 30 then
                tempString = "very_hot"
            elseif meanTemp >= 25 and meanTemp <= 30 then
                tempString = "hot"
            elseif meanTemp >= 15 and meanTemp < 25 then
                tempString = "normal"
            elseif meanTemp >= 5 and meanTemp < 15 then
                tempString = "cold"
            elseif meanTemp > 0 and meanTemp < 5 then
                tempString = "very_cold"
            elseif meanTemp <= 0 then
                tempString = "freezing"
            end
            -- Get the harshest condition
            local weatherCodes = {
                [6] = {severity = 1, name = "rainy"},
                [1] = {severity = 2, name = "rainy"},
                [5] = {severity = 3, name = "rainy"},
                [2] = {severity = 4, name = "heavy_rain"},
                [3] = {severity = 5, name = "storm"},
                [7] = {severity = 6, name = "blizzard"},
                [8] = {severity = 7, name = "tropical_storm"},
            }

            local harshestWeatherIndex = 0
            local condition = "normal"
            local cloudiness = forecaster:getCloudiness():getDayMean() -- get cloudiness 0.0-1.0
            local fogStrength = forecaster:getFogStrength() -- get fog strength 0.0-1.0

            if fogStrength > 0.3 then
                condition = "foggy"
            elseif cloudiness > 0.3 then
                condition = "cloudy"
            end

            local weatherCodesString = tostring(forecaster:getWeatherStages())
            for code in weatherCodesString:gmatch("%d+") do
                local codeNum = tonumber(code)

                if weatherCodes[codeNum] and weatherCodes[codeNum].severity > harshestWeatherIndex then
                    harshestWeatherIndex = weatherCodes[codeNum].severity
                    condition = weatherCodes[codeNum].name
                end
            end
            -- Slap together the broadcast *flextape dude.gif*
            getBroadcastPart(broadcastRoster.forecast.temperature[tempString], stationTexts.forecast.temperature[tempString])
            getBroadcastPart(broadcastRoster.forecast.conditions[condition], stationTexts.forecast.conditions[condition])
        end

        --[[
        Broadcast flow:
        - If not broadcast time, check if it's a rando breaking into the frequency
        - If event, use event broadcast sequence. Nothing else happens today, zombies are attackong radiostation
        - If the station is dead, why the hell we are in this block? I should have study programming instead!
        - Else, here's the pattern for a broadcast:
            1) Roll an intro appropriate for the current stage
            2) If the radio has heli warning, roll a heli warning appropriate for the current stage
            3) If radio has forecasts, roll a weather forecast
            4) Roll body appropriate for the current stage
            5) If we are playing song today, roll a song
            6) Roll an outro appropriate for the current stage
        
        After pulling an item from the roster, remove it from the roster.
        If the roster for this type of broadcast is empty AND broadcastTexts for it is not empty, reset the roster
        --]]
        if broadcastConfig.isRando then
            print("Rando broadcast!")
            getBroadcastPart(ModData.get("APFMdata").rando.broadcastRoster, broadcastTexts.rando)
        elseif broadcastConfig.isDeathBroadcast then
            if randomInstance:random() > channel.quietDeathChance then
                getBroadcastPart(broadcastRoster.death, stationTexts.death)
            end
            killTheStation(channel.channelUUID)
        elseif broadcastConfig.isEvent then
            print("Event!")
            -- Event is happening, roll d20 and get to the choppa!
            getBroadcastPart(broadcastRoster.event, stationTexts.event)
        else
            -- Broadcast goes as usual
            -- Intro:
            getBroadcastPart(broadcastRoster.intro[broadcastConfig.currentStage], stationTexts.intro[broadcastConfig.currentStage])
            -- Heli warning:
            if broadcastConfig.heli then
                getBroadcastPart(broadcastRoster.heli, stationTexts.heli)
            end
            -- Weather forecast:
            if channel.weatherForecast then
                getForecastBroadcast(1)
            end
            -- Body:
            getBroadcastPart(broadcastRoster.body[broadcastConfig.currentStage], stationTexts.body[broadcastConfig.currentStage])
            -- Song:
            if broadcastConfig.isSong then
                getBroadcastPart(broadcastRoster.song, stationTexts.song)
            end
            -- Outro:
            getBroadcastPart(broadcastRoster.outro, stationTexts.outro)
        end

        for key, val in pairs(broadcastLines) do
            local char = radioConfig.characters[val.char]
            local line
            print("Adding line: " .. key .. ": " .. val.text)
            if val.effect then
                line = RadioLine.new(val.text, char.colors.R/255.0, char.colors.G/255.0, char.colors.B/255.0, val.effect)
            else
                line = RadioLine.new(val.text, char.colors.R/255.0, char.colors.G/255.0, char.colors.B/255.0)
            end
            _bc:AddRadioLine(line);
        end
    end

    channel.scripts.CreateBroadcast = function(_isRando)
        print("Creating broadcast for " .. channel.channelUUID)
        local bc = RadioBroadCast.new(channel.channelUUID .. tostring(newrandom():random(999999)),-1,-1)
        channel.scripts.FormBroadcast(bc, _isRando)

        return bc;
    end

    channel.scripts.OnEveryHour = function(_channel, _gametime, _)
        local hour = _gametime:getHour()
        local day = _gametime:getWorldAgeDaysSinceBegin()
        local isChannelDead = ModData.get("APFMdata")[channel.channelUUID].isDead
        local isChannelStarted = (channel.startDay and day >= channel.startDay) or (channel.stageDays[1] and day >= channel.stageDays[1])
        print("Hour: " .. hour .. " Day: " .. day)
        
        local isRando = newrandom():random() < SandboxVars.APFM_radio.randoChance / 100

        if not isChannelDead and hour == channel.air_time and isChannelStarted then
            print("Airing broadcast for " .. channel.channelUUID)
            local bc = channel.scripts.CreateBroadcast(false)
            _channel:setAiringBroadcast(bc)
        elseif isRando and hour ~= channel.air_time then
            print("Rando breaking into the frequency")
            local bc = channel.scripts.CreateBroadcast(true)
            _channel:setAiringBroadcast(bc)
        end
    end

    table.insert(DynamicRadio.channels, channel.config)
    table.insert(DynamicRadio.scripts, channel.scripts)
end

local function initAPFM()
    for _, channel in ipairs(radioConfig.channels) do
        initStation(channel)
    end
end

local function repopulateChannelBroadcasts(_channelUUID)
    -- Reset the list of unaired broadcast types for this channel
    local APFMdata = ModData.get("APFMdata")

    for key in pairs(APFMdata[_channelUUID].broadcastRoster) do
        APFMdata[_channelUUID].broadcastRoster[key] = nil
    end
    local drilledTable = drillTable(broadcastTexts[_channelUUID]);
    if type(drilledTable) ~= "table" then
        print("Drill not drilling :<")
        return
    end
    for key,subtable in pairs(drilledTable) do
        APFMdata[_channelUUID].broadcastRoster[key] = subtable
    end
end

local function updateGolbalRoster(_modData)
    for _, channel in pairs(radioConfig.channels) do
    -- Create a list of unaired broadcasts for each channel
    _modData[channel.channelUUID] = {
            broadcastRoster = {}
        }
        repopulateChannelBroadcasts(channel.channelUUID)
    end
    -- Repopulate randos
    _modData.rando = {
        broadcastRoster = {}
    }
    repopulateChannelBroadcasts("rando")
end

local function setAPFMparameters(_isNewGame)
    local APFMdata = ModData.create("APFMdata")

    if _isNewGame or APFMdata.version ~= APFMversion then
        updateGolbalRoster(APFMdata)
        APFMdata.version = APFMversion
    end
end

Events.OnInitWorld.Add(initAPFM)
Events.OnInitGlobalModData.Add(setAPFMparameters)

-- Debug testing functions
function GetTable(table)
    if type(table) ~= "table" then
        print("!!!!  This is not a table, it's " .. type(table) .. "  !!!!")
        return
    end

    for key, value in pairs(table) do
        print(key .. " - " .. tostring(value))
    end
end

function PrintTable(tbl, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. " = {")
            PrintTable(v, indent + 1)
            print(prefix .. "}")
        else
            print(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

-- Examples:
-- GetTable(ModData.get("APFMdata"))
-- GetTable(ModData.get("APFMdata").HRMT.broadcastRoster)
-- PrintTable(ModData.get("APFMdata"))


-- getGameTime():getHelicopterDay1()
-- getGameTime():getWorldAgeDaysSinceBegin()
-- getGameTime():getWorldAgeHours()
-- getGameTime():getDaysSurvived()

-- getZomboidRadio():GetChannelList("Radio"):values()
-- print(tostring(getZomboidRadio():getFullChannelList()))
-- {Amateur={91200=Civilian Radio, 107600=Unknown Frequency, 100000=Hermit enthusiast}, Television={208=National Sports TV, 209=Brennan Movie Channel, 210=GBC, 200=Triple-N, 201=WBLN News, 203=Life and Living TV, 204=TURBO, 205=PawsTV, 206=KPATV, 207=Music Video Channel}, Radio={93200=LBMW - Kentucky Radio, 98000=NNR Radio, 101200=KnoxTalk Radio, 89400=Hitz FM, 94200=USR}, Emergency={88000=Automated Emergency Broadcast System}, Military={95000=Classified M1A1}}