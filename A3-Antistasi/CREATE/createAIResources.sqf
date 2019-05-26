if (!isServer and hasInterface) exitWith{};

private ["_marcador","_vehiclesX","_grupos","_soldados","_civs","_posicion","_pos","_typeGroup","_tipociv","_size","_mrk","_ang","_cuenta","_grupo","_veh","_civ","_frontera","_bandera","_perro","_garrison","_lado","_cfg","_esFIA","_roads","_dist","_road","_roadscon","_roadcon","_dirveh","_bunker","_tipoVeh","_tipoUnit","_unit","_typeGroup","_stance"];

_marcador = _this select 0;

_posicion = getMarkerPos _marcador;

_size = [_marcador] call A3A_fnc_sizeMarker;

_civs = [];
_soldados = [];
_grupos = [];
_vehiclesX = [];

_frontera = [_marcador] call A3A_fnc_isFrontline;

_lado = muyMalos;

_esFIA = false;
if (lados getVariable [_marcador,sideUnknown] == malos) then
	{
	_lado = malos;
	if ((random 10 <= (tierWar + difficultyCoef)) and !(_frontera)) then
		{
		_isFIA = true;
		};
	};
_roads = _posicion nearRoads _size;
_dist = 0;
_road = objNull;
{if ((position _x) distance _posicion > _dist) then {_road = _x;_dist = position _x distance _posicion}} forEach _roads;
_roadscon = roadsConnectedto _road;
_roadcon = objNull;
{if ((position _x) distance _posicion > _dist) then {_roadcon = _x}} forEach _roadscon;
_dirveh = [_roadcon, _road] call BIS_fnc_DirTo;

if ((spawner getVariable _marcador != 2) and _frontera) then
	{
	if (count _roads != 0) then
		{
		if (!_isFIA) then
			{
			_group = createGroup _lado;
			_groups pushBack _group;
			_pos = [getPos _road, 7, _dirveh + 270] call BIS_Fnc_relPos;
			_bunker = "Land_BagBunker_01_small_green_F" createVehicle _pos;
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
	while {(spawner getVariable _marcador != 2) and (_cuenta < 4)} do
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
			_nul = [leader _grupo, _mrk, "SAFE","SPAWNED", "RANDOM","NOVEH2"] execVM "scripts\UPSMON.sqf";
			_grupos pushBack _grupo;
			{[_x,_marcador] call A3A_fnc_NATOinit; _soldados pushBack _x} forEach units _grupo;
			};
		_countX = _countX +1;
		};
	};

_tipoVeh = if (_lado == malos) then {NATOFlag} else {CSATFlag};
_bandera = createVehicle [_tipoVeh, _posicion, [],0, "CAN_COLLIDE"];
_bandera allowDamage false;
[_bandera,"take"] remoteExec ["A3A_fnc_flagaction",[buenos,civilian],_bandera];
_vehiclesX pushBack _bandera;

if (not(_marcador in destroyedCities)) then
	{
	if ((daytime > 8) and (daytime < 18)) then
		{
		_group = createGroup civilian;
		_groups pushBack _group;
		for "_i" from 1 to 4 do
			{
			if (spawner getVariable _marcador != 2) then
				{
				_civ = _grupo createUnit ["C_man_w_worker_F", _posicion, [],0, "NONE"];
				_nul = [_civ] spawn A3A_fnc_CIVinit;
				_civs pushBack _civ;
				_civ setVariable ["marcador",_marcador,true];
				sleep 0.5;
				_civ addEventHandler ["Killed",
					{
					if (({alive _x} count units group (_this select 0)) == 0) then
						{
						_marcador = (_this select 0) getVariable "marcador";
						_nombre = [_marcador] call A3A_fnc_localizar;
						destroyedCities pushBackUnique _marcador;
						publicVariable "destroyedCities";
						["TaskFailed", ["", format ["%1 Destroyed",_nameX]]] remoteExec ["BIS_fnc_showNotification",[teamPlayer,civilian]];
						};
					}];
				};
			};
		//_nul = [_marcador,_civs] spawn destroyCheck;
		_nul = [leader _grupo, _marcador, "SAFE", "SPAWNED","NOFOLLOW", "NOSHARE","DORELAX","NOVEH2"] execVM "scripts\UPSMON.sqf";
		};
	};

_pos = _posicion findEmptyPosition [5,_size,"I_Truck_02_covered_F"];//donde pone 5 antes ponía 10
if (count _pos > 0) then
	{
	_typeVehX = if (_lado == Occupants) then
		{
		if (!_isFIA) then {vehNATOTrucks} else {[vehFIATruck]};
		}
	else
		{
		vehCSATTrucks
		};
	_veh = createVehicle [selectRandom _typeVehX, _pos, [], 0, "NONE"];
	_veh setDir random 360;
	_vehiclesX pushBack _veh;
	_nul = [_veh] call A3A_fnc_AIVEHinit;
	sleep 1;
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

waitUntil {sleep 1; (spawner getVariable _marcador == 2)};

deleteMarker _mrk;
{
if (alive _x) then
	{
	deleteVehicle _x
	};
} forEach _soldados;
//if (!isNull _periodista) then {deleteVehicle _periodista};
{deleteGroup _x} forEach _groups;
{deleteVehicle _x} forEach _civs;
{if (!([distanceSPWN-_size,1,_x,teamPlayer] call A3A_fnc_distanceUnits)) then {deleteVehicle _x}} forEach _vehiclesX;