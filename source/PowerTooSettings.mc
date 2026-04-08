import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;

import PowerTooZoneFormulas;

//! ==================== PowerToo Settings Manager ====================
//! Centralizes all settings loading, initialization, and zone threshold calculation

module PowerTooSettings {

    //! Load all application settings from user properties
    //! @param displaySettings Dictionary to populate with all display-related settings
    //! @param powerSettings Dictionary to populate with all power-related settings
    //! @param zoneThresholds Array to populate with 6 zone threshold values
    function loadAll(displaySettings as Dictionary, powerSettings as Dictionary, zoneThresholds as Array<Number>) as Void {
        if (Toybox.Application has :Properties) {
            // Load display preferences
            displaySettings[:preferredSmallFont] = Application.Properties.getValue("fontSize") == 0;
            displaySettings[:showPowerZoneBar] = Application.Properties.getValue("showPowerZoneBar");
            displaySettings[:powerZoneBarHeight] = Application.Properties.getValue("powerZoneBarHeight");
            displaySettings[:powerZoneIndexHeight] = Application.Properties.getValue("powerZoneIndexHeight");
            displaySettings[:showPowerZoneHistory] = Application.Properties.getValue("showPowerZoneHistory");
            displaySettings[:drawLabels] = Application.Properties.getValue("drawLabels");
            displaySettings[:drawCurrentZone] = Application.Properties.getValue("drawCurrentZone");
            displaySettings[:nSecondInterval] = Application.Properties.getValue("averageSec");
            displaySettings[:powerMode] = Application.Properties.getValue("powerMode");

            // Load power and zone calculation settings
            powerSettings[:FTP] = Application.Properties.getValue("FTP").toFloat();
            powerSettings[:averageMode] = Application.Properties.getValue("averageMode");
            powerSettings[:personalPower] = 200;
            powerSettings[:threshold] = Application.Properties.getValue("threshold");
            powerSettings[:manualPowerZone] = Application.Properties.getValue("manualPowerZone");
            powerSettings[:calcPowerZone] = Application.Properties.getValue("calcPowerZone");
            powerSettings[:calcTypePZ] = Application.Properties.getValue("calcTypePZ");

            // Calculate zone thresholds based on input method
            calculateZoneThresholds(
                powerSettings[:manualPowerZone] as Boolean,
                powerSettings[:calcPowerZone] as Boolean,
                powerSettings[:FTP] as Numeric,
                powerSettings[:calcTypePZ] as Numeric,
                zoneThresholds
            );
        }
    }

    //! Calculate power zone thresholds based on selected calculation method
    //! @param manualPowerZone Whether user manually defined zones
    //! @param calcPowerZone Whether zones should be calculated from FTP
    //! @param FTP User's functional threshold power value
    //! @param calcTypePZ The FTP formula type to use (1, 2, or default)
    //! @param thresholds Array to populate with calculated thresholds
    function calculateZoneThresholds(
        manualPowerZone as Boolean,
        calcPowerZone as Boolean,
        FTP as Numeric,
        calcTypePZ as Numeric,
        thresholds as Array<Number>) as Void {

        if (manualPowerZone) {
            // Load manually defined zone thresholds
            loadManualZoneThresholds(thresholds);
        } else if (calcPowerZone) {
            // Calculate thresholds from FTP using selected formula
            if (FTP == null || FTP == 0) {
                FTP = 200;
            }
            calculateFTPBasedThresholds(FTP, calcTypePZ, thresholds);
        } else {
            // Use default static thresholds
            copyArrayElements(PowerTooZoneFormulas.DEFAULT_ZONE_THRESHOLDS, thresholds);
        }

        // Validate thresholds, use defaults if invalid
        if (thresholds[0] == null || thresholds[0] == 0) {
            copyArrayElements(PowerTooZoneFormulas.DEFAULT_ZONE_THRESHOLDS, thresholds);
        }
    }

    //! Load zone thresholds from user settings
    //! @param thresholds Array to populate with user-defined thresholds
    function loadManualZoneThresholds(thresholds as Array<Number>) as Void {
        if (Toybox.Application has :Properties) {
            thresholds[0] = Application.Properties.getValue("Zone1maxValue");
            thresholds[1] = Application.Properties.getValue("Zone2maxValue");
            thresholds[2] = Application.Properties.getValue("Zone3maxValue");
            thresholds[3] = Application.Properties.getValue("Zone4maxValue");
            thresholds[4] = Application.Properties.getValue("Zone5maxValue");
            thresholds[5] = Application.Properties.getValue("Zone6maxValue");
        } else {
            copyArrayElements(PowerTooZoneFormulas.DEFAULT_ZONE_THRESHOLDS, thresholds);
        }
    }

    //! Calculate zone thresholds using FTP and selected formula
    //! @param FTP User's functional threshold power
    //! @param formulaType The calculation formula to use
    //! @param thresholds Array to populate with calculated thresholds
    function calculateFTPBasedThresholds(FTP as Numeric, formulaType as Numeric, thresholds as Array<Number>) as Void {
        var multipliers = PowerTooZoneFormulas.getMultipliersForFormula(formulaType);
        
        for (var i = 0; i < multipliers.size(); i++) {
            thresholds[i] = Math.floor(FTP * multipliers[i]);
        }
    }

    //! Helper function to copy array elements
    //! @param source Source array
    //! @param destination Destination array to populate
    function copyArrayElements(source as Array, destination as Array) as Void {
        for (var i = 0; i < source.size(); i++) {
            if (i < destination.size()) {
                destination[i] = source[i];
            }
        }
    }

}
