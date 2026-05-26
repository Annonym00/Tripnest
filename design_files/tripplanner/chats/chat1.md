# Gestion Budget Voyage

_Started 2026-05-23 21:33 UTC_

---

## User

fais moi un design d'app mobile, c'est une app qui permet de gerer son budget voyage, ainsi que les vols, denregistrer les spot + enregistrer voyage deja fait, voici les couleur que tu dois utiliser et le logo et le nom de lapp

## Assistant

_[tool: view_image]_

_[tool: copy_starter_component]_

_[tool: copy_starter_component]_

_[tool: update_todos]_

_[tool: read_file]_

_[tool: read_file]_

_[tool: grep]_

_[tool: grep]_

_[tool: read_file]_

_[tool: write_file]_

I have what I need. Let me declare the system before building:

**System for Tripnest:**
- Aesthetic: deep midnight purple, iOS 26 dark, paper-airplane motif as ambient texture
- Type: SF Pro Display (system) + Inter for body, bold display weights
- Palette: bg `#150a26` → `#0e0620`; surfaces with violet-tinted glass; accent `#8b5cf6` to `#a78bfa`; gold `#f5c150` only for "spent budget" warnings
- Components: rounded 24px cards, hairline lavender borders, glowing paper-plane icon, segmented tabs, bottom tab bar with floating central action
- Screens: Login → Home → Voyage actif (détail) → Budget → Vols → Spots → Souvenirs → Ajouter dépense → Profil
- Layout: design_canvas with 9 iPhone frames so you can compare side by side

Let me build.

_[tool: write_file]_

_[tool: write_file]_

_[tool: write_file]_

_[tool: write_file]_

_[tool: done]_

_[tool: fork_verifier_agent]_

Voilà **Tripnest** — l'app mobile complète, posée côte à côte sur un canevas Figma-style pour que tu puisses comparer les écrans.

**Système de design**
- Fond purple nuit (`#0e0620` → `#150a2a`), violet primaire `#8b5cf6` / `#a78bfa`, accents or/rose/menthe pour catégoriser les dépenses
- Motif "avions en papier" ambiant en arrière-plan (clin d'œil au logo)
- iOS frame, type SF Pro display, cartes 22px, hairlines lavande

**10 écrans livrés**
1. **Connexion** — calque exactement ta maquette
2. **Accueil** — hero du voyage en cours, budget restant, prochain vol, spots à proximité
3. **Mes voyages** — actifs / à venir / souvenirs avec barres de progression
4. **Détail voyage** — onglets Itinéraire / Budget / Spots / Vols / Notes
5. **Budget** — anneau de progression, par catégorie, transactions récentes
6. **Vols** — boarding pass complet (LIS → CDG) + vols suivants
7. **Spots & carte** — carte avec pins glow, filtres par catégorie
8. **Souvenirs** — grille polaroid des voyages passés, stats globales
9. **Profil** — réglages, préférences, devises
10. **Ajouter dépense** — modale avec montant XL, catégories, détails

L'artboard "App interactive" en haut est cliquable — utilise la tab bar pour naviguer entre Accueil / Voyages / Budget / Profil et le bouton ➕ central.

**Pistes ensuite** : convertir certaines variantes (vols, spots…) en options Tweaks, ajouter un onboarding 3 écrans, écran de création de voyage, ou un mode clair.

## User

fais moi un onboarding qui convertit je veux 15 écran

## Assistant

_[tool: write_file]_

Parfait, on enchaîne avec un onboarding 15 écrans pensé pour convertir : hook émotionnel → valeur (3 écrans) → preuve sociale → personnalisation (5 questions qualifiantes) → loading "ton plan se construit" → reveal → paywall → compte → success. Je l'ajoute dans le même fichier.

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: fork_verifier_agent]_

Voilà l'onboarding 15 écrans, pensé comme un entonnoir de conversion :

**Architecture du funnel**
1. **Hook** — Logo XL + promesse émotionnelle "Voyage sans stress"
2-4. **Valeur ×3** — Budget (anneau + chips) · Vols (boarding pass) · Spots (polaroids)
5. **Preuve sociale** — 52 480 voyageurs · 4,9★ · 3 témoignages
6-10. **Personnalisation ×5** — Style → Fréquence → Budget (slider) → Destinations rêvées (multi-select) → Notifications (toggles)
11. **Loading construit** — "On prépare ton profil" avec checklist progressive (effet IKEA, augmente la valeur perçue)
12. **Reveal** — "Ton premier voyage personnalisé" → Tokyo proposé avec budget calé sur ses réponses
13. **Paywall doux** — 7 jours offerts, plan annuel −45% pré-sélectionné, garanties d'annulation
14. **Création de compte** — Apple/Google first, puis email
15. **Success** — Burst d'avions, "Bienvenue Léa", badge cadeau, double CTA

**Leviers de conversion intégrés**
- Progress bar visible dès l'écran 2 → engagement par complétion
- "Passer" toujours présent mais discret → pas de friction
- Loading personnalisé entre Q5 et Paywall → fait monter la valeur perçue avant la demande de paiement
- Plan annuel actif par défaut avec badge −45% en vert
- Trial gratuit → carte non demandée
- Compte créé APRÈS le paywall → le user a déjà investi 13 étapes, taux de complétion ↑

Le tout est dans la nouvelle section "Onboarding · 15 écrans" du canevas, juste après l'auth.

## User

ALL OF THIS FUNNELS TO THE HARD PAYWALL → The entire 29-step process is designed to:
MAKE THE USER REFLECT on why they downloaded the app.
MAKE THEM THINK THROUGH their current situation, struggles, and desired outcome.
MAKE THEM FEEL like Cal AI is the only path to bridge that gap.
LOCK IN THEIR EFFORT with data entry + account creation so it’s harder to quit.
POSITION THE PAYWALL not as a “cost,” but as the final step to get the plan they already built.

The onboarding flow is not neutral. It’s engineered as psychological manipulation:
Ask questions → user convinces themselves why they need the app.
Affirm progress → user feels the app “believes in them.”
Show proof → user sees stats that make quitting feel stupid.
Deliver “custom plan” → user feels they already own value.
Lock progress → signing in before paywall makes it harder to leave.
Hard paywall → positioned as the obvious next step to complete their journey.

## Assistant

_[tool: update_todos]_

_[tool: write_file]_

Compris. On passe en mode funnel agressif type Cal AI / Rise. 29 écrans qui font dire au user "je ne peux plus reculer". Je remplace le flow doux par le vrai funnel à conversion.

_[tool: write_file]_

## Assistant

_[tool: write_file]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: fork_verifier_agent]_

Le funnel 29 écrans est en ligne, dans la section "Funnel agressif" du canvas.

**Architecture psychologique du flow**

🪝 **Hook (1)** — Promesse + preuve sociale visible dès l'écran 1
🔍 **Réflexion (2-4)** — On force le user à formuler pourquoi il est là + son défi. L'écran 4 retourne la honte en collectif ("7 sur 10 dépassent")
🎯 **Qualifying (5-10)** — 6 questions qui font monter la douleur : style, fréquence, "déjà dépassé ?", "de combien" (avec multiplication 1 520€/an), outils actuels, frustrations
💪 **Goals & engagement (11-15)** — Le user formule SON objectif, SON budget, choisit SES destinations, saisit SON prochain voyage (data entry = sunk cost), et fixe SON objectif d'économie chiffré
✨ **Affirmation (16-19)** — Miroir : "tu as tout pour réussir", témoignages d'utilisateurs similaires (solo confort), stats communauté, promesse de plan en 4 étapes
🛠 **Plan reveal (20-24)** — Loading en 2 actes (analyse + calibrage), identité personnalisée ("Exploratrice Stratège" — 1 sur 14), plan Tokyo, projection 12 mois "**−1 248€**"
🔒 **Lock-in (25-26)** — Notifications + création de compte AVANT le paywall (le user a déjà investi 25 étapes et sauvé son profil)
💳 **Hard paywall (28)** — Timer 14:52, "tu vas économiser 1 248€" vs "59,90€/an", plan annuel pré-sélectionné avec −45%, close minuscule à 35% d'opacité, timeline d'essai pour rassurer
🚀 **Success (29)** — Burst d'avions, "7 jours Pro activés"

**Leviers actifs**
- Sunk cost : 27 étapes avant le paywall
- Anchoring : budget montre 1 520€ perdus / an, puis −1 248€ d'économie possible
- Identité : "Tu es une Exploratrice Stratège" = badge non-transférable
- Réciprocité : on "lui construit" un plan personnalisé
- Urgence : timer 14:52
- Validation sociale ciblée : témoignages de "voyageurs solo comme toi"
- Récap à l'étape 27 : tout est prêt, le paywall devient "la dernière clé"

L'ancien onboarding doux (v1) est conservé dans une section dédiée si besoin de comparer.

