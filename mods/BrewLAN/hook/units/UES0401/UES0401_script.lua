#****************************************************************************
#**
#**  File     :  /cdimage/units/UES0401/UES0401_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  UEF Experimental Submersible Aircraft Carrier Script
#**
#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ATLANTIS = UES0401

UES0401 = Class(ATLANTIS) {
    OnStopBeingBuilt = function(self,builder,layer)
        ATLANTIS.OnStopBeingBuilt(self,builder,layer)

	    IssueDive({self})
    end,
}

TypeClass = UES0401
