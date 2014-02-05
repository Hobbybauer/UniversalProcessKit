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

Verfügbare UserAttributes
-------------------------

### Allgemein (für alle UPK-Module)

- __type__ (string): legt die Art des Moduls fest, zB. "tiptrigger", "processor" usw.
- __capacity__ (float): Festlegung der Füllmenge
- __isEnabled__ (string): Modul ist aktiviert oder deaktiviert, entweder "true" oder "false" (default: "true")

### tiptrigger
- __*fillTypes__ (string): Namen der akzeptierten Fruchtsorten, mit Leerzeichen getrennt, bspw. "wheat barley rape"
- __fillLitersPerSecond__ (float): Geschwindigkeit der Ausschüttung (default: 1500)
- __MapHotspot__ (string): Name des Icons zur Anzeige auf dem PDA. Keine Anzeige, falls leer
- __showNoAllowedText__ (string): ob angezeigt werden soll, wenn eine Fruchtsorte nicht akzeptiert wird, entweder "true" oder "false" (default: "false")
- __NotAcceptedText__ (string): Name des l10n-Textes bei Anzeige dass eine Fruchtsorte nicht akzeptiert wird (default: "notAcceptedHere")
- __CapacityReachedText__ (string): Text der angezeigt wird wenn die Füllmenge erreicht ist (default: "capacityReached")

### dumptrigger
- __*fillTypes__ (string): Namen der akzeptierten Fruchtsorten, mit Leerzeichen getrennt, bspw. "wheat barley rape"

### filltrigger
- __*fillType__ (string): Name der auszuschüttenden Fruchtsorte, bspw. "wheat" (default: "unknown")
- __fillLitersPerSecond__ (float): Geschwindigkeit der Ausschüttung (default: 1500)
- __createFillType__ (string): greift auf den Füllstand zurück oder erzeugt fillType einfach so, entweder "true" oder "false" (default: "false")
- __pricePerLiter__ (float): Kosten des fillTypes pro Liter (default: 0)
- __allowTrailer__ (string): akzeptiert Kipper als Füllobjekt, entweder "true" oder "false" (default: "true")
- __allowShovel__ (string): akzeptiert Schaufeln als Füllobjekt, entweder "true" oder "false" (default: "true")
- __allowSowingMachine__ (string): akzeptiert Sämaschinen als Füllobjekt, entweder "true" oder "false" (default: "true")
- __allowWaterTrailer__ (string): akzeptiert Wasseranhänger als Füllobjekt, entweder "true" oder "false" (default: "true")
- __allowSprayer__ (string): akzeptiert Spritzen/ Düngestreuer als Füllobjekt, entweder "true" oder "false" (default: "true")
- __allowFuelTrailer__ (string): akzeptiert Tankanhänger als Füllobjekt, entweder "true" oder "false" (default: "true")
- __useParticleSystem__ (string): legt fest ob Partikel beim Laden angezeigt werden sollen, entweder "true" oder "false" (default: "false")
- __particleSystem__ (string): Name des Partikelsystems (default: "wheatParticleSystemLong")
- __particlePosition__ (string): Lage des Ursprungs der Partikel (default: "0 0 0")

### displaytrigger

- __fillTypes__ (string): Namen der anzuzeigenden Fruchtsorten, mit Leerzeichen getrennt, bspw. "wheat barley rape"
- __i18nNameSpace__ (string): Name des Mods, um auf selbst festgelegte Namen in der l10n der modDesc zuzugreifen, bspw. auf Namen von Fruchtsorten, die der Mod neu einführt.
- __onlyFilled__ (string): legt fest, ob nur Füllstände ungleich 0 angezeigt werden soll, entweder "true" oder "false" (default: "false")
- __showFillLevel__ (string): legt fest, ob die Füllstände mit absoluten Zahlen angezeigt werden soll, entweder "true" oder "false" (default: "true")
- __showPercentage__ (string): legt fest, ob die Füllstände relativ zur Füllmenge angezeigt werden soll, entweder "true" oder "false" (default: "false")

### processor

- __*product__ (string): legt fest, welche Fruchtsorte erzeugt werden soll - Geld ist "money" (kein default)
- __<sup>a</sup>productsPerMinute__ (float): welche Menge maximal pro Minute erzeugt wird (veranlasst die Produktion der Fruchtsorte im Minutentakt) (default: 0)
- __<sup>b</sup>productsPerHour__ (float): welche Menge maximal pro Stunde erzeugt wird (veranlasst die Produktion der Fruchtsorte im Stundentakt) (default: 0)
- __<sup>c</sup>productsPerDay__ (float): welche Menge maximal pro Tag erzeugt wird (veranlasst die Produktion der Fruchtsorte im Tagestakt) (default: 0)
- __onlyWholeProducts__ (string): ob nur ganze Zahlen dem Füllstand hinzugefügt werden sollen, entweder "true" oder "false" (default: "false")
- __recipe__ (string): wie ein Liter des Produkts hergestellt werden soll, jeweils Menge und Fruchtsorte mit Leerzeichen getrennt, bspw "0.5 wheat 0.3 water 0.2 salt", zu lesen als "1 Liter des Produkts ergeben sich aus 0,5l Weizen + 0,3l Wasser + 0,2l Salz" (default: ohne)
- __statName__ (string): (falls product="money") zu welcher Statistik der Betrag gebucht wird, entweder "newVehiclesCost", "newAnimalsCost", "constructionCost", "vehicleRunningCost", "propertyMaintenance", "wagePayment", "harvestIncome", "missionIncome", "other", "loanInterest" (default: "other")

### mover

- __fillTypes__ (string): Namen der Fruchtsorten auf die reagiert werden soll, mit Leerzeichen getrennt, bspw. "wheat barley rape"
- __fillTypeChoice__ (string): Welcher Wert bei mehreren Fruchtsorten genommen wird, entweder "max" oder "min" (default: "max")
- __startMovingAt__ (float): (default: 0)
- __stopMovingAt__ (float): (default: Wert von capacity)
- __lowPosition__ (string): (default: "0 0 0")
- __highPosition__ (string): (default: Wert von lowPosition)
- __lowerPosition__ (string): (default: Wert von lowPosition)
- __higherPosition__ (string): (default: Wert von highPosition)
- __moveType__ (string): (default: "linear")
- __startRotatingAt__ (float): (default: 0)
- __stopRotatingAt__ (float): (default: Wert von capacity)
- __lowRotationsPerSecond__ (string): (default: "0 0 0")
- __highRotationsPerSecond__ (string): (default: Wert von lowRotationsPerSecond)
- __lowerRotationsPerSecond__ (string): (default: Wert von lowRotationsPerSecond)
- __higherRotationsPerSecond__ (string): (default: Wert von highRotationsPerSecond)
- __rotationType__ (string): (default: "linear")
- __startVisibilityAt__ (float): (default: 0)
- __stopVisibilityAt__ (float): (default: Wert von capacity)
- __visibilityType__ (string): (default: "linear")



Beispiele
---------

1. __Apfelmod__: Der __Apfelbaum__ besteht hauptsächlich aus einem processor und einem filltrigger. Der processor erzeugt die Äpfel (16l/h) und der filltrigger füllt Kipper und Schaufeln. Zusätzlich ist noch für jede der 5 Wachstumsstufen ein mover verbaut, das je nach Füllstand die entsprechende Textur anzeigt oder eben nicht). Der __Straßenverkauf__ ist ein processor, ein tiptrigger und ein mover. Der processor wandelt pro Stunde max. 200 Äpfel in 100 "money", also Geld, um und der mover regelt die y-Höhe der Apfelplane.

#### appleTree.i3d (ohne mover)
```
<UserAttributes>
 <UserAttribute nodeId="59">
  <Attribute name="capacity" type="float" value="400"/>
  <Attribute name="fillTypes" type="string" value="apfel"/>
 </UserAttribute>
 <UserAttribute nodeId="68">
  <Attribute name="fillLitersPerSecond" type="float" value="100"/>
  <Attribute name="fillType" type="string" value="apfel"/>
  <Attribute name="type" type="string" value="filltrigger"/>
 </UserAttribute>
 <UserAttribute nodeId="69">
  <Attribute name="fillTypes" type="string" value="apfel"/>
  <Attribute name="type" type="string" value="displaytrigger"/>
  <Attribute name="i18nNameSpace" type="string" value="Apfelmod"/>
 </UserAttribute>
 <UserAttribute nodeId="70">
  <Attribute name="onlyWholeProducts" type="string" value="true"/>
  <Attribute name="product" type="string" value="apfel"/>
  <Attribute name="productsPerHour" type="float" value="16"/>
  <Attribute name="type" type="string" value="processor"/>
  </UserAttribute>
 </UserAttributes>
```

#### appleKiosk.i3d (ohne mover)
```
<UserAttributes>
  <UserAttribute nodeId="31">
    <Attribute name="fillTypes" type="string" value="apfel"/>
    <Attribute name="showPercentage" type="string" value="true"/>
    <Attribute name="type" type="string" value="displaytrigger"/>
      <Attribute name="i18nNameSpace" type="string" value="Apfelmod"/>
  </UserAttribute>
  <UserAttribute nodeId="34">
    <Attribute name="product" type="string" value="money"/>
    <Attribute name="productsPerHour" type="float" value="100"/>
    <Attribute name="recipe" type="string" value="2 apfel"/>
    <Attribute name="statName" type="string" value="harvestIncome"/>
    <Attribute name="type" type="string" value="processor"/>
  </UserAttribute>
  <UserAttribute nodeId="26">
    <Attribute name="capacityApfel" type="float" value="2000"/>
    <Attribute name="fillTypes" type="string" value="apfel"/>
  </UserAttribute>
  <UserAttribute nodeId="29">
    <Attribute name="fillTypes" type="string" value="apfel"/>
    <Attribute name="type" type="string" value="dumptrigger"/>
  </UserAttribute>
  <UserAttribute nodeId="30">
    <Attribute name="fillTypes" type="string" value="apfel"/>
    <Attribute name="type" type="string" value="tiptrigger"/>
  </UserAttribute>
</UserAttributes>
```

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