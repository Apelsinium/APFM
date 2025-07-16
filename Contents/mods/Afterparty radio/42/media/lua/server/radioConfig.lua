-- List of radio stations and their configs:
local radioConfig = {
    channels = {
        {
            channelUUID = "HRMT",
            air_time = 21, --Time when the radio goes open air
            isSings = true, -- Are songs played on this station?
            stageDays = {7,15,42},  -- Days when the station starts(1), goes into mid(2) and late(3) phases
            stageNames = {"start", "early", "mid", "late"},
            deathChance = 0.0, -- Chance that this channel goes extinct
            quietDeathChance = 0.0, -- Chance that this channel goes extinct quietly
            weatherForecast = true, -- If true, the weather forecast will be aired
            heliForecast = false,
            config = {
                name = "Kentucky Last Weatherman",
                freq = 102000,
                category = "Amateur",
                uuid = "HRMT",
                register = true,
                airCounterMultiplier = 1.5
            },
        },
        {
            channelUUID = "GUNMEN",
            air_time = 23, --Time when the radio goes open air
            isSings = true, -- Are songs played on this station?
            stageDays = {0,12,30},  -- Days when the station starts(1), goes into mid(2) and late(3) phases
            stageNames = {"start", "early", "mid", "late"},
            deathChance = 0.0, -- Chance that this channel goes extinct
            quietDeathChance = 0.0, -- Chance that this channel goes extinct quietly
            weatherForecast = false, -- If true, the weather forecast will be aired
            heliForecast = true,
            config = {
                name = "C&T Radio",
                freq = 976000,
                category = "Amateur",
                uuid = "GUNMEN",
                register = true,
                airCounterMultiplier = 1.5
            },
        },
    },
    characters = {
        joshua = {
            colors = {
                R = 30,
                G = 160,
                B = 90,
            },
            description = "An old man in mid-60s, lost his wife in outbreak. Was working as weather forecast technician, has his own weather station. Speaking wisdom and weather"
        },
        caleb = {
            colors = {
                R = 230,
                G = 145,
                B = 40,
            },
            description = "An ex-military. Served in Desert Storm where was injured and dismissed, since then was an instructor on shooting range"
        },
        tyler = {
            colors = {
                R = 40,
                G = 200,
                B = 195,
            },
            description = "A young black man in early 20s, was raised by father who was an McCoyLoggingCorp worker. He got it into college to study law and was quite good in a local baseball team as a batter"
        },
        rando1 = {
            colors = {
                R = 40,
                G = 200,
                B = 230,
            },
        },
        rando2 = {
            colors = {
                R = 230,
                G = 40,
                B = 40,
            },
        },
        rando3 = {
            colors = {
                R = 230,
                G = 230,
                B = 40,
            },
        },
        rando4 = {
            colors = {
                R = 55,
                G = 40,
                B = 230,
            },
        },
        rando5 = {
            colors = {
                R = 40,
                G = 230,
                B = 60,
            },
        },
        cultist = {
            colors = {
                R = 160,
                G = 0,
                B = 215,
            },
        },
        sfx = {
            colors = {
                R = 105,
                G = 105,
                B = 105,
            },
        },
        sfx_loud = {
            colors = {
                R = 115,
                G = 40,
                B = 40,
            },
        }
    }
}

return radioConfig