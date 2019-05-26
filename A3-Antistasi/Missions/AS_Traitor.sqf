//Mission: Assassinate a traitor
if (!isServer and hasInterface) exitWith{};

_marcador = _this select 0;

_difficultX = if (random 10 < tierWar) then {true} else {false};
_leave = false;
_contactX = objNull;
_groupContact = grpNull;
_tsk = "";
_tsk1 = "";

_posicion = getMarkerPos _marcador;

_timeLimit = if (_difficultX) then {30} else {60};
if (hasIFA) then {_timeLimit = _timeLimit * 2};
_dateLimit = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _timeLimit];
_dateLimitNum = dateToNumber _dateLimit;

_tam = [_marcador] call A3A_fnc_sizeMarker;
_casas = (nearestObjects [_posicion, ["house"], _tam]) select {!((typeOf _x) in UPSMON_Bld_remove)};
_poscasa = [];
_casa = _casas select 0;
while {count _poscasa < 3} do
	{
	_casa = _houses call BIS_Fnc_selectRandom;
	_posHouse = _casa buildingPos -1;
	if (count _posHouse < 3) then {_houses = _houses - [_casa]};
	};

_max = (count _posHouse) - 1;
_rnd = floor random _max;
_posTraitor = _posHouse select _rnd;
_posSol1 = _posHouse select (_rnd + 1);
_posSol2 = (_casa buildingExit 0);

_nameDest = [_marcador] call A3A_fnc_localizar;

_groupTraitor = createGroup Occupants;

_arrayAirports = airportsX select {lados getVariable [_x,sideUnknown] == malos};
_base = [_arrayAirports, _posicion] call BIS_Fnc_nearestPosition;
_posBase = getMarkerPos _base;

_traitor = _groupTraitor createUnit [NATOOfficer2, _posTraitor, [], 0, "NONE"];
_traitor allowDamage false;
_traitor setPos _posTraitor;
_sol1 = _groupTraitor createUnit [NATOBodyG, _posSol1, [], 0, "NONE"];
_sol2 = _groupTraitor createUnit [NATOBodyG, _posSol2, [], 0, "NONE"];
_groupTraitor selectLeader _traitor;

_posTsk = (position _casa) getPos [random 100, random 360];

[[buenos,civilian],"AS",[format ["A traitor has scheduled a meeting with %4 in %1. Kill him before he provides enough intel to give us trouble. Do this before %2:%3. We don't where exactly this meeting will happen. You will recognise the building by the nearby Offroad and %4 presence.",_nameDest,numberToDate [2035,_dateLimitNum] select 3,numberToDate [2035,_dateLimitNum] select 4,nameOccupants],"Kill the Traitor",_marcador],_posTsk,false,0,true,"Kill",true] call BIS_fnc_taskCreate;
[[malos],"AS1",[format ["We arranged a meeting in %1 with a %4 contact who may have vital information about their Headquarters position. Protect him until %2:%3.",_nameDest,numberToDate [2035,_dateLimitNum] select 3,numberToDate [2035,_dateLimitNum] select 4,nameTeamPlayer],"Protect Contact",_marcador],getPos _casa,false,0,true,"Defend",true] call BIS_fnc_taskCreate;
misiones pushBack ["AS","CREATED"]; publicVariable "misiones";
{_nul = [_x,""] call A3A_fnc_NATOinit; _x allowFleeing 0} forEach units _groupTraitor;
_posVeh = [];
_dirVeh = 0;
_roads = [];
_radius = 20;
while {count _roads == 0} do
	{
	_roads = (getPos _casa) nearRoads _radius;
	_radius = _radius + 10;
	};

_road = _roads select 0;
_posroad = getPos _road;
_roadcon = roadsConnectedto _road; if (count _roadCon == 0) then {diag_log format ["Antistasi Error: Esta carretera no tiene conexión: %1",position _road]};
if (count _roadCon > 0) then
	{
	_posrel = getPos (_roadcon select 0);
	_dirveh = [_posroad,_posrel] call BIS_fnc_DirTo;
	}
else
	{
	_dirVeh = getDir _road;
	};
_posVeh = [_posroad, 3, _dirveh + 90] call BIS_Fnc_relPos;
_veh = vehSDKLightUnarmed createVehicle _posVeh;
_veh allowDamage false;
_veh setDir _dirVeh;
sleep 15;
_veh allowDamage true;
_traitor allowDamage true;
_nul = [_veh] call A3A_fnc_AIVEHinit;
{_x disableAI "MOVE"; _x setUnitPos "UP"} forEach units _groupTraitor;

_mrk = createMarkerLocal [format ["%1patrolarea", floor random 100], getPos _casa];
_mrk setMarkerShapeLocal "RECTANGLE";
_mrk setMarkerSizeLocal [50,50];
_mrk setMarkerTypeLocal "hd_warning";
_mrk setMarkerColorLocal "ColorRed";
_mrk setMarkerBrushLocal "DiagGrid";
_mrk setMarkerAlphaLocal 0;

_typeGroup = if (random 10 < tierWar) then {NATOSquad} else {[policeOfficer,policeGrunt,policeGrunt,policeGrunt,policeGrunt,policeGrunt,policeGrunt,policeGrunt]};
_grupo = [_posicion,malos, NATOSquad] call A3A_fnc_spawnGroup;
sleep 1;
if (random 10 < 2.5) then
	{
	_perro = _grupo createUnit ["Fin_random_F",_posicion,[],0,"FORM"];
	[_perro] spawn A3A_fnc_guardDog;
	};
_nul = [leader _group, _mrk, "SAFE","SPAWNED", "NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";
{[_x,""] call A3A_fnc_NATOinit} forEach units _group;

waitUntil {sleep 1; (dateToNumber date > _dateLimitNum) or (not alive _traitor) or ({_traitor knowsAbout _x > 1.4} count ([500,0,_traitor,teamPlayer] call A3A_fnc_distanceUnits) > 0)};

if ({_traitor knowsAbout _x > 1.4} count ([500,0,_traitor,teamPlayer] call A3A_fnc_distanceUnits) > 0) then
	{
	{_x enableAI "MOVE"} forEach units _groupTraitor;
	_traitor assignAsDriver _veh;
	[_traitor] orderGetin true;
	_wp0 = _groupTraitor addWaypoint [_posVeh, 0];
	_wp0 setWaypointType "GETIN";
	_wp1 = _groupTraitor addWaypoint [_posBase,1];
	_wp1 setWaypointType "MOVE";
	_wp1 setWaypointBehaviour "CARELESS";
	_wp1 setWaypointSpeed "FULL";
	};

waitUntil  {sleep 1; (dateToNumber date > _dateLimitNum) or (not alive _traitor) or (_traitor distance _posBase < 20)};

if (not alive _traitor) then
	{
	["AS",[format ["A traitor has scheduled a meeting with %4 in %1. Kill him before he provides enough intel to give us trouble. Do this before %2:%3. We don't where exactly this meeting will happen. You will recognise the building by the nearby Offroad and %4 presence.",_nameDest,numberToDate [2035,_dateLimitNum] select 3,numberToDate [2035,_dateLimitNum] select 4,nameOccupants],"Kill the Traitor",_marcador],_traidor,"SUCCEEDED"] call A3A_fnc_taskUpdate;
	["AS1",[format ["We arranged a meeting in %1 with a %4 contact who may have vital information about their Headquarters position. Protect him until %2:%3.",_nameDest,numberToDate [2035,_dateLimitNum] select 3,numberToDate [2035,_dateLimitNum] select 4,nameTeamPlayer],"Protect Contact",_marcador],getPos _casa,"FAILED"] call A3A_fnc_taskUpdate;
	if (_dificil) then
		{
		[4,0] remoteExec ["A3A_fnc_prestige",2];
		[0,600] remoteExec ["A3A_fnc_resourcesFIA",2];
		{
		if (!isPlayer _x) then
			{
			_skill = skill _x;
			_skill = _skill + 0.1;
			_x setSkill _skill;
			}
		else
			{
			[20,_x] call A3A_fnc_playerScoreAdd;
			};
		} forEach ([_tam,0,_posicion,buenos] call A3A_fnc_distanceUnits);
		[10,theBoss] call A3A_fnc_playerScoreAdd;
		}
	else
		{
		[2,0] remoteExec ["A3A_fnc_prestige",2];
		[0,300] remoteExec ["A3A_fnc_resourcesFIA",2];
		{
		if (!isPlayer _x) then
			{
			_skill = skill _x;
			_skill = _skill + 0.1;
			_x setSkill _skill;
			}
		else
			{
			[10,_x] call A3A_fnc_playerScoreAdd;
			};
		} forEach ([_tam,0,_posicion,buenos] call A3A_fnc_distanceUnits);
		[5,theBoss] call A3A_fnc_playerScoreAdd;
		};
	}
else
	{
	["AS",[format ["A traitor has scheduled a meeting with %4 in %1. Kill him before he provides enough intel to give us trouble. Do this before %2:%3. We don't where exactly this meeting will happen. You will recognise the building by the nearby Offroad and %4 presence.",_nameDest,numberToDate [2035,_dateLimitNum] select 3,numberToDate [2035,_dateLimitNum] select 4,nameOccupants],"Kill the Traitor",_marcador],_traidor,"FAILED"] call A3A_fnc_taskUpdate;
	["AS1",[format ["We arranged a meeting in %1 with a %4 contact who may have vital information about their Headquarters position. Protect him until %2:%3.",_nameDest,numberToDate [2035,_dateLimitNum] select 3,numberToDate [2035,_dateLimitNum] select 4,nameTeamPlayer],"Protect Contact",_marcador],getPos _casa,"SUCCEEDED"] call A3A_fnc_taskUpdate;
	if (_dificil) then {[-10,theBoss] call A3A_fnc_playerScoreAdd} else {[-10,theBoss] call A3A_fnc_playerScoreAdd};
	if (dateToNumber date > _dateLimitNum) then
		{
		_hrT = server getVariable "hr";
		_resourcesFIAT = server getVariable "resourcesFIA";
		[-1*(round(_hrT/3)),-1*(round(_resourcesFIAT/3))] remoteExec ["A3A_fnc_resourcesFIA",2];
		}
	else
		{
		if (isPlayer theBoss) then
			{
			if (!(["DEF_HQ"] call BIS_fnc_taskExists)) then
				{
				[[Occupants],"A3A_fnc_attackHQ"] remoteExec ["A3A_fnc_scheduler",2];
				};
			}
		else
			{
			_minasFIA = allmines - (detectedMines malos) - (detectedMines muyMalos);
			if (count _minasFIA > 0) then
				{
				{if (random 100 < 30) then {malos revealMine _x;}} forEach _minasFIA;
				};
			};
		};
	};

_nul = [1200,"AS"] spawn A3A_fnc_deleteTask;
_nul = [10,"AS1"] spawn A3A_fnc_deleteTask;
if (!([distanceSPWN,1,_veh,teamPlayer] call A3A_fnc_distanceUnits)) then {deleteVehicle _veh};

{
waitUntil {sleep 1; !([distanceSPWN,1,_x,teamPlayer] call A3A_fnc_distanceUnits)};
deleteVehicle _x
} forEach units _groupTraitor;
deleteGroup _groupTraitor;

{
waitUntil {sleep 1; !([distanceSPWN,1,_x,teamPlayer] call A3A_fnc_distanceUnits)};
deleteVehicle _x
} forEach units _group;
deleteGroup _group;