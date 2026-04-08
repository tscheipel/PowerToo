import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

import PowerTooConstants;
import PowerTooSettings;
import PowerTooZones;
import PowerTooRenderer;



class PowerTooView extends WatchUi.DataField {

    //==================== Power Metrics ====================
    hidden var currentPower as Numeric;                    // Current power value
    hidden var averagePower as Numeric;                    // Average power over session
    hidden var maxPower as Numeric;                        // Maximum power recorded
    hidden var nSecondPower as Numeric;                    // n-second rolling average power
    hidden var lapPower as Numeric;                        // Current lap average power
    hidden var normalizedPower as Numeric;                 // Normalized power metric

    //==================== Power Zone Data ====================
    hidden var currentPowerZone as Numeric;               // Current power zone (1-7)
    hidden var powerZoneDecimal as Numeric;                // Fractional portion of power zone
    hidden var powerArray as Array<Float> = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];        // Zone histogram counts
    hidden var normalizedPowerArray as Array<Float> = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];  // Normalized zone percentages
    hidden var powerZoneThreshold as Array<Number> = [110,150,180,210,240,300];  // Zone threshold watts
    hidden var powerZoneColor as Array<Number>;           // Zone color definitions array

    //==================== Power Calculation ====================
    hidden var arrPower as Array<Numeric> or Null;       // Rolling window for n-second average (30 elements)
    hidden var normalizedPowerCounter as Numeric;          // Counter for exponential power averaging
    hidden var previousNormalizedPower as Numeric;         // Previous normalized power value

    //==================== Layout & Display Configuration ====================
    hidden var locationCoordinates as Array<Numeric>;     // Device-specific coordinate array from PowerTooLayout
    hidden var fontDefinitions as Array<FontDefinition>;   // Device-specific font definitions
    hidden var width as Numeric;                          // Screen field width in pixels
    hidden var height as Numeric;                          // Screen field height in pixels
    hidden var fontHeight as Numeric;                      // Number font height (Edge 1040 detection)

    //==================== User Settings & Preferences ====================
    hidden var FTP as Numeric = 200;                      // Functional Threshold Power (watts)
    hidden var nSecondInterval as Numeric = 3;             // n-second averaging interval (3-30 seconds)
    hidden var averageMode as Numeric = 0;                // Average display mode selection
    hidden var powerMode as Numeric = 0;                  // Power display mode selection
    hidden var personalPower as Numeric = 200;            // Personal power reference value
    hidden var threshold as Numeric = 0;                  // Display threshold percentage
    hidden var manualPowerZone as Boolean = false;        // Manual power zone definition enabled
    hidden var calcPowerZone as Boolean = false;          // Calculated power zone toggle
    hidden var calcTypePZ as Numeric = 1;                 // Power zone calculation type
    hidden var preferredSmallFont as Boolean = false;     // User's font size preference (persisted)
    hidden var showPowerZoneBar as Boolean = true;        // Show power zone bar in display
    hidden var showPowerZoneHistory as Boolean = false;   // Show power zone history grid
    hidden var drawCurrentZone as Boolean = true;         // Highlight current zone indicator
    hidden var drawLabels as Boolean = true;              // Show metric labels

    //==================== Display State ====================
    hidden var smallFont as Boolean = false;              // Current font size toggle
    hidden var normalizeOn = false as Boolean;             // Histogram normalization toggle
    hidden var workoutState = 0 as Numeric;               // Current workout type state
    hidden var zoneLabelOffsetX = 0 as Numeric;           // Zone label X position offset
    hidden var powerZoneBarHeight as Numeric = 0;         // Calculated power zone bar height
    hidden var powerZoneIndexHeight as Numeric = 0;       // Power zone index height

    //==================== Lap Tracking ====================
    hidden var lapCount as Numeric;                        // Number of laps completed
    hidden var lastLapPower as Numeric;                    // Last lap's average power

    //==================== Resources & Labels ====================
    hidden var labelAvg;                                  // "Avg" label from resources
    hidden var labelPersonal;                             // "Personal" label from resources
    hidden var metric;                                    // Unit label from resources
    hidden var modeShortTermPower as Array<String> = new [4] as Array<String>;  // Display mode labels
    hidden var modeAveragePower as Array<String> = new [7] as Array<String>;    // Average mode labels

    //==================== Time Tracking ====================
    hidden var elapsedTimeSeconds = 0 as Numeric;         // Elapsed time counter in seconds


    function initialize() {
        DataField.initialize();

        currentPower = 0;
        averagePower = 0;
        maxPower = 0;
        nSecondPower = 0.0f;
        lapPower = 0.0f;
        normalizedPower = 0.0f;
        currentPowerZone = 1;
        powerZoneDecimal = 0.0f;
        normalizedPowerCounter = 0;
        previousNormalizedPower = 0.0f;
        locationCoordinates = [140, 2, 100,38, 78,38, 136,25, 138,17, 104,56, 82,56, 6, 14];
        fontDefinitions = [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_TINY];
        width = 140;
        height = 92;
        fontHeight = 47;
        arrPower = null;
        powerArray = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];
        normalizedPowerArray = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];

        powerZoneColor = PowerTooZones.initializeZoneColors();

        lapCount = 0;
        lastLapPower = 0.0f;

        labelAvg = loadResource(Rez.Strings.labelAvg);
        labelPersonal = loadResource(Rez.Strings.labelPersonal);
        metric = loadResource(Rez.Strings.metric);

        smallFont = false;

        initProperties();

        readModeShortTermPower();
        readModeAveragePower();
    }
    
    function initProperties() {
        var displaySettings = {} as Dictionary;
        var powerSettings = {} as Dictionary;
        var zoneThresholds = new Array<Number>[6];

        PowerTooSettings.loadAll(displaySettings, powerSettings, zoneThresholds);

        // Apply display settings
        preferredSmallFont = displaySettings[:preferredSmallFont] as Boolean;
        smallFont = preferredSmallFont;
        showPowerZoneBar = displaySettings[:showPowerZoneBar] as Boolean;
        powerZoneBarHeight = displaySettings[:powerZoneBarHeight] as Numeric;
        powerZoneIndexHeight = displaySettings[:powerZoneIndexHeight] as Numeric;
        showPowerZoneHistory = displaySettings[:showPowerZoneHistory] as Boolean;
        drawLabels = displaySettings[:drawLabels] as Boolean;
        drawCurrentZone = displaySettings[:drawCurrentZone] as Boolean;
        nSecondInterval = displaySettings[:nSecondInterval] as Numeric;
        powerMode = displaySettings[:powerMode] as Numeric;

        // Apply power settings
        FTP = powerSettings[:FTP] as Numeric;
        averageMode = powerSettings[:averageMode] as Numeric;
        personalPower = powerSettings[:personalPower] as Numeric;
        threshold = powerSettings[:threshold] as Numeric;
        manualPowerZone = powerSettings[:manualPowerZone] as Boolean;
        calcPowerZone = powerSettings[:calcPowerZone] as Boolean;
        calcTypePZ = powerSettings[:calcTypePZ] as Numeric;

        // Apply calculated zone thresholds
        for (var i = 0; i < 6; i++) {
            powerZoneThreshold[i] = zoneThresholds[i];
        }
    }
    
    function onLayout(dc as Dc) as Void {
        width = dc.getWidth();
        fontHeight = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM);
        height = dc.getHeight();
        getLocationCoordinates();

        // Large font is only allowed in full-width fields.
        var isFullWidth = width > locationCoordinates[0];
        smallFont = isFullWidth ? preferredSmallFont : true;

        if (smallFont) {
            zoneLabelOffsetX = dc.getTextWidthInPixels("Z1", fontDefinitions[2]) * 0.5;
        } else {
            zoneLabelOffsetX = dc.getTextWidthInPixels("Z1", fontDefinitions[1]) * 0.5;
        }
    }

    function getLocationCoordinates() as Void {
        var layoutConfig = PowerTooLayout.resolve(width, height, fontHeight);
        locationCoordinates = layoutConfig[:coordinates] as Array<Numeric>;
        fontDefinitions = layoutConfig[:fontDefinitions] as Array<FontDefinition>;

        //! ==================== Dynamic Offset Adjustments ====================
        //! Adjust coordinates based on power zone bar visibility and label display settings
        //! These adjustments compensate for reserved space allocation
        
        var labelAdjustmentOffset = 10;  // Pixels to adjust when labels are disabled
        var zoneBarMargin = locationCoordinates[PowerTooConstants.INDEX_ZONE_MARGIN];
        
        // Reduce title Y when zone bar is visible
        locationCoordinates[PowerTooConstants.INDEX_TITLE_Y] -= 
            (zoneBarMargin + (drawLabels ? 0 : labelAdjustmentOffset));
        
        // Reduce primary power Y when zone bar is visible
        locationCoordinates[PowerTooConstants.INDEX_PRIMARY_POWER_Y] -= 
            (zoneBarMargin + (drawLabels ? 0 : labelAdjustmentOffset));
        
        // Reduce secondary power Y when zone bar is visible
        locationCoordinates[PowerTooConstants.INDEX_SECONDARY_POWER_Y] -= 
            (zoneBarMargin + (drawLabels ? 0 : labelAdjustmentOffset));
        
        // Reduce primary metric Y when labels are disabled
        locationCoordinates[PowerTooConstants.INDEX_PRIMARY_METRIC_Y] -= 
            (drawLabels ? 0 : labelAdjustmentOffset);
        
        // Reduce reserved position Y when zone bar is visible
        locationCoordinates[PowerTooConstants.INDEX_RESERVED_Y] -= 
            (zoneBarMargin + (drawLabels ? 0 : labelAdjustmentOffset));
        
        // Reduce secondary metric Y when labels are disabled
        locationCoordinates[PowerTooConstants.INDEX_SECONDARY_METRIC_Y] -= 
            (drawLabels ? 0 : labelAdjustmentOffset);

        //! ==================== Wide Display Adjustments ====================
        //! For larger displays (> 150px width), shift main power display to the right
        if (width > 150) {
            locationCoordinates[PowerTooConstants.INDEX_PRIMARY_POWER_X] += 20;
            locationCoordinates[PowerTooConstants.INDEX_PRIMARY_METRIC_X] += 20;
        }
    }

    function compute(info as Activity.Info) as Void {
        var elapsed;
        if (info has :elapsedTime) {
            elapsed = info.elapsedTime;
            if (elapsed != null) {
                elapsedTimeSeconds = elapsed / 1000;
            }
        }

        var currentPowerValue;
        if (info has :currentPower) {
            currentPowerValue = info.currentPower;
            if (currentPowerValue != null) {
                currentPower = currentPowerValue;
            } else {
                currentPower = 0;
                return;
            }
        } else {
            currentPower = 0;
            return;
        }

        computePowers(info as Activity.Info, currentPower);

        if (currentPower != null && currentPower != 0) {
            computePowerZone(nSecondPower);
        } else {
            currentPowerZone = 1;
            powerZoneDecimal = 0.0f;
        }

        lapCount++;

        if (info.timerState == 0) {
            return;
        }

        if (showPowerZoneHistory) {
            if (currentPowerZone >= 1 && currentPowerZone <= 7) {
                if (currentPower > 0) {
                    var powerCount = powerArray[currentPowerZone-1];
                    powerCount++;
                    powerArray[currentPowerZone-1] = powerCount;
                } else {
                    return;
                }
                if (!normalizeOn) {
                    if (powerArray[currentPowerZone-1] > locationCoordinates[15]) {
                        normalizeOn = true;
                    }
                }
            } else {
                return;
            }
        }
    }  

    function onTimerLap() {
        lapCount = 0;
        lastLapPower = 0.0f;
    }

    function computePowers(info as Activity.Info, currentPowerValue as Numeric) as Void {
        // n-second average power calculation
        // Power is stored in 30-element array
        if (info has :timerState && info.timerState == 0) {
            arrPower = null;
            normalizedPowerCounter = 0;
            previousNormalizedPower = 0.0f;
            return;
        }

        var slicedPowerArray = null;
        var arraySize = 0;
        var normalizedPowerValue = null;

        // Initialize or update 1-second power array (30 elements)
        if (arrPower == null) {
            arrPower = [currentPower];
            arraySize = 1;
            normalizedPowerValue = null;
        } else {
            arraySize = arrPower.size();
            if (arraySize < 30) {
                arrPower.add(currentPower);
                normalizedPowerValue = null;
            } else {
                arrPower = PowerTooMath.pushWindow(arrPower, currentPower);
                normalizedPowerValue = PowerTooMath.mean(arrPower);
            }
        }

        // Calculate n-second average based on selected interval
        switch(nSecondInterval) {
            case 1:
                nSecondPower = currentPower.toFloat();
                break;
            case 10:
                if (arraySize <= 10) {
                    nSecondPower = PowerTooMath.mean(arrPower);
                } else {
                    slicedPowerArray = arrPower.slice(-10, null);
                    nSecondPower = PowerTooMath.mean(slicedPowerArray);
                }
                break;
            case 30:
                if (normalizedPowerValue != null) {
                    nSecondPower = normalizedPowerValue;
                } else {
                    nSecondPower = PowerTooMath.mean(arrPower);
                }
                break;
            default:
                if (arraySize <= 3) {
                    nSecondPower = PowerTooMath.mean(arrPower);
                } else {
                    slicedPowerArray = arrPower.slice(-3, null);
                    nSecondPower = PowerTooMath.mean(slicedPowerArray);
                }
        }
        slicedPowerArray = null;

        // Calculate average metrics based on selected mode
        switch(averageMode) {
            // Average Power
            case 0:
                if (info has :averagePower && info.averagePower != null) {
                    averagePower = info.averagePower;
                } else {
                    averagePower = 0;
                }
                break;
            // Maximum Power
            case 1:
                if (info has :maxPower && info.maxPower != null) {
                    maxPower = info.maxPower;
                } else {
                    maxPower = 0;
                }
                break;
            // Lap Power and Lap/NP
            case 3:
            case 6:
                var previousNormalized = 0.0f;
                var currentNormalized = 0.0f;
                if (lapCount > 1) {
                    previousNormalized = (lapCount - 1.0) / lapCount;
                    currentNormalized = 1.0 / lapCount;
                    lapPower = previousNormalized * lastLapPower + currentNormalized * currentPower;
                    lastLapPower = lapPower.toNumber();
                } else {
                    lapPower = currentPower;
                    lastLapPower = currentPower;
                }
                break;
            // Average and Maximum Power
            case 4:
                if (info has :averagePower && info.averagePower != null) {
                    averagePower = info.averagePower;
                } else {
                    averagePower = 0;
                }
                if (info has :maxPower && info.maxPower != null) {
                    maxPower = info.maxPower;
                } else {
                    maxPower = 0;
                }
                break;
            // Average and Normalized Power
            case 5:
                if (info has :averagePower && info.averagePower != null) {
                    averagePower = info.averagePower;
                } else {
                    averagePower = 0;
                }
                break;
            default:
                break;
        }

        // Calculate normalized power
        if (arraySize < 30) {
            normalizedPower = 0;
        } else {
            normalizedPower = PowerTooMath.updateNormalizedPowerMean(
                previousNormalizedPower,
                normalizedPowerCounter,
                normalizedPowerValue
            ).toNumber();
            previousNormalizedPower = normalizedPower;
            normalizedPowerCounter++;
        }
    }

    function clearCanvas(dc as Dc) as Void {
        var backgroundColor = getBackgroundColor();
        var textColor = backgroundColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(textColor, backgroundColor);
        dc.clear();
    }

    function onUpdate(dc as Dc) as Void {
        clearCanvas(dc);
        var colors = {
            :background => -1,
            :color => null,
            :pwr_color => null,
            :indication => PowerTooConstants.INDICATE_NORMAL
        };

        var backgroundColor = getBackgroundColor();
        var backgroundIsBlack = backgroundColor == Graphics.COLOR_BLACK;
        var defaultColor = backgroundIsBlack ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        colors[:pwr_color] = defaultColor;
        colors[:color] = defaultColor;

        dc.setColor(colors[:color], colors[:background]);
        dc.clear();

        drawPowerZones(dc, colors);
        drawPowerData(dc, colors);

        width = dc.getWidth();
        var fullWidth = width > locationCoordinates[0];

        if (!fullWidth) {
            return;
        }

        drawPowerSymbol(dc, 0, 8, Graphics.COLOR_YELLOW);
    }

    function getComparablePower() as Number {
        switch (averageMode) {
            case 0:
                return averagePower;
            case 1:
                return maxPower;
            case 2:
                return normalizedPower;
            case 3:
                return lapPower;
            default:
                return 0;
        }
    }

    function getVariations() as Dictionary {
        var comparablePower = getComparablePower();
        var thresholdDelta = comparablePower * (threshold / 100.0);
        return {
            :min => comparablePower - thresholdDelta,
            :max => comparablePower + thresholdDelta
        };
    }

    function computePowerZone(pwr as Number) as Void {
        var zoneOutput = { :value => 1 } as Dictionary;
        var decimalOutput = { :value => 0.0 } as Dictionary;

        PowerTooZones.calculateZone(pwr, powerZoneThreshold, zoneOutput, decimalOutput);

        currentPowerZone = zoneOutput[:value] as Numeric;
        powerZoneDecimal = decimalOutput[:value] as Numeric;
    }
    function drawPowerZones(dc as Dc, colors as Dictionary) {
        width = dc.getWidth();
        var backgroundColor = getBackgroundColor();
        var maxHeight = powerZoneBarHeight + powerZoneIndexHeight;

        // locationCoordinates[14] is margin to left and right
        var zoneWidth = Math.round((width - locationCoordinates[14] * 2.0) / 7.0);
        var bottomY = dc.getHeight();

        if (showPowerZoneBar) {
            // Draw colored bars for each power zone
            dc.setColor(powerZoneColor[0], -1);
            dc.fillRectangle(locationCoordinates[14], bottomY - maxHeight - (currentPowerZone == 1 ? powerZoneIndexHeight : 0), zoneWidth - 1, maxHeight + (currentPowerZone == 1 ? powerZoneIndexHeight : 0));

            dc.setColor(powerZoneColor[1], -1);
            dc.fillRectangle(locationCoordinates[14] + zoneWidth, bottomY - maxHeight - (currentPowerZone == 2 ? powerZoneIndexHeight : 0), zoneWidth - 1, maxHeight + (currentPowerZone == 2 ? powerZoneIndexHeight : 0));

            dc.setColor(powerZoneColor[2], -1);
            dc.fillRectangle(locationCoordinates[14] + zoneWidth * 2.0, bottomY - maxHeight - (currentPowerZone == 3 ? powerZoneIndexHeight : 0), zoneWidth - 1, maxHeight + (currentPowerZone == 3 ? powerZoneIndexHeight : 0));

            dc.setColor(powerZoneColor[3], -1);
            dc.fillRectangle(locationCoordinates[14] + zoneWidth * 3.0, bottomY - maxHeight - (currentPowerZone == 4 ? powerZoneIndexHeight : 0), zoneWidth - 1, maxHeight + (currentPowerZone == 4 ? powerZoneIndexHeight : 0));

            dc.setColor(powerZoneColor[4], -1);
            dc.fillRectangle(locationCoordinates[14] + zoneWidth * 4.0, bottomY - maxHeight - (currentPowerZone == 5 ? powerZoneIndexHeight : 0), zoneWidth - 1, maxHeight + (currentPowerZone == 5 ? powerZoneIndexHeight : 0));

            dc.setColor(powerZoneColor[5], -1);
            dc.fillRectangle(locationCoordinates[14] + zoneWidth * 5.0, bottomY - maxHeight - (currentPowerZone == 6 ? powerZoneIndexHeight : 0), zoneWidth - 1, maxHeight + (currentPowerZone == 6 ? powerZoneIndexHeight : 0));

            dc.setColor(powerZoneColor[6], -1);
            dc.fillRectangle(locationCoordinates[14] + zoneWidth * 6.0, bottomY - maxHeight - (currentPowerZone == 7 ? powerZoneIndexHeight : 0), zoneWidth - 1, maxHeight + (currentPowerZone == 7 ? powerZoneIndexHeight : 0));
        }

        var verticalCenter = bottomY - maxHeight;

        // Draw power zone history as grid
        if (showPowerZoneHistory) {
            var gridArray = PowerTooMath.normalizeHistogram(
                powerArray,
                locationCoordinates[PowerTooConstants.INDEX_NORMALIZED_GRID_HEIGHT],
                normalizeOn
            );
            for (var zoneIndex = 0; zoneIndex < 7; zoneIndex++) {
                dc.setColor(powerZoneColor[zoneIndex], -1);
                var xPosition = locationCoordinates[14] + zoneWidth * zoneIndex;
                var yPosition;
                for (var gridLineIndex = 0; gridLineIndex < gridArray[zoneIndex]; gridLineIndex++) {
                    yPosition = verticalCenter - (gridLineIndex + 1) * 4;
                    dc.drawLine(xPosition, yPosition, xPosition + zoneWidth - 1, yPosition);
                }
            }
        }

        // Draw current zone indicator arrow
        if (showPowerZoneBar) {
            var centerX = 140;
            var arrowColor = backgroundColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            var arrowHeight = maxHeight;

            if (currentPowerZone == 7 && powerZoneDecimal == 1) {
                centerX = locationCoordinates[14] + zoneWidth * 7;
            } else {
                centerX = locationCoordinates[14] + zoneWidth * (currentPowerZone - 1) + zoneWidth * powerZoneDecimal;
            }

            dc.setColor(backgroundColor, -1);
            dc.fillPolygon([[centerX - 2, verticalCenter + arrowHeight], [centerX - 2, verticalCenter - 10], [centerX + 2, verticalCenter - 10], [centerX + 2, verticalCenter + arrowHeight]]);
            dc.setColor(arrowColor, -1);
            dc.fillPolygon([[centerX - 1, verticalCenter + arrowHeight], [centerX - 1, verticalCenter - 9], [centerX + 1, verticalCenter - 9], [centerX + 1, verticalCenter + arrowHeight]]);
        }
    }
	
    function drawPowerData(dc as Dc, colors as Dictionary) {
        width = dc.getWidth();
        var heightOffset = height * 0.1;
        var zoneColor = PowerTooZones.getZoneColor(currentPowerZone, powerZoneColor);

        // Determine display mode based on dimensions
        var displayMode = PowerTooRenderer.getDisplayMode(width, height, locationCoordinates[0], smallFont, averageMode);

        // Get power and zone display values
        var powerValues = { :data => null } as Dictionary;
        var zoneValues = { :data => null } as Dictionary;
        PowerTooRenderer.getDisplayValues(displayMode, locationCoordinates, fontDefinitions, width, fontHeight, powerValues, zoneValues);

        var powerDisplayValues = powerValues[:data] as Array;
        var zoneDisplayValues = zoneValues[:data] as Array;

        // Draw current power display
        if (nSecondPower != null && nSecondPower >= 0) {
            dc.setColor(colors[:pwr_color], -1);
            dc.drawText((powerDisplayValues[0] as Numeric), (powerDisplayValues[1] as Numeric), powerDisplayValues[2], nSecondPower.format("%d"), Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Draw current power zone indicator
        dc.setColor(zoneColor, colors[:background]);
        if (drawCurrentZone) {
            dc.drawText((zoneDisplayValues[0] as Numeric), (zoneDisplayValues[1] as Numeric) + locationCoordinates[14], zoneDisplayValues[2], "Z" + currentPowerZone.format("%d"), zoneDisplayValues[3]);
        }

        // Build power values for display based on average mode
        var displayedPowerValue = getDisplayedPower(averageMode);
        var displayedPowerValue2 = "";
        var metricLabel1 = "";
        var metricLabel2 = "";
        getAdditionalPowerMetrics(averageMode, displayedPowerValue2, metricLabel1, metricLabel2);

        // Build mode labels
        var shortTermLabel = PowerTooRenderer.getIntervalLabel(nSecondInterval, modeShortTermPower);
        var averageLabel = PowerTooRenderer.getAverageModeLabel(averageMode, modeAveragePower);
        var displayTitle = PowerTooRenderer.buildDisplayTitle(width, displayMode, shortTermLabel, averageLabel);

        // Draw power data and labels
        dc.setColor(colors[:color], colors[:background]);
        drawPowerDataByMode(dc, displayMode, displayedPowerValue, displayedPowerValue2, metricLabel1, metricLabel2, displayTitle, heightOffset);
    }

    //! Extract primary power display value based on average mode
    private function getDisplayedPower(mode as Numeric) as String {
        switch(mode) {
            case 0:   return averagePower.format("%d");
            case 1:   return maxPower.format("%d");
            case 2:   return normalizedPower.format("%d");
            case 3:   return lapPower.format("%d");
            case 4:   return averagePower.format("%d");
            case 5:   return averagePower.format("%d");
            case 6:   return lapPower.format("%d");
            default:  return averagePower.format("%d");
        }
    }

    //! Extract secondary power metrics for dual-value display modes
    private function getAdditionalPowerMetrics(mode as Numeric, outPower2 as String, outLabel1 as String, outLabel2 as String) as Void {
        switch(mode) {
            case 4:  // Average / Maximum
                outPower2 = maxPower.format("%d");
                outLabel1 = modeAveragePower[0];
                outLabel2 = modeAveragePower[1];
                break;
            case 5:  // Average / Normalized
                outPower2 = normalizedPower.format("%d");
                outLabel1 = modeAveragePower[0];
                outLabel2 = modeAveragePower[2];
                break;
            case 6:  // Lap / Normalized
                outPower2 = normalizedPower.format("%d");
                outLabel1 = modeAveragePower[3];
                outLabel2 = modeAveragePower[2];
                break;
        }
    }

    //! Render power data for specific display mode
    private function drawPowerDataByMode(dc as Dc, mode as Numeric, power1 as String, power2 as String, label1 as String, label2 as String, title as String, heightOffset as Numeric) as Void {
        switch(mode) {
            case 0:  // Full width
                drawModeFullWidth(dc, power1, heightOffset, title);
                break;
            case 1:  // Full width x2
                drawModeFullWidthDual(dc, power1, power2, label1, label2, heightOffset, title);
                break;
            case 2:  // Half width big font
                drawModeHalfWidthBig(dc, power1, title);
                break;
            case 3:  // Half width big font x2
                dc.drawText(locationCoordinates[8], locationCoordinates[9], fontDefinitions[1], power1, PowerTooConstants.TEXT_RIGHT_VCENTER);
                dc.drawText(locationCoordinates[8], locationCoordinates[11], fontDefinitions[1], power2, PowerTooConstants.TEXT_RIGHT_VCENTER);
                break;
            case 4:  // Half width small font
                drawModeHalfWidthSmall(dc, power1, title);
                break;
            case 5:  // Half width small font x2
                drawModeHalfWidthSmallDual(dc, power1, power2, title);
                break;
        }
    }

    private function drawModeFullWidth(dc as Dc, power as String, heightOffset as Numeric, title as String) as Void {
        if (drawLabels) {
            dc.drawText(width * 0.5, locationCoordinates[1] + locationCoordinates[14], fontDefinitions[3], title, Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (height > 100) {
            dc.drawText(locationCoordinates[6], locationCoordinates[7] + heightOffset, fontDefinitions[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
            var font = smallFont ? Graphics.FONT_NUMBER_MILD : Graphics.FONT_NUMBER_MEDIUM;
            dc.drawText(locationCoordinates[4], locationCoordinates[5] + heightOffset, font, power, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(locationCoordinates[10], locationCoordinates[7] + heightOffset, fontDefinitions[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(locationCoordinates[10], locationCoordinates[5] + heightOffset, fontDefinitions[3], labelAvg, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(locationCoordinates[6], locationCoordinates[7], fontDefinitions[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
            var font = smallFont ? Graphics.FONT_NUMBER_MILD : Graphics.FONT_NUMBER_MEDIUM;
            dc.drawText(locationCoordinates[4], locationCoordinates[5], font, power, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(locationCoordinates[10], locationCoordinates[7], fontDefinitions[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(locationCoordinates[10], locationCoordinates[11], fontDefinitions[3], labelAvg, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    private function drawModeFullWidthDual(dc as Dc, power1 as String, power2 as String, label1 as String, label2 as String, heightOffset as Numeric, title as String) as Void {
        if (height > 100) {
            if (drawLabels) {
                dc.drawText(width * 0.34, locationCoordinates[1] + locationCoordinates[14], fontDefinitions[3], title, Graphics.TEXT_JUSTIFY_CENTER);
            }
            dc.drawText(locationCoordinates[6], locationCoordinates[7] + heightOffset, fontDefinitions[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(locationCoordinates[8], locationCoordinates[11] + heightOffset, fontDefinitions[0], power1, PowerTooConstants.TEXT_RIGHT_VCENTER);
            dc.drawText(locationCoordinates[8], locationCoordinates[9] + heightOffset, fontDefinitions[0], power2, PowerTooConstants.TEXT_RIGHT_VCENTER);
            dc.drawText(locationCoordinates[10], locationCoordinates[11] + heightOffset, fontDefinitions[3], label1, PowerTooConstants.TEXT_LEFT_VCENTER);
            dc.drawText(locationCoordinates[10], locationCoordinates[9] + heightOffset, fontDefinitions[3], label2, PowerTooConstants.TEXT_LEFT_VCENTER);
        } else {
            if (drawLabels) {
                dc.drawText(width * 0.4, locationCoordinates[1] + locationCoordinates[14], fontDefinitions[3], title, Graphics.TEXT_JUSTIFY_CENTER);
            }
            dc.drawText(locationCoordinates[6], locationCoordinates[7], fontDefinitions[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(locationCoordinates[8], locationCoordinates[11], fontDefinitions[1], power1, PowerTooConstants.TEXT_RIGHT_VCENTER);
            dc.drawText(locationCoordinates[8], locationCoordinates[9], fontDefinitions[1], power2, PowerTooConstants.TEXT_RIGHT_VCENTER);
            dc.drawText(locationCoordinates[10], locationCoordinates[11], fontDefinitions[3], label1, PowerTooConstants.TEXT_LEFT_VCENTER);
            dc.drawText(locationCoordinates[10], locationCoordinates[9], fontDefinitions[3], label2, PowerTooConstants.TEXT_LEFT_VCENTER);
        }
    }

    private function drawModeHalfWidthBig(dc as Dc, power as String, title as String) as Void {
        if (drawLabels) {
            dc.drawText(width * 0.5 + zoneLabelOffsetX, locationCoordinates[1] + locationCoordinates[14], fontDefinitions[3], title, Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.drawText(locationCoordinates[8], locationCoordinates[9], fontDefinitions[1], power, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(locationCoordinates[12], locationCoordinates[11], fontDefinitions[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawModeHalfWidthSmall(dc as Dc, power as String, title as String) as Void {
        if (drawLabels) {
            dc.drawText(width * 0.5 + zoneLabelOffsetX, locationCoordinates[1] + locationCoordinates[14], fontDefinitions[3], title, Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.drawText(locationCoordinates[6], locationCoordinates[7], fontDefinitions[2], power, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(locationCoordinates[10], locationCoordinates[11], fontDefinitions[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawModeHalfWidthSmallDual(dc as Dc, power1 as String, power2 as String, title as String) as Void {
        if (drawLabels) {
            dc.drawText(width * 0.5 + zoneLabelOffsetX, locationCoordinates[1] + locationCoordinates[14], fontDefinitions[3], title, Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.drawText(locationCoordinates[6], locationCoordinates[7], fontDefinitions[2], power1, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(locationCoordinates[6], locationCoordinates[11], fontDefinitions[2], power2, Graphics.TEXT_JUSTIFY_RIGHT);
    }


    function readModeShortTermPower() {
        modeShortTermPower[0] = loadResource(Rez.Strings.modeNone);
        modeShortTermPower[1] = loadResource(Rez.Strings.mode3s);
        modeShortTermPower[2] = loadResource(Rez.Strings.mode10s);
        modeShortTermPower[3] = loadResource(Rez.Strings.mode30s);
    }

    function readModeAveragePower() {
        modeAveragePower[0] = loadResource(Rez.Strings.modeAvg);
        modeAveragePower[1] = loadResource(Rez.Strings.modeMax);
        modeAveragePower[2] = loadResource(Rez.Strings.modeNP);
        modeAveragePower[3] = loadResource(Rez.Strings.modeLap);
        modeAveragePower[4] = loadResource(Rez.Strings.modeAvgMax);
        modeAveragePower[5] = loadResource(Rez.Strings.modeAvgNP);
        modeAveragePower[6] = loadResource(Rez.Strings.modeLapNP);
    }

    function drawPowerSymbol(dc, xOffset, yOffset, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        xOffset = xOffset + 12;
        yOffset = yOffset + 16;

        // Draw upward pointing triangle
        var x1 = xOffset;
        var y1 = yOffset;
        var x2 = xOffset - 7;
        var y2 = yOffset;
        var x3 = xOffset + 1;
        var y3 = yOffset - 8;
        var polyArray = [[x1, y1], [x2, y2], [x3, y3]];
        dc.fillPolygon(polyArray);

        // Draw downward pointing triangle
        x1 = xOffset;
        y1 = yOffset;
        x2 = xOffset + 7;
        y2 = yOffset;
        x3 = xOffset - 1;
        y3 = yOffset + 8;
        polyArray = [[x1, y1], [x2, y2], [x3, y3]];
        dc.fillPolygon(polyArray);
    }
}