if (!isServer and hasInterface) exitWith{};
private ["_marcador","_vehiclesX","_grupos","_soldados","_posicion","_pos","_size","_frontera","_lado","_cfg","_esFIA","_garrison","_antena","_tam","_buildings","_mrk","_cuenta","_typeGroup","_grupo","_tipoUnit","_tipoVeh","_veh","_unit","_bandera","_caja","_roads","_mrkMar","_vehicle","_vehCrew","_grupoVeh","_dist","_road","_roadCon","_dirVeh","_bunker","_dir","_posF"];
_marcador = _this select 0;

_vehiclesX = [];
_grupos = [];
_soldados = [];

_posicion = getMarkerPos (_marcador);
_pos = [];


_size = [_marcador] call A3A_fnc_sizeMarker;

_frontera = [_marcador] call A3A_fnc_isFrontline;
_lado = muyMalos;
_esFIA = false;
if (lados getVariable [_marcador,sideUnknown] == malos) then
	{
	_lado = malos;
	if ((random 10 >= (tierWar + difficultyCoef)) and !(_frontera) and !(_marcador in forcedSpawn)) then
		{
		_isFIA = true;
		};
	};

_antena = objNull;

if (_lado == Occupants) then
	{
	if (_marcador in puestos) then
		{
		_buildings = nearestObjects [_posicion,["Land_TTowerBig_1_F","Land_TTowerBig_2_F","Land_Communication_F"], _size];
		if (count _buildings > 0) then
			{
			_antena = _buildings select 0;
			};
		};
	};

_mrk = createMarkerLocal [format ["%1patrolarea", random 100], _posicion];
_mrk setMarkerShapeLocal "RECTANGLE";
_mrk setMarkerSizeLocal [(distanceSPWN/2),(distanceSPWN/2)];
_mrk setMarkerTypeLocal "hd_warning";
_mrk setMarkerColorLocal "ColorRed";
_mrk setMarkerBrushLocal "DiagGrid";
_ang = markerDir _marcador;
_mrk setMarkerDirLocal _ang;
if (!debug) then {_mrk setMarkerAlphaLocal 0};
_garrison = garrison getVariable [_marcador,[]];
_garrison = _garrison call A3A_fnc_garrisonReorg;
_tam = count _garrison;
private _patrol = true;
if (_tam < ([_marcador] call A3A_fnc_garrisonSize)) then
	{
	_patrol = false;
	}
else
	{
	if ({if ((getMarkerPos _x inArea _mrk) and (sidesX getVariable [_x,sideUnknown] != _lado)) exitWIth {1}} count markersX > 0) then {_patrol = false};
	};
if (_patrol) then
	{
	_cuenta = 0;
	while {(spawner getVariable _marcador !=2) and (_cuenta < 4)} do
		{
		_arraygroups = if (_lado == Occupants) then
			{
			if (!_isFIA) then {groupsNATOsmall} else {groupsFIASmall};
			}
		else
			{
			groupsCSATsmall
			};
		if ([_marcador,false] call A3A_fnc_fogCheck < 0.3) then {_arrayGrupos = _arrayGrupos - sniperGroups};
		_typeGroup = selectRandom _arrayGrupos;

		_grupo = [_posicion,_lado, _typeGroup,false,true] call A3A_fnc_spawnGroup;
		if !(isNull _grupo) then
			{
			sleep 1;
			if ((random 10 < 2.5) and (not(_typeGroup in sniperGroups))) then
				{
				_perro = _grupo createUnit ["Fin_random_F",_posicion,[],0,"FORM"];
				[_perro] spawn A3A_fnc_guardDog;
				sleep 1;
				};
			[leader _grupo, _mrk, "SAFE","SPAWNED", "RANDOM","NOVEH2"] execVM "scripts\UPSMON.sqf";
			_grupos pushBack _grupo;
			{[_x,_marcador] call A3A_fnc_NATOinit; _soldados pushBack _x} forEach units _grupo;
			};
		_countX = _countX +1;
		};
	};

if ((_frontera) and (spawner getVariable _marcador!=2) and (_marcador in puestos)) then
	{
	_grupo = createGroup _lado;
	_tipoUnit = if (_lado==malos) then {staticCrewOccupants} else {staticCrewInvaders};
	_tipoVeh = if (_lado == malos) then {NATOMortar} else {CSATMortar};
	_pos = [_posicion] call A3A_fnc_mortarPos;
	_veh = _tipoVeh createVehicle _pos;
	_nul=[_veh] execVM "scripts\UPSMON\MON_artillery_add.sqf";
	_unit = _grupo createUnit [_tipoUnit, _posicion, [], 0, "NONE"];
	[_unit,_marcador] call A3A_fnc_NATOinit;
	_unit moveInGunner _veh;
	_soldados pushBack _unit;
	_vehiclesX pushBack _veh;
	sleep 1;
	};

_ret = [_marcador,_size,_lado,_frontera] call A3A_fnc_milBuildings;
_grupos pushBack (_ret select 0);
_vehiclesX append (_ret select 1);
_soldados append (_ret select 2);

_tipoVeh = if (_lado == malos) then {NATOFlag} else {CSATFlag};
_bandera = createVehicle [_tipoVeh, _posicion, [],0, "CAN_COLLIDE"];
_bandera allowDamage false;
[_bandera,"take"] remoteExec ["A3A_fnc_flagaction",[buenos,civilian],_bandera];
_vehiclesX pushBack _bandera;

_caja = objNull;
if (_lado == Occupants) then
	{
	_caja = NATOAmmoBox createVehicle _posicion;
	_nul = [_caja] call A3A_fnc_NATOcrate;
	}
else
	{
	_caja = CSATAmmoBox createVehicle _posicion;
	_nul = [_caja] call A3A_fnc_CSATcrate;
	};
_vehiclesX pushBack _caja;
_caja call jn_fnc_logistics_addAction;
{_nul = [_x] call A3A_fnc_AIVEHinit;} forEach _vehiclesX;
_roads = _posicion nearRoads _size;

if ((_marcador in puertos) and (spawner getVariable _marcador!=2) and !hayIFA) then
	{
	_typeVehX = if (_lado == Occupants) then {vehNATOBoat} else {vehCSATBoat};
	if ([_typeVehX] call A3A_fnc_vehAvailable) then
		{
		_mrkMar = seaSpawn select {getMarkerPos _x inArea _marcador};
		_pos = (getMarkerPos (_mrkMar select 0)) findEmptyPosition [0,20,_tipoVeh];
		_vehicle=[_pos, 0,_tipoVeh, _lado] call bis_fnc_spawnvehicle;
		_veh = _vehicle select 0;
		[_veh] call A3A_fnc_AIVEHinit;
		_vehCrew = _vehicle select 1;
		{[_x,_marcador] call A3A_fnc_NATOinit} forEach _vehCrew;
		_grupoVeh = _vehicle select 2;
		_soldados = _soldados + _vehCrew;
		_grupos pushBack _grupoVeh;
		_vehiclesX pushBack _veh;
		sleep 1;
		};
	{_caja addItemCargoGlobal [_x,2]} forEach swoopShutUp;
	}
else
	{
	if (_frontera) then
		{
		if (spawner getVariable _marcador!=2) then
			{
			if (count _roads != 0) then
				{
				_dist = 0;
				_road = objNull;
				{if ((position _x) distance _posicion > _dist) then {_road = _x;_dist = position _x distance _posicion}} forEach _roads;
				_roadscon = roadsConnectedto _road;
				_roadcon = objNull;
				{if ((position _x) distance _posicion > _dist) then {_roadcon = _x}} forEach _roadscon;
				_dirveh = [_roadcon, _road] call BIS_fnc_DirTo;
				if (!_isFIA) then
					{
					_group = createGroup _lado;
					_groups pushBack _group;
					_pos = [getPos _road, 7, _dirveh + 270] call BIS_Fnc_relPos;
					_bunker = "Land_BagBunker_01_Small_green_F" createVehicle _pos;
					_vehiclesX pushBack _bunker;
					_bunker setDir _dirveh;
					_pos = getPosATL _bunker;
					_tipoVeh = if (_lado==malos) then {staticATOccupants} else {staticATInvaders};
					_veh = _tipoVeh createVehicle _posicion;
					_vehiclesX pushBack _veh;
					_veh setPos _pos;
					_veh setDir _dirVeh + 180;
					_tipoUnit = if (_lado==malos) then {staticCrewOccupants} else {staticCrewInvaders};
					_unit = _grupo createUnit [_tipoUnit, _posicion, [], 0, "NONE"];
					[_unit,_marcador] call A3A_fnc_NATOinit;
					[_veh] call A3A_fnc_AIVEHinit;
					_unit moveInGunner _veh;
					_soldados pushBack _unit;
					}
				else
					{
					_typeGroup = selectRandom groupsFIAMid;
					_grupo = [_posicion, _lado, _typeGroup,false,true] call A3A_fnc_spawnGroup;
					if !(isNull _grupo) then
						{
						_veh = vehFIAArmedCar createVehicle getPos _road;
						_veh setDir _dirveh + 90;
						_nul = [_veh] call A3A_fnc_AIVEHinit;
						_vehiclesX pushBack _veh;
						sleep 1;
						_unit = _grupo createUnit [FIARifleman, _posicion, [], 0, "NONE"];
						_unit moveInGunner _veh;
						{_soldados pushBack _x; [_x,_marcador] call A3A_fnc_NATOinit} forEach units _grupo;
						};
					};
				};
			};
		};
	};

if (count _roads != 0) then
	{
	_pos = _posicion findEmptyPosition [5,_size,"I_Truck_02_covered_F"];//donde pone 5 antes ponía 10
	if (count _pos > 0) then
		{
		_typeVehX = if (_lado == Occupants) then {if (!_isFIA) then {vehNATOTrucks} else {[vehFIATruck]}} else {vehCSATTrucks};
		_veh = createVehicle [selectRandom _typeVehX, _pos, [], 0, "NONE"];
		_veh setDir random 360;
		_vehiclesX pushBack _veh;
		_nul = [_veh] call A3A_fnc_AIVEHinit;
		sleep 1;
		};
	};

_countX = 0;

if ((!isNull _antena) and (spawner getVariable _marcador!=2)) then
	{
	if ((typeOf _antena == "Land_TTowerBig_1_F") or (typeOf _antena == "Land_TTowerBig_2_F")) then
		{
		_group = createGroup _lado;
		_pos = getPosATL _antena;
		_dir = getDir _antena;
		_posF = _pos getPos [2,_dir];
		_posF set [2,23.1];
		if (typeOf _antena == "Land_TTowerBig_2_F") then
			{
			_posF = _pos getPos [1,_dir];
			_posF set [2,24.3];
			};
		_tipoUnit = if (_lado == malos) then {if (!_esFIA) then {NATOMarksman} else {FIAMarksman}} else {CSATMarksman};
		_unit = _grupo createUnit [_tipoUnit, _posicion, [], _dir, "NONE"];
		_unit setPosATL _posF;
		_unit forceSpeed 0;
		//_unit disableAI "MOVE";
		//_unit disableAI "AUTOTARGET";
		_unit setUnitPos "UP";
		[_unit,_marcador] call A3A_fnc_NATOinit;
		_soldados pushBack _unit;
		_grupos pushBack _grupo;
		};
	};

_array = [];
_subArray = [];
_countX = 0;
_tam = _tam -1;
while {_countX <= _tam} do
	{
	_array pushBack (_garrison select [_countX,7]);
	_countX = _countX + 8;
	};
for "_i" from 0 to (count _array - 1) do
	{
	_grupo = if (_i == 0) then {[_posicion,_lado, (_array select _i),true,false] call A3A_fnc_spawnGroup} else {[_posicion,_lado, (_array select _i),false,true] call A3A_fnc_spawnGroup};
	_grupos pushBack _grupo;
	{[_x,_marcador] call A3A_fnc_NATOinit; _soldados pushBack _x} forEach units _grupo;
	if (_i == 0) then {_nul = [leader _grupo, _marcador, "SAFE", "RANDOMUP","SPAWNED", "NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf"} else {_nul = [leader _grupo, _marcador, "SAFE","SPAWNED", "RANDOM","NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf"};
	};


if (_marcador in puertos) then
	{
	_caja addItemCargo ["V_RebreatherIA",round random 5];
	_caja addItemCargo ["G_I_Diving",round random 5];
	};

waitUntil {sleep 1; (spawner getVariable _marcador == 2)};

deleteMarker _mrk;
//{if ((!alive _x) and (not(_x in destroyedBuildings))) then {destroyedBuildings = destroyedBuildings + [position _x]; publicVariableServer "destroyedBuildings"}} forEach _buildings;
{
if (alive _x) then
	{
	deleteVehicle _x
	};
} forEach _soldados;
//if (!isNull _periodista) then {deleteVehicle _periodista};
{deleteGroup _x} forEach _groups;
{
if (!(_x in staticsToSave)) then
	{
	if ((!([distanceSPWN-_size,1,_x,teamPlayer] call A3A_fnc_distanceUnits))) then {deleteVehicle _x}
	};
} forEach _vehiclesX;