import Toybox.Graphics;
import Toybox.Lang;

//! ==================== PowerToo Zone Manager ====================
//! Handles power zone calculations, color mapping, and zone indexing

module PowerTooZones {

    //! Calculate current power zone and fractional position within zone
    //! @param power Current power value in watts
    //! @param thresholds Array of 6 zone threshold values
    //! @param outZone Output variable for zone number (1-7)
    //! @param outDecimal Output variable for fractional position (0-1)
    function calculateZone(power as Numeric?, thresholds as Array<Number>, outZone as Dictionary, outDecimal as Dictionary) as Void {
        // Initialize with defaults
        outZone[:value] = 1;
        outDecimal[:value] = 0.0;

        if (power == null) {
            return;
        }

        if (power <= thresholds[0]) {
            // Zone 1: Below threshold 0
            outZone[:value] = 1;
            outDecimal[:value] = power / thresholds[0];
        } else if (power > thresholds[5]) {
            // Zone 7: Above threshold 5
            outZone[:value] = 7;
            outDecimal[:value] = (power - thresholds[5]) / (thresholds[5] * 2.0);
            if (outDecimal[:value] > 1) {
                outDecimal[:value] = 1.0;
            }
        } else {
            // Zones 2-6: Find range containing power value
            for (var i = 1; i < 6; i++) {
                if (power > thresholds[i - 1] && power <= thresholds[i]) {
                    outZone[:value] = i + 1;
                    var minZone = thresholds[i - 1].toFloat();
                    var maxZone = thresholds[i].toFloat();
                    outDecimal[:value] = (power.toFloat() - minZone) / (maxZone - minZone);
                    break;
                }
            }
        }
    }

    //! Get color for a specific power zone
    //! @param zone Zone number (1-7)
    //! @param colorArray Array of zone colors
    //! @return Graphic color value for the zone
    function getZoneColor(zone as Numeric, colorArray as Array<Number>) as Number {
        if (zone < 1 || zone > 7 || colorArray.size() < 7) {
            return Graphics.COLOR_LT_GRAY;
        }
        return colorArray[zone - 1] as Number;
    }

    //! Initialize standard power zone color array
    //! Colors index: 0=Zone1(Gray), 1=Zone2(Blue), 2=Zone3(Green), 3=Zone4(Yellow), 4=Zone5(Orange), 5=Zone6(Red), 6=Zone7(Purple)
    //! @return Array of 7 zone colors
    function initializeZoneColors() as Array<Number> {
        return [
            Graphics.COLOR_LT_GRAY,    // Zone 1
            Graphics.COLOR_BLUE,       // Zone 2
            Graphics.COLOR_GREEN,      // Zone 3
            Graphics.COLOR_YELLOW,     // Zone 4
            Graphics.COLOR_ORANGE,     // Zone 5
            Graphics.COLOR_RED,        // Zone 6
            Graphics.COLOR_PURPLE      // Zone 7
        ];
    }

}
