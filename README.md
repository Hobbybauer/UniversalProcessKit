UniversalProcessKit
===================

Grundsätzliches
---------------

Dies ist die Entwickler-Seite des UniversalProcessKits. Es werden Features ausprobiert oder es kann auch mal eine kaputte Version online stehen. Hier ist nichts "fertig" und es kann täglich zu Änderungen der Skripte kommen. Wenn du eine gebrauchsfähige Version suchst, schau auf www.modhoster.de (da wirst du wegen der momentanen Alpha-Phase nichts finden).

Nutzen
------

Das UniversalProcessKit, kurz UPK, stellt Funktionen für Modder und Mapper bereit, damit diese so wenig wie möglich oder auch gar nicht mehr selber skripten müssen.

Funktionsweise
--------------

Dieses Kit besteht aus einer __Basis__ sowie __Triggern__, deren Aktionen durch den Spieler ausgelöst werden, und __Funktionen__, die je nach Füllstand aktiv werden. Es kann zudem durch selbst programmierte __Module__ erweitert werden.

Die Steuerung des UPK wird allein über UserAttributes in der i3d geregelt.

Die Anordnung der Trigger, Funktionen und Module ist hierarchisch. Die Trigger sind üblicherweise das letzte Glied und regeln die Ein- und Ausgabe. Alles zwischen Triggern und Base ist frei konfigurierbar. Es kann Module geben, die wie ein Zwischenlager fungieren und Früchte nur in einer bestimmten Geschwindikgeit "nach oben" an die Base weitergeben oder ganz stoppen. Ein processor kann auf diesen Füllstand zugreifen und in einen anderen umwandeln, der nach oben durchgelassen wird. Somit lassen sich kleine Mods, die nur etwas lagern, oder große mit komplexer Funktionalität wie Fabriken mit dem UPK erschaffen.

### Basis

Die Basis verwaltet alle Füllstände. Alle Trigger und Funktionen greifen im einfachsten Fall auf die Füllstände der base zurück.

Die base ist über PlaceableUPK platzierbar oder über modOnCreate.UPK verbaubar.

### Trigger

Im Moment gibt es folgende Trigger:

1. __tiptrigger__: entlädt alle Arten von Anhängern (Kipper, Wasser-, Gülle- und Benzinanhänger)

2. __dumptrigger__: fängt das Entladen von Schaufeln und Erntemaschinen auf

3. __filltrigger__: lädt alle Arten von Anhänger (siehe tiptrigger) sowie Schaufeln

4. __displaytrigger__: veranlasst die Anzeige von Füllständen

### Funktionen

1. __processor__: Das Kernstück des UPK. Es erzeugt Güter bzw. Früchte, wenn gewünscht verbraucht es dafür andere.

2. __mover__: verändert die Eigenschaften der Position, Sichtbarkeit und Rotation je nach Füllstand

Beispiele
---------

1. __Apfelmod__: Der __Apfelbaum__ besteht hauptsächlich aus einem processor und einem filltrigger. Der processor erzeugt die Äpfel (16l/h) und der filltrigger füllt Kipper und Schaufeln. Zusätzlich ist noch für jede der 5 Wachstumsstufen ein mover verbaut, das je nach Füllstand die entsprechende Textur anzeigt oder eben nicht). Der __Straßenverkauf__ ist ein processor, ein tiptrigger und ein mover. Der processor wandelt pro Stunde max. 200 Äpfel in 100 "money", also Geld, um und der mover regelt die y-Höhe der Apfelplane.

Ausblick
--------

Mit der Zeit werden weitere Funktionen hinzukommen, so zB. Förderbänder oder switcher (zeigt verschiedene Objekte je nach Füllstand aus - fasst somit mehrere mover zusammen). Die base soll neben dem Standard "separate" 3 weitere Arten der Speicherarten bekommen: single, layered (FIFO) und layered (FILO).

Instalation
-----------

1. Lade die zuerst die Skripte bzw. alle Dateien des Projekts hier herunter: https://github.com/mor2000/UniversalProcessKit/archive/master.zip .
2. Entpacke diese Zip und gehe in den Unterordner.
3. Packe dann die Skripte erneut und benenne das Archiv "UPK.zip", das du schließlich in den Modordner kopierst.

Dieses Vorgehen ist notwendig, da Github alle Art von Quellcode hostet und keine Rücksicht auf die Packart eines Mods von LS nimmt.

Hinweise zum Gebrauch
---------------------

Es ist nicht gestattet diese Skripte in Maps oder Mods selbst einzubinden. Bitte verweist darauf, dass die Nutzer eurer Mods zusätzlich das UPK im Modordner haben müssen, damit eure Mods funktionieren.

English
=======

Unpack the downloaded zip and zip the scripts to "UPK.zip" and place it in your mods folder.

Interested in more? Let me know!