# Expense Tracker

Εφαρμογή Flutter για κινητές συσκευές, με σκοπό την καταγραφή και παρακολούθηση καθημερινών εξόδων.

---

## Λειτουργίες

- **Διαχείριση Κατηγοριών**: Δημιουργία, επεξεργασία και διαγραφή κατηγοριών εξόδων με όνομα και προαιρετική περιγραφή
- **Προσθήκη Εξόδου**: Καταγραφή εξόδων με ποσό, περιγραφή, κατηγορία, αυτόματη ημερομηνία/ώρα και τοποθεσία GPS
- **Λίστα Εξόδων**: Προβολή όλων των εξόδων ομαδοποιημένων ανά ημέρα με λεπτομέρειες, επεξεργασία και διαγραφή
- **Ανάλυση**: Επιλογή χρονικής περιόδου και προβολή συνολικών δαπανών ανά κατηγορία ταξινομημένων φθίνουσα με οπτικές μπάρες προόδου

---

## Τεχνολογίες

- **Framework**: Flutter (Dart)
- **Βάση Δεδομένων**: SQLite μέσω `sqflite`
- **Τοποθεσία**: `geolocator`
- **Γραφήματα**: `fl_chart`
- **Πλατφόρμα**: Android

---

## Δομή Project

```
lib/
├── models/
│   ├── category.dart
│   └── expense.dart
├── db/
│   └── database_config.dart
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── add_expense_screen.dart
│   ├── expenses_screen.dart
│   ├── categories_screen.dart
│   └── analysis_screen.dart
├── widgets/
│   ├── shimmer_card.dart         
│   ├── animated_list_card.dart   
│   ├── gradient_fab.dart         
│   ├── gradient_app_bar.dart     
│   ├── section_header.dart       
│   ├── expense_card.dart         
│   ├── summary_card.dart         
│   ├── bar_chart_widget.dart     
│   └── empty_state.dart         
├── utils/
│   └── category_style.dart       
└── main.dart                     
```

---

## Σχήμα Βάσης Δεδομένων

### `categories`
| Στήλη | Τύπος | Σημειώσεις |
|-------|-------|------------|
| id | INTEGER | Πρωτεύον κλειδί, αυτόματη αρίθμηση |
| name | TEXT | Υποχρεωτικό |
| description | TEXT | Προαιρετικό |

### `expenses`
| Στήλη | Τύπος | Σημειώσεις |
|-------|-------|------------|
| id | INTEGER | Πρωτεύον κλειδί, αυτόματη αρίθμηση |
| amount | REAL | Υποχρεωτικό, σε ευρώ |
| description | TEXT | Προαιρετικό |
| category_id | INTEGER | Ξένο κλειδί → categories.id |
| date | TEXT | Μορφή ISO 8601 |
| latitude | REAL | Προαιρετικό |
| longitude | REAL | Προαιρετικό |
| location_name | TEXT | Προαιρετικό |

---

## Εκκίνηση

### Προαπαιτούμενα
- Flutter SDK
- Android Studio με εξομοιωτή Android (API 33+)

### Εκτέλεση εφαρμογής

```bash
git clone https://github.com/alexPalladis/expense-tracker.git
cd expense-tracker/expense_tracker
flutter pub get
flutter run
```
