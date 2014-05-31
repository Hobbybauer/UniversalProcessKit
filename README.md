# UniversalProcessKit

## Nutzen

Das UniversalProcessKit, kurz UPK, stellt Funktionen für Modder und
Mapper bereit, damit diese so wenig wie möglich oder auch gar nicht mehr
selber skripten müssen. Dafür wurden bis jetzt etwa 4.500 Codezeilen neu geschrieben. Die Nutzung des UPK ist kostenlos.

#### Hinweise zum Gebrauch

Es ist nicht gestattet diese Skripte in Maps oder Mods selbst
einzubinden. Bitte verweist darauf, dass die Nutzer eurer Mods
zusätzlich das UPK im Modordner haben müssen, damit eure Mods
funktionieren.

## Instalation

Dies ist die Entwickler-Seite des UniversalProcessKits. Es werden
Features ausprobiert oder es kann auch mal eine kaputte Version online
stehen. Hier ist nichts "fertig" und es kann täglich zu Änderungen der
Skripte kommen. Wenn du eine gebrauchsfähige Version suchst, schau auf
http://www.modhoster.de/mods/universalprocesskit.

Lade dir die AAA_UniversalProcessKit.zip aus dem Ordner 00_mod-beta (https://github.com/mor2000/UniversalProcessKit/blob/master/00_mod-beta/AAA_UniversalProcessKit.zip?raw=true) herunter und speicher sie in deinem Mod-Ordner.

## Updates

Um immer auf dem Laufenden zu bleiben und alle Änderungen zu verfolgen einfach https://github.com/mor2000/UniversalProcessKit/commits/master.atom als Feed abonnieren.


## Funktionsweise

Dieses Kit besteht aus einer __Basis__ sowie __Triggern__, deren
Aktionen durch den Spieler ausgelöst werden, und __Funktionen__, die je
nach Füllstand aktiv werden. Es kann zudem durch selbst programmierte
__Module__ erweitert werden.

Die Steuerung des UPK wird allein über UserAttributes in der i3d geregelt. Mapper und Modder "verwenden" die Funktionen einfach (wie die Funktionen der Giants-Skripte auch) - es ist nicht nötig/erlaubt das UPK zu "verbauen".

Die Anordnung der Trigger, Funktionen und Module ist hierarchisch. Die
Trigger sind üblicherweise das letzte Glied und regeln die Ein- und
Ausgabe. Alles zwischen Triggern und der Basis ist frei konfigurierbar.
Es kann Module geben, die wie ein Zwischenlager fungieren und Früchte
nur in einer bestimmten Geschwindikgeit "nach oben" an die Base
weitergeben oder ganz stoppen. Ein _processor_ kann auf diesen Füllstand
zugreifen und in einen anderen umwandeln, der nach oben durchgelassen
wird. Somit lassen sich kleine Mods, die nur etwas lagern, oder große
mit komplexer Funktionalität wie Fabriken mit dem UPK erschaffen.

Mods, die das UPK verwenden, sind automatisch multiplayer-fähig. Eine Einschränkung gibt es zur Zeit noch: Das gilt nur für verbaute Mods. Platzierbare Mods gehen nur im Single-Player, da bin ich noch dabei.

### Basis

Die _base_ verwaltet alle Füllstände. Alle Trigger und Funktionen greifen im einfachsten Fall auf die Füllstände der _base_ zurück.

Die _base_ ist über PlaceableUPK platzierbar oder über mit dem GE in eine Karte verbaubar (siehe Anwendung).

### Trigger

Im Moment gibt es folgende Trigger:

1.  __tiptrigger__: entlädt alle Arten von Anhängern (Kipper, Wasser-, Gülle- und Benzinanhänger)

2.  __dumptrigger__: fängt das Entladen von Schaufeln und Erntemaschinen auf

3.  __filltrigger__: lädt alle Arten von Anhänger (siehe tiptrigger) sowie Schaufeln, Ladewagen und Ballenpressen

4.  __balertrigger__: wie der _filltrigger_ nur für Ladewagen und Ballenpressen

5.  __displaytrigger__: veranlasst die Anzeige von Füllständen

6.  __buytrigger__: ermöglicht das Freischalten von untergeordneten Modulen durch Kauf oder Miete

### Funktionen

1.  __processor__: Das Kernstück des UPK. Es erzeugt Güter bzw. Früchte, wenn gewünscht verbraucht es dafür andere.

2.  __mover__: verändert die Eigenschaften der Position, Sichtbarkeit und Rotation je nach Füllstand

3.  __scaler__: skaliert je nach Füllstand das Shape

4.  __switcher__: zeigt je nach Füllstand bzw. Fruchtart ein entsprechendes Shape an

5.  __storage__: lässt sich im UPK wie eine weitere _base_ verwenden und kann Füllstände speichern

## Verfügbare UserAttributes

### Allgemein (für alle UPK-Module)

-   __*type__ (string): legt die Art des Moduls fest, zB.
    "tiptrigger", "processor" usw.

-   __capacity__ (float): Festlegung der maximalen Füllmenge

-   __isEnabled__ (bool): Modul ist aktiviert oder deaktiviert,
    entweder "true" oder "false" (default: true)

-   __i18nNameSpace__ (string): Name des Mods genau wie er im Modordner als Zip oder Ordner liegt, um auf selbst festgelegte
    Namen in der l10n der modDesc zuzugreifen, bspw. auf Namen von
    Fruchtsorten, die der Mod neu einführt. (default: ohne)

-   __adjustToTerrainHeight__ (bool): Ob der Ursprung des Shapes (0,0,0) auf die Terrain-Höhe angeglichen wird. Empfehlenswert für die base von allen UPK-Mods. Auch ohne Modul bei beliebigen Shapes im UPK-Mod setzbar (default: false)

### base

Besonderheit: "type" wird durch die Verwendung als Basis festgelegt, nicht durch das Setzen des UserAttributes.

-   __storageType__ (string): wie die Füllstande gespeichert werden sollen, entweder "separate", "single", "fifo" oder "filo" (default: "separate")

### tiptrigger

-   __*fillTypes__ (string): Namen der akzeptierten Fruchtsorten,  mit Leerzeichen getrennt, bspw. "wheat barley rape"

-   __fillLitersPerSecond__ (float): Geschwindigkeit der Ausschüttung (default: 1500)

-   __MapHotspot__ (string): Name des Icons zur Anzeige auf dem PDA. Keine Anzeige, falls leer

-   __allowTrailer__ (bool): akzeptiert Kipper als Füllobjekt, entweder "true" oder "false" (default: true)

-   __allowWaterTrailer__ (bool): erlaubt Wasseranhängern das Abladen, entweder "true" oder "false" (default: true)

-   __allowFuelTrailer__ (bool): erlaubt Tankanhängern das Abladen, entweder "true" oder "false" (default: false)

-   __allowLiquidManureTrailer__ (bool): erlaubt Gülleanhängern das Abladen, entweder "true" oder "false" (default: false)

-   __allowMilkTrailer__ (bool): erlaubt Milchanhängern das Abladen, entweder "true" oder "false" (default: false)

-   __allowSprayer__ (bool): erlaubt Spritzen/ Düngestreuer das Abladen, entweder "true" oder "false" (default: false)

-   __showNoAllowedText__ (bool): ob angezeigt werden soll, wenn eine Fruchtsorte nicht akzeptiert wird, entweder "true" oder "false" (default: false)

-   __NotAcceptedText__ (string): Name des l10n-Textes bei Anzeige dass eine Fruchtsorte nicht akzeptiert wird (default: "notAcceptedHere")

-   __CapacityReachedText__ (string): Text der angezeigt wird wenn die Füllmenge erreicht ist (default: "capacityReached")

-   __l10n\_displayName__ (string): (nicht vergessen i18nNameSpace beim entsprechendem _tiptrigger_ zu setzen) anzuzeigender Triggername, v.a. zum Abladen von Flüssigkeiten. Muss
	im l10n-Abschnitt der modDesc aufgeführt sein (default: ohne)


### dumptrigger

-   __*fillTypes__ (string): Namen der akzeptierten Fruchtsorten,
    mit Leerzeichen getrennt, bspw. "wheat barley rape"

### filltrigger

-   __*fillType__ (string): Name der auszuschüttenden Fruchtsorte,
    bspw. "wheat" (default: "unknown")

-   __fillLitersPerSecond__ (float): Geschwindigkeit der Ausschüttung
    (default: 1500)

-   __createFillType__ (bool): greift auf den Füllstand zurück oder erzeugt fillType einfach so, entweder "true" oder
	"false" (default: false)

-   __pricePerLiter__ (float): Kosten des fillTypes pro Liter (default:
    0)

-   __statName__ (string): (falls pricePerLiter nicht 0) zu welcher Statistik
    die Kosten gebucht wird, entweder "newVehiclesCost",
    "newAnimalsCost", "constructionCost", "vehicleRunningCost",
    "propertyMaintenance", "wagePayment", "harvestIncome",
    "missionIncome", "other", "loanInterest" (default: "other")

-   __allowTrailer__ (bool): akzeptiert Kipper als Füllobjekt, entweder "true" oder "false" (default: true)

-   __allowShovel__ (bool): akzeptiert Schaufeln als Füllobjekt, entweder "true" oder "false" (default: true)

-   __allowSowingMachine__ (bool): akzeptiert Sämaschinen als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowWaterTrailer__ (bool): akzeptiert Wasseranhänger als Füllobjekt, entweder "true" oder "false" (default: true)

-   __allowSprayer__ (bool): akzeptiert Spritzen/ Düngestreuer als Füllobjekt, entweder "true" oder "false" (default: true)

-   __allowFuelTrailer__ (bool): akzeptiert Tankanhänger als Füllobjekt, entweder "true" oder "false" (default: true)

-   __allowFuelRefill__ (bool): (für fillType=fuel) legt fest, ob der Filltrigger bei Treibstoff auch Traktoren, Erntemaschinen etc. betanken kann, entweder "true" oder "false". Nicht
	vergessen die collisionMask des Triggers entsprechend abzuändern! (default: false)

-   __allowMilkTrailer__ (bool): akzeptiert Milchanhänger als Füllobjekt, entweder "true" oder "false" (default: true)

-   __allowForageWagon__ (bool): akzeptiert Ladewagen als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowBaler__ (bool): akzeptiert Ballenpressen als Füllobjekt, entweder "true" oder "false" (default: false)

-   __useParticleSystem__ (bool): legt fest ob Partikel beim Laden angezeigt werden sollen, entweder "true" oder "false" (default:
    false)

-   __particleSystem__ (string): Name des Partikelsystems (default: "wheatParticleSystemLong")

-   __particlePosition__ (string): Lage des Ursprungs der Partikel (default: "0 0 0")

-   __useFillSound__ (bool): gibt an, ob ein Sound beim Befüllen abgespielt werden soll (default: true)

-   __fillSoundFilename__ (string): Pfad zur Sounddatei (default: "$data/maps/sounds/siloFillSound.wav")

### balertrigger

Identisch zum _filltrigger_ mit denselben Attributen, jedoch mit der Standardkonfiguration, dass nur Ladewagen und Ballenpressen akzeptiert werden. Da die Ladewagen oder Ballenpressen in den Trigger fahren müssen, um erkannt zu werden, ist er zu groß für die Konfiguration mit Schaufeln, da diese dann in 2 oder 3 Meter Entfernung schon befüllt werden würden.

-   __allowTrailer__ (bool): akzeptiert Kipper als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowShovel__ (bool): akzeptiert Schaufeln als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowSowingMachine__ (bool): akzeptiert Sämaschinen als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowWaterTrailer__ (bool): akzeptiert Wasseranhänger als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowSprayer__ (bool): akzeptiert Spritzen/ Düngestreuer als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowFuelTrailer__ (bool): akzeptiert Tankanhänger als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowFuelRefill__ (bool): (für fillType=fuel) legt fest, ob der Filltrigger bei Treibstoff auch Traktoren, Erntemaschinen etc. betanken kann, entweder "true" oder "false". Nicht
	vergessen die collisionMask des Triggers entsprechend abzuändern! (default: false)

-   __allowMilkTrailer__ (bool): akzeptiert Milchanhänger als Füllobjekt, entweder "true" oder "false" (default: false)

-   __allowForageWagon__ (bool): akzeptiert Ladewagen als Füllobjekt, entweder "true" oder "false" (default: true)

-   __allowBaler__ (bool): akzeptiert Ballenpressen als Füllobjekt, entweder "true" oder "false" (default: true)


### displaytrigger

-   __fillTypes__ (string): Namen der anzuzeigenden Fruchtsorten, mit
    Leerzeichen getrennt, bspw. "wheat barley rape"

-   __i18nNameSpace__ (string): (falls nicht in der base festgelegt) Name des Mods genau wie er im Modordner als Zip oder Ordner liegt, um auf selbst festgelegte
    Namen in der l10n der modDesc zuzugreifen, bspw. auf Namen von
    Fruchtsorten, die der Mod neu einführt. (default: ohne)

-   __onlyFilled__ (bool): legt fest, ob nur Füllstände ungleich 0
    angezeigt werden soll, entweder "true" oder "false" (default:
    false)

-   __showFillLevel__ (bool): legt fest, ob die Füllstände mit
    absoluten Zahlen angezeigt werden soll, entweder "true" oder "false"
    (default: true)

-   __showPercentage__ (bool): legt fest, ob die Füllstände relativ
    zur Füllmenge angezeigt werden soll, entweder "true" oder "false"
    (default: false)

### buytrigger

Dieses Trigger ist gerade in der Entwicklung und noch nicht einsatzfähig.

-   __isBought__ (bool): legt fest, ob das Objekt schon gekauft ist, entweder "true" oder "false" (default: false)

-   __sellable__ (bool): legt fest, ob das Objekt gekauft werden kann, entweder "true" oder "false" (default: true)

-   __buyable__ (bool): legt fest, ob das Objekt verkauft werden kann, entweder "true" oder "false" (default: true)

-   __mode__ (string): entweder "buy" falls das Objekt kaufbar sein soll, oder "rent" für Miete (default: "buy")

-   __cost__ (float): (für mode="buy") Preis für das Objekt beim Kauf (default: 0)

-   __revenues__ (float): (für mode="buy") Erlös für das Objekt beim Verkauf (default: 0)

-   __dailyRent__ (float): (für mode="rent") tägliche Kosten der Miete (default: 0)

-   __statName__ (string): zu welcher Statistik der Betrag gebucht wird, entweder "newVehiclesCost", "newAnimalsCost", "constructionCost", "vehicleRunningCost",
    "propertyMaintenance", "wagePayment", "harvestIncome", "missionIncome", "other", "loanInterest" (default: "constructionCost")

-   __i18nNameSpace__ (string): (falls nicht in der base festgelegt) Name des Mods genau wie er im Modordner als Zip oder Ordner liegt, um auf selbst festgelegte
    Namen in der l10n der modDesc zuzugreifen, bspw. auf Namen von
    Fruchtsorten, die der Mod neu einführt. (default: ohne)

-   __objectName__ (string): Name des kauf-/mietbaren Objekts, der auf den entsprechenden Eintrag in der modDesc verweist (default: ohne)

### processor

-   __*product__ (string): legt fest, welche Fruchtsorte erzeugt
    werden soll - Geld ist "money" (default: ohne)

-   __recipe__ (string): wie ein Liter des Produkts hergestellt werden
    soll, jeweils Menge und Fruchtsorte mit Leerzeichen getrennt, bspw
    "0.5 wheat 0.3 water 0.2 salt", zu lesen als "1 Liter des Produkts
    ergeben sich aus 0,5l Weizen + 0,3l Wasser + 0,2l Salz" (default:
    ohne)

-   __productionPrerequisite__ (string): listet die Füllstände der Fruchtsorten auf, die zwingend vorhanden sein müssen, um 1 Liter des Produkts herzustellen. Bei product="cow" und productionPrerequisite="100 wheat_windrow" werden höchstens 5 Kühe produziert, wenn der Füllstand von Weizenstroh 500 Liter beträgt. Mit den aufgeführten Fruchtsorten passiert nichts weiter (default: ohne)

-   useRessources: veraltetet, productionPrerequisite benutzen

-   __byproducts__ (string): ähnlich wie recipe, nur werden die hier aufgelisteten dem Füllstand hinzugefügt, nicht abgezogen, um das Herstellen mehrerer Produkte zu ermöglichen. Im Verhältnis zu einem Liter des Produkts anzugeben. (default: ohne)

-   __onlyWholeProducts__ (bool): ob nur ganze Zahlen dem Füllstand
    hinzugefügt werden sollen, entweder "true" oder "false" (default:
    "false")

-   __a) productsPerMinute__ (float): welche Menge maximal pro Minute (Spielzeit) 
    erzeugt wird (veranlasst die Produktion der Fruchtsorte im
    Minutentakt) (default: 0)

-   __b) productsPerHour__ (float): welche Menge maximal pro Stunde (Spielzeit) 
    erzeugt wird (veranlasst die Produktion der Fruchtsorte im
    Stundentakt) (default: 0)

-   __c) productsPerDay__ (float): welche Menge maximal pro Tag (Spielzeit) erzeugt
    wird (veranlasst die Produktion der Fruchtsorte im Tagestakt)
    (default: 0)

-   __d) productsPerSecond__ (float): welche Menge maximal pro Sekunde (Echtzeit)
    erzeugt wird (veranlasst die Produktion der Fruchtsorte in Echtzeit). (default: 0)

-   __productionHours__ (string): für productsPerMinute, productsPerHour oder productsPerSecond. Legt fest, zu welchen Stunden produziert
	werden soll, Mitternacht ist 0 (nicht 24). Bsp: "6-12, 14-18" bedeutet von 6:00:00 bis 12:59:59 und von 14:00:00 bis 18:59:59 wird produziert (default: 0-23)

-   __productionInterval__ (float): in welchem Abstand der _processor_ tatsächlich produziert. Bspw. bei Verwendung von productionsPerMinute und productionInteral=5 würde alle 5 Minuten produziert werden. Auch in Kombination mit productionHours und productionProbability möglich. Gut für Wachstumszyklen und Prozessen, die länger als 1 Tag dauern sollen. "1" bedeutet jedes Mal, "x"  jedes x-te Mal (default: 1)

-   __productionProbability__ (float): Wahrscheinlichkeit als Kommazahl zwischen 0 und 1, ob die Produktion tatsächlich
	ausgeführt wird. Gut für zufällige Ereignisse oder Tierfarmen. Bsp: Beim Verwenden von productsPerHour und einer productionProbability von 0.8 (=80% Wahrscheinlichkeit), wird im Schnitt bei 4 von 5 Stunden etwas produziert (default: 1)

-   __outcomeVariation__ (float): Bestimmt um welchen Grad die Produktion schwankt, in Werten zwischen 0 und 1. Bsp: Eine Fabrik soll
	nicht jedes mal exakt(!) die Menge produzieren, die angegeben ist, sondern die hergestellten Güter sollen für jeden Durchgang 5%
	nach oben oder unter schwanken (outcomeVariation=0.05). Für productsPerHour=100 und outcomeVariation=0.05 werden stündlich zwischen
	95 und 105 Güter produziert - die dafür benötigten Asugangsressourcen werden entsprechend mehr oder weniger verbraucht (default: 0)

-   __outcomeVariationType__ (string): Legt die Verteilung für die zufällige Abweichung bei outcomeVariation fest. "equal" für
	Gleichverteilung und "normal" für Normalverteilung. Der Rechenaufwand für "normal" ist höher als für "equal", deshalb
	diese Variante sparsam einsetzen! (default: "equal")

-   __statName__ (string): (falls product="money") zu welcher Statistik (siehe Finanzen im PDA)
    der Betrag gebucht wird, entweder "newVehiclesCost",
    "newAnimalsCost", "constructionCost", "vehicleRunningCost",
    "propertyMaintenance", "wagePayment", "harvestIncome",
    "missionIncome", "other", "loanInterest" (default: "other")

### mover

-   __fillTypes__ (string): Namen der Fruchtsorten auf die reagiert werden soll, mit Leerzeichen getrennt, bspw. "wheat barley rape"

-   __fillTypeChoice__ (string): Welcher Wert bei mehreren Fruchtsorten genommen wird, entweder "max" oder "min" (default: "max")

-   __startMovingAt__ (float): (default: 0)

-   __stopMovingAt__ (float): (default: Wert von capacity)

-   __lowPosition__ (string): (default: "0 0 0")

-   __highPosition__ (string): (default: Wert von lowPosition)

-   __lowerPosition__ (string): (default: Wert von lowPosition)

-   __higherPosition__ (string): (default: Wert von highPosition)

-   __moveType__ (string): (default: "linear")

-   __startRotatingAt__ (float): (default: 0)

-   __stopRotatingAt__ (float): (default: Wert von capacity)

-   __lowRotationsPerSecond__ (string): (default: "0 0 0")

-   __highRotationsPerSecond__ (string): (default: Wert von lowRotationsPerSecond)

-   __lowerRotationsPerSecond__ (string): (default: Wert von lowRotationsPerSecond)

-   __higherRotationsPerSecond__ (string): (default: Wert von highRotationsPerSecond)

-   __rotationType__ (string): (default: "linear")

-   __startVisibilityAt__ (float): (default: 0)

-   __stopVisibilityAt__ (float): (default: Wert von capacity)

-   __visibilityType__ (string): Ob die Sichtbarkeit zwischen start- bzw. stopVisibilityAt gelten soll ("show") oder außerhalb ("hide") (default: "show")

###scaler

Skaliert je nach Füllstand das entsprechende Shape.

-   __fillTypeChoice__ (string): Welcher Wert bei mehreren Fruchtsorten genommen wird, entweder "max" oder "min" (default: "max")

-   __startScalingAt__ (float): (default: 0)

-   __stopScalingAt__ (float): (default: Wert von capacity)

-   __lowScale__ (string): (default: "0 0 0")

-   __highScale__ (string): (default: Wert von lowScale)

-   __lowerScale__ (string): (default: Wert von lowScale)

-   __higherScale__ (string): (default: Wert von highScale)

-   __scaleType__ (string): (default: "linear")

###switcher

Der _switcher_ umfasst mehrere Shapes oder TransformGroups (auch leere), die entweder in Abhängigkeit von der Fruchtsorte (es empfiehlt sich bei der _base_ oder _storage_ den storageType="single" zu setzen) oder des Füllstandes ausgetauscht werden. Dabei entspricht die Reihenfolge der Auflistung jeweils der Reihenfolge des Shapes. Im Modus "stack" beim Füllstand werden alle Shapes bis zum aktuellen Füllstand angezeigt.

-   __*fillTypes__ (string): Auflistung der zu berücksichtigenden Fülltypen (bspw. "water apfel")

-   __a) switchFillTypes__ (string): listet die Fruchtsorten auf, für die die Shapes angezeigt werden sollen. Zeigt das
	entsprechende Shape an, für das der Fruchttyp den maximalen oder minimalen (siehe fillTypeChoice) Füllstand hat. Es muss also genau so
	viele Shapes wie aufgelistete Fruchtsorten geben. Leere TransformGroups sind auch möglich.

-   __b) switchFillLevels__ (string): listet die Füllstände auf, bis zu welchem maximalen oder minimalen (siehe fillTypeChoice) Füllstand die Shapes angezeigt werden sollen. Die Zahlen geben der Reihenfolge nach an, bis wann ein Shape angezeigt werden soll. Es muss 1 Shape mehr geben als Zahlen aufgelistet sind - das letzte Shape wird immer "bis unenedlich" angezeigt. Leere TransformGroups sind auch möglich.

-   __fillTypeChoice__ (string): gibt die Entscheidungsregel an, welche Fruchtsorte (bei switchFillTypes) oder welcher Füllstand (bei switchFillLevels) bei mehreren genommen wird, "max" oder "min" (default: "max")

-   __mode__ (string): gibt den Modus des _switchers_ an. Der Modus "stack" gibt bei Verwendung von switchFillLevels an, dass
	 alle Shapes bis zu dem entsprechenden Füllstand angezeigt werden. Bspw. um Kartoffelsäcke an einer Marktbude nach und nach
	 einblenden zu lassen (default: leer)

-   __hidingPosition__ (string): relative Position der verborgenen Shapes (default: "0 -10 0")

### storage

Wie eine zusätzliche _base_ innerhalb des UPK-Mods, die unabhägig Füllstände speichern kann.

-   __storageType__ (string): wie die Füllstande gespeichert werden sollen, entweder "separate", "single", "fifo" oder "filo" (default: "separate")

-   __a) leakPerMinute__ (string): welche Menge maximal pro Minute (Spielzeit) 
    an das übergeordnete Modul weitergegeben wird, jeweils Menge und Fruchtsorte mit Leerzeichen getrennt, bspw
    "500 wheat 150 water" (default: ohne)

-   __b) leakPerHour__ (string): welche Menge maximal pro Stunde (Spielzeit) 
    an das übergeordnete Modul weitergegeben wird, jeweils Menge und Fruchtsorte mit Leerzeichen getrennt, bspw
    "500 wheat 150 water" (default: ohne)

-   __c) leakPerDay__ (string): welche Menge maximal pro Tag (Spielzeit) 
    an das übergeordnete Modul weitergegeben wird, jeweils Menge und Fruchtsorte mit Leerzeichen getrennt, bspw
    "500 wheat 150 water" (default: ohne)

-   __d) leakPerSecond__ (string): welche Menge maximal pro Sekunde (Echtzeit) 
    an das übergeordnete Modul weitergegeben wird, jeweils Menge und Fruchtsorte mit Leerzeichen getrennt, bspw
    "500 wheat 150 water" (default: ohne)

-   __leakVariation__ (float): Bestimmt um welchen Grad die Weitergabe schwankt, in Werten zwischen 0 und 1 ähnlich
	outcomeVariation beim _processor_ (default: 0)

-   __leakVariationType__ (string): Legt die Verteilung für die zufällige Abweichung bei leakVariation fest. "equal" für
	Gleichverteilung und "normal" für Normalverteilung. Der Rechenaufwand für "normal" ist höher als für "equal", deshalb
	diese Variante sparsam einsetzen! (default: "equal")


## Beispiele

1.  __Apfelmod__: Der __Apfelbaum__ besteht aus einem _switcher_, einem _filltrigger_, einem _displaytrigger_ und einem _proessor_. Der _processor_ erzeugt die Äpfel (16l/h) und der _filltrigger_ füllt Kipper und Schaufeln. Der _switcher_ zeigt je nach Füllstand das entsprechende Shape mit der Apfellautextur an (oder eben nicht). Der __Straßenverkauf__ ist ein _processor_, ein _tiptrigger_, ein _dumptrigger_, ein _displaytrigger_ und ein _mover_. Der _processor_ wandelt pro Stunde max. 200 Äpfel in 100 "money", also Geld, um und der _mover_ regelt die y-Höhe der Apfelplane.

#### appleTree.i3d

```
    <UserAttributes>
      <UserAttribute nodeId="28">
        <Attribute name="switchFillLevels" type="string" value="120 200 280 360"/>
        <Attribute name="type" type="string" value="switcher"/>
      </UserAttribute>
      <UserAttribute nodeId="35">
        <Attribute name="fillLitersPerSecond" type="float" value="15"/>
        <Attribute name="type" type="string" value="filltrigger"/>
      </UserAttribute>
      <UserAttribute nodeId="36">
        <Attribute name="type" type="string" value="displaytrigger"/>
      </UserAttribute>
      <UserAttribute nodeId="37">
        <Attribute name="onlyWholeProducts" type="string" value="true"/>
        <Attribute name="product" type="string" value="apfel"/>
        <Attribute name="productsPerHour" type="float" value="16"/>
        <Attribute name="type" type="string" value="processor"/>
      </UserAttribute>
      <UserAttribute nodeId="26">
        <Attribute name="capacity" type="float" value="400"/>
        <Attribute name="fillTypes" type="string" value="apfel"/>
        <Attribute name="i18nNameSpace" type="string" value="Apfelmod"/>
        <Attribute name="storageType" type="string" value="single"/>
      </UserAttribute>
    </UserAttributes>
```

#### appleKiosk.i3d

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
        <Attribute name="capacity" type="float" value="2000"/>
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
      <UserAttribute nodeId="33">
        <Attribute name="fillTypes" type="string" value="apfel"/>
        <Attribute name="lowPosition" type="string" value="0 -0.148 0"/>
        <Attribute name="highPosition" type="string" value="0 0 0"/>
        <Attribute name="moveType" type="string" value="square"/>
        <Attribute name="type" type="string" value="mover"/>
      </UserAttribute>
	</UserAttributes>
```

2. __Weitere Hofsilos__: Das ist eine kleine i3d, die die Funktionalität des normalen Hofsilos hat (mit eigenen Füllständen versteht sich). Einfach in die Karte importieren und Form und Größe der Trigger anpassen. Es besteht aus einer _base_ (nodeId 1), einem _tiptrigger_ (nodeId 101), einem _dumptrigger_ (nodeId 108), einem _displaytrigger_ (nodeId 107) und 4 _filltrigger_ (nodeIds 103-106). Der _tiptrigger_ ist zum Entladen von Kippern, der _dumptrigger_ zum Entladen von Schaufeln und Erntemaschinen (ist eigentlich kein Trigger, nur ein flaches Objekt am Boden was Schaufeln glauben lässt, sie entlädt in einen Kipper), die _filltrigger_ zum Füllen von Kippern und der _displaytrigger_ zum Anzeigen der Füllstände.

```
<UserAttributes>

  <UserAttribute nodeId="1">
    <Attribute name="fillTypes" type="string" value="wheat barley rape maize"/>
    <Attribute name="onCreate" type="scriptCallback" value="UniversalProcessKit.onCreate"/>
  </UserAttribute>

  <UserAttribute nodeId="101">
	<Attribute name="type" type="string" value="tiptrigger"/>
  </UserAttribute>

  <UserAttribute nodeId="108">
	<Attribute name="type" type="string" value="dumptrigger"/>
  </UserAttribute>

  <UserAttribute nodeId="107">
	<Attribute name="type" type="string" value="displaytrigger"/>
  </UserAttribute>

  <UserAttribute nodeId="103">
    <Attribute name="fillType" type="string" value="wheat"/>
    <Attribute name="particlePosition" type="string" value="0 7.7 0"/>
    <Attribute name="type" type="string" value="filltrigger"/>
  </UserAttribute>

  <UserAttribute nodeId="104">
    <Attribute name="fillType" type="string" value="barley"/>
    <Attribute name="particlePosition" type="string" value="0 7.7 0"/>
    <Attribute name="type" type="string" value="filltrigger"/>
  </UserAttribute>

  <UserAttribute nodeId="105">
    <Attribute name="fillType" type="string" value="rape"/>
    <Attribute name="particlePosition" type="string" value="0 7.7 0"/>
    <Attribute name="type" type="string" value="filltrigger"/>
  </UserAttribute>

  <UserAttribute nodeId="106">
    <Attribute name="fillType" type="string" value="maize"/>
    <Attribute name="particlePosition" type="string" value="0 7.7 0"/>
    <Attribute name="type" type="string" value="filltrigger"/>
  </UserAttribute>


</UserAttributes>
```


## Anwendung

Ein UPK-Mod lässt sich auf 2 Arten einbinden: als __Platzierbares Objekt__ oder zum __GE-Einbau__. An dem UPK-Mod muss nichts verändert werden, er funktioniert mit beiden Arten.

#### Zum Einbau mit dem Giants Editor

Für jeden in eine Karte verbauten UPK-Mod muss folgendes UserAttribute zur jeweiligen _base_ hinzugefügt werden:

```
    <Attribute name="onCreate" type="scriptCallback" value="UniversalProcessKit.onCreate"/>
```

#### Als platzierbares Objekt

Folgender Code muss in der register.lua des Mods stehen, die in der modDesc.xml aufgerufen wird. Dabei muss „NAME\_DES\_PLATZIERBAREN\_OBJEKTS“ durch den Namen des platzierbaren Objekts, wie er in der modDesc.xml unter storeItems verwendet wird, ersetzt werden:

```
    registerPlaceableType("NAME_DES_PLATZIERBAREN_OBJEKTS", PlaceableUPK)
```

## Ausblick

Mit der Zeit werden weitere Funktionen hinzukommen, so zB. Förderbänder. Priorität hat erstmal die Server-Client-Synchronisation.

#### Größtes Problem, das mal gelöst werden sollte

Die Netzwerksynchronisation funktioniert eigentlich ganz gut. Platzierbare und verbaute Objekte werden zwischen Server und Client synchronisiert. Das Problem entsteht beim Löschen von UPK-Objekten, da bleiben auf dem Client welche ungelöscht zurück und verursachen Fehler wegen falschen Netzwerk-Ids, die auf dem Client dann für dasgleiche Objekt andere sind, wie auf dem Server. Leider habe ich nicht rausgefunden, welche Objekte beim Löschen nicht gelöscht werden. Das sollte sich mal jemand anschauen..


# English

Download the file https://github.com/mor2000/UniversalProcessKit/blob/master/00_mod-beta/AAA_UniversalProcessKit.zip and place it in your mod folder.

Need a translation of all this? Let me know!
