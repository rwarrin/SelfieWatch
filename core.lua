-- create AddOn frame 
local selfieWatch = CreateFrame("FRAME", "selfieFrame", UIParent)
local g_IsInCombat = false;
local g_Selfies = {};

-- writes the message to the chosen channel
local function SelfieWatch_WriteToChannel(message)
    SendChatMessage(message, "GUILD");
end

-- logs the in-combat selfie event
local function SelfieWatch_LogSelfie(unitName)
    if(not g_Selfies) then
        g_Selfies = {};
    end

    if(g_Selfies[unitName] == nil) then
        g_Selfies[unitName] = { count = 0 };
    end

    g_Selfies[unitName].count = g_Selfies[unitName].count + 1;
end

-- decides whether or not a selfie should be tracked
local function SelfieWatch_OnSelfieTaken(sourceGUID)
    -- if not in a combat state then don't track selfies
    if(not g_IsInCombat) then
        return;
    end

    local className, classId, raceName, raceId, gender, name, realm = GetPlayerInfoByGUID(sourceGUID);

    -- if the unit taking the selfie is not the player then check if they are
    -- in the party or raid.
    if(name ~= select(1, UnitName("player"))) then
        if(not UnitInParty(sourceGUID) or not UnitInRaid(sourceGUID)) then
            return;
        end
    end

    -- at this point the player or someone in the raid or party has taken a
    -- selfie in combat
    print("SELFIE ALERT: " .. name .. " (" .. raceName .. ", " .. className .. ")");
    SelfieWatch_LogSelfie(name);
end

-- write the selfies taken to the output stream
local function SelfieWatch_AnnounceSelfiesTaken()
    if(g_Selfies == nil) then
        return;
    end

    SelfieWatch_WriteToChannel("IN-COMBAT-SELFIES TAKEN");
    for key, unitName in pairs(g_Selfies) do
        SelfieWatch_WriteToChannel(key .. ": " .. g_Selfies[key].count);
        print("Selfies take by " .. key .. ": " .. g_Selfies[key].count);
    end
end

-- handles events registered by the addon
local function SelfieWatch_OnEvent(self, event, ...)
    if(g_IsInCombat ~= InCombatLockdown()) then
        g_IsInCombat = InCombatLockdown();
        print("Switching combat state to " .. g_IsInCombat);
        if(g_IsInCombat) then
            print("Create a new selfie tracking object");
            g_Selfies = nil;
        else
            print("Can print or do w/e here idc");
            SelfieWatch_AnnounceSelfiesTaken();
        end
    end

    if(event == "ADDON_LOADED" or event == "PLAYER_LOGIN") then
        print("Logged in");
    end

    if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local timeStamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, overkill = ...;
        if(eventType == "SPELL_CAST_SUCCESS") then
            if(spellID == 181842 or spellName == "Take Selfie") then
                SelfieWatch_OnSelfieTaken(sourceGUID);
            end
        end
    end
end

-- handles slash commands
local function SelfieWatch_CommandHandler(command)
    print("Selfie command: " .. command);
end

-- register events
selfieWatch:RegisterEvent("ADDON_LOADED");
selfieWatch:RegisterEvent("PLAYER_LOGIN");
selfieWatch:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
selfieWatch:RegisterEvent("PLAYER_REGEN_ENABLED");
selfieWatch:RegisterEvent("PLAYER_REGEN_DISABLED");
selfieWatch:SetScript("OnEvent", SelfieWatch_OnEvent);

-- slash commands
SLASH_SELFIEWATCH1 = "/sw";
SlashCmdList["SELFIEWATCH"] =  SelfieWatch_CommandHandler;

