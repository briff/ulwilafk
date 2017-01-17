import QtQuick 2.0
import MuseScore 1.0
import QtQuick.Controls 1.3



MuseScore {

    property variant defaultXOffset : -1.8;
    property variant defaultYOffset : 2.9;
    property variant noteTemplate : "<font size=\"36\"/><font face=\"UlwilaFK\"/>";

    menuPath:    "Plugins.ulwila"
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

function toUlwila() {


      console.log("Convert to Ulwila");
      if (typeof curScore === 'undefined')
         return;
      var cursor = curScore.newCursor();
      var startStaff;
      var endStaff;
      var endTick;
      var fullScore = false;
      startStaff = 0; // start with 1st staff
      endStaff  = curScore.nstaves - 1; // and end with last
      curScore.startCmd();
      for (var staff = startStaff; staff <= endStaff; staff++) {
            console.log("Processing staff " + staff);
            cursor.voice    = 0;
            cursor.staffIdx = staff;
            cursor.rewind(0); // beginning of score
            while (cursor.segment) {
               if (cursor.element && (cursor.element.type == Element.CHORD ||
                        cursor.element.type == Element.REST)) {
                  addColorNote(cursor);
               }
               cursor.element.visible = false;
               cursor.next();

            }
      }
      curScore.endCmd();
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
                  else { durationSign = "H"; }
            }
            else if (pitch == 60+12+12) {
                  if (duration == 480/2) { durationSign = isMirrored ? "P" : "O"; }
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

function createSharpNote(lowerPitch, duration, cursor) {
      var currentOffset = 0;
      if (duration % 480 == 0) {
            for (var i = 0; i<duration; i+=480) {
                  drawNotePart(lowerPitch, 240, cursor, currentOffset);
                  currentOffset += 2.7;
                  drawNotePart(lowerPitch+2, 240, cursor, currentOffset, true);
                  currentOffset += 2.7;                              
            }
      } else if (duration == 240) {
            drawNotePart(lowerPitch, duration/2, cursor, currentOffset);
            currentOffset += 0.9;
            drawNotePart(lowerPitch+2, duration/2, cursor, currentOffset);
      }
}

function drawNotePart(pitch, duration, cursor, currentOffset, mirror) {
      var octaveSign = addOctaveSign(pitch, duration, cursor);
      if (octaveSign) {
            octaveSign.pos.x = defaultXOffset + currentOffset;
            octaveSign.pos.y = defaultYOffset;
      }
      var noteSign = createSingleNoteSign(pitch, duration, cursor, mirror);
      noteSign.pos.x = defaultXOffset + currentOffset;
      noteSign.pos.y = defaultYOffset;
      if (duration == 120) { noteSign.pos.x = 0.4 + currentOffset; }
      return noteSign;
}

function createSingleNote(pitch, duration, cursor, mirror) {
      var currentOffset = 0;
      var temp = duration;
      var noteSign;
      while (temp>0) {
            if (temp >= 480) { noteSign = drawNotePart(pitch, 480, cursor, currentOffset); temp -= 480; currentOffset += 5.2}
            else if (temp >= 240) { noteSign = drawNotePart(pitch, 240, cursor, currentOffset, mirror); temp -= 240; currentOffset += 2.6}
            else if (temp >= 120) { noteSign = drawNotePart(pitch, 120, cursor, currentOffset); temp -= 120;}
            else { temp = 0; }
      }
      return noteSign;
}

function createSingleNoteSign(pitch, duration, cursor, mirror) {
      var text = newElement(Element.STAFF_TEXT);
      var durationSign = getDurationSign(pitch, duration, false, mirror);
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

function addTriangle(cursor) {
      var text = newElement(Element.STAFF_TEXT);
      text.text = noteTemplate + "&lt;";
      text.pos.x = -1.9;
      text.pos.y = 0;
      cursor.add(text);
}

function addColorNote(cursor) {
      if (cursor.segment.annotations[0]) {
            if (cursor.segment.annotations[0].type == Element.STAFF_TEXT) {
                  var textElement = cursor.segment.annotations[0];
                  if (textElement.text == "&gt;") {
                        addTriangle(cursor);
                        textElement.visible = false;
                  }
            }
      }
      var element = cursor.element;
      if (element.type == Element.CHORD) {
            var note = element.notes[0];
            if (note.pitch % 12 == 8) {
                  createSharpNote(note.pitch-1, element.durationType, cursor);
            } else {
                  createSingleNote(note.pitch, element.durationType, cursor);
            }
            note.visible = false;
      } else if (element.type == Element.REST) {
            createRest(cursor);
      }


      if (element.stem) { element.stem.visible = false; }
      if (element.beam) { element.beam.visible = false; }
      if (element.hook) { element.hook.visible = false; }
      if (element.accidental) { element.accidental.visible = false; }
      

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
            text: "Original"
            onClicked: { }
      }

      Button {
            id: btnClose
            anchors.left: btnOriginal.right
            text: "Close"
            onClicked: { Qt.quit(); }
      }

}

}

