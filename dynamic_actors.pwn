/*

       /$$                                             /$$                                       /$$                                                               /$$
      | $$                                            |__/                                      | $$                                                              | $$
  /$$$$$$$ /$$   /$$ /$$$$$$$   /$$$$$$  /$$$$$$/$$$$  /$$  /$$$$$$$        /$$$$$$   /$$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$         /$$$$$$$ /$$   /$$  /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$/$$$$
 /$$__  $$| $$  | $$| $$__  $$ |____  $$| $$_  $$_  $$| $$ /$$_____/       |____  $$ /$$_____/|_  $$_/   /$$__  $$ /$$__  $$       /$$_____/| $$  | $$ /$$_____/|_  $$_/   /$$__  $$| $$_  $$_  $$
| $$  | $$| $$  | $$| $$  \ $$  /$$$$$$$| $$ \ $$ \ $$| $$| $$              /$$$$$$$| $$        | $$    | $$  \ $$| $$  \__/      |  $$$$$$ | $$  | $$|  $$$$$$   | $$    | $$$$$$$$| $$ \ $$ \ $$
| $$  | $$| $$  | $$| $$  | $$ /$$__  $$| $$ | $$ | $$| $$| $$             /$$__  $$| $$        | $$ /$$| $$  | $$| $$             \____  $$| $$  | $$ \____  $$  | $$ /$$| $$_____/| $$ | $$ | $$
|  $$$$$$$|  $$$$$$$| $$  | $$|  $$$$$$$| $$ | $$ | $$| $$|  $$$$$$$      |  $$$$$$$|  $$$$$$$  |  $$$$/|  $$$$$$/| $$             /$$$$$$$/|  $$$$$$$ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$ | $$ | $$
 \_______/ \____  $$|__/  |__/ \_______/|__/ |__/ |__/|__/ \_______/       \_______/ \_______/   \___/   \______/ |__/            |_______/  \____  $$|_______/    \___/   \_______/|__/ |__/ |__/
           /$$  | $$                                                                                                                         /$$  | $$
          |  $$$$$$/                                                                                                                        |  $$$$$$/
           \______/                                                                                                                          \______/
           
														  _              _  ___           _            ____ _
														 | |__  _   _   | |/ (_)_ __   __| | ___ _ __ / ___| | __ _ _ __  ___
														 | '_ \| | | |  | ' /| | '_ \ / _` |/ _ \ '__| |   | |/ _` | '_ \/ __|
														 | |_) | |_| |  | . \| | | | | (_| |  __/ |  | |___| | (_| | | | \__ \
														 |_.__/ \__, |  |_|\_\_|_| |_|\__,_|\___|_|   \____|_|\__,_|_| |_|___/
														        |___/
														        

You're free to edit and redistribute unless you keep credits.

Includes required:

MySQL R41-4: https://github.com/pBlueG/SA-MP-MySQL/releases
Sscanf: https://github.com/maddinat0r/sscanf/releases
Streamer: https://github.com/samp-incognito/samp-streamer-plugin/releases
I-ZCMD: https://github.com/YashasSamaga/I-ZCMD/blob/master/izcmd.inc

*/

#include <a_samp>
#include <sscanf2>
#include <a_mysql>
#include <streamer>
#include <izcmd>

#undef MAX_PLAYERS
#define	MAX_PLAYERS	50 //Change it according to your server slots.

/* ---- Colors ---- */
#define COLOR_DARKGREEN (0x33AA33FF)
#define COLOR_AQUA 0xBAFCFFFF
/* ---------------- */

/* ---- Defines ---- */
#define SCMEX SendClientMessageEx
#define function%0(%1) forward %0(%1); public %0(%1) //Just a little macro.

#define MAX_DYNAMIC_ACTORS (10) //Max actors that can be created, feel free to increase it.
#define MAX_ACTORS_RANGE 50.0 //Used for /locatenearactors, in meters.
/* ----------------- */

/* ---- Enums ---- */
enum DynamicActorData
{
	dynamicActorID,
	dynamicActorExists,
	Float:dynamicActorPos[4],
	dynamicActorVW,
	dynamicActorSkin,
	Text3D:dynamicActorLabel
};
/* --------------- */

/* ---- News ---- */
new MySQL: g_SQL;
new Dynamic_Actor_Data[MAX_DYNAMIC_ACTORS][DynamicActorData];
new Float:CheckpointPos[MAX_PLAYERS][3]; //For setting up the checkpoint.
/* -------------- */

/* ---- MySQL Database Informations ---- */
#define MYSQL_HOST		""
#define MYSQL_USER		""
#define MYSQL_PASS		""
#define MYSQL_DATABASE	""

Database_Connection()
{
    mysql_log(ALL); //Let's log everything that happens when we load actors, to find bugs/errors.

    g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATABASE);
    
	if (mysql_errno(g_SQL) != 0) return 0;

	mysql_tquery(g_SQL, "SELECT * FROM `actors`", "Load_Dynamic_Actors"); //Loading actors from database.
    return 1;
}
/* ------------------------------------- */

/* ---- Stocks ---- */
stock SendClientMessageEx(playerid, color, const str[], {Float,_}:...)
{
	static args, start, end,string[200];
	#emit LOAD.S.pri 8
	#emit STOR.pri args

	if (args > 12)
	{
		#emit ADDR.pri str
		#emit STOR.pri start

	    for (end = start + (args - 12); end > start; end -= 4)
		{
	        #emit LREF.pri end
	        #emit PUSH.pri
		}
		#emit PUSH.S str
		#emit PUSH.C 156
		#emit PUSH.C string
		#emit PUSH.C args
		#emit SYSREQ.C format

		SendClientMessage(playerid, color, string);

		#emit LCTRL 5
		#emit SCTRL 4
		#emit RETN
	}
	return SendClientMessage(playerid, color, str);
} // Credits to Emmet
/* ---------------- */

public OnFilterScriptInit()
{
    if (Database_Connection() == 0)
	{
		printf("Couldn't connect to MySQL database.");
		return 0;
    }
	return 1;
}

public OnFilterScriptExit()
{
    mysql_close(g_SQL);
	return 1;
}

/* ---- Dynamic Actors Functions ---- */
function SetPlayerCheckpointEx(playerid, Float:x, Float:y, Float:z, Float:size)
{
	SetPlayerCheckpoint(playerid, x, y, z, size);
	CheckpointPos[playerid][0] = x;
	CheckpointPos[playerid][1] = y;
	CheckpointPos[playerid][2] = z;
	return 1;
}

function OnActorCreated(dynamicactorid)
{
	if (dynamicactorid == -1 || !Dynamic_Actor_Data[dynamicactorid][dynamicActorExists])
	    return 0;

	Dynamic_Actor_Data[dynamicactorid][dynamicActorID] = cache_insert_id();

	Save_Dynamic_Actor(dynamicactorid);
	return 1;
}

function Load_Dynamic_Actors()
{
    for(new i, j = cache_num_rows(); i != j; i++)
    {
        if(i < MAX_DYNAMIC_ACTORS)
        {
             	Dynamic_Actor_Data[i][dynamicActorExists] = true;
                cache_get_value_int(i,"dynamicActorID",Dynamic_Actor_Data[i][dynamicActorID]);
                cache_get_value_float(i, "dynamicActorX",Dynamic_Actor_Data[i][dynamicActorPos][0]);
                cache_get_value_float(i, "dynamicActorY",Dynamic_Actor_Data[i][dynamicActorPos][1]);
                cache_get_value_float(i, "dynamicActorZ",Dynamic_Actor_Data[i][dynamicActorPos][2]);
                cache_get_value_float(i, "dynamicActorA",Dynamic_Actor_Data[i][dynamicActorPos][3]);
                cache_get_value_int(i,"dynamicActorVW",Dynamic_Actor_Data[i][dynamicActorVW]);
                cache_get_value_int(i,"dynamicActorSkin",Dynamic_Actor_Data[i][dynamicActorSkin]);
                Refresh_Dynamic_Actor(i);
        }
    }
    return 1;
}
/* ---------------------------------- */

/* ---- Dynamic Actor Stocks ---- */
stock Create_Dynamic_Actor(playerid, skin)
{
	for (new i = 0; i != MAX_DYNAMIC_ACTORS; i ++) if (!Dynamic_Actor_Data[i][dynamicActorExists])
	{
	    Dynamic_Actor_Data[i][dynamicActorExists] = true;
	    
	    Dynamic_Actor_Data[i][dynamicActorSkin] = skin;

	    GetPlayerPos(playerid, Dynamic_Actor_Data[i][dynamicActorPos][0], Dynamic_Actor_Data[i][dynamicActorPos][1], Dynamic_Actor_Data[i][dynamicActorPos][2]);
	    GetPlayerFacingAngle(playerid, Dynamic_Actor_Data[i][dynamicActorPos][3]);

	    Dynamic_Actor_Data[i][dynamicActorPos][0] = Dynamic_Actor_Data[i][dynamicActorPos][0] + (1.5 * floatsin(-Dynamic_Actor_Data[i][dynamicActorPos][3], degrees));
	    Dynamic_Actor_Data[i][dynamicActorPos][1] = Dynamic_Actor_Data[i][dynamicActorPos][1] + (1.5 * floatcos(-Dynamic_Actor_Data[i][dynamicActorPos][3], degrees));

		Dynamic_Actor_Data[i][dynamicActorVW] = GetPlayerVirtualWorld(playerid);
		
		Refresh_Dynamic_Actor(i);
		
		mysql_tquery(g_SQL, "INSERT INTO `actors` (`dynamicActorSkin`) VALUES(0)", "OnActorCreated", "d", i);
		return i;
	}
	return -1;
}

stock Remove_Dynamic_Actor(dynamicactorid)
{
	if (dynamicactorid != -1 && Dynamic_Actor_Data[dynamicactorid][dynamicActorExists])
	{
	    DestroyActor(dynamicactorid);
	    
	    new string[80];

		format(string, sizeof(string), "DELETE FROM `actors` WHERE `dynamicActorID` = '%d'", Dynamic_Actor_Data[dynamicactorid][dynamicActorID]);
		mysql_tquery(g_SQL, string);

        if (IsValidDynamic3DTextLabel(Dynamic_Actor_Data[dynamicactorid][dynamicActorLabel])) DestroyDynamic3DTextLabel(Dynamic_Actor_Data[dynamicactorid][dynamicActorLabel]);

	    Dynamic_Actor_Data[dynamicactorid][dynamicActorExists] = false;
	    Dynamic_Actor_Data[dynamicactorid][dynamicActorID] = 0;
	}
	return 1;
}

stock Refresh_Dynamic_Actor(dynamicactorid)
{
	if (dynamicactorid != -1 && Dynamic_Actor_Data[dynamicactorid][dynamicActorExists])
	{
	    if (IsValidDynamic3DTextLabel(Dynamic_Actor_Data[dynamicactorid][dynamicActorLabel])) DestroyDynamic3DTextLabel(Dynamic_Actor_Data[dynamicactorid][dynamicActorLabel]);

		new string[80];

		format(string, sizeof(string), "[Actor ID: %d]\nPress ~k~~VEHICLE_ENTER_EXIT~ to interact.", dynamicactorid);
		
		Dynamic_Actor_Data[dynamicactorid][dynamicActorLabel] = CreateDynamic3DTextLabel(string, -1, Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][0], Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][1], Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][2], 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, Dynamic_Actor_Data[dynamicactorid][dynamicActorVW]);

		Dynamic_Actor_Data[dynamicactorid][dynamicActorID] = CreateActor(Dynamic_Actor_Data[dynamicactorid][dynamicActorSkin], Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][0], Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][1], Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][2], Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][3]);

		SetActorVirtualWorld(Dynamic_Actor_Data[dynamicactorid][dynamicActorID], Dynamic_Actor_Data[dynamicactorid][dynamicActorVW]);

	}
	return 1;
}

stock Save_Dynamic_Actor(dynamicactorid)
{
	new query[300];

	format(query, sizeof(query), "UPDATE `actors` SET `dynamicActorX` = '%.4f', `dynamicActorY` = '%.4f', `dynamicActorZ` = '%.4f', `dynamicActorA` = '%.4f', `dynamicActorVW` = '%d', `dynamicActorSkin` = '%d' WHERE `dynamicActorID` = '%d'",
        Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][0],
        Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][1],
        Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][2],
        Dynamic_Actor_Data[dynamicactorid][dynamicActorPos][3],
        Dynamic_Actor_Data[dynamicactorid][dynamicActorVW],
        Dynamic_Actor_Data[dynamicactorid][dynamicActorSkin],
        Dynamic_Actor_Data[dynamicactorid][dynamicActorID]
	);
	return mysql_tquery(g_SQL, query);
}
/* ------------------------------ */

public OnPlayerEnterCheckpoint(playerid)
{
    DisablePlayerCheckpoint(playerid);
	return 1;
}

Get_Nearest_Dynamic_Actor(playerid)
{
	new Float:fDistance[2] = {MAX_ACTORS_RANGE, 0.0}, iIndex = -1;
	for (new i = 0; i < MAX_DYNAMIC_ACTORS; i ++) if (Dynamic_Actor_Data[i][dynamicActorExists] && GetPlayerVirtualWorld(playerid) == Dynamic_Actor_Data[i][dynamicActorVW])
	{
		fDistance[1] = GetPlayerDistanceFromPoint(playerid, Dynamic_Actor_Data[i][dynamicActorPos][0], Dynamic_Actor_Data[i][dynamicActorPos][1], Dynamic_Actor_Data[i][dynamicActorPos][2]);

		if (fDistance[1] < fDistance[0])
		{
		    fDistance[0] = fDistance[1];
		    iIndex = i;
		}
	}
	return iIndex;
}

/* ---- Admin Commands ---- */
CMD:actorhelp(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return 0;
	
	SendClientMessage(playerid, -1, "[ ---- Dynamic Actor Commands ---- ]");
	
	SendClientMessage(playerid, COLOR_AQUA, "/createactor [skin id] - Creates an actor at your position with the skin set.");
	SendClientMessage(playerid, COLOR_AQUA, "/removeactor [actor id] - Removes an actor from the database.");
	SendClientMessage(playerid, COLOR_AQUA, "/removeallactors - Removes all created actors from the database.");
	SendClientMessage(playerid, COLOR_AQUA, "/locatenearactors - Locates all actors in a range defined with MAX_ACTORS_RANGE.");
	
	SendClientMessage(playerid, -1, "[ --------------------------------------------- ]");
    return 1;
}

CMD:createactor(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    
    static id = -1, skin;
	
	if(sscanf(params, "d", skin)) return SendClientMessage(playerid, COLOR_AQUA, "* [USAGE]: /createactor [skin id]");

	if(skin < 0 || skin > 311) return SendClientMessage(playerid, -1, "* Invalid skin ID (1-311)");
	
	id = Create_Dynamic_Actor(playerid, skin);

	if (id == -1) return SendClientMessage(playerid, COLOR_AQUA, "* The server has reached the limit for dynamic actors.");

	SCMEX(playerid, -1, "* You have successfully created an actor. ID: %d - Skin: %d", id, skin);
	return 1;
}

CMD:removeactor(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    
	static id = 0;

	if (sscanf(params, "d", id)) return SendClientMessage(playerid, COLOR_AQUA, "* [USAGE]: /removeactor [actor id]");

	if ((id < 0 || id >= MAX_DYNAMIC_ACTORS) || !Dynamic_Actor_Data[id][dynamicActorExists]) return SendClientMessage(playerid, COLOR_AQUA, "* You have specified an invalid actor ID.");

	Remove_Dynamic_Actor(id);

	SCMEX(playerid, -1, "* You have successfully destroyed actor ID: %d.", id);
	return 1;
}

CMD:removeallactors(playerid)
{
	for (new i = 0; i != MAX_DYNAMIC_ACTORS; i ++) if (Dynamic_Actor_Data[i][dynamicActorExists]) Remove_Dynamic_Actor(i);
	
	SendClientMessage(playerid, COLOR_AQUA, "* All actors have been removed from database.");
	return 1;
}

CMD:locatenearactors(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return 0;
	
	new id = Get_Nearest_Dynamic_Actor(playerid);

	if (id == -1) return SendClientMessage(playerid, -1, "* There are no actors near you.");

    SetPlayerCheckpointEx(playerid, Dynamic_Actor_Data[id][dynamicActorPos][0], Dynamic_Actor_Data[id][dynamicActorPos][1], Dynamic_Actor_Data[id][dynamicActorPos][2], 2.5);

    new Float: fDistance = GetPlayerDistanceFromPoint(playerid, CheckpointPos[playerid][0], CheckpointPos[playerid][1], CheckpointPos[playerid][2]);
    
    SCMEX(playerid, -1, "* Marker set to nearest actor. Distance: %0.1fm", fDistance);
	return 1;
}
/* ------------------------ */
