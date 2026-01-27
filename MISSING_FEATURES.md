# 🔍 Fonctionnalités Non Implémentées - Application Pharmacy

## 📋 Résumé

| Catégorie | Fonctionnalité | Statut | Priorité |
|-----------|----------------|--------|----------|
| Commandes | Rejeter une commande | ⚠️ TODO | Haute |
| Profil | Page paramètres notifications | ⚠️ TODO | Moyenne |
| Profil | Sélection de langue | ⚠️ TODO | Basse |
| Profil | Page Aide & Support | ⚠️ TODO | Moyenne |
| Profil | Conditions d'utilisation | ⚠️ TODO | Moyenne |
| Profil | Politique de confidentialité | ⚠️ TODO | Moyenne |
| Inventaire | Scan depuis image/galerie | ⚠️ TODO | Basse |
| Inventaire | Recherche produits persistante | ⚠️ TODO | Basse |
| Inventaire | Appliquer promotion stock | ⚠️ TODO | Moyenne |
| Inventaire | Supprimer produit du stock | ⚠️ TODO | Moyenne |

---

## 🛒 COMMANDES

### 1. Rejeter une commande
**Fichier**: `lib/features/orders/presentation/pages/orders_list_page.dart:219`
**Description**: La fonction pour rejeter une commande affiche seulement un SnackBar mais n'appelle pas l'API.

**Solution requise**:
1. Ajouter `rejectOrder(int id)` dans `OrderRepository`
2. Implémenter dans `OrderRepositoryImpl`
3. Ajouter la méthode dans `OrderListNotifier`
4. Connecter au bouton dans la page

---

## 👤 PROFIL

### 2. Page Paramètres Notifications
**Fichier**: `lib/features/profile/presentation/widgets/profile_menu_section.dart:54`
**Description**: Menu "Notifications" n'a pas de page dédiée.

**Solution**: Créer `notification_settings_page.dart` avec:
- Toggle notifications push
- Toggle notifications email
- Choix sons de notification
- Heures silencieuses

### 3. Sélection de langue
**Fichier**: `lib/features/profile/presentation/widgets/profile_menu_section.dart:66`
**Description**: Menu "Langue" ne fonctionne pas.

**Solution**: Créer sélecteur de langue (FR/EN) avec persistance.

### 4. Page Aide & Support
**Fichier**: `lib/features/profile/presentation/widgets/profile_menu_section.dart:78`
**Description**: Pas de page d'aide.

**Solution**: Créer page avec FAQ, contact support, liens utiles.

### 5. Conditions d'utilisation (CGU)
**Fichier**: `lib/features/profile/presentation/widgets/profile_menu_section.dart:121`
**Description**: Pas d'affichage des CGU.

**Solution**: Créer page ou modal affichant les CGU.

### 6. Politique de confidentialité
**Fichier**: `lib/features/profile/presentation/widgets/profile_menu_section.dart:132`
**Description**: Pas d'affichage de la politique.

**Solution**: Créer page ou modal affichant la politique.

---

## 📦 INVENTAIRE

### 7. Scanner depuis image/galerie
**Fichier**: `lib/features/inventory/presentation/pages/enhanced_scanner_page.dart:341`
**Description**: Le bouton "Importer depuis galerie" n'est pas implémenté.

**Solution**: Utiliser `image_picker` pour sélectionner une image et scanner le QR/barcode.

### 8. Persistance recherche produits
**Fichier**: `lib/features/inventory/presentation/widgets/product_search_widget.dart:69`
**Description**: Historique de recherche non persisté.

**Solution**: Sauvegarder dans SharedPreferences.

### 9. Appliquer promotion sur produit
**Fichier**: `lib/features/inventory/presentation/widgets/stock_alerts_widget.dart:553`
**Description**: Bouton "Promotion" ne fait rien.

**Solution**: Créer modale pour définir promotion et appeler API.

### 10. Supprimer produit du stock
**Fichier**: `lib/features/inventory/presentation/widgets/stock_alerts_widget.dart:563`
**Description**: Bouton "Supprimer" ne fait rien.

**Solution**: Appeler API de suppression avec confirmation.

---

## ✅ Fonctionnalités DÉJÀ Implémentées

- ✅ Authentification (Login, Register, Forgot Password)
- ✅ Liste des commandes avec filtres
- ✅ Détails commande
- ✅ Confirmer/Préparer commande
- ✅ Gestion inventaire
- ✅ Scanner codes-barres
- ✅ Ajout produit
- ✅ Mise à jour stock
- ✅ Alertes stock bas
- ✅ Liste ordonnances
- ✅ Notifications
- ✅ Wallet/Finances
- ✅ Rapports & Analytics
- ✅ Paramètres sécurité (PIN, Biométrie)
- ✅ Paramètres apparence (Thème, Couleur accent)
- ✅ Profil utilisateur (Édition)
- ✅ Profil pharmacie (Édition)
- ✅ Mode garde

---

## 🎯 Prochaines Étapes Recommandées

1. **Haute priorité**: Implémenter `rejectOrder` (critique pour la gestion des commandes)
2. **Moyenne priorité**: Pages légales (CGU, Confidentialité) pour conformité
3. **Basse priorité**: Améliorations UX (langue, recherche persistante)
