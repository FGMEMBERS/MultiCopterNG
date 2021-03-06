############################################################
##  Adapted from R22.nas for R44 by Clement DE L'HAMAIDE  ##
##                  Date : 05/05/2011                     ##
############################################################

var RPM_arm=props.globals.getNode("/instrumentation/alerts/rpm",1);
var last_time = 0;
var start_timer=0;
var GPS = 0.002222;  ### avg cruise = 8 gph
var Fuel_Density=6.0;
var Fuel1_Level= props.globals.getNode("/consumables/fuel/tank/level-gal_us",1);
var Fuel1_LBS= props.globals.getNode("/consumables/fuel/tank/level-lbs",1);
var Fuel2_Level= props.globals.getNode("/consumables/fuel/tank[1]/level-gal_us",1);
var Fuel2_LBS= props.globals.getNode("/consumables/fuel/tank[1]/level-lbs",1);
var TotalFuelG=props.globals.getNode("/consumables/fuel/total-fuel-gals",1);
var TotalFuelP=props.globals.getNode("/consumables/fuel/total-fuel-lbs",1);
var NoFuel=props.globals.getNode("/engines/engine/out-of-fuel",1);

var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();

setlistener("/sim/signals/fdm-initialized", func {
    Fuel_Density=props.globals.getNode("/consumables/fuel/tank/density-ppg").getValue();
    setprop("/instrumentation/clock/flight-meter-hour",0);
    RPM_arm.setBoolValue(0);
    print("Systems ... Check");
    settimer(update_systems,2);
    setprop("sim/model/sound/volume", 0.5);
    setprop("/instrumentation/doors/Rcrew/position-norm",1);
});

setlistener("/sim/signals/reinit", func {
    RPM_arm.setBoolValue(0);
    setprop("/controls/engines/engine/throttle",1);
});

setlistener("/sim/current-view/view-number", func(vw) {
    var nm = vw.getValue();
    setprop("sim/model/sound/volume", 1.0);
    if(nm == 0 or nm == 7)setprop("sim/model/sound/volume", 0.5);
},1,0);

setlistener("/gear/gear[1]/wow", func(gr) {
    if(gr.getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
},0,0);

setlistener("/engines/engine/out-of-fuel", func(fl) {
    var nofuel = fl.getBoolValue();
    if(nofuel)kill_engine();
},0,0);

setlistener("/controls/electric/key", func(key){
    var key = key.getValue();
    if(key == 0)kill_engine();
},0,0);

setlistener("controls/engines/engine[0]/clutch", func(clutch){
    var clutch= clutch.getBoolValue();
    if(clutch and props.globals.getNode("/engines/engine/running",1).getBoolValue()){
      setprop("/engines/engine/clutch-engaged",1);
    }else{
      setprop("/engines/engine/clutch-engaged",0);
    }
},0,0);

##############################################
######### AUTOSTART / AUTOSHUTDOWN ###########
##############################################

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

var Startup = func {
  setprop("/controls/electric/battery-switch",1);
  setprop("/controls/electric/engine/generator",1);
  setprop("/controls/electric/key",4);
  setprop("/engines/engine/rpm",2700);
  setprop("/engines/engine/running",1);
  setprop("/controls/engines/engine/clutch",1);
}

var Shutdown = func {
  setprop("/controls/electric/battery-switch",0);
  setprop("/controls/electric/engine/generator",0);
  setprop("/controls/electric/key",0);
  setprop("/engines/engine/rpm",0);
  setprop("/engines/engine/running",0);
  setprop("/controls/engines/engine/clutch",0);
}

###############################################
###############################################
###############################################

var flight_meter = func{
  var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
  var fminute = fmeter * 0.016666;
  var fhour = fminute * 0.016666;
  setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

var kill_engine=func{
        setprop("/controls/engines/engine/magnetos",0);
        setprop("/engines/engine/clutch-engaged",0);
        setprop("/engines/engine/running",0);
        start_timer=0;
}

var update_fuel = func{
    var amnt = arg[0] * GPS;
    amnt = amnt * 0.5;
    var lvl = Fuel1_Level.getValue();
    var lvl2 = Fuel2_Level.getValue();
    lvl = lvl-amnt;
    if(lvl2 > 0){lvl2 = lvl2-amnt;
    }else{
    lvl = lvl-amnt;
    }
    if(lvl < 0.0)lvl = 0.0;
    if(lvl2 < 0.0)lvl2 = 0.0;
    var ttl = lvl+lvl2;
    Fuel1_Level.setDoubleValue(lvl);
    Fuel1_LBS.setDoubleValue(lvl * Fuel_Density);
    Fuel2_Level.setDoubleValue(lvl2);
    Fuel2_LBS.setDoubleValue(lvl2 * Fuel_Density);
    TotalFuelG.setDoubleValue(ttl);
    TotalFuelP.setDoubleValue(ttl * Fuel_Density);
    if(ttl < 0.2){
        if(!NoFuel.getBoolValue()){
            NoFuel.setBoolValue(1);
        }
    }
}

var update_systems = func {
	var time = getprop("/sim/time/elapsed-sec");
	var dt = time - last_time;
	last_time = time;
	var throttle = getprop("/controls/rotor/engine-throttle");
	if(getprop("engines/engine/running"))update_fuel(dt);
	flight_meter();
	if(!RPM_arm.getBoolValue()){
	if(getprop("/rotors/main/rpm") > 525)RPM_arm.setBoolValue(1);
	}

	if(getprop("/systems/electrical/outputs/starter") > 11){
	    if(getprop("/controls/electric/key") > 2){
	      setprop("/engines/engine/cranking",1);
	    }
	    if(getprop("/controls/engines/engine/clutch")){
	      setprop("/engines/engine/clutch-engaged",1);
	    } else {
	      setprop("/engines/engine/clutch-engaged",0);
	    }
	}else{
	    setprop("/engines/engine/cranking",0);
	}

	if(getprop("/engines/engine/cranking") != 0){
	    if(!getprop("/engines/engine/running")){
	    start_timer +=1;
	    }else{start_timer = 0;}
	}

	if(start_timer > 40){
	    setprop("/engines/engine/running",1);
	    start_timer = 0;
	    }

	if(getprop("/engines/engine/running")){
	  if(getprop("/engines/engine/amp-v") > 0){
	    if(getprop("/engines/engine/clutch-engaged")){
		interpolate("/rotors/main/rpm", 2700 * throttle, 0.9);
		interpolate("/rotors/tail/rpm", 2700 * throttle, 0.9);
	    }else{
		interpolate("/rotors/main/rpm", 0, 0.2);
		interpolate("/rotors/tail/rpm", 0, 0.2);
	    }
	    interpolate("/engines/engine/rpm", 2700 * throttle, 0.8);
	  } else {
	    if(!getprop("/controls/engines/engine/generator") and getprop("/engines/engine/amp-v") < 2){
		setprop("/engines/engine/clutch-engaged",0);
		setprop("/engines/engine/running",0);
	    }
	  }
	}else{
	  interpolate("/engines/engine/rpm", 0, 0.8);
	  interpolate("/rotors/main/rpm", 0, 0.4);
	  interpolate("/rotors/tail/rpm", 0, 0.4);
	}
	settimer(update_systems,0);
}
