# Service Levels

## 1. Définition du périmètre

Le présent SLO/SLA s’applique au service de production kube-api, incluant l’ensemble des composants nécessaires à sa disponibilité opérationnelle pour les utilisateurs finaux.

## 2. Définitions

- **Incident** : Un incident est défini comme une coupure franche du service d’une durée continue égale ou supérieure à 1 seconde, entraînant une indisponibilité totale du service.

- **Détection d’incident** : Identification automatique ou manuelle d’un incident conforme à la définition ci-dessus, déclenchant un événement de supervision ou d’alerte.

- **Période d’évaluation SLO** : Hebdomadaire calendaire (du lundi 00:00 au dimanche 23:59).

- **Période d’évaluation SLA** : Mensuelle calendaire (du 1er au dernier jour du mois).

## 3. Indicateurs (SLI – Service Level Indicators)
### SLI 1 – Nombre d’incidents détectés (hebdo)
- **Description** : Nombre total d’incidents détectés sur la semaine.
- **Unité** : nombre d’incidents / semaine.

### SLI 2 – Durée cumulée d’indisponibilité (hebdo)
- **Description** : Somme des durées de toutes les coupures franches détectées sur la semaine.
- **Unité** : secondes / semaine.

## 4. Objectifs de service (SLO – Service Level Objectives hebdomadaires)
### SLO 1 – Fréquence des incidents
- **Objectif** : ≤ 1 incident / semaine

### SLO 2 – Durée cumulée d’indisponibilité
- **Objectif** : ≤ 60 s / semaine

Ces SLO hebdomadaires définissent la marge opérationnelle pour l’opérateur.

## 5. Error Budget hebdomadaire
| Type                  | Limite         | Description                                          |
| --------------------- | -------------- | ---------------------------------------------------- |
| Incidents             | 1 / semaine    | Nombre maximal d’incidents autorisés pour la semaine |
| Durée indisponibilité | 60 s / semaine | Durée cumulée maximale d’indisponibilité             |

## 6. SLA mensuel (calculé à partir des SLO hebdomadaires)
### Calcul
Pour un mois calendaire, on considère 4 semaines complètes pour simplifier :
- Error budget incidents : 1 incident × 4 semaines = 4 incidents → arrondi inférieur → 4 incidents / mois
- Error budget indisponibilité : 60 s × 4 semaines = 240 s / mois

> Le SLA mensuel est donc légèrement plus strict que la simple somme des semaines pour garantir qu’un petit dépassement ponctuel hebdomadaire reste visible.

### Interprétation

- Les SLO hebdos restent la référence opérationnelle, permettant à l’opérateur une petite marge semaine par semaine.

- Le SLA mensuel sert au reporting contractuel et impose un suivi global plus strict.

## 7. KPI et suivi
| KPI           | Période | Cible         |
| ------------- | ------- | ------------- |
| KPI-INC-COUNT | Semaine | ≤ 1 incident  |
| KPI-DOWNTIME  | Semaine | ≤ 60 s        |
| KPI-INC-COUNT | Mois    | ≤ 4 incidents |
| KPI-DOWNTIME  | Mois    | ≤ 240 s       |

## 8. Politique d’error budget et gestion des dépassements

- **Hebdomadaire** : Analyse et correction locales si l’error budget hebdo est dépassé.

- **Mensuel** : Toute consommation complète ou dépassement du SLA mensuel déclenche un RCA formel, des actions correctives et, le cas échéant, des mesures contractuelles.