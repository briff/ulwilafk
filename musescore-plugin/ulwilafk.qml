import QtQuick 2.0
import MuseScore 1.0
import QtQuick.Controls 1.3

MuseScore {
    
    property variant fullXOffset : -1.8;
    property variant fullYOffset : 2.9;
    property variant fullFontSize : 36;
    property variant fullNoteSignSize : 5.5;
    
    property variant smallXOffset : -0.9;
    property variant smallYOffset : 0;
    property variant smallFontSize : 18;
    property variant smallNoteSignSize : 2.75;
    
    // offset when I want to put a sharp note to an other
    property variant halfWidthOffset : 0.47;
    property variant quarterWidthOffset : 0.2;
    
    // offset when I overlap one note on the other
    property variant overlapOffset : 0.67;
    
    property variant defaultXOffset;
    property variant defaultYOffset;
    property variant noteTemplate;
    property variant noteSignSize;
    property variant fontSize;
    
    property variant lastProcessedMeasure: 0;
    
    menuPath:    "Plugins.UlwilaFK"
    version:     "1.0"
    description: qsTr("Create ulwila color sheet")
    pluginType: "dialog"
    
    width:  400
    height: 200
    onRun: {
        if (typeof curScore === 'undefined')
            Qt.quit();
        var score = curScore
        console.log(score.name)
    }
    
    function setVisibility(visible) {
        var startStaff;
        var endStaff;
        var endTick;
        var fullScore;        
        var cursor = curScore.newCursor();        
        cursor.rewind(1);
        if (!cursor.segment) {
            fullScore = true;
            for (var track = 0; track < curScore.ntracks; ++track) {
                var segment = curScore.firstSegment();
                while (segment) {
                    var element = segment.elementAt(track);
                    setElementVisibility(element, visible);
                    segment = segment.next;
                }
            }             
        } else {
            console.log("Processing selection");
            startStaff = cursor.staffIdx;
            cursor.rewind(2);
            if (cursor.tick == 0) {
                endTick = curScore.lastSegment.tick + 1;
            } else {
                endTick = cursor.tick;
            }
            endStaff = cursor.staffIdx;            
            
            for (var staff = startStaff; staff <= endStaff; staff++) {
                cursor.rewind(1);
                cursor.voice = 0;
                cursor.staffIdx = staff;
                if (fullScore) cursor.rewind(0); // beginning of score
                
                while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                    var element = cursor.element;
                    setElementVisibility(element, visible);
                    cursor.next();
                }
            }
        }
    }
    
    function setElementVisibility(element, visible) {
        if (element) {
            element.visible = visible;
            if (element.stem) { element.stem.visible = visible; }
            if (element.beam) { element.beam.visible = visible; }
            if (element.hook) { element.hook.visible = visible; }
            if (element.accidental) { element.accidental.visible = visible; }
            if (element.dots) {
                var note = element;
                for (var i = 0; i < note.dots.length; i++) {
                    if (note.dots[i]) {
                        note.dots[i].visible = visible;
                    }
                }
            }
            if (element.type == Element.CHORD) {
                for (var noteIndex = 0; noteIndex < element.notes.length; noteIndex++) {
                    var note = element.notes[noteIndex];
                    note.visible = visible;
                }
            }
        }
    }
    
    function toUlwila() {
        if (!chkAboveStaff.checked) {
            defaultXOffset = fullXOffset;
            defaultYOffset = fullYOffset;
            noteSignSize = fullNoteSignSize;
            fontSize = fullFontSize;        
        } else {
            defaultXOffset = smallXOffset;
            defaultYOffset = smallYOffset;
            noteSignSize = smallNoteSignSize;
            fontSize = smallFontSize;        
        }
            noteTemplate = "<font size=\""+fontSize+"\"/><font face=\"UlwilaFK\"/>";        
        console.log("Convert to Ulwila");
        if (typeof curScore === 'undefined')
            return;
        var startStaff;
        var endStaff;
        var endTick;
        var fullScore;
        var cursor = curScore.newCursor();        
        cursor.rewind(1);
        if (!cursor.segment) { // no selection
            fullScore = true;
            startStaff = 0; // start with 1st staff
            endStaff = curScore.nstaves - 1; // and end with last
        } else {
            console.log("Processing selection");
            startStaff = cursor.staffIdx;
            cursor.rewind(2);
            if (cursor.tick == 0) {
                endTick = curScore.lastSegment.tick + 1;
            } else {
                endTick = cursor.tick;
            }
            endStaff = cursor.staffIdx;            
        }
        curScore.startCmd();
        for (var staff = startStaff; staff <= endStaff; staff++) {
            cursor.rewind(1);
            cursor.voice = 0;
            cursor.staffIdx = staff;
            if (fullScore) cursor.rewind(0); // beginning of score
            while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                if (cursor.element && (cursor.element.type == Element.CHORD || cursor.element.type == Element.REST)) {
                    addColorNote(cursor);
                }
                cursor.next();
            }
        }
        setVisibility(false);
        curScore.endCmd();
        Qt.quit();
    }
    
    function getColor(pitch) {
        var color = "#000000";
        if (pitch % 12 == 2) color = "brown";
        else if (pitch % 12 == 4) color = "blue";
        else if (pitch % 12 == 5) color = "green";
        else if (pitch % 12 == 7) color = "red";
        else if (pitch % 12 == 9) color = "orange";
        else if (pitch % 12 == 11) color = "yellow";
        return color;
    }
    
    function getDurationSign(pitch, duration, isRest, isMirrored) {
        var durationSign;
        if (!isRest) {
            if (pitch == 60-12) {
                if (duration == 480/2) { durationSign = isMirrored ? "N" : "M"; }
                else if (duration == 480/4) { durationSign = "C"; }
                else { durationSign = "H"; }
            } else if (pitch == 60+12) {
                if (duration == 480/2) { durationSign = isMirrored ? "L" : "K"; }
                else if (duration == 480/4) { durationSign = "C"; }
                else { durationSign = "G"; }
            }
            else if (pitch == 60+12+12) {
                if (duration == 480/2) { durationSign = isMirrored ? "P" : "O"; }
                else if (duration == 480/4) { durationSign = "C"; }
                else { durationSign = "I"; }
            } else {
                if (duration == 480/2) durationSign = isMirrored ? "J" : "B";
                else if (duration == 480/4) durationSign = "C";
                else durationSign = "A";
            }
        } else {
            var temp = duration;
            var durationSign = "";
            while (temp > 0) {
                if (temp >= 480) { durationSign += "D"; temp -= 480; }
                else if (temp >= 240) { durationSign += "E"; temp -= 240; }
                else if (temp >= 120) { durationSign += "F"; temp -= 120; }
                else { temp = 0; }
            }
        }
        return durationSign;
    }
    
    function createSharpNote(lowerPitch, duration, cursor, chordNoteOffset) {
        var currentOffset = 0;
        if (duration % 480 == 0) {
            for (var i = 0; i<duration; i+=480) {
                drawNotePart(lowerPitch, 240, cursor, currentOffset, false, chordNoteOffset);
                currentOffset += noteSignSize * halfWidthOffset;
                drawNotePart(lowerPitch+2, 240, cursor, currentOffset, true, chordNoteOffset);
                currentOffset += noteSignSize * halfWidthOffset * overlapOffset;                              
            }
        } else if (duration == 240) {
            var octaveSign = addOctaveSign(lowerPitch+2, duration, cursor);
            if (octaveSign) {
                octaveSign.pos.x = defaultXOffset + currentOffset;
                octaveSign.pos.y = defaultYOffset;
            }
            var noteSign = createSingleNoteSign(lowerPitch, duration/2, cursor, false, "V");
            noteSign.pos.x = defaultXOffset + currentOffset;
            noteSign.pos.y = defaultYOffset;
            currentOffset += noteSignSize*0.35;
            noteSign = createSingleNoteSign(lowerPitch + 2, duration/2, cursor, false, "W");
            noteSign.pos.x = defaultXOffset + currentOffset;
            noteSign.pos.y = defaultYOffset;
        }
    }
    
    function drawNotePart(pitch, duration, cursor, currentOffset, mirror, chordNoteOffset) {
        var octaveSign = addOctaveSign(pitch, duration, cursor, mirror);
        if (octaveSign) {
            if (duration != 120) {
                octaveSign.pos.x = defaultXOffset + currentOffset;
                octaveSign.pos.y = defaultYOffset + chordNoteOffset * noteSignSize / 2.0;
            } else {
                octaveSign.pos.x = defaultXOffset + currentOffset - noteSignSize / 4;
                octaveSign.pos.y = defaultYOffset + chordNoteOffset * noteSignSize / 2.0 + noteSignSize / 6;
            }
        }
        var contour = addContour(duration, cursor, currentOffset);
        contour.pos.x = defaultXOffset + currentOffset;
        contour.pos.y = defaultYOffset + chordNoteOffset;                
        var noteSign = createSingleNoteSign(pitch, duration, cursor, mirror);
        noteSign.pos.x = defaultXOffset + currentOffset;
        noteSign.pos.y = defaultYOffset + chordNoteOffset * noteSignSize / 2.0;
        return noteSign;
    }
    
    function addContour(duration, cursor) {
        var text = newElement(Element.STAFF_TEXT);
        var sign;
        switch (duration) {
        case 240: sign = "R"; break;
        case 120: sign = "F"; break;
        default: sign = "Q";
        }
        text.text = "<font size=\""+fontSize+"\"/><font face=\"UlwilaFK\"/>" + sign;
        cursor.add(text);
        return text;
    }
    
    function createSingleNote(pitch, duration, cursor, chordNoteOffset) {
        var noteSign;
        var currentOffset = 0;
        var noOf16th = Math.floor(((duration % 480) % 240) / 120);
        var noOf8th = Math.floor((duration % 480) / 240);
        var noOf4th = Math.floor(duration / 480);
        var currentOffset = noOf4th > 0 ? noOf4th * noteSignSize*overlapOffset : 0;
        currentOffset += noOf8th > 0 ? (noOf8th) * noteSignSize * halfWidthOffset : 0;
        currentOffset += noOf16th > 0 ? (noOf16th) * noteSignSize * quarterWidthOffset * 1.1 : 0;
        if (duration > 120 && duration < 480) {
            currentOffset += noteSignSize / 8;
        } else if (duration == 120) {
            currentOffset += noteSignSize / 4;
        }
        for (var i = 0; i < noOf16th; i++) {
            currentOffset -= noteSignSize * quarterWidthOffset; noteSign = drawNotePart(pitch, 120, cursor, currentOffset, false, chordNoteOffset);
            currentOffset -= noteSignSize * quarterWidthOffset / 2;
        }        
        for (var i = 0; i < noOf8th; i++) {
            currentOffset -= noteSignSize * halfWidthOffset; noteSign = drawNotePart(pitch, 240, cursor, currentOffset, false, chordNoteOffset); 
        }
        for (var i = 0; i < noOf4th; i++) {
            currentOffset -= noteSignSize * overlapOffset; noteSign = drawNotePart(pitch, 480, cursor, currentOffset, false, chordNoteOffset);
        }

        return noteSign;
    }
    
    function createSingleNoteSign(pitch, duration, cursor, mirror, overrideSign) {
        var text = newElement(Element.STAFF_TEXT);
        var durationSign = overrideSign ? overrideSign : getDurationSign(pitch, duration, false, mirror);
        text.color = getColor(pitch);
        text.text = noteTemplate + durationSign;
        cursor.add(text);
        return text;
    }
    
    function addOctaveSign(pitch, duration, cursor, mirror) {
        if (pitch == 48 || pitch == 84) return; // no octave sign for Cs
        var text;
        var middleC = 60;
        var octave = (pitch - middleC + 48) / 12 | 0;
        if (octave != 4) {
            var durationSign;
            if (duration >= 480 || duration == 120) durationSign = ".";
            else if (duration == 240) durationSign = mirror ? "/" : "-";
            text = newElement(Element.STAFF_TEXT);
            text.text = "<font size=\""+ ( duration == 120 ? Math.floor(fontSize * 0.7) : fontSize )+"\"/><font face=\"UlwilaFK\"/>" + durationSign;
            if (octave == 3) {
                text.color = "black";
            } else if (octave == 5) {
                text.color = "white";
            }
            cursor.add(text);
        }
        return text;
    }
    
    function createRest(cursor) {
        var element = cursor.element;
        var text = newElement(Element.STAFF_TEXT);
        var noteTemplate = "<font size=\""+fontSize+"\"/><font face=\"UlwilaFK\"/>";
        var durationSign = getDurationSign(null, element.durationType, true);
        text.text = noteTemplate + durationSign;
        text.pos.x = defaultXOffset;
        text.pos.y = defaultYOffset;
        cursor.add(text);
    }
    
    function addTriangle(cursor, triangleOffset) {
        var text = newElement(Element.STAFF_TEXT);
        text.text = noteTemplate + "&lt;";
        text.pos.x = -0.35*noteSignSize;
        text.pos.y = defaultYOffset - noteSignSize / 2.0 + triangleOffset * noteSignSize / 2.0;
        cursor.add(text);
    }
    
    function isSharp(pitch) {
        return pitch % 12 == 1 || pitch % 12 == 3 || pitch % 12 == 6 || pitch % 12 == 8 || pitch % 12 == 10;
    }
    
    function addColorNote(cursor) {
        var element = cursor.element;
        var triangleOffset = 0;
        if (element.type == Element.CHORD) {
            for (var noteIndex = 0; noteIndex<element.notes.length; noteIndex++) { 
                var note = element.notes[noteIndex];
                if (isSharp(note.pitch)) {
                    createSharpNote(note.pitch-1, element.durationType, cursor, getChordNoteOffset(noteIndex, element.notes.length));
                } else {
                    createSingleNote(note.pitch, element.durationType, cursor, getChordNoteOffset(noteIndex, element.notes.length));
                }
                note.visible = false;
            }
            triangleOffset = getChordNoteOffset(0, element.notes.length); 
        } else if (element.type == Element.REST) {
            createRest(cursor);
        }
        if (cursor.measure && lastProcessedMeasure != cursor.measure) {
            lastProcessedMeasure = cursor.measure;
            addTriangle(cursor, triangleOffset);
        }
    }
    
    function getChordNoteOffset(noteIndex, noteCount) {
        switch (noteCount) {
        case 2:
            return noteIndex == 0 ? -1 : 1;
        case 3:
            if (noteIndex == 0) { return -2; }
            if (noteIndex == 1) { return 0; }
            if (noteIndex == 2) { return 2; }
        case 4:
            if (noteIndex == 0) { return -3; }
            if (noteIndex == 1) { return -1; }
            if (noteIndex == 2) { return 1; }
            if (noteIndex == 3) { return 3; }
        default:
            return 0;
        }
    }
    
    Item {
        
        id: buttons
        
        Button {
            id: btnUlwila
            text: "Ulwila"
            onClicked: { toUlwila(); }
        }
        
        CheckBox {
            id: chkAboveStaff
            anchors.left: btnUlwila.right
            checked: false
            text: "Above staff"
        }
        
        Button {
            id: btnOriginal
            anchors.left: chkAboveStaff.right
            text: "Everything visible"
            onClicked: { 
                curScore.startCmd();
                setVisibility(true);
                curScore.endCmd();
                Qt.quit();        
            }
        }
        
        
        
        Button {
            id: btnClose
            anchors.left: btnOriginal.right
            text: "Close"
            onClicked: { Qt.quit(); }
        }
        
    }
    
}

// :noTabs=true:maxLineLen=150:mode=javascript:folding=indent: