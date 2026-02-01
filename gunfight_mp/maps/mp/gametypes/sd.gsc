#include maps\mp\gametypes\_globallogic_audio;
#include maps\mp\gametypes\_globallogic_score;
#include maps\mp\gametypes\_spawnlogic;
#include maps\mp\gametypes\_spawning;
#include maps\mp\gametypes\_callbacksetup;
#include maps\mp\gametypes\_globallogic;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_wager;
#include common_scripts\utility;
#include maps\mp\_utility;

main()
{
    maps\mp\gametypes\_globallogic::init();
    maps\mp\gametypes\_callbacksetup::setupcallbacks();
    maps\mp\gametypes\_globallogic::setupcallbacks();
    
    maps\mp\_utility::registerroundswitch(0, 9);
    maps\mp\_utility::registertimelimit(0, 1440);
    maps\mp\_utility::registerscorelimit(0, 500);
    maps\mp\_utility::registerroundlimit(0, 12);
    maps\mp\_utility::registerroundwinlimit(0, 10);
    maps\mp\_utility::registernumlives(1, 1);
    
    maps\mp\gametypes\_globallogic::registerfriendlyfiredelay(level.gametype, 15, 0, 1440);
    
    level.teambased = 1;
    level.overrideteamscore = 1;
    level.endgameonscorelimit = 0;
    
    level.disableClassSelection = 1;
    level.disableweapondrop = 1;
    level.loadoutkillstreaksenabled = 0;
    level.maxkillstreaks = 0;
    
    level.useBombTimer = 0;
    level.bombPlanted = 0;
    level.bombExploded = 0;
    level.bombDefused = 0;
    
    setDvar("scr_sd_bombtimer", 0);
    setDvar("scr_sd_defusetime", 0);
    setDvar("scr_sd_planttime", 0);
    setDvar("scr_player_forcerespawn", 0);
    setDvar("scr_game_allowkillcam", 1);
    setDvar("scr_game_disableweapondrop", 1);
    
    level.onstartgametype = ::onstartgametype;
    level.onspawnplayer = ::onspawnplayer;
    level.onspawnplayerunified = ::onspawnplayerunified;
    level.onroundswitch = ::onroundswitch;
    level.ondeadevent = ::ondeadevent;
    level.ontimelimit = ::ontimelimit;
    level.givecustomloadout = ::givecustomloadout;
    
    game["strings"]["change_class"] = "";
    game["strings"]["press_to_spawn"] = "Press ^3[{+activate}]^7 to spawn";
    game["menu_changeclass"] = "";
    game["menu_changeclass_offline"] = "";
    game["menu_changeclass_wager"] = "";
    game["menu_changeclass_custom"] = "";
    
    game["dialog"]["gametype"] = "sd_start";
    
    setscoreboardcolumns("score", "kills", "deaths", "kdratio", "assists");
}

getDvarIntDefault(dvar, defaultval)
{
    if(getDvar(dvar) == "")
    {
        setDvar(dvar, defaultval);
        return defaultval;
    }
    return getDvarInt(dvar);
}

onstartgametype()
{
    setclientnamemode("auto_change");
    
    if(!isDefined(game["switchedsides"]))
        game["switchedsides"] = 0;
    
    game["attackers"] = "allies";
    game["defenders"] = "axis";
    
    maps\mp\gametypes\_spawning::create_map_placed_influencers();
    
    level.spawnmins = (0, 0, 0);
    level.spawnmaxs = (0, 0, 0);
    
    maps\mp\gametypes\_spawnlogic::placespawnpoints("mp_sd_spawn_attacker");
    maps\mp\gametypes\_spawnlogic::placespawnpoints("mp_sd_spawn_defender");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("allies", "mp_sd_spawn_attacker");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("axis", "mp_sd_spawn_defender");
    
    level.mapcenter = maps\mp\gametypes\_spawnlogic::findboxcenter(level.spawnmins, level.spawnmaxs);
    setmapcenter(level.mapcenter);
    
    spawnpoint = maps\mp\gametypes\_spawnlogic::getrandomintermissionpoint();
    setdemointermissionpoint(spawnpoint.origin, spawnpoint.angles);
    
    if(!isDefined(game["gunfight_loadouts_initialized"]))
    {
        game["gunfight_loadouts"] = [];
        game["gunfight_loadouts"][0] = selectRandomLoadout();
        game["gunfight_loadouts"][1] = selectRandomLoadout();
        game["gunfight_loadouts"][2] = selectRandomLoadout();
        game["gunfight_loadouts"][3] = selectRandomLoadout();
        game["gunfight_loadouts"][4] = selectRandomLoadout();
        game["gunfight_loadouts"][5] = selectRandomLoadout();
        
        game["gunfight_current_loadout_index"] = 0;
        game["gunfight_rounds_completed"] = 0;
        game["gunfight_loadouts_initialized"] = 1;
    }
    
    level.gunfight_current_loadout = game["gunfight_loadouts"][game["gunfight_current_loadout_index"]];
}

onroundswitch()
{
    game["switchedsides"] = !game["switchedsides"];
}

onspawnplayerunified()
{
    maps\mp\gametypes\_spawning::onspawnplayer_unified();
}

onspawnplayer(predictedspawn)
{
    spawnpoints = maps\mp\gametypes\_spawnlogic::getteamspawnpoints(self.pers["team"]);
    spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random(spawnpoints);
    
    if(predictedspawn)
        self predictspawnpoint(spawnpoint.origin, spawnpoint.angles);
    else
        self spawn(spawnpoint.origin, spawnpoint.angles, "sd");
}

selectRandomLoadout()
{
    loadout = [];
    
    primaries = [];
    primaries[0] = "mp7_mp";
    primaries[1] = "pdw57_mp";
    primaries[2] = "vector_mp";
    primaries[3] = "tar21_mp";
    primaries[4] = "an94_mp";
    primaries[5] = "scar_mp";
    primaries[6] = "hk416_mp";
    primaries[7] = "type95_mp";
    primaries[8] = "870mcs_mp";
    primaries[9] = "ksg_mp";
    primaries[10] = "saiga12_mp";
    primaries[11] = "dsr50_mp";
    primaries[12] = "ballista_mp";
    
    secondaries = [];
    secondaries[0] = "kard_mp";
    secondaries[1] = "fiveseven_mp";
    secondaries[2] = "fnp45_mp";
    secondaries[3] = "judge_mp";
    
    attachments = [];
    attachments[0] = "";
    attachments[1] = "+reflex";
    attachments[2] = "+acog";
    attachments[3] = "+fastads";
    attachments[4] = "+grip";
    attachments[5] = "+steadyaim";
    attachments[6] = "+extclip";
    attachments[7] = "+fmj";
    attachments[8] = "+silencer";
    
    lethals = [];
    lethals[0] = "frag_grenade_mp";
    lethals[1] = "sticky_grenade_mp";
    lethals[2] = "hatchet_mp";
    lethals[3] = "claymore_mp";
    
    tacticals = [];
    tacticals[0] = "flash_grenade_mp";
    tacticals[1] = "concussion_grenade_mp";
    tacticals[2] = "smoke_grenade_mp";
    tacticals[3] = "emp_grenade_mp";
    
    basePrimary = primaries[randomInt(primaries.size)];
    primaryAttachment = attachments[randomInt(attachments.size)];
    
    loadout["primary"] = basePrimary + primaryAttachment;
    loadout["secondary"] = secondaries[randomInt(secondaries.size)];
    loadout["lethal"] = lethals[randomInt(lethals.size)];
    loadout["tactical"] = tacticals[randomInt(tacticals.size)];
    
    return loadout;
}

ondeadevent(team)
{
    if(!isDefined(game["gunfight_rounds_completed"]))
        game["gunfight_rounds_completed"] = 0;
    
    game["gunfight_rounds_completed"]++;
    
    newLoadoutIndex = int(game["gunfight_rounds_completed"] / 2);
    
    if(!isDefined(game["gunfight_current_loadout_index"]))
        game["gunfight_current_loadout_index"] = 0;
    
    if(newLoadoutIndex != game["gunfight_current_loadout_index"] && isDefined(game["gunfight_loadouts"][newLoadoutIndex]))
    {
        game["gunfight_current_loadout_index"] = newLoadoutIndex;
        level.gunfight_current_loadout = game["gunfight_loadouts"][newLoadoutIndex];
    }
    
    if(team == "all")
    {
        level thread maps\mp\gametypes\_globallogic::endgame(undefined, &"MP_ROUND_DRAW");
    }
    else if(team == game["attackers"])
    {
        maps\mp\gametypes\_globallogic_score::giveteamscoreforobjective(game["defenders"], 1);
        level thread maps\mp\gametypes\_globallogic::endgame(game["defenders"], game["strings"][game["attackers"] + "_eliminated"]);
    }
    else if(team == game["defenders"])
    {
        maps\mp\gametypes\_globallogic_score::giveteamscoreforobjective(game["attackers"], 1);
        level thread maps\mp\gametypes\_globallogic::endgame(game["attackers"], game["strings"][game["defenders"] + "_eliminated"]);
    }
}

ontimelimit()
{
    if(isDefined(game["gunfight_overtime_triggered"]))
        return;
    
    game["gunfight_overtime_triggered"] = 1;
    
    iPrintLnBold("^1OVERTIME: 15 seconds remaining!");
    
    wait 15;
    
    alliesHealth = 0;
    axisHealth = 0;
    alliesAlive = 0;
    axisAlive = 0;
    
    players = level.players;
    for(i = 0; i < players.size; i++)
    {
        if(!isDefined(players[i]) || !isAlive(players[i]))
            continue;
        
        if(players[i].team == "allies")
        {
            alliesHealth += players[i].health;
            alliesAlive++;
        }
        else if(players[i].team == "axis")
        {
            axisHealth += players[i].health;
            axisAlive++;
        }
    }
    
    if(alliesAlive == 0 && axisAlive == 0)
    {
        game["gunfight_overtime_triggered"] = undefined;
        level thread maps\mp\gametypes\_globallogic::endgame(undefined, &"MP_ROUND_DRAW");
        return;
    }
    
    if(alliesHealth > axisHealth)
    {
        for(i = 0; i < players.size; i++)
        {
            if(isDefined(players[i]) && isAlive(players[i]) && players[i].team == "axis")
                players[i] suicide();
        }
    }
    else if(axisHealth > alliesHealth)
    {
        for(i = 0; i < players.size; i++)
        {
            if(isDefined(players[i]) && isAlive(players[i]) && players[i].team == "allies")
                players[i] suicide();
        }
    }
    else
    {
        for(i = 0; i < players.size; i++)
        {
            if(isDefined(players[i]) && isAlive(players[i]))
                players[i] suicide();
        }
    }
    
    game["gunfight_overtime_triggered"] = undefined;
}

givecustomloadout(takeallweapons, alreadyspawned)
{
    currentweapon = level.gunfight_current_loadout["primary"];
    
    self maps\mp\gametypes\_wager::setupblankrandomplayer(takeallweapons, 0, currentweapon);
    
    self giveWeapon(currentweapon);
    self giveMaxAmmo(currentweapon);
    self switchToWeapon(currentweapon);
    
    if(isDefined(level.gunfight_current_loadout["secondary"]))
    {
        secondaryweapon = level.gunfight_current_loadout["secondary"];
        self giveWeapon(secondaryweapon);
        self giveMaxAmmo(secondaryweapon);
    }
    
    if(isDefined(level.gunfight_current_loadout["lethal"]))
    {
        lethal = level.gunfight_current_loadout["lethal"];
        self giveWeapon(lethal);
        self setWeaponAmmoClip(lethal, 1);
        self switchToOffhand(lethal);
    }
    
    if(isDefined(level.gunfight_current_loadout["tactical"]))
    {
        tactical = level.gunfight_current_loadout["tactical"];
        self giveWeapon(tactical);
        self setWeaponAmmoClip(tactical, 1);
    }
    
    self giveWeapon("knife_mp");
    
    if(!isDefined(alreadyspawned) || !alreadyspawned)
        self setspawnweapon(currentweapon);
    
    return currentweapon;
}
