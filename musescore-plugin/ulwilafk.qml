import QtQuick 2.0
import MuseScore 1.0
import QtQuick.Controls 1.3

MuseScore {
    
    property variant defaultXOffset : -1.8;
    property variant defaultYOffset : 2.9;
    property variant noteTemplate : "<font size=\"36\"/><font face=\"UlwilaFK\"/>";
    property variant noteSignSize : 5.5;
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
                currentOffset += 2.6;
                drawNotePart(lowerPitch+2, 240, cursor, currentOffset, true, chordNoteOffset);
                currentOffset += 2.6;                              
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
            currentOffset += 1.4;
            noteSign = createSingleNoteSign(lowerPitch + 2, duration/2, cursor, false, "W");
            noteSign.pos.x = defaultXOffset + currentOffset;
            noteSign.pos.y = defaultYOffset;
        }
    }
    
    function drawNotePart(pitch, duration, cursor, currentOffset, mirror, chordNoteOffset) {
        var octaveSign = addOctaveSign(pitch, duration, cursor, mirror);
        if (octaveSign) {
            octaveSign.pos.x = defaultXOffset + currentOffset;
            octaveSign.pos.y = defaultYOffset + chordNoteOffset * noteSignSize / 2.0;
        }
        var noteSign = createSingleNoteSign(pitch, duration, cursor, mirror);
        noteSign.pos.x = defaultXOffset + currentOffset;
        noteSign.pos.y = defaultYOffset + chordNoteOffset * noteSignSize / 2.0;
        if (duration == 120) { noteSign.pos.x = 0.4 + currentOffset; }
        return noteSign;
    }
    
    function createSingleNote(pitch, duration, cursor, chordNoteOffset) {
        var currentOffset = 0;
        var temp = duration;
        var noteSign;
        while (temp>0) {
            if (temp >= 480) { noteSign = drawNotePart(pitch, 480, cursor, currentOffset, false, chordNoteOffset); temp -= 480; currentOffset += 5.2}
            else if (temp >= 240) { noteSign = drawNotePart(pitch, 240, cursor, currentOffset, false, chordNoteOffset); temp -= 240; currentOffset += 2.6}
            else if (temp >= 120) { noteSign = drawNotePart(pitch, 120, cursor, currentOffset, false, chordNoteOffset); temp -= 120;}
            else { temp = 0; }
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
            text.text = "<font size=\"36\"/><font face=\"UlwilaFK\"/>" + durationSign;
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
        var noteTemplate = "<font size=\"36\"/><font face=\"UlwilaFK\"/>";
        var durationSign = getDurationSign(null, element.durationType, true);
        text.text = noteTemplate + durationSign;
        text.pos.x = defaultXOffset;
        text.pos.y = defaultYOffset;
        cursor.add(text);
    }
    
    function addTriangle(cursor, triangleOffset) {
        var text = newElement(Element.STAFF_TEXT);
        text.text = noteTemplate + "&lt;";
        text.pos.x = -1.9;
        text.pos.y = 0 + triangleOffset * noteSignSize / 2.0;
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
        
        Button {
            id: btnOriginal
            anchors.left: btnUlwila.right
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