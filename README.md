# Yumi 🍅🌱

Yumi è un'applicazione indipendente e open-source per la tutela del consumatore e l'analisi nutrizionale dei prodotti alimentari. 

Nata come alternativa rispettosa della privacy a servizi come Yuka, Yumi permette di conoscere istantaneamente l'impatto sulla salute di ciò che mangi senza scendere a compromessi con i tuoi dati personali.

<p align="center">
  <img src="assets/icon.png" width="120" alt="Yumi App Icon" />
</p>

## ✨ Caratteristiche Principali

- **100% Privacy-First:** Nessun account richiesto, nessun tracciamento, nessun dato inviato a server di terze parti per profilazione.
- **Scansione Rapida:** Riconoscimento immediato dei codici a barre (EAN-13, EAN-8, UPC, ecc.) tramite fotocamera o inserimento manuale.
- **Interfaccia Adattiva:** Supporto completo al tema automatico di sistema, tema scuro, modalità AMOLED per il risparmio energetico e un raffinato **Tema Chiaro Verde Acqua Scuro** ad alto contrasto.
- **Cronologia e Preferiti:** Salva i tuoi prodotti preferiti o consulta le ultime scansioni direttamente in locale sul tuo dispositivo.
- **Multilingua:** Supporto nativo per Italiano e Inglese.

## 🧮 Come Funziona l'Algoritmo (Health Score)

Yumi calcola un punteggio di salute in centesimi (`0-100`) basato su un rigido modello matematico che elabora i dati di Open Food Facts. Il calcolo segue questi passaggi esatti:

### 1. Definizione del Punteggio Base (Nutri-Score)
L'applicazione estrae il grado ufficiale Nutri-Score (`A`, `B`, `C`, `D`, `E`) e il relativo punteggio numerico di base (`da -15 a +40`).

* **Se il prodotto è Acqua:** Riceve automaticamente un punteggio di partenza di **100 punti** e non subisce malus biologici.
* **Se sono disponibili i dati numerici del Nutri-Score:**
  * **Cibi Solidi:** Il punteggio viene proporzionato sulla scala ufficiale da -15 a +40. La formula applicata è:  
    `Punteggio Base = 100 - (((NutriScore_Score + 15) / 55) * 100)`
  * **Bevande:** Il punteggio viene proporzionato sulla scala specifica per i liquidi da -20 a +40. La formula applicata è:  
    `Punteggio Base = 100 - (((NutriScore_Score + 20) / 60) * 100)`
* **Se è disponibile solo la Lettera (Grado Stimato):**  
  In mancanza del punteggio numerico preciso, viene assegnato un valore standard in base alla lettera:  
  `A = 100` | `B = 85` | `C = 65` | `D = 45` | `E = 25`.

### 2. Penalità per Additivi Nocivi
L'algoritmo analizza i tag degli additivi alimentari presenti (`E-number`) e applica una penalizzazione basata sul livello di rischio scientifico (viene applicato solo il malus della categoria più grave trovata):

* **Rischio Alto (Malus: -15 punti):** Nitriti e nitrati (`E249, E250, E251, E252`), solfiti (`E220-E228`), coloranti azoici e nocivi (`E102, E104, E110, E122, E124, E129, E131, E133, E150c, E150d, E151`), edulcoranti artificiali intensi (`E950, E951, E952, E954, E955, E961, E962`).
* **Rischio Moderato (Malus: -8 punti):** Fosfati (`E338, E339, E340, E341, E343, E450, E451, E452`), glutammati (`E620-E625`), esaltatori d'sapidità (`E627, E631, E635`), ed emulsionanti/addensanti critici (`E432-E436, E466, E471, E472e, E473, E475, E476, E491, E492`).
* **Rischio Limitato (Malus: -4 punti):** Addensanti e gelificanti secondari (`E407, E412, E414, E415, E416, E417, E425, E461`), polioli/dolcificanti di massa (`E420, E421, E953, E965, E966, E967, E968`).

### 3. Penalità per Mancanza di Certificazione Biologica
L'agricoltura biologica riduce l'esposizione ai pesticidi chimici. Se il prodotto (escluse le acque) **non possiede** tag o etichette che ne certifichino la natura biologica (`organic`), subisce un malus fisso di **-5 punti**.

### 4. Calcolo Finale e Limiti di Sicurezza
Il punteggio finale viene calcolato sottraendo i malus dal punteggio base:  
`Punteggio Finale = Punteggio Base - Malus Additivi - Malus Bio`

Per evitare che prodotti qualitativamente pessimi ricevano voti alti solo grazie all'assenza di additivi, l'algoritmo applica dei **tetti massimi invalicabili** determinati dal grado Nutri-Score reale:
* Se il Nutri-Score è **E**: il punteggio non può superare **29/100**
* Se il Nutri-Score è **D**: il punteggio non può superare **49/100**
* Se il Nutri-Score è **C**: il punteggio non può superare **69/100**

Il risultato viene infine arrotondato all'intero più vicino e limitato rigidamente nel range `0-100`.

## 📸 Screenshot

<p align="center">
  <img src="screenshots/scan_screen.png" width="350" alt="Schermata di Scansione" />
  <img src="screenshots/result_screen.png" width="350" alt="Dettaglio Prodotto" />
</p>

## 🚀 Come Iniziare (Sviluppo)

L'applicazione è sviluppata in **Flutter (Material 3)** ed è compatibile con Android e iOS.

### Prerequisiti
- Flutter SDK (versione 3.22 o superiore)
- Android Studio / Xcode

### Installazione
1. Clona la repository:
   ```bash
   git clone [https://github.com/tuo-username/yumi.git](https://github.com/tuo-username/yumi.git)

```

2. Entra nella cartella del progetto:
```bash
cd yumi

```


3. Installa le dipendenze:
```bash
flutter pub get

```


4. Avvia l'applicazione:
```bash
flutter run

```



## 🛠️ Tecnologie Utilizzate

* **Framework:** [Flutter](https://flutter.dev)
* **Scansione:** [mobile_scanner](https://pub.dev/packages/mobile_scanner) (basato su Google ML Kit)
* **Database di prodotti:** API pubbliche di [Open Food Facts](https://world.openfoodfacts.org/)
* **Persistenza Dati:** `shared_preferences` per il salvataggio locale di cronologia e impostazioni.

## 📜 Riconoscimenti Obbligatori e Licenze

Yumi è un progetto trasparente che si basa sul lavoro di grandi community open source:

* **Open Food Facts:** I dati sui prodotti provengono dal database libero e collaborativo di Open Food Facts, distribuito sotto licenza *Open Database License (ODbL)* e i contenuti multimediali sotto *CC-BY-SA*.
* **Flutter SDK & Cupertino:** Distribuiti sotto licenza *BSD 3-Clause*.
* **mobile_scanner:** Distribuito sotto licenza *MIT*.
* **shared_preferences:** Distribuito sotto licenza *BSD 3-Clause*.
* **Google ML Kit Barcode Scanning:** Soggetto ai *Google APIs Terms of Service*.

---

*Yumi è un'applicazione indipendente e non è affiliata in alcun modo a Yuka né a Open Food Facts.*

```

```
