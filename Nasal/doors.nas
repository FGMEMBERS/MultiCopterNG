# =====
# Doors
# =====

Doors = {};

Doors.new = func {
   obj = { parents : [Doors],
           frontR : aircraft.door.new("instrumentation/doors/frontR", 2.0),
           frontL : aircraft.door.new("instrumentation/doors/frontL", 2.0),
           rearR : aircraft.door.new("instrumentation/doors/rearR", 2.0),
           rearL : aircraft.door.new("instrumentation/doors/rearL", 2.0),
           paxR : aircraft.door.new("instrumentation/doors/paxR", 2.0),
           paxL : aircraft.door.new("instrumentation/doors/paxL", 2.0),
         };
   return obj;
};

Doors.rearRexport = func {
   me.rearR.toggle();
}
Doors.rearLexport = func {
   me.rearL.toggle();
}
Doors.frontRexport = func {
   me.frontR.toggle();
}
Doors.frontLexport = func {
   me.frontL.toggle();
}
Doors.paxRexport = func {
   me.paxR.toggle();
}
Doors.paxLexport = func {
   me.paxL.toggle();
}

# ==============
# Initialization
# ==============

# objects must be here, otherwise local to init()
doorsystem = Doors.new();

