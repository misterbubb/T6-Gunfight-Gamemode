#include maps\mp\gametypes\_globallogic_audio;
#include maps\mp\gametypes\_globallogic_score;
#include maps\mp\gametypes\_spawnlogic;
#include maps\mp\gametypes\_spawning;
#include maps\mp\gametypes\_callbacksetup;
#include maps\mp\gametypes\_globallogic;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_gameobjects;
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

    level.teambased             = 1;
    level.overrideteamscore     = 1;
    level.endgameonscorelimit   = 0;
    level.disableClassSelection = 1;
    level.disableweapondrop     = 1;
    level.loadoutkillstreaksenabled = 0;
    level.maxkillstreaks        = 0;
    level.useBombTimer          = 0;
    level.bombPlanted           = 0;
    level.bombExploded          = 0;
    level.bombDefused           = 0;

    setDvar("scr_sd_bombtimer",           0);
    setDvar("scr_sd_defusetime",          0);
    setDvar("scr_sd_planttime",           0);
    setDvar("scr_player_forcerespawn",    0);
    setDvar("scr_game_allowkillcam",      1);
    setDvar("scr_game_disableweapondrop", 1);

    level.onstartgametype       = ::onstartgametype;
    level.onspawnplayer         = ::onspawnplayer;
    level.onspawnplayerunified  = ::onspawnplayerunified;
    level.onroundswitch         = ::onroundswitch;
    level.ondeadevent           = ::ondeadevent;
    level.ontimelimit           = ::ontimelimit;
    level.givecustomloadout     = ::givecustomloadout;
    level.onprecachegametype    = ::onprecachegametype;

    game["strings"]["change_class"]  = "";
    game["menu_changeclass"]         = "";
    game["menu_changeclass_offline"] = "";
    game["menu_changeclass_wager"]   = "";
    game["menu_changeclass_custom"]  = "";

    game["strings"]["allies_eliminated"] = &"MP_ENEMIES_ELIMINATED";
    game["strings"]["axis_eliminated"]   = &"MP_ENEMIES_ELIMINATED";
    game["strings"]["press_to_spawn"]    = "Press ^3[{+activate}]^7 to spawn";
    game["dialog"]["gametype"]           = "sd_start";

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

onprecachegametype()
{
    precacheshader("waypoint_defend");
}

onstartgametype()
{
    setclientnamemode("auto_change");

    if(!isDefined(game["switchedsides"]))
        game["switchedsides"] = 0;

    maps\mp\gametypes\_spawning::create_map_placed_influencers();

    allowed = [];
    allowed[0] = "hq";
    maps\mp\gametypes\_gameobjects::main(allowed);
    
    level thread hideBombSiteModels();
    level thread hideHardpointModels();

    level.spawnmins = (0, 0, 0);
    level.spawnmaxs = (0, 0, 0);

    maps\mp\gametypes\_spawnlogic::placespawnpoints("mp_sd_spawn_attacker");
    maps\mp\gametypes\_spawnlogic::placespawnpoints("mp_sd_spawn_defender");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("allies", "mp_sd_spawn_attacker");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("axis",   "mp_sd_spawn_defender");

    maps\mp\gametypes\_spawning::updateallspawnpoints();

    level.mapcenter = maps\mp\gametypes\_spawnlogic::findboxcenter(level.spawnmins, level.spawnmaxs);
    setmapcenter(level.mapcenter);

    spawnpoint = maps\mp\gametypes\_spawnlogic::getrandomintermissionpoint();
    setdemointermissionpoint(spawnpoint.origin, spawnpoint.angles);

    if(!isDefined(game["gunfight_loadouts_initialized"]))
    {
        game["gunfight_used_primaries"] = [];
        game["gunfight_loadouts"]       = [];

        for(i = 0; i < 6; i++)
            game["gunfight_loadouts"][i] = selectRandomLoadout();

        game["gunfight_current_loadout_index"] = 0;
        game["gunfight_rounds_completed"]      = 0;
        game["gunfight_loadouts_initialized"]  = 1;
    }

    level.gunfight_current_loadout = game["gunfight_loadouts"][game["gunfight_current_loadout_index"]];

    level thread teamHealthHUD();
    level thread monitorPlayerConnections();
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
    spawnpointname = "";
    
    if(game["switchedsides"])
    {
        if(self.pers["team"] == "allies")
            spawnpointname = "mp_sd_spawn_defender";
        else if(self.pers["team"] == "axis")
            spawnpointname = "mp_sd_spawn_attacker";
    }
    else
    {
        if(self.pers["team"] == "allies")
            spawnpointname = "mp_sd_spawn_attacker";
        else if(self.pers["team"] == "axis")
            spawnpointname = "mp_sd_spawn_defender";
    }
    
    spawnpoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray(spawnpointname);
    
    if(!isDefined(spawnpoints) || spawnpoints.size == 0)
        spawnpoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray("mp_sd_spawn_attacker");
    
    spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random(spawnpoints);

    if(predictedspawn)
        self predictspawnpoint(spawnpoint.origin, spawnpoint.angles);
    else
        self spawn(spawnpoint.origin, spawnpoint.angles, "sd");
}

isInArray(array, value)
{
    for(i = 0; i < array.size; i++)
    {
        if(array[i] == value)
            return true;
    }
    return false;
}

selectRandomLoadout()
{
    primaries = [];
    primaries[0]  = "mp7_mp";
    primaries[1]  = "pdw57_mp";
    primaries[2]  = "vector_mp";
    primaries[3]  = "insas_mp";
    primaries[4]  = "qcw05_mp";
    primaries[5]  = "evoskorpion_mp";
    primaries[6]  = "peacekeeper_mp";
    primaries[7]  = "tar21_mp";
    primaries[8]  = "type95_mp";
    primaries[9]  = "sig556_mp";
    primaries[10] = "sa58_mp";
    primaries[11] = "hk416_mp";
    primaries[12] = "scar_mp";
    primaries[13] = "saritch_mp";
    primaries[14] = "xm8_mp";
    primaries[15] = "an94_mp";
    primaries[16] = "870mcs_mp";
    primaries[17] = "saiga12_mp";
    primaries[18] = "ksg_mp";
    primaries[19] = "srm1216_mp";
    primaries[20] = "mk48_mp";
    primaries[21] = "qbb95_mp";
    primaries[22] = "lsat_mp";
    primaries[23] = "hamr_mp";
    primaries[24] = "svu_mp";
    primaries[25] = "dsr50_mp";
    primaries[26] = "ballista_mp";
    primaries[27] = "as50_mp";

    secondaries = [];
    secondaries[0] = "kard_mp";
    secondaries[1] = "fiveseven_mp";
    secondaries[2] = "fnp45_mp";
    secondaries[3] = "judge_mp";
    secondaries[4] = "beretta93r_mp";

    attachments = [];
    attachments[0]  = "";
    attachments[1]  = "+reflex";
    attachments[2]  = "+acog";
    attachments[3]  = "+fastads";
    attachments[4]  = "+grip";
    attachments[5]  = "+steadyaim";
    attachments[6]  = "+extclip";
    attachments[7]  = "+fmj";
    attachments[8]  = "+silencer";
    attachments[9]  = "+stock";
    attachments[10] = "+quickdraw";
    attachments[11] = "+holo";
    attachments[12] = "+dualclip";
    attachments[13] = "+rf";
    attachments[14] = "+extbarrel";

    lethals = [];
    lethals[0] = "frag_grenade_mp";
    lethals[1] = "sticky_grenade_mp";
    lethals[2] = "hatchet_mp";
    lethals[3] = "claymore_mp";
    lethals[4] = "bouncingbetty_mp";

    tacticals = [];
    tacticals[0] = "flash_grenade_mp";
    tacticals[1] = "concussion_grenade_mp";
    tacticals[2] = "smoke_grenade_mp";
    tacticals[3] = "emp_grenade_mp";
    tacticals[4] = "willy_pete_mp";

    basePrimary = primaries[randomInt(primaries.size)];

    attempts = 0;
    while(isInArray(game["gunfight_used_primaries"], basePrimary) && attempts < 20)
    {
        basePrimary = primaries[randomInt(primaries.size)];
        attempts++;
    }

    game["gunfight_used_primaries"][game["gunfight_used_primaries"].size] = basePrimary;

    loadout = [];
    loadout["primary"]   = basePrimary + attachments[randomInt(attachments.size)];
    loadout["secondary"] = secondaries[randomInt(secondaries.size)];
    loadout["lethal"]    = lethals[randomInt(lethals.size)];
    loadout["tactical"]  = tacticals[randomInt(tacticals.size)];

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

    if(newLoadoutIndex != game["gunfight_current_loadout_index"] &&
       isDefined(game["gunfight_loadouts"][newLoadoutIndex]))
    {
        game["gunfight_current_loadout_index"] = newLoadoutIndex;
        level.gunfight_current_loadout = game["gunfight_loadouts"][newLoadoutIndex];
    }

    if(team == "all")
    {
        level thread maps\mp\gametypes\_globallogic::endgame(undefined, &"MP_ROUND_DRAW");
    }
    else if(team == "allies")
    {
        maps\mp\gametypes\_globallogic_score::giveteamscoreforobjective("axis", 1);
        level thread maps\mp\gametypes\_globallogic::endgame("axis", &"MP_ENEMIES_ELIMINATED");
    }
    else if(team == "axis")
    {
        maps\mp\gametypes\_globallogic_score::giveteamscoreforobjective("allies", 1);
        level thread maps\mp\gametypes\_globallogic::endgame("allies", &"MP_ENEMIES_ELIMINATED");
    }
}

ontimelimit()
{
    level endon("game_ended");

    if(isDefined(game["gunfight_overtime_triggered"]))
        return;

    game["gunfight_overtime_triggered"] = 1;

    level thread clearOvertimeFlagOnEnd();
    level thread overtimeCountdown();

    captureOrigin = findBombSiteCapturePoint();
    
    if(isDefined(captureOrigin))
        level thread overtimeCapturePoint(captureOrigin);

    level waittill("overtime_complete");

    alliesHealth = 0;
    axisHealth   = 0;
    alliesAlive  = 0;
    axisAlive    = 0;

    foreach(player in level.players)
    {
        if(!isAlive(player))
            continue;

        if(player.team == "allies")
        {
            alliesHealth += player.health;
            alliesAlive++;
        }
        else if(player.team == "axis")
        {
            axisHealth += player.health;
            axisAlive++;
        }
    }

    if(alliesAlive == 0 && axisAlive == 0)
    {
        level thread maps\mp\gametypes\_globallogic::endgame(undefined, &"MP_ROUND_DRAW");
        return;
    }

    if(alliesHealth > axisHealth)
    {
        foreach(player in level.players)
        {
            if(isAlive(player) && player.team == "axis")
                player suicide();
        }
    }
    else if(axisHealth > alliesHealth)
    {
        foreach(player in level.players)
        {
            if(isAlive(player) && player.team == "allies")
                player suicide();
        }
    }
    else
    {
        foreach(player in level.players)
        {
            if(isAlive(player))
                player suicide();
        }
    }
}

clearOvertimeFlagOnEnd()
{
    level waittill("game_ended");
    game["gunfight_overtime_triggered"] = undefined;
    level.overtimeCaptureActive = undefined;
}

hideBombSiteModels()
{
    wait 0.05;
    
    bombzones = getentarray("bombzone", "targetname");
    
    foreach(zone in bombzones)
    {
        if(isDefined(zone.target))
        {
            visuals = getentarray(zone.target, "targetname");
            foreach(visual in visuals)
            {
                if(isDefined(visual))
                {
                    visual.origin = visual.origin + (0, 0, -10000);
                    visual hide();
                }
            }
        }
    }
}

hideHardpointModels()
{
    wait 0.05;
    
    hardpoints = getentarray("hq_hardpoint", "targetname");
    
    foreach(hp in hardpoints)
    {
        hp.original_origin = hp.origin;
        
        if(isDefined(hp.target))
        {
            visuals = getentarray(hp.target, "targetname");
            foreach(visual in visuals)
            {
                if(isDefined(visual))
                {
                    visual.origin = visual.origin + (0, 0, -10000);
                    visual hide();
                }
            }
        }
        
        if(isDefined(hp.model))
            hp hide();
    }
}

findBombSiteCapturePoint()
{
    hardpoints = getentarray("hq_hardpoint", "targetname");

    if(!isDefined(hardpoints) || hardpoints.size <= 0)
        return undefined;

    selectedOrigin = isDefined(hardpoints[0].original_origin) ? hardpoints[0].original_origin : hardpoints[0].origin;

    return selectedOrigin;
}

overtimeCapturePoint(origin)
{
    level endon("game_ended");

    captureRadius   = 256;
    captureRequired = 3.0;
    captureProgress = 0.0;
    capturingTeam   = "";
    
    level.overtimeCaptureActive = false;

    objId = 150;
    objective_add(objId, "active", origin);
    objective_icon(objId, "waypoint_defend");
    objective_state(objId, "active");
    
    foreach(player in level.players)
        objective_setvisibletoplayer(objId, player);

    level thread overtimeCaptureCleanup(objId);
    level thread createCaptureWaypoints(origin);

    captureModel = spawn("script_model", origin + (0, 0, 10));
    captureModel setModel("t6_wpn_supply_drop_ally");
    captureModel.angles = (0, 0, 0);
    
    level thread overtimeCaptureCleanupModel(captureModel);

    progressHUD = createServerFontString("hudbig", 1.6);
    progressHUD.horzAlign = "center";
    progressHUD.vertAlign = "top";
    progressHUD.alignX = "center";
    progressHUD.alignY = "top";
    progressHUD.x = 0;
    progressHUD.y = 80;
    progressHUD.hidewheninmenu = true;
    progressHUD.archived = false;

    level thread overtimeCaptureHUDCleanup(progressHUD);

    while(true)
    {
        alliesOnPoint = 0;
        axisOnPoint   = 0;

        foreach(player in level.players)
        {
            if(!isAlive(player))
                continue;
            if(Distance(player.origin, origin) <= captureRadius)
            {
                if(player.team == "allies")
                    alliesOnPoint++;
                else if(player.team == "axis")
                    axisOnPoint++;
            }
        }

        contested = (alliesOnPoint > 0 && axisOnPoint > 0);
        level.overtimeCaptureActive = (alliesOnPoint > 0 || axisOnPoint > 0);

        if(!contested)
        {
            if(alliesOnPoint > 0)
            {
                if(capturingTeam != "allies")
                {
                    capturingTeam   = "allies";
                    captureProgress = 0.0;
                }
                captureProgress += 0.1;
            }
            else if(axisOnPoint > 0)
            {
                if(capturingTeam != "axis")
                {
                    capturingTeam   = "axis";
                    captureProgress = 0.0;
                }
                captureProgress += 0.1;
            }
            else
            {
                captureProgress = 0.0;
                capturingTeam = "";
            }
        }

        pct = int(captureProgress / captureRequired * 100);
        if(pct > 100)
            pct = 100;
        
        pctRounded = int(pct / 10) * 10;

        if(contested)
            progressHUD setText("^3CONTESTED");
        else if(capturingTeam == "allies")
            progressHUD setText("^5CAPTURING: " + pctRounded + "%");
        else if(capturingTeam == "axis")
            progressHUD setText("^1CAPTURING: " + pctRounded + "%");
        else
            progressHUD setText("^7CAPTURE THE POINT");

        if(captureProgress >= captureRequired)
        {
            progressHUD destroy();

            if(capturingTeam == "allies")
            {
                foreach(player in level.players)
                {
                    if(isAlive(player) && player.team == "axis")
                        player suicide();
                }
            }
            else
            {
                foreach(player in level.players)
                {
                    if(isAlive(player) && player.team == "allies")
                        player suicide();
                }
            }

            return;
        }

        wait 0.1;
    }
}

overtimeCaptureCleanup(objId)
{
    level waittill("game_ended");
    objective_delete(objId);
}

createCaptureWaypoints(origin)
{
    level endon("game_ended");
    
    wait 0.1;
    
    waypoints = [];
    
    foreach(player in level.players)
    {
        if(!isDefined(player))
            continue;
            
        waypoint = newClientHudElem(player);
        waypoint.x = origin[0];
        waypoint.y = origin[1];
        waypoint.z = origin[2] + 40;
        
        waypoint setShader("waypoint_defend", 12, 12);
        
        waypoint setwaypoint(true, true);
        waypoint.alpha = 1;
        waypoint.color = (1, 1, 0);
        waypoint.hidewheninmenu = true;
        
        waypoints[waypoints.size] = waypoint;
        player.overtimeWaypoint = waypoint;
    }
    
    level waittill("game_ended");
    
    foreach(player in level.players)
    {
        if(isDefined(player.overtimeWaypoint))
        {
            player.overtimeWaypoint destroy();
            player.overtimeWaypoint = undefined;
        }
    }
}

rotateWaypointModel()
{
    level endon("game_ended");
    
    while(true)
    {
        self rotateyaw(360, 2);
        wait 2;
    }
}

overtimeCaptureCleanupModel(model)
{
    level waittill("game_ended");
    if(isDefined(model))
        model delete();
}

overtimeCaptureHUDCleanup(hud)
{
    level waittill("game_ended");
    if(isDefined(hud))
        hud destroy();
}

overtimeCountdown()
{
    level endon("game_ended");

    level thread overtimeVisibilityCleanup();

    countdownHUD = createServerFontString("hudbig", 1.6);
    countdownHUD.horzAlign = "center";
    countdownHUD.vertAlign = "top";
    countdownHUD.alignX = "center";
    countdownHUD.alignY = "top";
    countdownHUD.x = 0;
    countdownHUD.y = 50;
    countdownHUD.color = (1, 0, 0);
    countdownHUD.glowcolor = (1, 0.3, 0);
    countdownHUD.glowAlpha = 0.5;
    countdownHUD.hidewheninmenu = true;
    countdownHUD.archived = false;

    timeRemaining = 20.0;
    lastDisplayedSecond = 20;
    
    while(timeRemaining > 0)
    {
        if(isDefined(level.overtimeCaptureActive) && level.overtimeCaptureActive)
        {
            countdownHUD.color = (1, 1, 0);
            
            currentSecond = int(timeRemaining);
            if(currentSecond != lastDisplayedSecond)
            {
                countdownHUD setText("^3OVERTIME: " + currentSecond + " (PAUSED)");
                lastDisplayedSecond = currentSecond;
            }
        }
        else
        {
            countdownHUD.color = (1, 0, 0);
            
            currentSecond = int(timeRemaining);
            if(currentSecond != lastDisplayedSecond)
            {
                countdownHUD setText("^1OVERTIME: " + currentSecond);
                lastDisplayedSecond = currentSecond;
            }
            
            timeRemaining -= 0.1;
            
            if(timeRemaining < 0)
                timeRemaining = 0;
        }
        
        wait 0.1;
    }

    countdownHUD destroy();

    level notify("overtime_objectives_done");
    level notify("overtime_complete");
}

overtimeVisibilityCleanup()
{
    level waittill("game_ended");

    if(!isDefined(game["gunfight_overtime_triggered"]))
        return;

    level notify("overtime_objectives_done");
}

teamHealthHUD()
{
    level notify("kill_health_hud");
    level endon("kill_health_hud");
    level endon("game_ended");

    foreach(player in level.players)
    {
        if(!isDefined(player.hasHealthHUD))
            player thread playerHealthHUD();
    }
}

monitorPlayerConnections()
{
    level endon("game_ended");
    
    while(true)
    {
        level waittill("connected", player);
        player.hasHealthHUD = undefined;
        player thread playerHealthHUD();
    }
}

playerHealthHUD()
{
    level endon("game_ended");
    self endon("disconnect");
    
    if(isDefined(self.hasHealthHUD))
        return;
        
    self.hasHealthHUD = true;
    
    healthHUD = newClientHudElem(self);
    healthHUD.horzAlign = "center";
    healthHUD.vertAlign = "top";
    healthHUD.alignX = "center";
    healthHUD.alignY = "top";
    healthHUD.x = 0;
    healthHUD.y = 10;
    healthHUD.fontScale = 1.4;
    healthHUD.font = "hudbig";
    healthHUD.hidewheninmenu = true;
    healthHUD.archived = false;

    lastString = "";

    while(true)
    {
        myTeamHealth = 0;
        enemyTeamHealth = 0;

        foreach(player in level.players)
        {
            if(!isAlive(player))
                continue;

            if(player.team == self.team)
                myTeamHealth += player.health;
            else
                enemyTeamHealth += player.health;
        }

        myTeamHealth = int(myTeamHealth / 10) * 10;
        enemyTeamHealth = int(enemyTeamHealth / 10) * 10;

        newString = "^5" + myTeamHealth + " ^7- ^1" + enemyTeamHealth;

        if(newString != lastString)
        {
            healthHUD setText(newString);
            lastString = newString;
        }

        wait 0.1;
    }
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

    self giveWeapon("knife_mp");

    if(!isDefined(alreadyspawned) || !alreadyspawned)
        self setspawnweapon(currentweapon);

    self thread giveDelayedEquipment();

    return currentweapon;
}

giveDelayedEquipment()
{
    self endon("death");
    self endon("disconnect");
    level endon("game_ended");
    
    while(isDefined(level.inprematchperiod) && level.inprematchperiod)
        wait 0.05;
    
    wait 3;
    
    if(isDefined(level.gunfight_current_loadout["lethal"]) && isAlive(self))
    {
        lethal = level.gunfight_current_loadout["lethal"];
        self giveWeapon(lethal);
        self setWeaponAmmoClip(lethal, 1);
        self switchToOffhand(lethal);
    }
    
    wait 2;
    
    if(isDefined(level.gunfight_current_loadout["tactical"]) && isAlive(self))
    {
        tactical = level.gunfight_current_loadout["tactical"];
        self giveWeapon(tactical);
        self setWeaponAmmoClip(tactical, 1);
    }
}
